# Multi-Database Harness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend AutoTTE's harness so one invocation can target any subset (or all) of the YAML-configured databases in `databases/`, with triage-based handling of missing profiles and a multiplexed r_executor MCP server that serves N concurrent R sessions keyed by DB ID.

**Architecture:** A new `tools/db_triage.py` module owns DB discovery and disposition logic (pure Python, fully tested). `run.sh` delegates YAML parsing, discovery, and triage to this module via CLI subcommands. `tools/r_executor_server.py` is refactored from one global R session to a registry of sessions keyed by DB ID, with `db_id` added as a required argument on every tool. Agent instructions are updated to reflect per-DB prompts and the new tool signatures. Literature discovery remains shared; feasibility → protocols → execution → reports branch per DB in a nested output layout.

**Tech Stack:** Python 3.11+, pytest, PyYAML, bash, FastMCP.

**Spec:** `docs/superpowers/specs/2026-04-12-multi-db-harness-design.md`

---

## File Structure

**New files:**
- `tools/db_triage.py` — DB discovery, triage logic, CLI entrypoint for `--list-dbs`, `--show-db`, and the JSON triage output consumed by `run.sh`.
- `tests/test_db_triage.py` — unit tests for discovery, triage dispositions, CLI output.
- `tests/test_r_executor_multi_session.py` — tests for the session registry and multi-config loading.
- `tests/test_run_sh_multi_db.sh` — end-to-end bash tests of `run.sh` argument parsing, discovery commands, and triage integration (no Claude invocation — short-circuit before the `claude -p` call).

**Modified files:**
- `tools/r_executor_server.py` — session registry, repeatable `--config`, `db_id` argument on every tool.
- `tests/test_r_executor.py` — adapt existing tests for the new registry-based code paths where they cover module-level state.
- `run.sh` — new flags (`--dbs`, `--list-dbs`, `--show-db`), triage integration, multi-config `.mcp-session.json`, multi-DB coordinator prompt.
- `COORDINATOR.md` — new "Multi-DB runs" section covering phase-major orchestration, `db_triage.json` handling, and per-DB state.
- `WORKER.md` — note that feasibility/protocol/execution workers are scoped to one DB ID and every r_executor call requires `db_id`.
- `REVIEW.md` — reviewers inherit their worker's DB ID.
- `REPORT_WRITER.md` — input JSON path moved under per-DB subdirectory.

**Out of scope (no changes):** `tools/datasource_server.py`, `tools/pubmed_server.py`, `tools/rxnorm_server.py`, `tools/clinical_codes_server.py`, `tools/stream_viewer.py`, `.mcp.json`.

---

## Phase A — Triage module

### Task A1: Create `discover_dbs()` in `tools/db_triage.py`

**Files:**
- Create: `tools/db_triage.py`
- Test: `tests/test_db_triage.py`

- [ ] **Step 1: Write the failing test**

Create `tests/test_db_triage.py`:

```python
"""Tests for tools/db_triage.py."""
import yaml
import pytest

from tools.db_triage import discover_dbs


def _write_yaml(path, data):
    path.write_text(yaml.dump(data))


@pytest.fixture
def databases_dir(tmp_path):
    d = tmp_path / "databases"
    d.mkdir()
    (d / "schemas").mkdir()
    (d / "profiles").mkdir()
    (d / "conventions").mkdir()
    _write_yaml(d / "alpha.yaml", {
        "id": "alpha", "name": "Alpha DB", "cdm": "pcornet",
        "engine": "duckdb", "online": True,
        "connection": {"r_code": "con <- NULL"},
        "schema_dump": "databases/schemas/alpha_schema.txt",
        "data_profile": "databases/profiles/alpha_profile.md",
        "conventions": "databases/conventions/alpha_conventions.md",
    })
    _write_yaml(d / "beta.yaml", {
        "id": "beta", "name": "Beta DB", "cdm": "omop",
        "engine": "mssql", "online": False,
        "connection": {"r_code": "con <- NULL"},
        "schema_dump": "databases/schemas/beta_schema.txt",
        "data_profile": "databases/profiles/beta_profile.md",
        "conventions": "databases/conventions/beta_conventions.md",
    })
    return d


def test_discover_dbs_returns_all_yamls(databases_dir):
    dbs = discover_dbs(str(databases_dir))
    ids = sorted(db["id"] for db in dbs)
    assert ids == ["alpha", "beta"]


def test_discover_dbs_includes_config_and_yaml_path(databases_dir):
    dbs = discover_dbs(str(databases_dir))
    alpha = next(db for db in dbs if db["id"] == "alpha")
    assert alpha["config"]["name"] == "Alpha DB"
    assert alpha["yaml_path"].endswith("alpha.yaml")


def test_discover_dbs_empty_dir(tmp_path):
    empty = tmp_path / "empty"
    empty.mkdir()
    assert discover_dbs(str(empty)) == []


def test_discover_dbs_skips_non_yaml(databases_dir):
    (databases_dir / "README.md").write_text("ignore me")
    dbs = discover_dbs(str(databases_dir))
    assert len(dbs) == 2


def test_discover_dbs_skips_yaml_without_id(databases_dir):
    _write_yaml(databases_dir / "broken.yaml", {"name": "No ID"})
    dbs = discover_dbs(str(databases_dir))
    ids = sorted(db["id"] for db in dbs)
    assert ids == ["alpha", "beta"]
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/test_db_triage.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'tools.db_triage'`

- [ ] **Step 3: Write minimal implementation**

Create `tools/db_triage.py`:

```python
"""Database discovery and triage for AutoTTE multi-DB runs.

This module is the single source of truth for:
  - Which DB YAMLs exist under databases/
  - Whether a selected DB can be run (triage disposition)
  - CLI-facing output for --list-dbs and --show-db
  - The JSON triage output consumed by run.sh

It is a pure Python module with no MCP or R dependencies, so it can be
tested thoroughly without needing mcp or a live R installation.
"""
from __future__ import annotations

from pathlib import Path
from typing import Any

import yaml


def discover_dbs(databases_dir: str) -> list[dict[str, Any]]:
    """Return a list of {id, yaml_path, config} for every valid YAML
    under *databases_dir*.

    Entries missing an `id` key are silently skipped. Nested subdirectories
    (schemas/, profiles/, conventions/) are not traversed.
    """
    root = Path(databases_dir)
    if not root.is_dir():
        return []
    results: list[dict[str, Any]] = []
    for yaml_path in sorted(root.glob("*.yaml")):
        try:
            with open(yaml_path, "r", encoding="utf-8") as fh:
                config = yaml.safe_load(fh) or {}
        except Exception:
            continue
        db_id = config.get("id")
        if not db_id:
            continue
        results.append({
            "id": db_id,
            "yaml_path": str(yaml_path),
            "config": config,
        })
    return results
```

- [ ] **Step 4: Run test to verify it passes**

Run: `pytest tests/test_db_triage.py -v`
Expected: all five tests PASS.

- [ ] **Step 5: Commit**

```bash
git add tools/db_triage.py tests/test_db_triage.py
git commit -m "feat(triage): add discover_dbs for scanning databases/*.yaml"
```

---

### Task A2: Add `triage_one()` — per-DB disposition logic

**Files:**
- Modify: `tools/db_triage.py`
- Modify: `tests/test_db_triage.py`

- [ ] **Step 1: Write the failing test**

Append to `tests/test_db_triage.py`:

```python
from tools.db_triage import triage_one


def _make_config(online=True, **overrides):
    base = {
        "id": "example",
        "name": "Example",
        "cdm": "pcornet",
        "engine": "duckdb",
        "online": online,
        "connection": {"r_code": "con <- NULL"},
        "schema_dump": "databases/schemas/example_schema.txt",
        "data_profile": "databases/profiles/example_profile.md",
        "conventions": "databases/conventions/example_conventions.md",
    }
    base.update(overrides)
    return base


def test_triage_online_profile_present(tmp_path):
    (tmp_path / "schema.txt").write_text("x")
    (tmp_path / "profile.md").write_text("x")
    (tmp_path / "conv.md").write_text("x")
    result = triage_one(
        _make_config(online=True),
        schema_path=str(tmp_path / "schema.txt"),
        profile_path=str(tmp_path / "profile.md"),
        conventions_path=str(tmp_path / "conv.md"),
        mode_override="",
    )
    assert result["disposition"] == "RUN"
    assert result["effective_mode"] == "online"
    assert result["warnings"] == []


def test_triage_online_profile_missing_is_auto_onboard(tmp_path):
    (tmp_path / "schema.txt").write_text("x")
    (tmp_path / "conv.md").write_text("x")
    result = triage_one(
        _make_config(online=True),
        schema_path=str(tmp_path / "schema.txt"),
        profile_path=str(tmp_path / "missing_profile.md"),
        conventions_path=str(tmp_path / "conv.md"),
        mode_override="",
    )
    assert result["disposition"] == "RUN_AUTO_ONBOARD"
    assert result["effective_mode"] == "online"
    assert any("profile missing" in w.lower() for w in result["warnings"])


def test_triage_offline_profile_present(tmp_path):
    (tmp_path / "schema.txt").write_text("x")
    (tmp_path / "profile.md").write_text("x")
    (tmp_path / "conv.md").write_text("x")
    result = triage_one(
        _make_config(online=False),
        schema_path=str(tmp_path / "schema.txt"),
        profile_path=str(tmp_path / "profile.md"),
        conventions_path=str(tmp_path / "conv.md"),
        mode_override="",
    )
    assert result["disposition"] == "RUN"
    assert result["effective_mode"] == "offline"


def test_triage_offline_profile_missing_is_skip(tmp_path):
    (tmp_path / "schema.txt").write_text("x")
    (tmp_path / "conv.md").write_text("x")
    result = triage_one(
        _make_config(online=False),
        schema_path=str(tmp_path / "schema.txt"),
        profile_path=str(tmp_path / "missing_profile.md"),
        conventions_path=str(tmp_path / "conv.md"),
        mode_override="",
    )
    assert result["disposition"] == "SKIP"
    assert "offline" in result["reason"].lower()


def test_triage_schema_missing_offline_is_skip(tmp_path):
    (tmp_path / "profile.md").write_text("x")
    (tmp_path / "conv.md").write_text("x")
    result = triage_one(
        _make_config(online=False),
        schema_path=str(tmp_path / "missing_schema.txt"),
        profile_path=str(tmp_path / "profile.md"),
        conventions_path=str(tmp_path / "conv.md"),
        mode_override="",
    )
    assert result["disposition"] == "SKIP"


def test_triage_schema_missing_online_is_auto_onboard(tmp_path):
    (tmp_path / "profile.md").write_text("x")
    (tmp_path / "conv.md").write_text("x")
    result = triage_one(
        _make_config(online=True),
        schema_path=str(tmp_path / "missing_schema.txt"),
        profile_path=str(tmp_path / "profile.md"),
        conventions_path=str(tmp_path / "conv.md"),
        mode_override="",
    )
    assert result["disposition"] == "RUN_AUTO_ONBOARD"


def test_triage_conventions_missing_warns_but_runs(tmp_path):
    (tmp_path / "schema.txt").write_text("x")
    (tmp_path / "profile.md").write_text("x")
    result = triage_one(
        _make_config(online=True),
        schema_path=str(tmp_path / "schema.txt"),
        profile_path=str(tmp_path / "profile.md"),
        conventions_path=str(tmp_path / "missing_conv.md"),
        mode_override="",
    )
    assert result["disposition"] == "RUN"
    assert any("conventions" in w.lower() for w in result["warnings"])


def test_triage_mode_override_online_forces_online(tmp_path):
    (tmp_path / "schema.txt").write_text("x")
    (tmp_path / "profile.md").write_text("x")
    (tmp_path / "conv.md").write_text("x")
    result = triage_one(
        _make_config(online=False),
        schema_path=str(tmp_path / "schema.txt"),
        profile_path=str(tmp_path / "profile.md"),
        conventions_path=str(tmp_path / "conv.md"),
        mode_override="online",
    )
    assert result["effective_mode"] == "online"


def test_triage_mode_override_offline_forces_offline(tmp_path):
    (tmp_path / "schema.txt").write_text("x")
    (tmp_path / "profile.md").write_text("x")
    (tmp_path / "conv.md").write_text("x")
    result = triage_one(
        _make_config(online=True),
        schema_path=str(tmp_path / "schema.txt"),
        profile_path=str(tmp_path / "profile.md"),
        conventions_path=str(tmp_path / "conv.md"),
        mode_override="offline",
    )
    assert result["effective_mode"] == "offline"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/test_db_triage.py -v`
Expected: the new tests FAIL with `ImportError: cannot import name 'triage_one'`.

- [ ] **Step 3: Write minimal implementation**

Append to `tools/db_triage.py`:

```python
# Disposition constants — these appear in db_triage.json and are checked
# by run.sh and the coordinator prompt. Do not rename without updating
# both consumers.
RUN = "RUN"
RUN_AUTO_ONBOARD = "RUN_AUTO_ONBOARD"
SKIP = "SKIP"


def _effective_mode(config: dict, mode_override: str) -> str:
    if mode_override in ("online", "offline"):
        return mode_override
    return "online" if config.get("online") else "offline"


def triage_one(
    config: dict,
    schema_path: str,
    profile_path: str,
    conventions_path: str,
    mode_override: str,
) -> dict[str, Any]:
    """Triage one DB. Return {disposition, effective_mode, reason, warnings}.

    disposition is one of RUN, RUN_AUTO_ONBOARD, SKIP.
    reason is a human-readable string explaining a SKIP or auto-onboard.
    warnings is a list of non-fatal issues (e.g. missing conventions).
    """
    effective_mode = _effective_mode(config, mode_override)
    schema_present = Path(schema_path).exists() if schema_path else False
    profile_present = Path(profile_path).exists() if profile_path else False
    conventions_present = Path(conventions_path).exists() if conventions_path else False

    warnings: list[str] = []
    if not conventions_present:
        warnings.append("Conventions file missing; protocols may miss DB-specific rules.")

    missing_parts: list[str] = []
    if not schema_present:
        missing_parts.append("schema dump")
    if not profile_present:
        missing_parts.append("data profile")

    if not missing_parts:
        return {
            "disposition": RUN,
            "effective_mode": effective_mode,
            "reason": "",
            "warnings": warnings,
        }

    missing_str = " and ".join(missing_parts)
    if effective_mode == "online":
        warnings.append(f"{missing_str} missing; Phase 0 will generate via r_executor.")
        return {
            "disposition": RUN_AUTO_ONBOARD,
            "effective_mode": effective_mode,
            "reason": f"{missing_str} missing (will be auto-generated).",
            "warnings": warnings,
        }

    return {
        "disposition": SKIP,
        "effective_mode": effective_mode,
        "reason": (
            f"Offline with no {missing_str}. Run in online mode once or "
            "generate the files manually."
        ),
        "warnings": warnings,
    }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `pytest tests/test_db_triage.py -v`
Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add tools/db_triage.py tests/test_db_triage.py
git commit -m "feat(triage): add triage_one for per-DB disposition logic"
```

---

### Task A3: Add `triage_selection()` — resolve selected IDs into triage results

**Files:**
- Modify: `tools/db_triage.py`
- Modify: `tests/test_db_triage.py`

- [ ] **Step 1: Write the failing test**

Append to `tests/test_db_triage.py`:

```python
from tools.db_triage import triage_selection


def test_triage_selection_all_keyword(databases_dir, tmp_path):
    # Touch the files each config references so both DBs come out RUN.
    (tmp_path / "alpha_schema.txt").write_text("x")
    (tmp_path / "alpha_profile.md").write_text("x")
    (tmp_path / "alpha_conv.md").write_text("x")
    (tmp_path / "beta_schema.txt").write_text("x")
    (tmp_path / "beta_profile.md").write_text("x")
    (tmp_path / "beta_conv.md").write_text("x")
    # Override the relative paths in the config files.
    for p in (databases_dir / "alpha.yaml", databases_dir / "beta.yaml"):
        data = yaml.safe_load(p.read_text())
        prefix = data["id"]
        data["schema_dump"] = str(tmp_path / f"{prefix}_schema.txt")
        data["data_profile"] = str(tmp_path / f"{prefix}_profile.md")
        data["conventions"] = str(tmp_path / f"{prefix}_conv.md")
        p.write_text(yaml.dump(data))
    results = triage_selection(
        selection="all",
        databases_dir=str(databases_dir),
        project_root=str(tmp_path),
        mode_override="",
    )
    ids = sorted(r["id"] for r in results)
    assert ids == ["alpha", "beta"]


def test_triage_selection_csv_ids(databases_dir, tmp_path):
    results = triage_selection(
        selection="alpha",
        databases_dir=str(databases_dir),
        project_root=str(tmp_path),
        mode_override="",
    )
    assert [r["id"] for r in results] == ["alpha"]


def test_triage_selection_unknown_id_raises(databases_dir, tmp_path):
    with pytest.raises(ValueError) as exc_info:
        triage_selection(
            selection="alpha,unknown_db",
            databases_dir=str(databases_dir),
            project_root=str(tmp_path),
            mode_override="",
        )
    assert "unknown_db" in str(exc_info.value)
    assert "alpha" in str(exc_info.value)  # valid IDs listed


def test_triage_selection_relative_paths_resolved(databases_dir, tmp_path):
    # Config has "databases/schemas/alpha_schema.txt" (relative).
    # Create the file relative to tmp_path acting as project root.
    (tmp_path / "databases" / "schemas").mkdir(parents=True, exist_ok=True)
    (tmp_path / "databases" / "schemas" / "alpha_schema.txt").write_text("x")
    (tmp_path / "databases" / "profiles").mkdir(parents=True, exist_ok=True)
    (tmp_path / "databases" / "profiles" / "alpha_profile.md").write_text("x")
    (tmp_path / "databases" / "conventions").mkdir(parents=True, exist_ok=True)
    (tmp_path / "databases" / "conventions" / "alpha_conventions.md").write_text("x")
    results = triage_selection(
        selection="alpha",
        databases_dir=str(databases_dir),
        project_root=str(tmp_path),
        mode_override="",
    )
    assert results[0]["disposition"] == "RUN"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/test_db_triage.py -v`
Expected: the new tests FAIL with `ImportError: cannot import name 'triage_selection'`.

- [ ] **Step 3: Write minimal implementation**

Append to `tools/db_triage.py`:

```python
def _resolve(project_root: str, p: str) -> str:
    """Resolve *p* against *project_root* if it is relative."""
    if not p:
        return p
    path = Path(p)
    if path.is_absolute():
        return str(path)
    return str(Path(project_root) / path)


def triage_selection(
    selection: str,
    databases_dir: str,
    project_root: str,
    mode_override: str,
) -> list[dict[str, Any]]:
    """Resolve *selection* into a list of per-DB triage results.

    selection is either "all" or a comma-separated list of DB IDs.
    Raises ValueError if any requested ID is not present in *databases_dir*.
    """
    known = discover_dbs(databases_dir)
    known_by_id = {db["id"]: db for db in known}

    if selection.strip() == "all":
        selected = known
    else:
        ids = [s.strip() for s in selection.split(",") if s.strip()]
        unknown = [i for i in ids if i not in known_by_id]
        if unknown:
            valid = ", ".join(sorted(known_by_id)) or "(none)"
            raise ValueError(
                f"Unknown DB id(s): {', '.join(unknown)}. Valid ids: {valid}"
            )
        selected = [known_by_id[i] for i in ids]

    results: list[dict[str, Any]] = []
    for db in selected:
        cfg = db["config"]
        triage = triage_one(
            cfg,
            schema_path=_resolve(project_root, cfg.get("schema_dump", "")),
            profile_path=_resolve(project_root, cfg.get("data_profile", "")),
            conventions_path=_resolve(project_root, cfg.get("conventions", "")),
            mode_override=mode_override,
        )
        results.append({
            "id": db["id"],
            "name": cfg.get("name", db["id"]),
            "cdm": cfg.get("cdm", ""),
            "engine": cfg.get("engine", ""),
            "yaml_path": db["yaml_path"],
            **triage,
        })
    return results
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `pytest tests/test_db_triage.py -v`
Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add tools/db_triage.py tests/test_db_triage.py
git commit -m "feat(triage): add triage_selection to resolve selection + mode"
```

---

### Task A4: Add CLI entrypoint for `--list-dbs`, `--show-db`, `--triage`

**Files:**
- Modify: `tools/db_triage.py`
- Modify: `tests/test_db_triage.py`

- [ ] **Step 1: Write the failing test**

Append to `tests/test_db_triage.py`:

```python
import json
import subprocess
import sys
from pathlib import Path


def _project_root() -> str:
    return str(Path(__file__).resolve().parent.parent)


def test_cli_list_dbs_prints_table(databases_dir, tmp_path):
    env = {"PYTHONPATH": str(tmp_path.parent.parent.parent)}
    result = subprocess.run(
        [sys.executable, "-m", "tools.db_triage", "list",
         "--databases-dir", str(databases_dir)],
        capture_output=True, text=True, cwd=_project_root(),
    )
    assert result.returncode == 0
    assert "alpha" in result.stdout
    assert "beta" in result.stdout
    assert "ID" in result.stdout  # header row
    assert "DEFAULT" in result.stdout


def test_cli_show_db_prints_config(databases_dir, tmp_path):
    result = subprocess.run(
        [sys.executable, "-m", "tools.db_triage", "show", "alpha",
         "--databases-dir", str(databases_dir)],
        capture_output=True, text=True, cwd=_project_root(),
    )
    assert result.returncode == 0
    assert "alpha" in result.stdout
    assert "Alpha DB" in result.stdout


def test_cli_show_db_unknown_id_exits_nonzero(databases_dir, tmp_path):
    result = subprocess.run(
        [sys.executable, "-m", "tools.db_triage", "show", "missing_id",
         "--databases-dir", str(databases_dir)],
        capture_output=True, text=True, cwd=_project_root(),
    )
    assert result.returncode != 0
    assert "missing_id" in (result.stdout + result.stderr)


def test_cli_triage_emits_json(databases_dir, tmp_path):
    result = subprocess.run(
        [sys.executable, "-m", "tools.db_triage", "triage",
         "--selection", "alpha",
         "--databases-dir", str(databases_dir),
         "--project-root", str(tmp_path)],
        capture_output=True, text=True, cwd=_project_root(),
    )
    assert result.returncode == 0
    parsed = json.loads(result.stdout)
    assert isinstance(parsed, list)
    assert parsed[0]["id"] == "alpha"
    assert parsed[0]["disposition"] in ("RUN", "RUN_AUTO_ONBOARD", "SKIP")


def test_cli_triage_unknown_id_exits_nonzero(databases_dir, tmp_path):
    result = subprocess.run(
        [sys.executable, "-m", "tools.db_triage", "triage",
         "--selection", "no_such_db",
         "--databases-dir", str(databases_dir),
         "--project-root", str(tmp_path)],
        capture_output=True, text=True, cwd=_project_root(),
    )
    assert result.returncode != 0
    assert "no_such_db" in (result.stdout + result.stderr)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/test_db_triage.py -k cli -v`
Expected: FAIL — `tools.db_triage` has no `__main__` handler yet.

- [ ] **Step 3: Write minimal implementation**

Append to `tools/db_triage.py`:

```python
import argparse
import json
import sys


def format_list_table(dbs: list[dict[str, Any]], project_root: str) -> str:
    """Return a plain-text table of all known DBs with file-presence flags."""
    headers = ["ID", "NAME", "CDM", "ENGINE", "DEFAULT", "SCHEMA", "PROFILE", "CONVENTIONS"]
    rows: list[list[str]] = [headers]
    for db in dbs:
        cfg = db["config"]
        default_mode = "online" if cfg.get("online") else "offline"
        schema_present = Path(_resolve(project_root, cfg.get("schema_dump", ""))).exists()
        profile_present = Path(_resolve(project_root, cfg.get("data_profile", ""))).exists()
        conv_present = Path(_resolve(project_root, cfg.get("conventions", ""))).exists()
        rows.append([
            db["id"],
            cfg.get("name", db["id"]),
            cfg.get("cdm", ""),
            cfg.get("engine", ""),
            default_mode,
            "yes" if schema_present else "no",
            "yes" if profile_present else "no",
            "yes" if conv_present else "no",
        ])

    # Pad each column to its max width.
    widths = [max(len(row[i]) for row in rows) for i in range(len(headers))]
    lines = []
    for row in rows:
        lines.append("  ".join(cell.ljust(widths[i]) for i, cell in enumerate(row)))
    return "\n".join(lines)


def format_show_db(db: dict[str, Any], project_root: str) -> str:
    """Return a multi-line description of one DB + its file presence."""
    cfg = db["config"]
    lines = [
        f"ID:        {db['id']}",
        f"Name:      {cfg.get('name', db['id'])}",
        f"CDM:       {cfg.get('cdm', '')}",
        f"Engine:    {cfg.get('engine', '')}",
        f"Default:   {'online' if cfg.get('online') else 'offline'}",
        f"YAML:      {db['yaml_path']}",
        "",
        "Files:",
    ]
    for label, key in [
        ("  schema_dump  ", "schema_dump"),
        ("  data_profile ", "data_profile"),
        ("  conventions  ", "conventions"),
    ]:
        path = cfg.get(key, "")
        resolved = _resolve(project_root, path)
        present = "present" if (resolved and Path(resolved).exists()) else "MISSING"
        lines.append(f"{label}{path:<60} [{present}]")
    return "\n".join(lines)


def _cli_list(args: argparse.Namespace) -> int:
    dbs = discover_dbs(args.databases_dir)
    print(format_list_table(dbs, args.project_root))
    return 0


def _cli_show(args: argparse.Namespace) -> int:
    dbs = discover_dbs(args.databases_dir)
    match = next((db for db in dbs if db["id"] == args.id), None)
    if match is None:
        valid = ", ".join(sorted(db["id"] for db in dbs)) or "(none)"
        print(f"No DB with id {args.id!r}. Valid ids: {valid}", file=sys.stderr)
        return 1
    print(format_show_db(match, args.project_root))
    return 0


def _cli_triage(args: argparse.Namespace) -> int:
    try:
        results = triage_selection(
            selection=args.selection,
            databases_dir=args.databases_dir,
            project_root=args.project_root,
            mode_override=args.mode or "",
        )
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 1
    print(json.dumps(results, indent=2))
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="tools.db_triage")
    parser.add_argument("--databases-dir", default="databases")
    parser.add_argument("--project-root", default=".")
    subparsers = parser.add_subparsers(dest="cmd", required=True)

    subparsers.add_parser("list")

    show = subparsers.add_parser("show")
    show.add_argument("id")

    triage = subparsers.add_parser("triage")
    triage.add_argument("--selection", required=True)
    triage.add_argument("--mode", choices=["online", "offline"], default="")

    args = parser.parse_args(argv)
    if args.cmd == "list":
        return _cli_list(args)
    if args.cmd == "show":
        return _cli_show(args)
    if args.cmd == "triage":
        return _cli_triage(args)
    return 2


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `pytest tests/test_db_triage.py -v`
Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add tools/db_triage.py tests/test_db_triage.py
git commit -m "feat(triage): add CLI subcommands list / show / triage"
```

---

## Phase B — r_executor multi-session refactor

### Task B1: Add `SessionRegistry` class

**Files:**
- Modify: `tools/r_executor_server.py`
- Create: `tests/test_r_executor_multi_session.py`

- [ ] **Step 1: Write the failing test**

Create `tests/test_r_executor_multi_session.py`:

```python
"""Tests for the multi-session registry in tools/r_executor_server.py."""
import yaml
import pytest

from tools.r_executor_server import SessionRegistry


def _write_yaml(path, data):
    path.write_text(yaml.dump(data))


@pytest.fixture
def two_configs(tmp_path):
    a = {
        "id": "alpha", "name": "Alpha", "cdm": "pcornet",
        "engine": "duckdb", "online": True,
        "connection": {"r_code": "con <- NULL"},
        "schema_dump": str(tmp_path / "a_schema.txt"),
        "data_profile": str(tmp_path / "a_profile.md"),
    }
    b = {
        "id": "beta", "name": "Beta", "cdm": "omop",
        "engine": "duckdb", "online": True,
        "connection": {"r_code": "con <- NULL"},
        "schema_dump": str(tmp_path / "b_schema.txt"),
        "data_profile": str(tmp_path / "b_profile.md"),
    }
    pa = tmp_path / "alpha.yaml"
    pb = tmp_path / "beta.yaml"
    _write_yaml(pa, a)
    _write_yaml(pb, b)
    return [str(pa), str(pb)]


def test_registry_loads_multiple_configs(two_configs):
    reg = SessionRegistry()
    reg.load_configs(two_configs)
    assert sorted(reg.db_ids()) == ["alpha", "beta"]


def test_registry_get_config_by_id(two_configs):
    reg = SessionRegistry()
    reg.load_configs(two_configs)
    cfg = reg.get_config("alpha")
    assert cfg["name"] == "Alpha"


def test_registry_get_config_unknown_id_raises(two_configs):
    reg = SessionRegistry()
    reg.load_configs(two_configs)
    with pytest.raises(KeyError) as exc:
        reg.get_config("unknown")
    assert "unknown" in str(exc.value)


def test_registry_get_session_lazy_creates(two_configs):
    reg = SessionRegistry()
    reg.load_configs(two_configs)
    # Before any call, no sessions exist.
    assert reg.has_session("alpha") is False
    s1 = reg.get_session("alpha")
    assert reg.has_session("alpha") is True
    # Calling again returns the same session, not a new one.
    s2 = reg.get_session("alpha")
    assert s1 is s2
    # Unrelated session still absent.
    assert reg.has_session("beta") is False


def test_registry_get_session_unknown_id_raises(two_configs):
    reg = SessionRegistry()
    reg.load_configs(two_configs)
    with pytest.raises(KeyError):
        reg.get_session("unknown")


def test_registry_load_configs_rejects_duplicate_ids(tmp_path):
    cfg = {
        "id": "dup", "name": "Dup", "cdm": "x", "engine": "x",
        "online": True, "connection": {"r_code": ""},
    }
    pa = tmp_path / "one.yaml"
    pb = tmp_path / "two.yaml"
    _write_yaml(pa, cfg)
    _write_yaml(pb, cfg)
    reg = SessionRegistry()
    with pytest.raises(ValueError) as exc:
        reg.load_configs([str(pa), str(pb)])
    assert "dup" in str(exc.value).lower()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/test_r_executor_multi_session.py -v`
Expected: FAIL — `ImportError: cannot import name 'SessionRegistry'`.

- [ ] **Step 3: Write minimal implementation**

In `tools/r_executor_server.py`, add the `SessionRegistry` class immediately before the `# Global state` section (around line 253):

```python
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `pytest tests/test_r_executor_multi_session.py -v`
Expected: all tests PASS. Also run: `pytest tests/test_r_executor.py -v` to confirm no regression.

- [ ] **Step 5: Commit**

```bash
git add tools/r_executor_server.py tests/test_r_executor_multi_session.py
git commit -m "feat(r_executor): add SessionRegistry for multi-DB support"
```

---

### Task B2: Rewire `_ensure_connected` to take `db_id`

**Files:**
- Modify: `tools/r_executor_server.py` (function `_ensure_connected` around line 262)

- [ ] **Step 1: Write the failing test**

Append to `tests/test_r_executor_multi_session.py`:

```python
from tools.r_executor_server import _ensure_connected, _registry


def test_ensure_connected_offline_returns_error(two_configs, monkeypatch):
    # Rewrite one config to be offline.
    import yaml
    with open(two_configs[0]) as fh:
        cfg = yaml.safe_load(fh)
    cfg["online"] = False
    with open(two_configs[0], "w") as fh:
        yaml.dump(cfg, fh)

    _registry.__init__()  # reset global registry
    _registry.load_configs(two_configs)
    err = _ensure_connected("alpha")
    assert err is not None
    assert "offline" in err["error"].lower()


def test_ensure_connected_unknown_id_returns_error(two_configs):
    _registry.__init__()
    _registry.load_configs(two_configs)
    err = _ensure_connected("no_such_db")
    assert err is not None
    assert "unknown" in err["error"].lower()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/test_r_executor_multi_session.py::test_ensure_connected_offline_returns_error tests/test_r_executor_multi_session.py::test_ensure_connected_unknown_id_returns_error -v`
Expected: FAIL — `_ensure_connected` signature does not accept `db_id`; `_registry` does not exist.

- [ ] **Step 3: Write minimal implementation**

Replace the `# Global state` and `_ensure_connected` blocks in `tools/r_executor_server.py` (lines ~253–297):

```python
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
```

Delete the old module-level `_config`, `_mode_override`, and `_session` variables — they are superseded by the registry.

- [ ] **Step 4: Run tests to verify they pass**

Run: `pytest tests/test_r_executor_multi_session.py -v`
Expected: all tests PASS. Also run: `pytest tests/test_r_executor.py -v` to confirm no regression.

- [ ] **Step 5: Commit**

```bash
git add tools/r_executor_server.py tests/test_r_executor_multi_session.py
git commit -m "feat(r_executor): route _ensure_connected through SessionRegistry"
```

---

### Task B3: Add `db_id` parameter to every MCP tool

**Files:**
- Modify: `tools/r_executor_server.py` (every `@mcp.tool()` function, lines ~305–528)

- [ ] **Step 1: Write the failing test**

These tool functions are decorated with `@mcp.tool()` (mocked in tests), so we can't call them directly. Instead, verify the underlying helper logic by inspecting function signatures and adding a test that the tools use the registry correctly.

Append to `tests/test_r_executor_multi_session.py`:

```python
import inspect

from tools import r_executor_server as rex


def test_tool_signatures_include_db_id():
    """Every MCP tool must accept db_id as its first parameter."""
    # The tools are decorated, so we pull the underlying function via __wrapped__ if
    # available; otherwise use the decorated object directly (tests run with mcp mocked).
    tool_names = ["execute_r", "query_db", "list_tables", "describe_table",
                  "dump_schema", "run_profiler"]
    for name in tool_names:
        fn = getattr(rex, name)
        # Unwrap if possible.
        target = getattr(fn, "__wrapped__", fn)
        sig = inspect.signature(target)
        params = list(sig.parameters)
        assert params[0] == "db_id", (
            f"Tool {name} must take db_id as its first parameter, got {params}"
        )
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/test_r_executor_multi_session.py::test_tool_signatures_include_db_id -v`
Expected: FAIL — current tools don't have `db_id`.

- [ ] **Step 3: Write minimal implementation**

Rewrite each `@mcp.tool()` function in `tools/r_executor_server.py`. Each tool gains a `db_id` parameter as its first argument, uses `_registry.get_config(db_id)` and `_registry.get_session(db_id)` instead of module-level state:

```python
@mcp.tool()
async def execute_r(db_id: str, code: str) -> str:
    """Execute arbitrary R code in the persistent R session for *db_id*.

    Args:
        db_id: The database id (e.g. 'nhanes', 'mimic_iv').
        code: R code to execute.
    """
    err = _ensure_connected(db_id)
    if err:
        return json.dumps(err)

    session = _registry.get_session(db_id)
    result = session.execute(code)
    return json.dumps({
        "stdout": truncate_output(result["stdout"]),
        "stderr": truncate_output(result["stderr"]),
        "success": result["success"],
    })


@mcp.tool()
async def query_db(db_id: str, sql: str) -> str:
    """Run a SQL query against *db_id* via DBI and return results (up to 50 rows).

    Args:
        db_id: The database id.
        sql: SQL query string.
    """
    err = _ensure_connected(db_id)
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
    session = _registry.get_session(db_id)
    result = session.execute(r_code)
    if not result["success"]:
        return json.dumps({"error": result["stderr"], "stdout": result["stdout"]})

    return json.dumps({
        "output": result["stdout"],
        "stderr": result["stderr"] if result["stderr"].strip() else None,
        "success": True,
    })


@mcp.tool()
async def list_tables(db_id: str) -> str:
    """List all tables in the connected database for *db_id* with row counts."""
    err = _ensure_connected(db_id)
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
    session = _registry.get_session(db_id)
    result = session.execute(r_code)
    return json.dumps({
        "stdout": truncate_output(result["stdout"]),
        "stderr": result["stderr"] if result["stderr"].strip() else None,
        "success": result["success"],
    })


@mcp.tool()
async def describe_table(db_id: str, table: str) -> str:
    """Return column info and sample values for *table* in *db_id* (LIMIT 5).

    Args:
        db_id: The database id.
        table: Table name to describe.
    """
    err = _ensure_connected(db_id)
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
    session = _registry.get_session(db_id)
    result = session.execute(r_code)
    return json.dumps({
        "stdout": truncate_output(result["stdout"]),
        "stderr": result["stderr"] if result["stderr"].strip() else None,
        "success": result["success"],
    })


@mcp.tool()
async def dump_schema(db_id: str) -> str:
    """Introspect *db_id* schema and write it to its configured schema_dump path."""
    err = _ensure_connected(db_id)
    if err:
        return json.dumps(err)

    config = _registry.get_config(db_id)
    schema_path = config.get("schema_dump", "")
    engine = config.get("engine", "").lower()

    if not schema_path:
        return json.dumps({"error": f"No schema_dump path configured for {db_id}."})

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

    session = _registry.get_session(db_id)
    result = session.execute(r_code)
    return json.dumps({
        "stdout": result["stdout"],
        "stderr": result["stderr"] if result["stderr"].strip() else None,
        "success": result["success"],
        "schema_path": schema_path,
    })


@mcp.tool()
async def run_profiler(db_id: str, code: str) -> str:
    """Run agent-provided profiling R code for *db_id*, capturing to its data_profile path.

    Args:
        db_id: The database id.
        code: R profiling code to execute.
    """
    err = _ensure_connected(db_id)
    if err:
        return json.dumps(err)

    config = _registry.get_config(db_id)
    profile_path = config.get("data_profile", "")
    if not profile_path:
        return json.dumps({"error": f"No data_profile path configured for {db_id}."})

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
    session = _registry.get_session(db_id)
    result = session.execute(r_code)
    return json.dumps({
        "stdout": result["stdout"],
        "stderr": result["stderr"] if result["stderr"].strip() else None,
        "success": result["success"],
        "profile_path": profile_path,
    })
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `pytest tests/test_r_executor_multi_session.py tests/test_r_executor.py -v`
Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add tools/r_executor_server.py tests/test_r_executor_multi_session.py
git commit -m "feat(r_executor): add db_id parameter to every MCP tool"
```

