# AutoTTE Database Integration — Design Spec

## Problem

AutoTTE currently generates R code that must be run separately against databases.
It has hardcoded knowledge of one CDW (via root-level schema/profile files) and a
handful of public datasets (embedded in `pubmed_server.py`). Adding a new data
source requires editing agent instructions and templates. There is no way for the
agents to validate generated code against a live database during a run.

## Solution

A config-driven database abstraction with two operating modes:

- **Offline mode** — Agents work from a schema dump + data profile. Generated R
  code is run by the user separately. This is a generalization of the current
  behavior.
- **Online mode** — Agents have a live DB connection via an R execution MCP
  server. They validate feasibility claims against real data, execute and iterate
  on generated R code during the run, and produce tested protocols.

## Components

### 1. Database Configuration Files

Location: `databases/<id>.yaml` (filename matches the `id` field)

Each file declares one data source. The `id` field is a slug used consistently
for the YAML filename and all associated file paths:

```yaml
id: "synthetic_pcornet"      # slug — used for file naming and API lookups
name: "PCORnet Synthetic CDW" # display name — used in agent output
cdm: "pcornet"              # pcornet | omop | custom
cdm_version: "6.0"
engine: "duckdb"             # duckdb | mssql | postgres | sqlite
online: true                 # can agents query this DB during the run?

connection:
  r_code: |
    library(pcornet.synthetic)
    dbs <- load_pcornet_database(path = "/path/to/synthetic")
    con <- dbs$cdw

schema_prefix: "main"

# Auto-populated by coordinator if missing:
schema_dump: "databases/schemas/synthetic_pcornet_schema.txt"
data_profile: "databases/profiles/synthetic_pcornet_profile.md"
conventions: "databases/conventions/synthetic_pcornet_conventions.md"
```

Key fields:

| Field | Purpose |
|-------|---------|
| `id` | Slug used for file naming and MCP tool lookups. Must match the YAML filename (without `.yaml`) |
| `name` | Human-readable display name, used in agent output and protocol documents |
| `cdm` | Tells agents the expected table/column conventions. `pcornet`, `omop`, or `custom` |
| `cdm_version` | Optional. Helps agents know which version of the CDM spec to reference |
| `engine` | Determines SQL dialect: T-SQL for `mssql`, standard SQL for `duckdb`/`postgres` |
| `online` | Whether the R executor should attempt to connect to this DB |
| `connection.r_code` | R code that creates a DBI connection object named `con` |
| `schema_prefix` | Table qualification prefix (e.g., `CDW.dbo` for SQL Server, `main` for DuckDB) |
| `schema_dump` | Path to generated schema dump file. Auto-generated if missing and online |
| `data_profile` | Path to generated data profile. Auto-generated if missing and online |
| `mpi_schema_dump` | Optional. Path to MPI schema dump for PCORnet CDWs with separate MPI databases |
| `conventions` | Optional. Path to a markdown file documenting database-specific quirks, filters, and coding requirements that agents must follow. See "Database Conventions" section below |

Example config for the existing secure CDW:

```yaml
id: "secure_pcornet_cdw"
name: "Secure PCORnet CDW"
cdm: "pcornet"
cdm_version: "6.1"
engine: "mssql"
online: false

connection:
  r_code: |
    con <- DBI::dbConnect(odbc::odbc(), "SQLODBCD17CDM")

schema_prefix: "CDW.dbo"
schema_dump: "databases/schemas/secure_pcornet_cdw_schema.txt"
mpi_schema_dump: "databases/schemas/secure_pcornet_cdw_mpi_schema.txt"
data_profile: "databases/profiles/secure_pcornet_cdw_profile.md"
conventions: "databases/conventions/secure_pcornet_cdw_conventions.md"
```

### 2. R Execution MCP Server

File: `tools/r_executor_server.py`

A Python MCP server that manages a persistent R subprocess with an active DB
connection. Uses subprocess (stdin/stdout pipes to a long-running R process),
not `rpy2`, to avoid compilation dependencies.

