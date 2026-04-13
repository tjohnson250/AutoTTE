"""R Executor MCP server.

Manages a persistent R subprocess with a database connection, allowing agents
to execute R code and SQL queries against live databases during protocol
generation.
"""

from __future__ import annotations

import argparse
import json
import os
import select
import subprocess
import sys
import threading
import uuid
from pathlib import Path
from typing import Any

import yaml
from mcp.server.fastmcp import FastMCP

# ---------------------------------------------------------------------------
# MCP server instance
# ---------------------------------------------------------------------------

mcp = FastMCP("r_executor")

# ---------------------------------------------------------------------------
# Pure helper functions (testable without MCP or R)
# ---------------------------------------------------------------------------


def load_config(config_path: str) -> dict:
    """Load a YAML config file from *config_path*.

    Raises:
        FileNotFoundError: if the file does not exist.
    """
    path = Path(config_path)
    if not path.exists():
        raise FileNotFoundError(f"Config file not found: {config_path}")
    with open(path, "r", encoding="utf-8") as fh:
        return yaml.safe_load(fh)


def is_online(config: dict, mode_override: str = "") -> bool:
    """Return True if the database connection is available.

    *mode_override* accepts ``"online"`` or ``"offline"`` to bypass the
    config flag; an empty string defers to the config's ``online`` key.
    """
    if mode_override == "online":
        return True
    if mode_override == "offline":
        return False
    return bool(config.get("online", False))


def get_connection_code(config: dict) -> str:
    """Extract the R connection code from *config*."""
    return config.get("connection", {}).get("r_code", "")


def build_sentinel() -> str:
    """Return a unique sentinel string used to delimit R output.

    Format: ``__SENTINEL_{12-hex-chars}__``
    """
    hex12 = uuid.uuid4().hex[:12]
    return f"__SENTINEL_{hex12}__"


def wrap_r_code(code: str, max_output_lines: int = 200) -> tuple[str, str]:
    """Wrap *code* in a tryCatch block that emits a sentinel on completion.

    Returns:
        A tuple of ``(wrapped_code, sentinel)`` where *sentinel* is the
        unique marker written to stdout after the block finishes.
    """
    sentinel = build_sentinel()
    wrapped = (
        "tryCatch({\n"
        f"{code}\n"
        "}, error = function(e) {\n"
        '  cat("R_ERROR:", conditionMessage(e), "\\n")\n'
        "})\n"
        f'cat("{sentinel}\\n")\n'
    )
    return wrapped, sentinel


def truncate_output(output: str, max_lines: int = 200) -> str:
    """Return *output* truncated to *max_lines* lines.

    If the output exceeds *max_lines*, a notice is appended showing how many
    lines were omitted.
    """
    lines = output.splitlines()
    if len(lines) <= max_lines:
        return output
    kept = lines[:max_lines]
    omitted = len(lines) - max_lines
    kept.append(f"[... {omitted} lines truncated ...]")
    return "\n".join(kept)


# ---------------------------------------------------------------------------
# RSession — persistent R subprocess
# ---------------------------------------------------------------------------