---

### Task B4: Convert `main()` to accept repeatable `--config`

**Files:**
- Modify: `tools/r_executor_server.py` (function `main`, lines ~536–553)

- [ ] **Step 1: Write the failing test**

Append to `tests/test_r_executor_multi_session.py`:

```python
from tools.r_executor_server import main as rex_main


def test_main_accepts_multiple_configs(two_configs, monkeypatch):
    """Running main() with two --config args should populate the registry."""
    called = {}

    def fake_run():
        called["ran"] = True

    monkeypatch.setattr("tools.r_executor_server.mcp.run", fake_run)
    # Reset the global registry.
    import tools.r_executor_server as rex
    rex._registry = rex.SessionRegistry()

    argv = ["--config", two_configs[0], "--config", two_configs[1]]
    rex_main(argv)

    assert called.get("ran") is True
    assert sorted(rex._registry.db_ids()) == ["alpha", "beta"]


def test_main_rejects_zero_configs(monkeypatch):
    import tools.r_executor_server as rex

    def fake_run():
        pass

    monkeypatch.setattr("tools.r_executor_server.mcp.run", fake_run)
    rex._registry = rex.SessionRegistry()
    with pytest.raises(SystemExit):
        rex_main([])


def test_main_applies_mode_override(two_configs, monkeypatch):
    import tools.r_executor_server as rex

    def fake_run():
        pass

    monkeypatch.setattr("tools.r_executor_server.mcp.run", fake_run)
    rex._registry = rex.SessionRegistry()

    rex_main(["--config", two_configs[0], "--mode", "offline"])
    assert rex._registry.get_mode_override("alpha") == "offline"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `pytest tests/test_r_executor_multi_session.py::test_main_accepts_multiple_configs -v`
Expected: FAIL — current `main()` takes one `--config` (required single).

- [ ] **Step 3: Write minimal implementation**

Replace `main()` in `tools/r_executor_server.py`:

```python
def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(description="R Executor MCP Server")
    parser.add_argument(
        "--config",
        required=True,
        action="append",
        help="Path to a database config YAML. Repeat to serve multiple DBs.",
    )
    parser.add_argument(
        "--mode",
        choices=["online", "offline"],
        default="",
        help="Override online/offline mode from every config uniformly.",
    )
    args = parser.parse_args(argv)

    _registry.load_configs(args.config)
    if args.mode:
        for db_id in _registry.db_ids():
            _registry.set_mode_override(db_id, args.mode)

    mcp.run()


if __name__ == "__main__":
    main()
```

Remove the old `main()` that set the global `_config` / `_mode_override` — they no longer exist.

- [ ] **Step 4: Run tests to verify they pass**

Run: `pytest tests/test_r_executor_multi_session.py tests/test_r_executor.py -v`
Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
git add tools/r_executor_server.py tests/test_r_executor_multi_session.py
git commit -m "feat(r_executor): make --config repeatable for multi-DB serving"
```

---

### Task B5: Session-isolation test — crashing one does not kill another

**Files:**
- Modify: `tests/test_r_executor_multi_session.py`
- Modify: `tools/r_executor_server.py` (if drop_session needs refinement)

- [ ] **Step 1: Write the failing test**

Append to `tests/test_r_executor_multi_session.py`:

```python
def test_registry_drop_session_isolates_failures(two_configs):
    """Dropping a failed session must not affect other sessions."""
    reg = SessionRegistry()
    reg.load_configs(two_configs)
    s_alpha = reg.get_session("alpha")
    s_beta = reg.get_session("beta")
    assert reg.has_session("alpha") and reg.has_session("beta")

    # Simulate a crash in alpha's session by dropping it.
    reg.drop_session("alpha")

    assert reg.has_session("alpha") is False
    assert reg.has_session("beta") is True
    # Beta is still the same object as before.
    assert reg.get_session("beta") is s_beta
    # Re-acquiring alpha creates a new session.
    s_alpha_2 = reg.get_session("alpha")
    assert s_alpha_2 is not s_alpha
```

- [ ] **Step 2: Run test to verify it fails or passes**

Run: `pytest tests/test_r_executor_multi_session.py::test_registry_drop_session_isolates_failures -v`
Expected: should PASS given `drop_session` was implemented in B1. If it fails, fix `drop_session`.

- [ ] **Step 3: Verify `drop_session` already covers the assertions**

The `drop_session` method from Task B1 already pops the key from `_sessions` and calls `stop()` on the old session. The test should pass without changes.

- [ ] **Step 4: Commit (empty-change-friendly: only the test file was modified)**

```bash
git add tests/test_r_executor_multi_session.py
git commit -m "test(r_executor): verify session drop isolates failures between DBs"
```

---

## Phase C — run.sh changes

### Task C1: Add `--dbs`, `--list-dbs`, `--show-db` argument parsing

**Files:**
- Modify: `run.sh`
- Create: `tests/test_run_sh_multi_db.sh`

- [ ] **Step 1: Write the failing test**

Create `tests/test_run_sh_multi_db.sh`:

```bash
#!/usr/bin/env bash
# Shell tests for run.sh multi-DB CLI. We short-circuit before the
# actual `claude -p` invocation by intercepting via AUTOTTE_DRY_RUN=1
# (run.sh must honor this env var to exit after printing the resolved
# plan). No Claude API calls happen in these tests.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

PASS=0
FAIL=0

assert_contains() {
  local needle="$1" haystack="$2" desc="$3"
  if printf "%s" "$haystack" | grep -qF -- "$needle"; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc — expected to find: $needle"
    echo "         actual output:"
    printf "%s" "$haystack" | sed 's/^/           /'
    FAIL=$((FAIL + 1))
  fi
}

assert_exit_code() {
  local expected="$1" actual="$2" desc="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "  PASS: $desc (exit $actual)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc — expected exit $expected, got $actual"
    FAIL=$((FAIL + 1))
  fi
}

echo "Test 1: --list-dbs prints a table and exits 0"
OUT=$(./run.sh --list-dbs 2>&1); RC=$?
assert_exit_code 0 "$RC" "exit 0"
assert_contains "ID" "$OUT" "contains header"
assert_contains "nhanes" "$OUT" "mentions nhanes"

echo "Test 2: --show-db <id> prints one DB"
OUT=$(./run.sh --show-db nhanes 2>&1); RC=$?
assert_exit_code 0 "$RC" "exit 0"
assert_contains "nhanes" "$OUT" "mentions nhanes"
assert_contains "Default:" "$OUT" "shows default mode"

echo "Test 3: --show-db with unknown id exits non-zero"
OUT=$(./run.sh --show-db no_such_db 2>&1); RC=$?
[[ "$RC" != "0" ]] && { echo "  PASS: unknown id exits non-zero"; PASS=$((PASS + 1)); } \
  || { echo "  FAIL: unknown id should exit non-zero"; FAIL=$((FAIL + 1)); }

echo "Test 4: --dbs + --db-config together is an error"
OUT=$(./run.sh "topic" --dbs nhanes --db-config databases/nhanes.yaml 2>&1); RC=$?
[[ "$RC" != "0" ]] && { echo "  PASS: rejected"; PASS=$((PASS + 1)); } \
  || { echo "  FAIL: should have errored"; FAIL=$((FAIL + 1)); }
assert_contains "cannot combine" "$OUT" "error message explains the conflict"

echo "Test 5: --dbs with unknown id exits non-zero"
OUT=$(AUTOTTE_DRY_RUN=1 ./run.sh "topic" --dbs no_such_db 2>&1); RC=$?
[[ "$RC" != "0" ]] && { echo "  PASS: rejected"; PASS=$((PASS + 1)); } \
  || { echo "  FAIL: should have errored"; FAIL=$((FAIL + 1)); }

echo "Test 6: --dbs all with AUTOTTE_DRY_RUN=1 exits 0 and prints triage"
OUT=$(AUTOTTE_DRY_RUN=1 ./run.sh "topic" --dbs all 2>&1); RC=$?
assert_exit_code 0 "$RC" "dry-run exits 0"
assert_contains "triage" "$OUT" "mentions triage or db_triage"

echo "Test 7: --db-config legacy path resolves to nested layout"
OUT=$(AUTOTTE_DRY_RUN=1 ./run.sh "topic" --db-config databases/nhanes.yaml 2>&1); RC=$?
assert_exit_code 0 "$RC" "exit 0"
assert_contains "nhanes" "$OUT" "nhanes selected"

echo "Test 8: public-datasets mode still works"
OUT=$(AUTOTTE_DRY_RUN=1 ./run.sh "topic" 2>&1); RC=$?
assert_exit_code 0 "$RC" "exit 0"
assert_contains "Public datasets" "$OUT" "banner mentions public datasets"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" == "0" ]] && exit 0 || exit 1
```

