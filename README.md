# Auto-Protocol Designer (AutoTTE)

An autonomous multi-agent system that discovers causal questions from the
clinical literature and generates target trial emulation protocols — with
independent review loops driven by agent judgment, not hardcoded logic.

## Architecture

```
                 ┌──────────────────────────────┐
                 │     Coordinator Agent         │
                 │     (Claude Code session)     │
                 │                               │
                 │  Reads COORDINATOR.md         │
                 │  Launches sub-agents          │
                 │  Reads their output files     │
                 │  Decides: advance / revise /  │
                 │           backtrack           │
                 └──────┬───────────────┬────────┘
                        │               │
            ┌───────────┘               └───────────┐
            ▼                                       ▼
   ┌─────────────────┐                    ┌─────────────────┐
   │  Worker Agents   │                    │ Reviewer Agents  │
   │  (claude -p)     │                    │  (claude -p)     │
   │                  │                    │                  │
   │  Read WORKER.md  │                    │  Read REVIEW.md  │
   │  Search PubMed   │ ── files on ──→   │  Verify PMIDs    │
   │  Write protocols │    disk            │  Check methods   │
   │  Generate R code │                    │  Write critiques │
   └──────────────────┘                    └──────────────────┘
```

**No hardcoded state machine.** The coordinator agent decides when work is
good enough to advance, when it needs revision, and when to backtrack. It
evaluates sub-agent output against objective acceptance criteria defined in
COORDINATOR.md, but the judgment and routing are the agent's own.

**Independent review.** Every reviewer runs in a fresh Claude Code session
with no access to the worker's reasoning — only the output files. This
prevents anchoring and enables genuine error detection.

## How It Works

The coordinator runs as a long-lived Claude Code session. It launches
sub-agents (workers and reviewers) by calling `claude -p` in bash, reads
their output files, and decides what to do next.

The four-phase pipeline:

1. **Literature Scan** — Worker searches PubMed using a three-pass strategy
   (broad landscape → targeted per-question → citation chaining), extracts
   PICO questions, and identifies evidence gaps.
2. **Evidence Gaps & Review** — Reviewer verifies PMIDs, runs independent
   searches, stress-tests "no prior studies" claims. Coordinator decides:
   accept / revise / backtrack.
3. **Feasibility Assessment** — Worker checks whether the CDW (or public
   datasets) can support each question, using the data profile for realistic
   sample size estimates and variable availability.
4. **Protocol Generation & Review** — Worker writes full target trial
   emulation protocols with runnable R/SQL code. Reviewer checks methods,
   code correctness, and CDW-specific pitfalls.

The coordinator logs every decision to `coordinator_log.md` and tracks
state in `agent_state.json` for transparency and debugging.

## Prerequisites

```bash
# Claude Code CLI
npm install -g @anthropic-ai/claude-code

# Python dependencies for the PubMed MCP server
pip install mcp httpx lxml

# API key
export ANTHROPIC_API_KEY="sk-ant-..."
```

For CDW mode, you also need R with the following packages on the machine
where you will render the Quarto analysis documents:

```r
install.packages(c("DBI", "odbc", "tidyverse", "WeightIt", "cobalt",
                    "survival", "EValue", "knitr", "quarto"))
```

And a working ODBC connection to your PCORnet CDW (MS SQL Server).

## Running: Public Data Mode

The simplest mode — generates protocols targeting public datasets like
MIMIC-IV and NHANES. No database connection required.

```bash
./run.sh "atrial fibrillation"
```

## Running: CDW Mode

CDW mode generates protocols targeting your institutional PCORnet Clinical
Data Warehouse on MS SQL Server. This requires additional setup.

### Step 1: Generate the CDW data profile

Before running AutoTTE against your CDW for the first time, you need to
generate a data profile that tells the agents what is actually in your
database — patient counts, coding systems, temporal coverage, legacy
encounter volumes, etc.

Open `CDW_DB_Profiler.qmd` in RStudio on your secure machine (the one
with the ODBC connection to the CDW) and update the connection string in
both execution chunks to match your DSN:

```r
con <- DBI::dbConnect(odbc::odbc(), "YOUR_DSN_HERE")
```

Then render the document:

```bash
quarto render CDW_DB_Profiler.qmd
```

This produces two outputs:
- `CDW_data_profile.md` — the machine-readable profile that agents read
  during feasibility assessment. Contains aggregate counts only, no PHI.
- `CDW_DB_Profiler.html` — a human-readable version with the same tables
  rendered inline with the profiler code.

Commit `CDW_data_profile.md` to the repo. The agents reference it by name.

**What the profile contains (16 sections):**