#### Tools

| Tool | Args | Returns | Notes |
|------|------|---------|-------|
| `execute_r(code)` | R code string | stdout + stderr, truncated | General-purpose R execution |
| `query_db(sql)` | SQL string | First 50 rows + total row count + column types | Uses active `con` object |
| `list_tables()` | none | Table names with row counts | Introspects connected DB |
| `describe_table(table)` | Table name | Column names, types, NULL rates, sample values | Per-table detail |
| `dump_schema()` | none | Path to generated schema file | Writes to config's `schema_dump` path |
| `run_profiler(code)` | R profiling code | Path to generated profile file | Agent writes the profiling code; this tool executes it and saves output to config's `data_profile` path |

#### Lifecycle

1. Server starts when `.mcp.json` references it; receives DB config YAML path
   as a command-line argument.
2. On first tool call, spawns an R subprocess (`Rscript --vanilla` with
   stdin/stdout pipes).
3. Runs the `connection.r_code` from the config to establish `con`.
4. Validates the connection with a test query (`DBI::dbListTables(con)`).
5. Keeps the R session alive for the duration of the AutoTTE run.
6. If `online: false` in the config, all DB-dependent tools return an error
   directing the agent to use the offline profile.

#### R Subprocess Communication

- Commands sent via stdin with a unique sentinel marker (e.g.,
  `cat("__SENTINEL_<uuid>__\n")`) appended to detect completion.
- stdout/stderr captured between sentinels and returned.
- Results truncated to prevent flooding agent context:
  - `execute_r`: max 200 lines of output
  - `query_db`: first 50 rows, formatted as a text table

### 3. Datasource Registry MCP Server

File: `tools/datasource_server.py`

Replaces the dataset registry currently embedded in `tools/pubmed_server.py`.
Serves as the single source of truth for all available data sources.

#### Data Sources

1. **Static public dataset registry** — the existing `DATASET_REGISTRY` list
   (MIMIC-IV, NHANES, MEPS, eICU-CRD, CMS SynPUF, Synthea), moved from
   `pubmed_server.py`.
2. **Database config files** — reads all `databases/*.yaml` files at startup
   and presents them alongside public datasets.

#### Tools

