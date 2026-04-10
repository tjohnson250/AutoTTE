# Auto-Protocol Designer (AutoTTE)

An autonomous multi-agent system that discovers causal questions from the
clinical literature and generates target trial emulation protocols -- complete
with analysis code, independent review loops, and optional execution against
a configured database. The coordinator agent drives the entire pipeline using
its own judgment, not hardcoded logic.

## Architecture

```
                 ┌──────────────────────────────┐
                 │      Coordinator Agent        │
                 │      (Claude Code session)    │
                 │                               │
                 │  Reads COORDINATOR.md         │
                 │  Launches sub-agents          │
                 │  Reads their output files     │
                 │  Decides: advance / revise /  │
                 │           backtrack           │
                 └──┬──────────┬────────────┬────┘
                    │          │            │
        ┌───────────┘          │            └────────────┐
        ▼                      ▼                         ▼
┌────────────────┐   ┌─────────────────┐       ┌─────────────────┐
│ Worker Agents  │   │ Reviewer Agents │       │ Report Writer   │
│ (claude -p)    │   │ (claude -p)     │       │ (claude -p)     │
│                │   │                 │       │                 │
│ Read WORKER.md │   │ Read REVIEW.md  │       │ Read REPORT_    │
│ Search PubMed  │   │ Verify PMIDs   │       │   WRITER.md     │
│ Query databases│   │ Check methods  │       │ Read results    │
│ Write protocols│──→│ Check SQL/R    │       │ Write per-      │
│ Generate R code│   │ Write critiques│       │   protocol      │
│ Run R scripts  │   │ Review conven- │       │   reports       │
│  (online mode) │   │   tions usage  │       │                 │
└────────────────┘   └────────────────┘       └─────────────────┘
        │                                              │
        │           ┌──────────────┐                   │
        └──────────→│  MCP Servers │←──────────────────┘
                    ├──────────────┤
                    │ PubMed       │
                    │ Datasource   │
                    │ R Executor   │
                    │ RxNorm       │
                    │ Clinical     │
                    │   Codes      │
                    └──────────────┘
```

**No hardcoded state machine.** The coordinator agent decides when work is
good enough to advance, when it needs revision, and when to backtrack. It
evaluates sub-agent output against objective acceptance criteria defined in
COORDINATOR.md, but the judgment and routing are the agent's own.

**Independent review.** Every reviewer runs in a fresh Claude Code session
with no access to the worker's reasoning -- only the output files. This
prevents anchoring and enables genuine error detection.

## How It Works

The coordinator runs as a long-lived Claude Code session. It launches
sub-agents (workers, reviewers, and report writers) by calling `claude -p`
in bash, reads their output files, and decides what to do next.

### Pipeline Phases

**Phase 0 -- Data Source Onboarding** (if a database is configured)
Auto-generates schema dump and data profile if they are missing. In online
mode the coordinator uses `dump_schema()` and `run_profiler()` from the R
executor MCP server. In offline mode the schema dump and profile must
already exist on disk.

**Phase 1 -- Literature Discovery**
Worker searches PubMed using a three-pass strategy (broad landscape, targeted
per-question, citation chaining), extracts PICO questions, and identifies
evidence gaps. Reviewer verifies PMIDs, runs independent searches, and
stress-tests "no prior studies" claims.

**Phase 2 -- Feasibility Assessment**
Worker checks whether the configured database (or public datasets) can
support each question, using the data profile for realistic sample size
estimates and variable availability. In online mode, workers can query the
live database to validate feasibility assumptions.

**Phase 3 -- Protocol Generation & Review**
Worker writes full target trial emulation protocols with runnable R analysis
scripts. Reviewer checks methods, code correctness, database conventions
compliance, and statistical pitfalls.

**Phase 4 -- Execution & Reporting**
In online mode, the coordinator runs R analysis scripts against the live
database via the R executor and collects structured results
(`protocol_NN_results.json`). In offline mode, it writes a `NEXT_STEPS.md`
file so the user can execute scripts on a secure machine and return results.
A report-writing agent then produces a per-protocol analysis report
(`protocol_NN_report.md`).

**Phase 5 -- Executive Summary**
The coordinator synthesizes all protocol reports into a final `summary.md`
covering key findings across the therapeutic area.