| Section | What it tells the agents |
|---------|------------------------|
| 1. Overall size & date ranges | Per-table patient counts, temporal coverage |
| 2. Year-by-year volume | Patient volume trends, data thinning in early years |
| 3. Legacy encounters & EHR migration | AllScripts-to-Epic duplicate detection, RAW_ENC_TYPE distribution, CDW_Source feeds, linked-data completeness for legacy vs non-legacy |
| 4. ICD-9 vs ICD-10 by year | Which years use which coding system |
| 5. Procedure coding systems | CPT/HCPCS vs ICD-10-PCS coverage |
| 6-7. Top labs and medications | Most common LOINCs and RXNORMs |
| 8-9. Demographics & encounter types | SEX/RACE/HISPANIC distributions, IP/ED/AV volumes |
| 10-11. Vitals & death records | Completeness, DEATH_SOURCE, duplicate death rows |
| 12. Column completeness | NULL rates for key fields in DEMOGRAPHIC, PRESCRIBING, DIAGNOSIS, LAB_RESULT_CM |
| 13-14. Condition & medication prevalence | Patient counts for AF, CKD, HF, DOACs, SGLT2i, etc. |
| 15-16. Key lab LOINCs | Coverage for creatinine, eGFR, HbA1c, INR, troponin, etc. |

**PHI protection:** All outputs are aggregates. Counts < 11 are suppressed.
Dates are year-month only. No PATIDs or individual rows are exported.

### Step 2: Provide your schema files

The repo should already contain these (generated by the schema extraction
function in `CDW_DB_Profiler.qmd`):
- `CDW_DBO_database_schema.txt` — PCORnet CDM table/column definitions
- `MasterPatientIndex_DBO_database_schema.txt` — MPI schema

If these are missing or stale, re-render the profiler to regenerate them.

### Step 3: Run with --cdw and your connection string

```bash
# Basic CDW run — you MUST provide your ODBC connection string
./run.sh "atrial fibrillation" --cdw \
  --db-connect 'con <- DBI::dbConnect(odbc::odbc(), "SQLODBCD17CDM")'

# With custom max turns per sub-agent (default 50)
./run.sh "atrial fibrillation" --cdw \
  --db-connect 'con <- DBI::dbConnect(odbc::odbc(), "SQLODBCD17CDM")' 75

# Target both public datasets AND the CDW
./run.sh "atrial fibrillation" --both \
  --db-connect 'con <- DBI::dbConnect(odbc::odbc(), "SQLODBCD17CDM")'
```

The `--db-connect` value is passed verbatim into the R scripts that the
worker generates. It replaces the `connect_cdw()` function body. Use
whatever DBI connection code works on your machine — DSN-based or
explicit Server/Database/Driver arguments:

```bash
# DSN-based (recommended if your DSN is configured)
--db-connect 'con <- DBI::dbConnect(odbc::odbc(), "SQLODBCD17CDM")'

# Explicit connection string
--db-connect 'con <- DBI::dbConnect(odbc::odbc(), Driver = "ODBC Driver 17 for SQL Server", Server = "your-server.example.com", Database = "CDW", Trusted_Connection = "yes")'
```

### Step 4: Render the analysis documents

The pipeline generates `.qmd` (Quarto) analysis documents in the
`results/<area>/protocols/` folder. These contain R + T-SQL code that
must be executed against the live CDW, so they need to be rendered on
your secure machine:

```bash
cd results/atrial_fibrillation/protocols/
quarto render protocol_01_analysis.qmd
```

The rendered HTML will show CONSORT diagrams, Table 1, propensity score
diagnostics, Kaplan-Meier curves, and Cox model results inline.

### CDW-specific behavior the agents handle automatically

When running in `--cdw` mode, the agents are instructed to:

- Write T-SQL (MS SQL Server syntax) with fully qualified table names
  (`CDW.dbo.TABLE_NAME`)
- **Filter out legacy encounters** (`AND e.RAW_ENC_TYPE <> 'Legacy Encounter'`)
  to avoid double-counting records from the AllScripts-to-Epic migration
- Check ICD-9 vs ICD-10 coverage and include both coding systems when
  the study lookback period crosses the October 2015 transition
- Use `ROW_NUMBER() OVER (PARTITION BY PATID ...)` on all LEFT JOINs
  to prevent row duplication (especially DEATH, VITAL, LAB_RESULT_CM)
- Ground sample size estimates in the data profile rather than guessing
- Use `dbExecute()` for DDL/DML and separate `dbGetQuery()` for SELECT
  (ODBC multi-statement batching bug)
- Produce two-part Quarto documents: function definitions first, then
  execution sections with results rendered inline

## run.sh Reference