Mark it executable: `chmod +x tests/test_run_sh_multi_db.sh`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `bash tests/test_run_sh_multi_db.sh`
Expected: every test fails (run.sh doesn't implement these flags yet).

- [ ] **Step 3: Write minimal implementation — argument parsing only**

Edit `run.sh` to replace the argument parsing block (lines ~24–58). Replace with:

```bash
# Handle discovery subcommands first (do not require a therapeutic area).
case "${1:-}" in
  --list-dbs)
    exec python3 -m tools.db_triage list --project-root "$(pwd)"
    ;;
  --show-db)
    shift
    [[ -n "${1:-}" ]] || { echo "Usage: --show-db <id>" >&2; exit 2; }
    exec python3 -m tools.db_triage show "$1" --project-root "$(pwd)"
    ;;
esac

THERAPEUTIC_AREA="${1:?Usage: ./run.sh \"therapeutic area\" [--dbs <id,id,...>|all] [--db-config <path>] [--db-mode online|offline] [--resume-reports] [max_turns]}"
shift

# Parse optional flags.
DB_CONFIG=""
DB_IDS=""
DB_MODE=""
RESUME_REPORTS=false
MAX_TURNS="50"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --db-config)
      DB_CONFIG="$2"; shift 2
      ;;
    --dbs)
      DB_IDS="$2"; shift 2
      ;;
    --db-mode)
      DB_MODE="$2"; shift 2
      ;;
    --resume-reports)
      RESUME_REPORTS=true; shift
      ;;
    [0-9]*)
      MAX_TURNS="$1"; shift
      ;;
    *)
      echo "Unknown argument: $1" >&2; exit 2
      ;;
  esac
done

if [[ -n "$DB_CONFIG" && -n "$DB_IDS" ]]; then
  echo "Error: cannot combine --db-config and --dbs. Use one or the other." >&2
  exit 2
fi

# Legacy --db-config path: resolve to a single DB id via python.
if [[ -n "$DB_CONFIG" ]]; then
  if [[ ! -f "$DB_CONFIG" ]]; then
    echo "ERROR: DB config file not found: $DB_CONFIG" >&2
    exit 1
  fi
  DB_IDS=$(python3 -c "
import sys, yaml
with open('$DB_CONFIG') as f:
    c = yaml.safe_load(f)
id = c.get('id')
if not id:
    sys.stderr.write('Config missing id field\n'); sys.exit(1)
print(id)
") || exit 1
fi
```

This task only covers argument parsing + legacy resolution + `--list-dbs` / `--show-db`. Triage happens in Task C2, so nothing depends on `DB_IDS` yet.

To allow tests 6–8 to pass without real coordinator launch, also add near the top of the "Display banner" block (around line 107):

```bash
if [[ "${AUTOTTE_DRY_RUN:-}" == "1" ]]; then
  echo "AUTOTTE_DRY_RUN — stopping after parse. DB_IDS='$DB_IDS' DB_CONFIG='$DB_CONFIG' MODE='$DB_MODE'"
  if [[ -z "$DB_IDS" && -z "$DB_CONFIG" ]]; then
    echo "Public datasets only."
  fi
  echo "triage: not yet implemented"  # Task C2 replaces this line with real output
  exit 0
fi
```

- [ ] **Step 4: Run tests to verify the arg-parsing cases pass**

Run: `bash tests/test_run_sh_multi_db.sh`
Expected: tests 1, 2, 3, 4, 7, 8 PASS. Tests 5 and 6 may still partially fail until Task C2 wires triage.

- [ ] **Step 5: Commit**

```bash
git add run.sh tests/test_run_sh_multi_db.sh
chmod +x tests/test_run_sh_multi_db.sh
git commit -m "feat(run): add --dbs, --list-dbs, --show-db flags; reject conflicts"
```

---

### Task C2: Call triage, write `db_triage.json`, exit-1 if all-skipped

**Files:**
- Modify: `run.sh`

- [ ] **Step 1: Rerun the failing tests from C1**

Run: `bash tests/test_run_sh_multi_db.sh`
Expected: tests 5 and 6 still fail (triage not wired yet). Test 6 should mention "triage" in output.

- [ ] **Step 2: Write minimal implementation**

In `run.sh`, after argument parsing and before the banner/MCP-config blocks, insert the triage call:

```bash
# ---------------------------------------------------------------------------
# Triage: resolve DB_IDS through tools.db_triage and capture disposition.
# ---------------------------------------------------------------------------

TRIAGE_JSON=""
if [[ -n "$DB_IDS" ]]; then
  RESULTS_DIR="results/$(echo "$THERAPEUTIC_AREA" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')"
  mkdir -p "$RESULTS_DIR"

  TRIAGE_JSON="$RESULTS_DIR/db_triage.json"
  if ! python3 -m tools.db_triage triage \
        --selection "$DB_IDS" \
        --project-root "$(pwd)" \
        --mode "${DB_MODE:-}" > "$TRIAGE_JSON" 2> "$RESULTS_DIR/db_triage.err"; then
    cat "$RESULTS_DIR/db_triage.err" >&2
    rm -f "$TRIAGE_JSON" "$RESULTS_DIR/db_triage.err"
    exit 1
  fi
  rm -f "$RESULTS_DIR/db_triage.err"

  # Print a human-readable summary.
  python3 -c "
import json
with open('$TRIAGE_JSON') as f:
    rows = json.load(f)
for r in rows:
    tag = {'RUN': '[OK]', 'RUN_AUTO_ONBOARD': '[WARN]', 'SKIP': '[SKIP]'}.get(r['disposition'], '[???]')
    print(f\"{tag} {r['id']} — {r['effective_mode']}; {r['disposition']}\")
    if r.get('reason'):
        print(f\"       reason: {r['reason']}\")
    for w in r.get('warnings', []):
        print(f\"       warn: {w}\")
"

  # Count live DBs (RUN or RUN_AUTO_ONBOARD).
  LIVE_COUNT=$(python3 -c "
import json
with open('$TRIAGE_JSON') as f:
    rows = json.load(f)
print(sum(1 for r in rows if r['disposition'] in ('RUN', 'RUN_AUTO_ONBOARD')))
")
  if [[ "$LIVE_COUNT" == "0" ]]; then
    echo "ERROR: every selected DB was skipped. Nothing to run." >&2
    exit 1
  fi
fi
```

Update the `AUTOTTE_DRY_RUN` stub to surface the triage:

```bash
if [[ "${AUTOTTE_DRY_RUN:-}" == "1" ]]; then
  echo "AUTOTTE_DRY_RUN — stopping after parse. DB_IDS='$DB_IDS' DB_CONFIG='$DB_CONFIG' MODE='$DB_MODE'"
  if [[ -z "$DB_IDS" && -z "$DB_CONFIG" ]]; then
    echo "Public datasets only."
  elif [[ -n "$TRIAGE_JSON" && -s "$TRIAGE_JSON" ]]; then
    echo "triage written to $TRIAGE_JSON"
  fi
  exit 0
fi
```

- [ ] **Step 3: Run tests to verify they pass**

Run: `bash tests/test_run_sh_multi_db.sh`
Expected: all 8 tests PASS.

- [ ] **Step 4: Commit**

```bash
git add run.sh
git commit -m "feat(run): triage selected DBs into db_triage.json; skip-all exits 1"
```

---

### Task C3: Generate `.mcp-session.json` with multi-config r_executor

**Files:**
- Modify: `run.sh`

- [ ] **Step 1: Write the failing test**

Append to `tests/test_run_sh_multi_db.sh`:

```bash
echo "Test 9: --dbs multi with online DBs writes multi-config r_executor to .mcp-session.json"
OUT=$(AUTOTTE_DRY_RUN=2 ./run.sh "topic" --dbs nhanes,synthetic_pcornet --db-mode online 2>&1); RC=$?
assert_exit_code 0 "$RC" "exit 0"
if [[ -f ".mcp-session.json" ]]; then
  SESSION_CONFIGS=$(python3 -c "
import json
with open('.mcp-session.json') as f:
    c = json.load(f)
args = c['mcpServers']['r_executor']['args']
count = sum(1 for a in args if a == '--config')
print(count)
")
  assert_contains "2" "$SESSION_CONFIGS" "two --config args in .mcp-session.json"
  rm -f .mcp-session.json
else
  echo "  FAIL: .mcp-session.json not created"; FAIL=$((FAIL + 1))
fi

echo "Test 10: --dbs offline-only does NOT create .mcp-session.json"
rm -f .mcp-session.json
OUT=$(AUTOTTE_DRY_RUN=2 ./run.sh "topic" --dbs secure_pcornet_cdw 2>&1); RC=$?
if [[ ! -f ".mcp-session.json" ]]; then
  echo "  PASS: no .mcp-session.json written for offline-only run"; PASS=$((PASS + 1))
else
  echo "  FAIL: .mcp-session.json should not exist when no DB is online"; FAIL=$((FAIL + 1))
  rm -f .mcp-session.json
fi
```

The new `AUTOTTE_DRY_RUN=2` mode stops after MCP session generation but before the coordinator launches.

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_run_sh_multi_db.sh`
Expected: new tests 9 and 10 FAIL — `.mcp-session.json` is still written from the single-DB template.

- [ ] **Step 3: Write minimal implementation**

Replace the MCP session block in `run.sh` (lines ~129–155):

```bash
# ---------------------------------------------------------------------------
# Build MCP session config when any selected DB needs online r_executor.
# ---------------------------------------------------------------------------

MCP_CONFIG_FLAG=""
cleanup_session_config() {
  rm -f "$SCRIPT_DIR/.mcp-session.json"
}

ONLINE_YAML_PATHS=""
if [[ -n "$TRIAGE_JSON" ]]; then
  ONLINE_YAML_PATHS=$(python3 -c "
import json
with open('$TRIAGE_JSON') as f:
    rows = json.load(f)
paths = [r['yaml_path'] for r in rows
         if r['disposition'] in ('RUN', 'RUN_AUTO_ONBOARD')
         and r['effective_mode'] == 'online']
print('\n'.join(paths))
")
fi

if [[ -n "$ONLINE_YAML_PATHS" ]]; then
  python3 -c "
import json, sys
paths = '''$ONLINE_YAML_PATHS'''.strip().splitlines()
mode = '${DB_MODE:-}'
with open('.mcp.json') as f:
    config = json.load(f)
args = ['tools/r_executor_server.py']
for p in paths:
    args += ['--config', p]
if mode:
    args += ['--mode', mode]
config['mcpServers']['r_executor'] = {
    'command': 'python',
    'args': args,
    'env': {},
}
with open('.mcp-session.json', 'w') as f:
    json.dump(config, f, indent=2)
"
  MCP_CONFIG=".mcp-session.json"
  trap cleanup_session_config EXIT
  echo "Generated .mcp-session.json with r_executor for $(echo "$ONLINE_YAML_PATHS" | wc -l | tr -d ' ') online DB(s)."
else
  MCP_CONFIG=".mcp.json"
fi

# Dry-run stage 2: stop after session config generation.
if [[ "${AUTOTTE_DRY_RUN:-}" == "2" ]]; then
  echo "AUTOTTE_DRY_RUN=2 — stopping after MCP session generation."
  exit 0
fi
```

Also adjust `cleanup_session_config` — it must not remove the file during normal successful runs via the EXIT trap; the trap is set only when a session file was created, so this is correct. For tests we explicitly `rm -f .mcp-session.json` in the bash test to avoid trap interference.

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/test_run_sh_multi_db.sh`
Expected: tests 9 and 10 PASS along with earlier tests.

- [ ] **Step 5: Commit**

```bash
git add run.sh tests/test_run_sh_multi_db.sh
git commit -m "feat(run): emit multi-config .mcp-session.json for online DB selections"
```

---

### Task C4: Build multi-DB coordinator prompt context

**Files:**
- Modify: `run.sh` (coordinator prompt heredoc, around lines 178–249)

- [ ] **Step 1: Write the failing test**

Append to `tests/test_run_sh_multi_db.sh`:

```bash
echo "Test 11: AUTOTTE_DRY_RUN=3 prints the coordinator prompt with multi-DB context"
rm -f .mcp-session.json
OUT=$(AUTOTTE_DRY_RUN=3 ./run.sh "topic" --dbs nhanes,synthetic_pcornet --db-mode online 2>&1); RC=$?
assert_exit_code 0 "$RC" "exit 0"
assert_contains "db_triage.json" "$OUT" "prompt references db_triage.json"
assert_contains "Multi-DB run" "$OUT" "prompt mentions Multi-DB run"
assert_contains "nhanes" "$OUT" "prompt lists nhanes"
assert_contains "synthetic_pcornet" "$OUT" "prompt lists synthetic_pcornet"
rm -f .mcp-session.json

echo "Test 12: AUTOTTE_DRY_RUN=3 for single DB still prints prompt"
OUT=$(AUTOTTE_DRY_RUN=3 ./run.sh "topic" --dbs nhanes 2>&1); RC=$?
assert_exit_code 0 "$RC" "exit 0"
assert_contains "Single-DB run" "$OUT" "prompt mentions Single-DB run"
assert_contains "nhanes" "$OUT" "prompt lists nhanes"
rm -f .mcp-session.json
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/test_run_sh_multi_db.sh`
Expected: tests 11 and 12 FAIL (current prompt has single-DB context only).

- [ ] **Step 3: Write minimal implementation**

Replace the DB_CONTEXT construction in `run.sh` (the single-DB block around lines 178–202) with a multi-DB version:

```bash
# ---------------------------------------------------------------------------
# Build coordinator prompt context.
# ---------------------------------------------------------------------------

DB_CONTEXT=""
if [[ -n "$TRIAGE_JSON" ]]; then
  # Count RUN/RUN_AUTO_ONBOARD entries.
  LIVE_COUNT=$(python3 -c "
import json
with open('$TRIAGE_JSON') as f:
    rows = json.load(f)
print(sum(1 for r in rows if r['disposition'] in ('RUN', 'RUN_AUTO_ONBOARD')))
")

  if [[ "$LIVE_COUNT" == "1" ]]; then
    HEADER="Single-DB run"
  else
    HEADER="Multi-DB run across $LIVE_COUNT databases"
  fi

  DB_CONTEXT=$(python3 -c "
import json
with open('$TRIAGE_JSON') as f:
    rows = json.load(f)
header = '$HEADER'
lines = [f'{header}.', '']
lines.append('Selected databases (from db_triage.json):')
for r in rows:
    lines.append(
        f\"  - id={r['id']} name={r['name']!r} cdm={r['cdm']} engine={r['engine']} \"
        f\"mode={r['effective_mode']} disposition={r['disposition']}\"
    )
    if r.get('reason'):
        lines.append(f\"    reason: {r['reason']}\")
    for w in r.get('warnings', []):
        lines.append(f\"    warn: {w}\")
lines += [
    '',
    'Triage file path: ' + '$TRIAGE_JSON',
    'Read this file at startup to understand per-DB status and mode.',
    '',
    'For every sub-agent launch:',
    '  - Tell workers the exact DB id they are targeting and its CDM/engine/mode.',
    '  - Tell workers to call get_schema(id), get_profile(id), and get_conventions(id)',
    '    from the datasource MCP server scoped to their DB id.',
    '  - Tell workers that any r_executor call (execute_r, query_db, list_tables,',
    '    describe_table, dump_schema, run_profiler) requires a db_id argument',
    '    matching the DB they were told to target.',
    '  - Feasibility, protocol, execution, and report workers each handle exactly',
    '    one DB. Literature discovery is shared across all DBs (run once).',
    '',
    'Output layout:',
    '  results/{ta}/{db_id}/ — per-DB feasibility, protocols, reports',
    '  results/{ta}/         — shared literature, summary, coordinator_log, agent_state',
]
print('\n'.join(lines))
")
fi

# Dry-run stage 3: stop after prompt context is built.
if [[ "${AUTOTTE_DRY_RUN:-}" == "3" ]]; then
  echo "AUTOTTE_DRY_RUN=3 — stopping after prompt context build."
  echo "----- DB_CONTEXT -----"
  echo "$DB_CONTEXT"
  echo "----------------------"
  exit 0
fi
```

Also update the heredoc template that launches the coordinator so the new `$DB_CONTEXT` is inserted and the legacy single-DB fields (`$DB_ID`, `$DB_NAME`, etc.) are no longer referenced — they've been replaced by the triage JSON the coordinator reads.

In the `cat <<PROMPT | claude -p ...` block, replace the lines beginning `Database configuration:` through `--mcp-config $MCP_CONFIG (pass this as --mcp-config to sub-agents)` with:

```bash
Your configuration:
- Therapeutic area: "$THERAPEUTIC_AREA"
- Results directory: $RESULTS_DIR
- Max turns per sub-agent: $MAX_TURNS (pass this as --max-turns to sub-agents)
- MCP config: $MCP_CONFIG (pass this as --mcp-config to sub-agents)

$DB_CONTEXT
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `bash tests/test_run_sh_multi_db.sh`
Expected: all 12 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add run.sh tests/test_run_sh_multi_db.sh
git commit -m "feat(run): build coordinator prompt from db_triage.json for multi-DB"
```

---

## Phase D — Agent instruction updates

### Task D1: Update `COORDINATOR.md` with Multi-DB runs section

**Files:**
- Modify: `COORDINATOR.md`

- [ ] **Step 1: Identify the insertion point**

Read `COORDINATOR.md` and locate the `## Data Sources` section (currently around line 87). Multi-DB guidance should either replace or supplement the current single-DB guidance.

- [ ] **Step 2: Edit the Data Sources section**

Replace the current `## Data Sources` section with:

```markdown
## Data Sources

Your initial prompt lists the selected databases in one of three shapes:

- **Public datasets only:** no `--dbs` / `--db-config` was passed. Workers use
  `list_datasources` / `get_datasource_details` to target public datasets.
- **Single-DB run:** one DB id is listed. All feasibility / protocol /
  execution / report work targets that one DB. Output lives under
  `results/{ta}/{db_id}/`. Literature discovery remains at `results/{ta}/`.
- **Multi-DB run:** two or more DB ids are listed in `db_triage.json`.
  Literature discovery runs ONCE at `results/{ta}/`. Feasibility, protocol
  generation, execution, and per-protocol reports branch per DB into
  `results/{ta}/{db_id}/`. The executive summary synthesizes across all DBs.

### Reading `db_triage.json`

At the start of every run that selected any DB, read
`{results_dir}/db_triage.json`. It is a JSON array of entries:

```json
[
  {
    "id": "nhanes",
    "name": "NHANES",
    "cdm": "nhanes",
    "engine": "duckdb",
    "yaml_path": "databases/nhanes.yaml",
    "disposition": "RUN" | "RUN_AUTO_ONBOARD" | "SKIP",
    "effective_mode": "online" | "offline",
    "reason": "…",
    "warnings": ["…"]
  }
]
```

- `RUN` — the DB is ready. Proceed through every phase.
- `RUN_AUTO_ONBOARD` — the DB is missing a schema dump or profile. During
  Phase 0, generate the missing files via the r_executor.
- `SKIP` — `run.sh` has already excluded this DB. It will not appear in
  later phases; reflect the skip in `agent_state.json` and note it in the
  executive summary.

### Multi-DB phase orchestration (phase-major)

Advance all active DBs through each phase before starting the next. Run
phases in this order:

1. **Phase 0 (per-DB, parallelizable):** For each `RUN_AUTO_ONBOARD` DB,
   generate schema dump (if missing) then profile (if missing) via
   `dump_schema(db_id=…)` and `run_profiler(db_id=…, code=…)`.
2. **Phase 1 (shared, once):** Launch one discovery worker and one
   reviewer. Outputs live at `results/{ta}/01_literature_scan.md` and
   `02_evidence_gaps.md`. No DB awareness needed.
3. **Phase 2 (per-DB, sequential):** Launch one feasibility worker per
   active DB. Each worker writes to
   `results/{ta}/{db_id}/03_feasibility.md`. After all report, read every
   feasibility file and tag questions feasible on ≥2 DBs for later
   replication analysis. Launch one reviewer per DB.
4. **Phase 3 (per-DB, sequential):** Per DB, launch one protocol worker.
   Protocol numbering restarts at 01 inside each DB's `protocols/` folder.
   When the same PICO question is feasible on multiple DBs, each DB's
   worker produces a protocol tailored to its own CDM and conventions
   (peer protocols, not copies). Launch one reviewer per DB.
5. **Phase 4 (per-DB, mode-dependent):** For each online DB, launch an
   execution worker per protocol and then a report writer. For each
   offline DB, write a per-DB `NEXT_STEPS.md` and transition that DB to
   `awaiting_results`. Continue other DBs regardless.
6. **Executive summary (shared):** Read every per-DB feasibility file and
   every per-protocol report, then write `results/{ta}/summary.md`.

### Failure isolation

Failures are isolated per DB. Max 3 revisions per phase per DB, max 2
backtracks across the whole run. When a DB fails beyond the revision
guardrail, mark it `failed` in `agent_state.json` and drop it from later
phases; other DBs continue unaffected. The summary records what failed.

### Telling workers about their DB

Every feasibility / protocol / execution / report sub-agent targets
exactly one DB. In the worker prompt, include:

1. The DB id (e.g. `'nhanes'`), name, CDM, engine, and `effective_mode`
   from `db_triage.json`.
2. Exact file paths: what to read and what to write, scoped to
   `results/{ta}/{db_id}/`.
3. A reminder that every r_executor call (`execute_r`, `query_db`,
   `list_tables`, `describe_table`, `dump_schema`, `run_profiler`) takes
   a required `db_id` argument that must match the DB the worker was
   told to target.
4. If this is a revision: the review notes.
```

Also append to `## State Tracking` a per-DB extension showing the new `agent_state.json` shape (from the spec's Coordinator state section):

```markdown
In multi-DB runs, `agent_state.json` tracks shared and per-DB phases
independently:

\`\`\`json
{
  "therapeutic_area": "...",
  "current_phase": "discovery|feasibility|protocol|execution|reporting|summary|done",
  "shared": {
    "discovery": {"status": "accepted", "revision_count": 1}
  },
  "dbs": {
    "nhanes":   {"mode": "online",  "phase": "reporting", "status": "running",
                 "revision_counts": {"feasibility": 0, "protocol": 1},
                 "protocols": 3, "protocols_completed": 2},
    "mimic_iv": {"mode": "offline", "phase": "awaiting_results", "status": "paused"},
    "foo":      {"status": "skipped", "reason": "offline_no_profile"}
  },
  "backtrack_count": 0,
  "total_sub_agents_launched": 14,
  "history": [ ... ]
}
\`\`\`
```

- [ ] **Step 3: Verify no broken cross-references**

Run `grep -n "DB_ID\|DB_NAME\|DB_CDM\|DB_ENGINE\|DB_SCHEMA_PREFIX\|DB_ONLINE" COORDINATOR.md` — these env-var references from the old single-DB path must be gone.

- [ ] **Step 4: Commit**

```bash
git add COORDINATOR.md
git commit -m "docs(coordinator): multi-DB orchestration, db_triage.json, per-DB state"
```

---

### Task D2: Update `WORKER.md`, `REVIEW.md`, `REPORT_WRITER.md`

**Files:**
- Modify: `WORKER.md`
- Modify: `REVIEW.md`
- Modify: `REPORT_WRITER.md`

- [ ] **Step 1: Edit `WORKER.md`**

Find the `## Your Tools` section (top of file) and update the r_executor bullet to:

```markdown
- **execute_r(db_id, code)** — (Online mode only) Execute R code in the persistent R session for *db_id*.
- **query_db(db_id, sql)** — (Online mode only) Run SQL against *db_id*.
- **list_tables(db_id)** — (Online mode only) List tables in *db_id*.
- **describe_table(db_id, table)** — (Online mode only) Describe a table in *db_id*.
- **dump_schema(db_id)** — (Phase 0 only) Write *db_id*'s schema to its configured path.
- **run_profiler(db_id, code)** — (Phase 0 only) Run profiling code and write *db_id*'s profile.
```

Then add a new subsection right after `## Working Style`:

```markdown
## Single-DB Scope

Feasibility, protocol, execution, and report workers are always scoped to
exactly ONE database, identified by `db_id` in the coordinator's prompt to
you. Every r_executor call you make must pass that `db_id` — never omit it,
never substitute another DB's id, never guess.

If the coordinator did not give you a `db_id`, you are a literature worker
and r_executor is not available to you.
```

- [ ] **Step 2: Edit `REVIEW.md`**

Add near the top (after any intro):

```markdown
## DB Scope

When reviewing work that was produced against a specific database, you
will receive the same `db_id` that was given to the worker. Any
r_executor calls you make (e.g. to verify SQL execution) must pass that
same `db_id`. Do not review a worker's output against a different DB.
```

- [ ] **Step 3: Edit `REPORT_WRITER.md`**

Find any absolute or relative path references that assume the old flat
layout (`results/{ta}/protocols/protocol_NN.md`) and update them to the
new nested layout (`results/{ta}/{db_id}/protocols/protocol_NN.md`). Add a
note near the top:

```markdown
## DB-scoped input paths

In multi-DB and single-DB runs, protocols and results files live under a
per-DB subdirectory:

- `results/{ta}/{db_id}/protocols/protocol_NN.md`
- `results/{ta}/{db_id}/protocols/protocol_NN_results.json`
- `results/{ta}/{db_id}/protocols/protocol_NN_table1.html` (if present)
- `results/{ta}/{db_id}/protocols/protocol_NN_*.png` (if present)

Your output goes in the same folder:

- `results/{ta}/{db_id}/protocols/protocol_NN_report.md`

The shared literature files you reference live at the top level:

- `results/{ta}/01_literature_scan.md`
- `results/{ta}/02_evidence_gaps.md`
```

- [ ] **Step 4: Verify all three files reference `db_id` consistently**

Run: `grep -n "execute_r\|query_db\|list_tables\|describe_table\|dump_schema\|run_profiler" WORKER.md REVIEW.md REPORT_WRITER.md`
Expected: every r_executor mention in WORKER.md / REVIEW.md reflects the new `db_id` parameter. REPORT_WRITER.md may not mention r_executor at all (report writers don't use it).

- [ ] **Step 5: Commit**

```bash
git add WORKER.md REVIEW.md REPORT_WRITER.md
git commit -m "docs(agents): require db_id on r_executor tools; nested output paths"
```

---

## Phase E — Manual smoke test

### Task E1: Run a real multi-DB smoke test

No code changes. This task documents the check an engineer should run before declaring the feature done.

- [ ] **Step 1: Confirm prerequisites**

- R installed and on PATH.
- `pip install mcp httpx lxml pyyaml` completed.
- DuckDB + nhanesA + PCORnet synthetic R packages installed.
- `databases/profiles/nhanes_profile.md` and `databases/profiles/synthetic_pcornet_profile.md` present (or both online with `--db-mode online`).

- [ ] **Step 2: Run the smoke test**

```bash
./run.sh "atrial fibrillation" --dbs synthetic_pcornet,nhanes --db-mode online 10
```

`10` caps sub-agent turns low so the test is fast. Expected observations:

1. Banner lists both DBs with their dispositions.
2. `.mcp-session.json` is created with two `--config` args.
3. `results/atrial_fibrillation/db_triage.json` contains two entries.
4. `results/atrial_fibrillation/01_literature_scan.md` appears.
5. `results/atrial_fibrillation/nhanes/03_feasibility.md` and
   `results/atrial_fibrillation/synthetic_pcornet/03_feasibility.md`
   appear after Phase 2.
6. `results/atrial_fibrillation/summary.md` references both DBs and flags
   any PICO questions feasible on both.

- [ ] **Step 3: Run the listing-only smoke tests**

```bash
./run.sh --list-dbs
./run.sh --show-db nhanes
./run.sh --show-db no_such_db  # should exit 1
```

- [ ] **Step 4: Run the unit-test suite**

```bash
pytest tests/ -v
bash tests/test_run_sh_multi_db.sh
```

All tests should pass.

- [ ] **Step 5: Clean up and commit any smoke-test artifacts**

The smoke test's `results/atrial_fibrillation/` directory should NOT be committed — it contains run outputs. If the test revealed real bugs, fix them and add a regression test; otherwise no commit is needed for this task.

---

## Summary

- 16 tasks total across 5 phases (A1–A4, B1–B5, C1–C4, D1–D2, E1).
- Each task follows TDD: failing test → minimal implementation → passing test → commit.
- Every new Python module has unit tests; bash-level behavior has `tests/test_run_sh_multi_db.sh`.
- No task introduces code that a later task hasn't tested.
- Backward compatibility verified in test 7 (`--db-config` resolves to the new nested layout) and test 8 (public-datasets mode).
- Documentation updates (Phase D) have no tests but are small, mechanical, and easy to verify by `grep`.