class RSession:
    """Manages a single persistent R subprocess."""

    def __init__(self) -> None:
        self._proc: subprocess.Popen | None = None
        self._connected: bool = False
        self._lock = threading.Lock()

    # ------------------------------------------------------------------
    # Lifecycle
    # ------------------------------------------------------------------

    def start(self) -> None:
        """Spawn ``R --vanilla --quiet --no-save`` with stdio pipes."""
        self._proc = subprocess.Popen(
            ["R", "--vanilla", "--quiet", "--no-save"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1,  # line-buffered
        )

    def stop(self) -> None:
        """Terminate the R subprocess if running."""
        if self._proc is not None:
            try:
                self._proc.terminate()
                self._proc.wait(timeout=5)
            except Exception:
                try:
                    self._proc.kill()
                except Exception:
                    pass
            self._proc = None
            self._connected = False

    # ------------------------------------------------------------------
    # Code execution
    # ------------------------------------------------------------------

    def execute(self, code: str, timeout: int = 120) -> dict[str, Any]:
        """Send *code* to R and return its output.

        Returns a dict with keys:
          - ``stdout``: captured standard output (sentinel stripped)
          - ``stderr``: captured standard error
          - ``success``: True unless ``R_ERROR:`` appears in stderr
        """
        if self._proc is None:
            return {"stdout": "", "stderr": "R session not started.", "success": False}

        wrapped_code, sentinel = wrap_r_code(code)

        with self._lock:
            # Write code to R stdin
            try:
                self._proc.stdin.write(wrapped_code)
                self._proc.stdin.flush()
            except OSError as exc:
                return {"stdout": "", "stderr": f"Failed to write to R: {exc}", "success": False}

            # Read stdout lines until we find the sentinel
            stdout_lines: list[str] = []
            try:
                import signal

                def _timeout_handler(signum, frame):
                    raise TimeoutError("R execution timed out")

                # Use alarm-based timeout on Unix; fall back to line-by-line read
                if hasattr(signal, "SIGALRM"):
                    old_handler = signal.signal(signal.SIGALRM, _timeout_handler)
                    signal.alarm(timeout)

                try:
                    while True:
                        line = self._proc.stdout.readline()
                        if not line:
                            break  # EOF — R died
                        stripped = line.rstrip("\n")
                        if stripped == sentinel:
                            break
                        stdout_lines.append(stripped)
                finally:
                    if hasattr(signal, "SIGALRM"):
                        signal.alarm(0)
                        signal.signal(signal.SIGALRM, old_handler)

            except TimeoutError:
                return {
                    "stdout": "\n".join(stdout_lines),
                    "stderr": f"R_ERROR: Execution timed out after {timeout}s",
                    "success": False,
                }

            # Non-blocking stderr drain
            stderr_lines: list[str] = []
            try:
                readable, _, _ = select.select([self._proc.stderr], [], [], 0.1)
                if readable:
                    # Read whatever is immediately available
                    chunk = os.read(self._proc.stderr.fileno(), 65536)
                    if chunk:
                        stderr_lines = chunk.decode("utf-8", errors="replace").splitlines()
            except Exception:
                pass

        stdout = "\n".join(stdout_lines)
        stderr = "\n".join(stderr_lines)
        success = "R_ERROR:" not in stderr
        return {"stdout": stdout, "stderr": stderr, "success": success}

    # ------------------------------------------------------------------
    # Database connection
    # ------------------------------------------------------------------

    def connect_db(self, r_code: str) -> dict[str, Any]:
        """Run *r_code* to establish a DB connection and verify it.

        Sets ``_connected = True`` on success.
        """
        result = self.execute(r_code)
        if not result["success"]:
            return result

        # Verify connection by listing tables
        verify = self.execute("cat(paste(DBI::dbListTables(con), collapse=', '), '\\n')")
        if not verify["success"]:
            return verify

        self._connected = True
        return verify

    @property
    def connected(self) -> bool:
        return self._connected


# ---------------------------------------------------------------------------
# SessionRegistry — holds N configs and N lazy-initialized sessions keyed by db_id
# ---------------------------------------------------------------------------


class SessionRegistry:
    """Holds YAML configs + R sessions for any number of DBs, keyed by id.

    Sessions are created lazily on first access via get_session(). Configs
    are loaded eagerly so unknown ids can be rejected at startup.
    """

    def __init__(self) -> None:
        self._configs: dict[str, dict] = {}
        self._sessions: dict[str, RSession] = {}
        self._mode_overrides: dict[str, str] = {}

    def load_configs(self, config_paths: list[str]) -> None:
        """Load every config path and register by its id field."""
        for path in config_paths:
            cfg = load_config(path)
            db_id = cfg.get("id")
            if not db_id:
                raise ValueError(f"Config {path!r} missing 'id' field.")
            if db_id in self._configs:
                raise ValueError(
                    f"Duplicate DB id {db_id!r} across configs; ids must be unique."
                )
            self._configs[db_id] = cfg

    def db_ids(self) -> list[str]:
        return list(self._configs.keys())

    def get_config(self, db_id: str) -> dict:
        if db_id not in self._configs:
            raise KeyError(
                f"Unknown db_id {db_id!r}. Known: {sorted(self._configs)}"
            )
        return self._configs[db_id]

    def has_session(self, db_id: str) -> bool:
        return db_id in self._sessions

    def get_session(self, db_id: str) -> "RSession":
        if db_id not in self._configs:
            raise KeyError(
                f"Unknown db_id {db_id!r}. Known: {sorted(self._configs)}"
            )
        if db_id not in self._sessions:
            self._sessions[db_id] = RSession()
        return self._sessions[db_id]

    def drop_session(self, db_id: str) -> None:
        """Stop and remove a session (used after a crash to force restart)."""
        sess = self._sessions.pop(db_id, None)
        if sess is not None:
            sess.stop()

    def set_mode_override(self, db_id: str, mode: str) -> None:
        self._mode_overrides[db_id] = mode

    def get_mode_override(self, db_id: str) -> str:
        return self._mode_overrides.get(db_id, "")


# ---------------------------------------------------------------------------
# Global registry (used by MCP tools)
# ---------------------------------------------------------------------------

_registry = SessionRegistry()


def _ensure_connected(db_id: str) -> dict | None:
    """Lazily start and connect the R session for *db_id*.

    Returns an error dict if the id is unknown, offline, or the connection
    fails; otherwise None.
    """
    try:
        config = _registry.get_config(db_id)
    except KeyError:
        return {"error": f"Unknown db_id {db_id!r}. Known: {sorted(_registry.db_ids())}"}

    mode_override = _registry.get_mode_override(db_id)
    if not is_online(config, mode_override):
        db_name = config.get("name", db_id)
        return {
            "error": (
                f"Database '{db_name}' ({db_id}) is offline. "
                "Set online: true in its YAML or pass --mode online."
            )
        }

    session = _registry.get_session(db_id)
    if session.connected:
        return None

    if session._proc is None:
        try:
            session.start()
        except FileNotFoundError:
            return {"error": "R executable not found. Ensure R is installed and on PATH."}
        except Exception as exc:
            return {"error": f"Failed to start R session for {db_id}: {exc}"}

    r_code = get_connection_code(config)
    if not r_code:
        return {"error": f"No connection.r_code configured for {db_id}."}

    result = session.connect_db(r_code)
    if not result.get("success", False):
        return {"error": f"DB connection failed for {db_id}: {result.get('stderr', '')}"}

    return None


# ---------------------------------------------------------------------------
# MCP tools
# ---------------------------------------------------------------------------


@mcp.tool()
async def execute_r(code: str) -> str:
    """Execute arbitrary R code in the persistent R session.

    Args:
        code: R code to execute.
    """
    err = _ensure_connected()
    if err:
        return json.dumps(err)

    result = _session.execute(code)
    return json.dumps(
        {
            "stdout": truncate_output(result["stdout"]),
            "stderr": truncate_output(result["stderr"]),
            "success": result["success"],
        }
    )


@mcp.tool()
async def query_db(sql: str) -> str:
    """Run a SQL query via DBI and return results (up to 50 rows).

    Args:
        sql: SQL query string.
    """
    err = _ensure_connected()
    if err:
        return json.dumps(err)

    r_code = f"""
local({{
  .res <- DBI::dbGetQuery(con, {json.dumps(sql)})
  .total <- nrow(.res)
  .preview <- head(.res, 50)
  cat("ROWS:", .total, "\\n")
  cat("COLS:", paste(colnames(.preview), collapse=","), "\\n")
  cat("TYPES:", paste(sapply(.preview, class), collapse=","), "\\n")
  cat("DATA_START\\n")
  write.csv(.preview, stdout(), row.names=FALSE, quote=TRUE)
  cat("DATA_END\\n")
}})
"""
    result = _session.execute(r_code)
    if not result["success"]:
        return json.dumps({"error": result["stderr"], "stdout": result["stdout"]})

    return json.dumps(
        {
            "output": result["stdout"],
            "stderr": result["stderr"] if result["stderr"].strip() else None,
            "success": True,
        }
    )


@mcp.tool()
async def list_tables() -> str:
    """List all tables in the connected database with row counts."""
    err = _ensure_connected()
    if err:
        return json.dumps(err)

    r_code = """
local({
  .tables <- DBI::dbListTables(con)
  .counts <- sapply(.tables, function(t) {
    tryCatch(
      DBI::dbGetQuery(con, paste0("SELECT COUNT(*) AS n FROM ", t))$n,
      error = function(e) NA_integer_
    )
  })
  .df <- data.frame(table=.tables, row_count=.counts, stringsAsFactors=FALSE)
  cat(format(.df, row.names=FALSE), "\n")
})
"""
    result = _session.execute(r_code)
    return json.dumps(
        {
            "stdout": truncate_output(result["stdout"]),
            "stderr": result["stderr"] if result["stderr"].strip() else None,
            "success": result["success"],
        }
    )


@mcp.tool()
async def describe_table(table: str) -> str:
    """Return column info and sample values for *table* (LIMIT 5).

    Args:
        table: Table name to describe.
    """
    err = _ensure_connected()
    if err:
        return json.dumps(err)

    r_code = f"""
local({{
  .cols <- DBI::dbListFields(con, {json.dumps(table)})
  cat("Columns:\\n")
  cat(paste(" -", .cols), sep="\\n")
  cat("\\nSample rows (LIMIT 5):\\n")
  .sample <- DBI::dbGetQuery(con, paste0("SELECT * FROM {table} LIMIT 5"))
  print(.sample)
}})
"""
    result = _session.execute(r_code)
    return json.dumps(
        {
            "stdout": truncate_output(result["stdout"]),
            "stderr": result["stderr"] if result["stderr"].strip() else None,
            "success": result["success"],
        }
    )


@mcp.tool()
async def dump_schema() -> str:
    """Introspect the full DB schema and write it to the configured schema_dump path."""
    err = _ensure_connected()
    if err:
        return json.dumps(err)

    schema_path = _config.get("schema_dump", "")
    engine = _config.get("engine", "").lower()

    if not schema_path:
        return json.dumps({"error": "No schema_dump path configured."})

    if engine == "duckdb":
        r_code = f"""
local({{
  .tables <- DBI::dbListTables(con)
  .out <- character(0)
  for (.t in .tables) {{
    .info <- DBI::dbGetQuery(con, paste0("PRAGMA table_info(", .t, ")"))
    .out <- c(.out, paste0("TABLE: ", .t), capture.output(print(.info)), "")
  }}
  writeLines(.out, {json.dumps(schema_path)})
  cat("Schema written to {schema_path}\\n")
}})
"""
    elif engine == "mssql":
        r_code = f"""
local({{
  .cols <- DBI::dbGetQuery(con,
    "SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
     FROM INFORMATION_SCHEMA.COLUMNS
     ORDER BY TABLE_NAME, ORDINAL_POSITION")
  .out <- character(0)
  for (.t in unique(.cols$TABLE_NAME)) {{
    .tcols <- .cols[.cols$TABLE_NAME == .t, ]
    .out <- c(.out, paste0("TABLE: ", .t), capture.output(print(.tcols[,-1])), "")
  }}
  writeLines(.out, {json.dumps(schema_path)})
  cat("Schema written to {schema_path}\\n")
}})
"""
    else:
        r_code = f"""
local({{
  .tables <- DBI::dbListTables(con)
  .out <- character(0)
  for (.t in .tables) {{
    .fields <- DBI::dbListFields(con, .t)
    .out <- c(.out, paste0("TABLE: ", .t), paste0("  ", .fields), "")
  }}
  writeLines(.out, {json.dumps(schema_path)})
  cat("Schema written to {schema_path}\\n")
}})
"""

    result = _session.execute(r_code)
    return json.dumps(
        {
            "stdout": result["stdout"],
            "stderr": result["stderr"] if result["stderr"].strip() else None,
            "success": result["success"],
            "schema_path": schema_path,
        }
    )


@mcp.tool()
async def run_profiler(code: str) -> str:
    """Run agent-provided profiling R code, capturing output to the data_profile path.

    Args:
        code: R profiling code to execute.  Output is captured via sink() to
              the configured data_profile path.
    """
    err = _ensure_connected()
    if err:
        return json.dumps(err)

    profile_path = _config.get("data_profile", "")
    if not profile_path:
        return json.dumps({"error": "No data_profile path configured."})

    r_code = f"""
local({{
  sink({json.dumps(profile_path)})
  tryCatch({{
    {code}
  }}, error = function(e) {{
    cat("R_ERROR:", conditionMessage(e), "\\n")
  }}, finally = {{
    sink()
  }})
  cat("Profile written to {profile_path}\\n")
}})
"""
    result = _session.execute(r_code)
    return json.dumps(
        {
            "stdout": result["stdout"],
            "stderr": result["stderr"] if result["stderr"].strip() else None,
            "success": result["success"],
            "profile_path": profile_path,
        }
    )


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------


def main() -> None:
    global _config, _mode_override
    parser = argparse.ArgumentParser(description="R Executor MCP Server")
    parser.add_argument("--config", required=True, help="Path to database config YAML")
    parser.add_argument(
        "--mode",
        choices=["online", "offline"],
        default="",
        help="Override online/offline mode from config",
    )
    args = parser.parse_args()
    _config = load_config(args.config)
    _mode_override = args.mode
    mcp.run()


if __name__ == "__main__":
    main()