| Tool | Args | Returns |
|------|------|---------|
| `list_datasources(domain?, cdm?, online_only?)` | Optional filters | List of all data sources with key metadata |
| `get_datasource_details(id)` | Data source id | Full details — for public datasets: registry info; for DBs: config + schema/profile paths |
| `get_schema(id)` | Data source id | Schema dump file contents (reads the file at the config's `schema_dump` path) |
| `get_profile(id)` | Data source id | Data profile file contents (reads the file at the config's `data_profile` path) |
| `get_conventions(id)` | Data source id | Conventions file contents, or empty if no conventions file configured |

#### Migration from pubmed_server.py

- Remove `DATASET_REGISTRY`, `query_dataset_registry()`, and
  `get_dataset_details()` from `tools/pubmed_server.py`.
- `pubmed_server.py` retains only PubMed search and abstract retrieval.
- All `--allowedTools` references to `mcp__pubmed__query_dataset_registry` and
  `mcp__pubmed__get_dataset_details` change to `mcp__datasource__*` equivalents.

### 3.5. Database Conventions

Location: `databases/conventions/<id>_conventions.md`

Each configured database can have an optional conventions file that documents
database-specific quirks, required filters, and coding requirements. This is
where institutional knowledge lives — things that are true about *this specific
database* but not inherent to the CDM standard or SQL engine.

Example content for `databases/conventions/secure_pcornet_cdw_conventions.md`:

```markdown
# Secure PCORnet CDW — Database Conventions

## Required Filters

- **Legacy Encounter filtering:** Every query that joins ENCOUNTER must include
  `AND e.RAW_ENC_TYPE <> 'Legacy Encounter'`. The CDW contains re-imported
  AllScripts-era records that cause double-counting if not excluded.

- **Date bounds:** All queries on date columns must include explicit date range
  bounds. The CDW contains junk dates from 1820 to 3019. Unbounded queries
  will include garbage records.

## Coding System Requirements

- **ICD-9/10 transition:** The ICD-10 transition date is October 1, 2015. If
  the study period extends before this date, queries must include both
  `DX_TYPE = '09'` and `DX_TYPE = '10'`. If the study starts after Oct 2015,
  `DX_TYPE = '10'` alone is sufficient.

## SQL Patterns

- **DEATH table deduplication:** Always use `ROW_NUMBER() OVER (PARTITION BY
  PATID ORDER BY DEATH_DATE) AS rn ... WHERE rn = 1` when joining DEATH.
  Some patients have duplicate death records.

- **ODBC batch bug:** Do not combine `SELECT INTO #temp` and
  `SELECT * FROM #temp` in the same `dbExecute()` / `dbGetQuery()` call.
  The ODBC driver fails silently. Use separate calls.

- **Table qualification:** All tables must be fully qualified as
  `CDW.dbo.TABLE_NAME`, not bare `dbo.TABLE_NAME`.

## Column Handling

- **Case normalization:** After `dbGetQuery()`, always call
  `names(df) <- tolower(names(df))` — SQL Server returns uppercase column names.

- **Factor naming:** Create new factor columns with distinct names
  (`sex_cat`, `race_cat`), not by overwriting the raw column.
```

#### How conventions flow through the pipeline

The CDW-specific red flags and SQL conventions currently hardcoded in
`COORDINATOR.md`, `WORKER.md`, and `REVIEW.md` are migrated into the
conventions file for the secure CDW. The agent instruction files become generic:

1. **Coordinator** — During Phase 0, reads the conventions file and confirms it
   exists. Every sub-agent prompt includes: "Read the database conventions via
   `get_conventions('<id>')` before writing any SQL or R code. Treat every
   convention as a hard requirement."

2. **Workers** — Call `get_conventions(id)` at the start of feasibility and
   protocol generation phases. Apply every convention when writing SQL and R
   code. If a convention is not applicable to the current query, document why.

3. **Reviewers** — Call `get_conventions(id)` and use each convention as a
   checklist item. Every SQL query and R code block is checked against every
   applicable convention. Violations are flagged as REVISE items.

This means adding a new database with its own quirks requires only writing a
conventions file — no changes to the core agent instructions.

### 4. Pipeline Changes

#### run.sh

New CLI interface:

```bash
# Public datasets only (unchanged behavior):
./run.sh "atrial fibrillation"

# With a configured database:
./run.sh "atrial fibrillation" --db-config databases/synthetic_pcornet.yaml

# Force offline even if config says online:
./run.sh "atrial fibrillation" --db-config databases/secure_pcornet_cdw.yaml --db-mode offline

# With custom max turns:
./run.sh "atrial fibrillation" --db-config databases/my_cdw.yaml 75
```

Removed flags: `--cdw`, `--both`, `--db-connect`

New flags:

| Flag | Required | Default | Purpose |
|------|----------|---------|---------|
| `--db-config <path>` | No | none | Path to a database config YAML |
| `--db-mode online\|offline` | No | Value from config's `online` field | Override online/offline mode |

When `--db-config` is provided:
- The `r_executor` MCP server is added to the sub-agent tool allowlists (online
  mode only).
- The `datasource` MCP server is always added.
- The coordinator prompt includes the DB config path and mode.

When no `--db-config` is provided:
- The `datasource` MCP server is still added (serves the public registry).
- No `r_executor` server.
- Behavior is identical to today's public-only mode.

#### .mcp.json

Updated to include new servers:

```json
{
  "mcpServers": {
    "pubmed": {
      "command": "python",
      "args": ["tools/pubmed_server.py"]
    },
    "rxnorm": {
      "command": "python",
      "args": ["tools/rxnorm_server.py"]
    },
    "clinical_codes": {
      "command": "python",
      "args": ["tools/clinical_codes_server.py"]
    },
    "datasource": {
      "command": "python",
      "args": ["tools/datasource_server.py"]
    },
    "r_executor": {
      "command": "python",
      "args": ["tools/r_executor_server.py", "--config", "databases/synthetic_pcornet.yaml"]
    }
  }
}
```

Note: The static `.mcp.json` checked into the repo includes only `pubmed`,
`rxnorm`, `clinical_codes`, and `datasource`. It does NOT include `r_executor`.
When `--db-config` is provided, `run.sh` writes a session-specific
`.mcp-session.json` that merges the base config with an `r_executor` entry
pointing to the specified config path. The coordinator's `claude -p` invocation
uses this session config. The session file is gitignored and cleaned up after
the run.

#### COORDINATOR.md Changes

New Phase 0 — Data Source Onboarding (inserted before Phase 1):

1. If `--db-config` was provided and mode is online:
   a. Read the DB config YAML.
   b. Check if `schema_dump` file exists. If not, call `dump_schema()` via the
      R executor MCP to generate it.
   c. Check if `data_profile` file exists. If not:
      - Read the generated schema dump.
      - Determine appropriate profiling queries based on the `cdm` type.
      - Write R profiling code.
      - Call `run_profiler(code)` to execute it and save the output.
   d. Log onboarding results to `coordinator_log.md`.
2. If `--db-config` was provided but mode is offline:
   a. Verify that `schema_dump` and `data_profile` files exist.
   b. If missing, warn in the log that offline mode requires pre-generated
      files and proceed with whatever is available.

Updated protocol target logic:
- The old `public` / `cdw` / `both` target is replaced by the presence or
  absence of a `--db-config` flag.
- If a DB config is provided, protocols target that database.
- Public datasets are always available via the datasource registry.
- The coordinator decides whether to generate protocols for the configured DB,
  public datasets, or both, based on feasibility.

Updated sub-agent prompts:
- Workers are told the DB id, name, CDM type, engine, schema prefix, and
  whether they have online access.
- Workers are pointed to `get_schema(id)`, `get_profile(id)`, and
  `get_conventions(id)` instead of hardcoded file paths.
- In online mode, workers are told they can use `execute_r()` and `query_db()`
  to validate their work.
- Every sub-agent prompt includes: "Read the database conventions via
  `get_conventions('<id>')` before writing any SQL or R code. Treat every
  convention as a hard requirement."

#### WORKER.md Changes

New section on data source access:
- Use `mcp__datasource__get_schema(id)`, `mcp__datasource__get_profile(id)`,
  and `mcp__datasource__get_conventions(id)` to get schema, profile, and
  conventions for any configured database.
- Do not reference hardcoded file paths for schemas or profiles.

New section on database conventions:
- Call `get_conventions(id)` at the start of feasibility and protocol
  generation phases.
- Apply every convention when writing SQL and R code.
- If a convention is not applicable to the current query, document why.

New section on SQL dialect awareness:
- Check the `engine` field from the DB config to determine SQL dialect.
- `mssql`: T-SQL — `#temp` tables, `DATEADD`, `DATEDIFF`, `GETDATE()`,
  `SELECT INTO`, tables qualified as `schema_prefix.TABLE`.
- `duckdb`: Standard SQL — `CREATE TEMP TABLE ... AS SELECT`, `DATE_ADD`,
  `CURRENT_DATE`, no `#` prefix, schema prefix from config.
- `postgres`: Standard SQL with PostgreSQL date functions.

New section on online mode validation:
- After writing protocol R code, execute key sections via `execute_r()`:
  1. Run cohort-building SQL and verify temp tables have rows.
  2. Check CONSORT counts are plausible.
  3. Run the propensity score model.
  4. Fix any errors and re-execute until successful.
- Only declare the protocol complete after successful execution.
- If execution reveals data issues (empty cohorts, missing codes), update the
  protocol and document the findings.

CDW-specific SQL conventions currently in WORKER.md are migrated to the
conventions file for the secure CDW database. WORKER.md retains only generic
engine-dialect guidance.

#### REVIEW.md Changes

New section on conventions-based review:
- Call `get_conventions(id)` and use each convention as a checklist item.
- Every SQL query and R code block is checked against every applicable
  convention. Violations are flagged as REVISE items.

New online-mode review criteria:
- If the run was online, reviewer checks that the worker actually executed the
  code (evidence of execution output in the protocol or logs).
- Reviewer can independently run `query_db()` to spot-check claims about
  patient counts or code coverage.

### 5. File Migration

Files moved from root to `databases/`:

| Old Location | New Location |
|-------------|-------------|
| `CDW_DBO_database_schema.txt` | `databases/schemas/secure_pcornet_cdw_schema.txt` |
| `MasterPatientIndex_DBO_database_schema.txt` | `databases/schemas/secure_pcornet_cdw_mpi_schema.txt` |
| `CDW_data_profile.md` | `databases/profiles/secure_pcornet_cdw_profile.md` |

CDW-specific conventions extracted from `COORDINATOR.md`, `WORKER.md`, and
`REVIEW.md` into `databases/conventions/secure_pcornet_cdw_conventions.md`.

A new `databases/secure_pcornet_cdw.yaml` config file is created pointing to
these paths.

All references in `COORDINATOR.md`, `WORKER.md`, and `REVIEW.md` to the old
file paths are updated to use datasource MCP tools instead.

`CDW_DB_Profiler.qmd` remains in the root — it is a standalone Quarto document
for manually regenerating the secure CDW profile and is not part of the
automated pipeline.

### 6. Directory Layout

```
AutoTTE/
  databases/
    schemas/
      secure_pcornet_cdw_schema.txt
      secure_pcornet_cdw_mpi_schema.txt
    profiles/
      secure_pcornet_cdw_profile.md
    conventions/
      secure_pcornet_cdw_conventions.md
    secure_pcornet_cdw.yaml
    synthetic_pcornet.yaml          (example)
  tools/
    pubmed_server.py                (modified — registry removed)
    datasource_server.py            (new)
    r_executor_server.py            (new)
    rxnorm_server.py
    clinical_codes_server.py
    stream_viewer.py
  run.sh                            (modified)
  .mcp.json                         (modified)
  COORDINATOR.md                    (modified)
  WORKER.md                         (modified)
  REVIEW.md                         (modified)
  analysis_plan_template.R
  analysis_plan_template_cdw.R
  CDW_DB_Profiler.qmd
```

`.gitignore` additions:
- `databases/schemas/` — auto-generated, may contain sensitive schema info
- `databases/profiles/` — auto-generated, may contain aggregate counts
- `databases/conventions/` — may contain sensitive institutional details
- `.mcp-session.json` — session-specific MCP config generated by `run.sh`

Database config YAML files (`databases/*.yaml`) are tracked in git but should
not contain credentials. Connection code should use environment variables or
DSN names rather than inline passwords.

## Out of Scope

- **OMOP CDM support:** The architecture supports it (set `cdm: "omop"` in the
  config), but OMOP-specific profiling logic and SQL conventions are not
  implemented in this iteration. The agent can work from a schema dump + custom
  profile.
- **Multiple databases per run:** One `--db-config` per run. The datasource
  registry still lists all configured DBs and public datasets, but only one DB
  has an active R executor connection.
- **Credential management:** Connection code is stored as-is in the YAML config.
  No secrets manager integration.
- **Concurrent R execution:** One R subprocess per run. No parallelism within
  the R session.

## Dependencies

New Python dependencies for the R executor server:
- `pyyaml` — for reading DB config files (also needed by datasource server)
- No other new dependencies; subprocess communication with R uses stdlib

R environment requirements (for online mode):
- R installed and on PATH
- `DBI` package
- Engine-specific driver package (`duckdb`, `odbc`, etc.)
- Any packages referenced in the config's `connection.r_code`