The coordinator logs every decision to `coordinator_log.md` and tracks
state in `agent_state.json` for transparency and debugging.

## Prerequisites

```bash
# Claude Code CLI
npm install -g @anthropic-ai/claude-code

# Python dependencies for MCP servers
pip install mcp httpx lxml pyyaml

# API key (if using the Anthropic API directly)
export ANTHROPIC_API_KEY="sk-ant-..."
```

> **Using Claude Code with a subscription?** If you have a Claude Pro or Max
> subscription, Claude Code works without an API key -- just run `claude` and
> authenticate with your Anthropic account. No `ANTHROPIC_API_KEY` needed.
> Sub-agents launched via `claude -p` inherit the same subscription billing.

**For online database mode** (agents query a live database):

[R](https://cran.r-project.org/) (≥ 4.1) must be installed and available on
your `PATH`. Then open an R session and install the required packages:

```r
# Core packages
install.packages(c("DBI", "jsonlite"))

# Plus the driver for your database engine:
install.packages("duckdb")   # DuckDB
install.packages("odbc")     # MS SQL Server, PostgreSQL via ODBC
```

**For the synthetic test database** (used for development and testing):

Run in R:

```r
devtools::install_github("tjohnson250/PCORnet-CDM-Synthetic-DB")
```

## Quick Start (Public Datasets Only)

The simplest mode -- generates protocols targeting public datasets like
MIMIC-IV and NHANES. No database connection required.

```bash
./run.sh "atrial fibrillation"
```

Results appear in `results/atrial_fibrillation/`.

## Quick Start (Synthetic Test Database)

To run against the bundled synthetic PCORnet database (requires R and the
`PCORnetCDMSyntheticDB` package from prerequisites above):

```bash
./run.sh "atrial fibrillation" --db-config databases/synthetic_pcornet.yaml
```

This runs in online mode -- agents query the synthetic DuckDB database,
validate cohort sizes, and execute analysis scripts end-to-end. Results
appear in `results/atrial_fibrillation/`.

## Database Mode

To target a specific database, create a YAML config file in `databases/`
and pass it with `--db-config`.

### Database Config Format

```yaml
id: "my_pcornet_cdw"
name: "My Institution's PCORnet CDW"
cdm: "pcornet"
cdm_version: "6.1"
engine: "mssql"
online: true

connection:
  r_code: |
    con <- DBI::dbConnect(odbc::odbc(), "MY_DSN")

schema_prefix: "CDW.dbo"
schema_dump: "databases/schemas/my_pcornet_cdw_schema.txt"
data_profile: "databases/profiles/my_pcornet_cdw_profile.md"
conventions: "databases/conventions/my_pcornet_cdw_conventions.md"
```

| Field | Description |
|-------|-------------|
| `id` | Unique identifier, used as a key by the datasource MCP server |
| `name` | Human-readable name shown in banners and logs |
| `cdm` | Common data model type (e.g., `pcornet`, `omop`) |
| `engine` | Database engine (`duckdb`, `mssql`, `postgres`, etc.) |
| `online` | Default connectivity mode; can be overridden with `--db-mode` |
| `connection.r_code` | R code that creates a DBI connection object named `con` |
| `schema_prefix` | Table qualifier (e.g., `CDW.dbo`, `main`) |
| `schema_dump` | Path to the schema dump file (auto-generated in online mode) |
| `data_profile` | Path to the data profile file (auto-generated in online mode) |
| `conventions` | Path to the database conventions markdown file |

### Running with a Database

```bash
# Online mode — agents query the live database
./run.sh "atrial fibrillation" --db-config databases/synthetic_pcornet.yaml

# Offline mode — agents work from schema dump + data profile
./run.sh "atrial fibrillation" --db-config databases/secure_pcornet_cdw.yaml --db-mode offline
```

## Online vs Offline Mode

| | Online | Offline |
|---|--------|---------|
| **When to use** | Database is reachable from the machine running Claude Code | Database is behind a firewall or requires a secure environment |
| **Agent capabilities** | Query live DB, validate cohort sizes, run analysis scripts | Work from schema dump and data profile only |
| **MCP tools** | All tools + R executor (`execute_r`, `query_db`, `list_tables`, etc.) | All tools except R executor |
| **Schema/profile** | Auto-generated during Phase 0 if missing | Must already exist on disk |
| **Analysis execution** | Coordinator runs R scripts via R executor, collects results JSON | User runs scripts on the secure machine and brings back results JSON |

Set `online: true` or `online: false` in the YAML config to choose the
default. Override at runtime with `--db-mode online` or `--db-mode offline`.

## Report Generation

### Online workflow

In online mode, the pipeline is fully automated:

1. Phase 3 generates R analysis scripts (`protocol_NN_analysis.R`).
2. Phase 4 executes them via the R executor MCP server.
3. Each script saves structured results to `protocol_NN_results.json`.
4. A report-writing agent reads the protocol spec + results JSON and
   produces `protocol_NN_report.md`.

### Offline workflow

When the database is not directly accessible:

1. Phases 1--3 run normally, producing protocols and R analysis scripts.
2. The coordinator writes `NEXT_STEPS.md` with instructions for the user.
3. **User action**: copy the R scripts to the secure machine, execute them,
   and copy the `protocol_NN_results.json` files back.
4. Re-run with `--resume-reports` to generate reports from the results:

```bash
./run.sh "atrial fibrillation" \
  --db-config databases/secure_pcornet_cdw.yaml \
  --resume-reports
```

This skips Phases 0--3 and goes straight to report generation and the
executive summary.

## Adding a New Database

1. **Create a config file** at `databases/my_database.yaml` following the
   format above. Set `online: true` if the database is reachable.

2. **Write conventions** at `databases/conventions/my_database_conventions.md`.
   Document engine-specific SQL dialect quirks, table naming patterns,
   known data quality issues, legacy data caveats, and any other
   requirements that agents must follow when writing queries.

3. **For offline mode**, generate the schema dump and data profile manually
   and place them at the paths declared in the config. For PCORnet CDWs,
   `CDW_DB_Profiler.qmd` can generate these on a secure machine.

4. **For online mode**, the coordinator auto-generates the schema dump and
   data profile during Phase 0 if the files do not yet exist.

5. **Run it**:

```bash
./run.sh "therapeutic area" --db-config databases/my_database.yaml
```

## run.sh Reference

```
./run.sh <therapeutic_area> [flags] [max_turns]

Arguments:
  therapeutic_area    Required. Clinical topic, e.g., "atrial fibrillation",
                      "type 2 diabetes", "sepsis".

Flags:
  --db-config PATH    Path to a database YAML config file.
  --db-mode MODE      Override connectivity mode: "online" or "offline".
  --resume-reports    Skip Phases 0-3. Generate reports from existing
                      protocol_NN_results.json files and produce the
                      executive summary.

Options:
  max_turns           Integer. Max turns per sub-agent (default 50).
                      Higher values allow more thorough but longer runs.

Examples:
  ./run.sh "atrial fibrillation"
  ./run.sh "atrial fibrillation" --db-config databases/synthetic_pcornet.yaml
  ./run.sh "atrial fibrillation" --db-config databases/secure_pcornet_cdw.yaml --db-mode offline
  ./run.sh "atrial fibrillation" --db-config databases/secure_pcornet_cdw.yaml --resume-reports
  ./run.sh "type 2 diabetes" --db-config databases/my_db.yaml 75
```

## File Structure

```
AutoTTE/
├── CLAUDE.md                          # Router — points agents to their instructions
├── COORDINATOR.md                     # Coordinator instructions + acceptance criteria
├── WORKER.md                          # Worker instructions + domain expertise
├── REVIEW.md                          # Reviewer instructions + verification protocol
├── REPORT_WRITER.md                   # Report-writing instructions
├── .mcp.json                          # MCP server configuration
├── run.sh                             # Launch script
├── CDW_DB_Profiler.qmd                # Manual CDW profiler (for secure machines)
├── analysis_plan_template.R           # R template for public datasets
├── analysis_plan_template_cdw.R       # R template for DB-targeted protocols
├── databases/
│   ├── secure_pcornet_cdw.yaml        # Config: institutional PCORnet CDW
│   ├── synthetic_pcornet.yaml         # Config: synthetic DuckDB for testing
│   ├── schemas/                       # Schema dumps (auto-generated or manual)
│   ├── profiles/                      # Data profiles (auto-generated or manual)
│   ├── conventions/                   # Per-database conventions (markdown)
│   └── data/                          # Database files (gitignored)
├── tools/
│   ├── pubmed_server.py               # MCP: PubMed search + abstract retrieval
│   ├── datasource_server.py           # MCP: unified datasource registry
│   ├── r_executor_server.py           # MCP: persistent R session + DB connection
│   ├── rxnorm_server.py               # MCP: RxNorm drug code lookup
│   ├── clinical_codes_server.py       # MCP: LOINC + HCPCS code lookup
│   └── stream_viewer.py               # Streaming output formatter
├── tests/
│   ├── conftest.py                    # MCP module mock for testing
│   ├── test_datasource_server.py      # Datasource registry tests
│   └── test_r_executor.py            # R executor tests
└── results/                           # Agent outputs (per therapeutic area)
    └── <therapeutic_area>/
        ├── agent_state.json           # Coordinator state
        ├── coordinator_log.md         # Decision log
        ├── 01_literature_scan.md      # Phase 1 output
        ├── 02_evidence_gaps.md        # Phase 1 output (ranked PICO questions)
        ├── discovery_review.md        # Phase 1 review
        ├── 03_feasibility.md          # Phase 2 output
        ├── feasibility_review.md      # Phase 2 review
        ├── summary.md                 # Executive summary
        ├── NEXT_STEPS.md              # Offline mode: user instructions
        └── protocols/
            ├── protocol_01.md         # Protocol specification
            ├── protocol_01_analysis.R # R analysis script
            ├── protocol_01_results.json  # Structured execution results
            ├── protocol_01_report.md  # Per-protocol analysis report
            ├── protocol_review.md     # Protocol reviews
            └── ...
```

## Agent Instruction Files

The system's behavior is controlled by four markdown files that serve as
instructions for each agent role. Modify these to change how the system works:

- **COORDINATOR.md** -- Acceptance criteria for each phase, red flags that
  trigger revision, and guardrails (max revisions, max backtracks). This is
  where you tune quality thresholds.
- **WORKER.md** -- Domain expertise, literature search protocol (three-pass
  strategy), SQL dialect awareness, database conventions compliance, and
  known pitfalls. This is where you encode lessons learned.
- **REVIEW.md** -- Verification protocol, PMID checking procedure, search
  completeness verification, code review checklist, and conventions-based
  review. This is where you encode quality checks.
- **REPORT_WRITER.md** -- Report structure, accuracy rules, and citation
  handling. Controls how execution results are translated into
  publication-quality reports.

## Extending

- **Add databases**: Create a new YAML config in `databases/` with
  conventions in `databases/conventions/`
- **Add public datasets**: Edit the datasource registry in
  `tools/datasource_server.py`
- **Add MCP tools**: New `@mcp.tool()` functions in an existing or new
  server (register in `.mcp.json`)
- **Adjust acceptance criteria**: Edit rubrics in `COORDINATOR.md`
- **Adjust review rigor**: Edit standards in `REVIEW.md`
- **Add new therapeutic areas**: Just run with a new area name; the system
  creates a new results subdirectory automatically

## Design Principles

1. **Agent-driven orchestration.** The coordinator is an LLM, not a script.
   It can adapt to unexpected situations, make nuanced quality judgments,
   and route work based on content -- not just exit codes.

2. **Independent review.** Reviewers get fresh context. They cannot be
   anchored by the worker's reasoning or self-assessment.

3. **Objective criteria with subjective judgment.** COORDINATOR.md defines
   acceptance checklists, but the coordinator applies them with judgment --
   the same way a PI reviews a postdoc's work.

4. **Transparency.** Every decision is logged. The coordinator_log.md and
   agent_state.json create a full audit trail of the run.

5. **Graceful degradation.** Guardrails (max revisions, max backtracks)
   prevent infinite loops, but they are guidelines for the coordinator's
   judgment, not hardcoded limits.

6. **Database conventions as first-class concept.** Every database carries
   a conventions file documenting its quirks -- legacy data caveats, SQL
   dialect differences, known data quality issues. Agents must read and
   apply conventions before writing any query or analysis code.

7. **Lessons encoded, not just learned.** When a run reveals a bug or
   pitfall, the fix is propagated to agent instruction files so future
   runs do not repeat it.