```
./run.sh <therapeutic_area> [flags] [max_turns]

Arguments:
  therapeutic_area   Required. Clinical topic, e.g., "atrial fibrillation",
                     "type 2 diabetes", "sepsis"

Flags:
  --cdw              Target the PCORnet CDW (requires --db-connect)
  --both             Target both public datasets and the CDW
  --db-connect CODE  R code for the DBI database connection. Passed
                     verbatim into worker-generated R scripts. Required
                     with --cdw or --both.

Options:
  max_turns          Integer. Max turns per sub-agent (default 50).
                     Higher values allow more thorough but longer runs.

Examples:
  ./run.sh "atrial fibrillation"
  ./run.sh "atrial fibrillation" --cdw --db-connect 'con <- DBI::dbConnect(odbc::odbc(), "SQLODBCD17CDM")'
  ./run.sh "type 2 diabetes" --cdw --db-connect 'con <- DBI::dbConnect(odbc::odbc(), "SQLODBCD17CDM")' 75
  ./run.sh "heart failure" --both --db-connect 'con <- DBI::dbConnect(odbc::odbc(), "MY_DSN")'
```

## File Structure

```
AutoTTE/
├── CLAUDE.md                          # Router — points agents to their instructions
├── COORDINATOR.md                     # Coordinator agent instructions + acceptance criteria
├── WORKER.md                          # Worker agent instructions + domain expertise
├── REVIEW.md                          # Reviewer agent instructions + verification protocol
├── .mcp.json                          # MCP server configuration (PubMed tools)
├── run.sh                             # Launch script
├── CDW_DB_Profiler.qmd                # CDW data profiler (render on secure machine)
├── CDW_DBO_database_schema.txt        # PCORnet CDM schema (tables, columns, keys)
├── CDW_data_profile.md                # Data profile output (generated by profiler)
├── MasterPatientIndex_DBO_database_schema.txt  # MPI schema
├── analysis_plan_template.R           # R template for public datasets
├── analysis_plan_template_cdw.R       # R template for CDW protocols
├── tools/
│   ├── pubmed_server.py               # MCP server: PubMed + dataset registry
│   └── stream_viewer.py               # Streaming output formatter
└── results/                           # Agent outputs (created at runtime)
    └── atrial_fibrillation/
        ├── agent_state.json           # Coordinator state
        ├── coordinator_log.md         # Decision log
        ├── 01_literature_scan.md      # Phase 1: literature landscape
        ├── 02_evidence_gaps.md        # Phase 2: ranked PICO questions
        ├── discovery_review.md        # Review of discovery phase
        ├── 03_feasibility.md          # Phase 3: dataset/CDW feasibility
        ├── feasibility_review.md      # Review of feasibility
        ├── summary.md                 # Executive summary
        └── protocols/
            ├── protocol_01.md         # Protocol specification
            ├── protocol_01_analysis.qmd  # Quarto analysis (CDW mode)
            ├── protocol_01_analysis.R    # R script (public data mode)
            ├── protocol_review.md     # Protocol reviews
            └── ...
```

## Agent Instruction Files

The system's behavior is controlled by three markdown files that serve as
instructions for each agent role. Modify these to change how the system works:

- **COORDINATOR.md** — Acceptance criteria for each phase, red flags that
  trigger revision, and guardrails (max revisions, max backtracks). This is
  where you tune quality thresholds.
- **WORKER.md** — Domain expertise, literature search protocol (three-pass
  strategy), CDW-specific SQL conventions, Quarto document structure, and
  known pitfalls (legacy encounters, ICD-9/10 transition, DEATH table
  duplication). This is where you encode lessons learned.
- **REVIEW.md** — Verification protocol, PMID checking procedure, search
  completeness verification, code review checklist (ROW_NUMBER, legacy
  filtering, treatment arms guards). This is where you encode quality checks.

## Extending

- **Add datasets**: Edit `DATASET_REGISTRY` in `tools/pubmed_server.py`
- **Add tools**: New `@mcp.tool()` functions (e.g., ClinicalTrials.gov)
- **Adjust acceptance criteria**: Edit rubrics in `COORDINATOR.md`
- **Adjust review rigor**: Edit standards in `REVIEW.md`
- **Update CDW knowledge**: Re-render `CDW_DB_Profiler.qmd` after schema
  changes and commit the updated `CDW_data_profile.md`
- **Add new therapeutic areas**: Just run with a new area name; the system
  creates a new results subdirectory automatically

## Design Principles

1. **Agent-driven orchestration.** The coordinator is an LLM, not a script.
   It can adapt to unexpected situations, make nuanced quality judgments,
   and route work based on content — not just exit codes.

2. **Independent review.** Reviewers get fresh context. They can't be
   anchored by the worker's reasoning or self-assessment.

3. **Objective criteria with subjective judgment.** COORDINATOR.md defines
   acceptance checklists, but the coordinator applies them with judgment —
   the same way a PI reviews a postdoc's work.

4. **Transparency.** Every decision is logged. The coordinator_log.md and
   agent_state.json create a full audit trail of the run.

5. **Graceful degradation.** Guardrails (max revisions, max backtracks)
   prevent infinite loops, but they're guidelines for the coordinator's
   judgment, not hardcoded limits.

6. **Lessons encoded, not just learned.** When a run reveals a bug or
   pitfall (legacy encounter duplication, DEATH table row inflation,
   positivity violations from treatment imbalance), the fix is propagated
   to all three agent instruction files so future runs don't repeat it.
