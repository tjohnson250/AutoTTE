# Multi-Database Harness Design

Date: 2026-04-12
Status: Draft for review

## Problem

AutoTTE currently runs against at most one database per invocation. `run.sh` accepts a single `--db-config <path>` flag, generates a session-specific `.mcp-session.json` wrapping one `r_executor` bound to that one DB, and embeds that one DB's identifiers into the coordinator prompt. Researchers who want to exercise a therapeutic area across several databases — either to validate feasibility in different populations or to look for cross-database replication — must today run the harness repeatedly and stitch results together by hand.

This design extends the harness so that a single run can target any subset of the YAML-configured databases in `databases/` (or all of them), with appropriate warnings when a selected database cannot be fully supported.

## Goals

- Accept any subset of databases — or `all` — in a single invocation.
- Surface database availability upfront: warn when a profile is missing, auto-onboard online databases, skip offline-and-unprofiled databases with clear messaging.
- Share work that is genuinely shared (literature discovery) and isolate work that is genuinely per-database (feasibility, protocol generation, execution, per-protocol reports).
- Preserve single-database runs without breaking existing scripts.

## Non-goals

- Cross-database protocol unification. Each database gets its own protocols informed by its own CDM and conventions; the summary phase synthesizes across them but does not produce shared protocol files.
- Parallel DB execution inside a phase. Sequential-per-DB within each phase keeps coordinator turn-budget consumption predictable given current polling overhead.
- New data-source types. Only YAML-configured databases under `databases/` are in scope; public-dataset-only runs continue to work as today.

## Pipeline shape

Literature discovery runs once for the therapeutic area. Feasibility, protocol generation, execution, and per-protocol reporting branch per database. The executive summary synthesizes across all databases and explicitly calls out replication signals when the same PICO question produced protocols on multiple databases.

## CLI

**Primary flag:**

```bash
./run.sh "atrial fibrillation" --dbs nhanes,mimic_iv
./run.sh "atrial fibrillation" --dbs all
./run.sh "atrial fibrillation"                      # public datasets only
```

`--dbs` takes a comma-separated list of database IDs (the `id` field inside each `databases/*.yaml`) or the literal keyword `all`, which expands to every YAML in `databases/`. Unknown IDs fail fast with the list of valid IDs. The flag is backed by the canonical ID, not file paths.

**Backward compatibility:** `--db-config <path>` still works and is internally equivalent to `--dbs <id_from_that_yaml>`. Combining `--db-config` and `--dbs` in the same invocation is an error. Existing scripts continue to work untouched.

**Mode override:** `--db-mode online|offline` remains a global override applied uniformly to every selected DB. Set to `online`, every DB runs online regardless of its YAML default (if a DB's `connection.r_code` cannot actually connect, that surfaces as a Phase 0 failure for that DB and it drops out). Set to `offline`, every DB runs offline regardless of YAML. Omitted, each DB uses its own YAML `online` setting.

**Resume reports:** `--resume-reports` continues to work. With `--dbs foo` it iterates `results/{ta}/foo/protocols/`; with `--dbs all` it iterates every DB subdirectory under `results/{ta}/`.

**Discovery flags:**

```bash
./run.sh --list-dbs            # enumerate all DBs with id, name, default mode, file presence
./run.sh --show-db <id>        # print resolved config + file presence for one DB
```

Both exit 0 after printing; neither requires a therapeutic area. `--list-dbs` output format:

```
ID                   NAME                     CDM       ENGINE   DEFAULT  SCHEMA  PROFILE  CONVENTIONS
nhanes               NHANES                   nhanes    duckdb   online   yes     yes      yes
mimic_iv             MIMIC-IV v3.1            mimic     duckdb   online   yes     yes      yes
synthetic_pcornet    PCORnet Synthetic CDW    pcornet   duckdb   online   yes     yes      yes
secure_pcornet_cdw   Secure PCORnet CDW       pcornet   mssql    offline  yes     no       yes
```

## Startup triage

After parsing `--dbs`, `run.sh` triages each selected DB before launching the coordinator. For each DB it checks: the YAML parses, the `schema_dump` file exists, the `data_profile` file exists, the `conventions` file exists, and the effective online mode (YAML merged with any `--db-mode` override).

Each DB gets one of these dispositions:

| Condition | Disposition | User-visible output |
|---|---|---|
| Online + profile present | RUN | `[OK] nhanes — online, fully profiled` |
| Online + profile missing | RUN (auto-onboard) | `[WARN] mimic_iv — online, profile missing; Phase 0 will generate it` |
| Offline + profile present | RUN | `[OK] secure_pcornet_cdw — offline, fully profiled` |
| Offline + profile missing | SKIP | `[SKIP] foo — offline with no profile; cannot auto-generate. Run in online mode once or generate the profile manually.` |
| Schema dump missing | SKIP if offline, RUN (auto-onboard) if online | same tiered treatment |
| Conventions missing | RUN + WARN | `[WARN] foo — no conventions file; protocols may miss DB-specific rules` |
| Unknown ID | ERROR | fail fast, list valid IDs |

If every selected DB is skipped, `run.sh` exits 1 with a message identifying which DBs were skipped and why — there is nothing to run.

The surviving set and their dispositions are serialized to `results/{ta}/db_triage.json` and referenced in the coordinator's initial prompt, so the coordinator knows which DBs need Phase 0 auto-onboarding versus which are ready to go.

## Output layout

```
results/{therapeutic_area}/
├── coordinator_log.md           # shared — every decision across all DBs
├── agent_state.json             # shared — per-DB sub-state
├── db_triage.json               # from startup validation
├── 01_literature_scan.md        # shared — Phase 1
├── 02_evidence_gaps.md          # shared — Phase 1
├── summary.md                   # shared — cross-DB executive summary
├── nhanes/
│   ├── 03_feasibility.md
│   ├── protocols/
│   │   ├── protocol_01.md
│   │   ├── protocol_01_analysis.R
│   │   ├── protocol_01_results.json
│   │   └── protocol_01_report.md
│   └── NEXT_STEPS.md            # only if this DB is offline and awaiting results
├── mimic_iv/
│   └── …
└── secure_pcornet_cdw/
    └── …
```

Shared work lives at the top level. Per-DB work lives in per-DB subdirectories. Resume-reports iterates `results/{ta}/*/protocols/` across every DB subdirectory.

## Coordinator state

`agent_state.json` tracks shared phases and per-DB phases independently:

```json
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
    "mimic_iv": {"mode": "offline", "phase": "awaiting_results", "status": "paused",
                 "revision_counts": {"feasibility": 0, "protocol": 0},
                 "protocols": 2, "protocols_completed": 0},
    "foo":      {"status": "skipped", "reason": "offline_no_profile"}
  },
  "backtrack_count": 0,
  "total_sub_agents_launched": 14,
  "history": [ ... ]
}
```

`coordinator_log.md` remains a single chronological file. Each entry is prefixed with the DB it applies to (or `shared:` for Phase 1 and the summary) so the log is easy to filter.

## Orchestration flow

The coordinator is phase-major: it advances all active DBs through a phase before starting the next.

**Phase 0 — Data source onboarding.** For each DB marked RUN (auto-onboard), the coordinator invokes the multiplexed r_executor to generate the schema dump (if missing) and the profile (if missing). Outputs land under `databases/schemas/` and `databases/profiles/` (unchanged paths). Each DB's onboarding is logged. If onboarding fails for one DB, that DB transitions to `status: "skipped", reason: "phase_0_failure"` and drops out of later phases; other DBs continue unaffected.

**Phase 1 — Literature discovery.** One worker and one reviewer, identical to the single-DB pipeline. Outputs go to `results/{ta}/01_literature_scan.md` and `02_evidence_gaps.md`. No DB-awareness — literature is about the therapeutic area.

**Phase 2 — Feasibility.** For each active DB, the coordinator launches one feasibility worker sequentially. Each worker is told its DB ID, CDM, engine, and mode, and writes to its own `03_feasibility.md` in the per-DB subdirectory. Workers use `get_schema(id)`, `get_profile(id)`, and `get_conventions(id)` scoped to their DB, and `execute_r(db_id=…)` / `query_db(db_id=…)` when online. After all DBs report, the coordinator reads every feasibility file and tags cross-DB overlaps — PICO questions feasible on multiple DBs are noted for replication analysis in the summary. One review per DB.

**Phase 3 — Protocol generation.** Per DB, one worker generates protocols from that DB's feasibility output. Protocol numbering is per-DB (each DB's folder starts at `protocol_01`). When a PICO question is feasible on multiple DBs, the coordinator instructs each DB's worker to produce a protocol tailored to its own CDM and conventions — they are peer protocols, not copies. One review per DB. Revision guardrails (max 3 revisions per phase) apply per DB.

**Phase 4 — Execution and reporting.** Online DBs: the coordinator launches an execution worker per protocol, sequential within a DB, iterated across DBs. The worker calls `execute_r(db_id=<this_db>, code=…)` and verifies that `protocol_NN_results.json` appears in the per-DB protocols folder. Offline DBs: a per-DB `NEXT_STEPS.md` is written and that DB transitions to `awaiting_results`. The run still completes for online DBs. For any DB with a `protocol_NN_results.json`, a report worker produces `protocol_NN_report.md` in that DB's folder.

**Final — Executive summary.** One worker reads every feasibility file, every per-protocol report, and the shared literature outputs, and produces `summary.md` (see next section).

Sequential per-DB within a phase is a deliberate tradeoff: it trades runtime for turn-budget predictability. Parallel branching inside the coordinator burns turns fast given current polling overhead. Revisit if turn budget improves.

## Failure isolation

Failures are isolated per DB. If DB X fails Phase 2 or Phase 3 beyond the revision guardrail, it transitions to `status: "failed"` and drops out of later phases; DBs Y and Z continue unaffected. The executive summary documents which DBs failed where and why. Global guardrails stay as today: max 3 revisions per phase per DB, max 2 backtracks total across the whole run.

## r_executor multiplexing

The r_executor MCP server grows to hold N R sessions keyed by DB ID.

**CLI change:** `--config` becomes repeatable.

```bash
python tools/r_executor_server.py \
  --config databases/nhanes.yaml \
  --config databases/mimic_iv.yaml
```

At startup, the server loads every config into a registry `{db_id: {yaml, r_code, session}}` but lazily initializes each R session on first use, so startup does not block on all N connections.

**Tool signatures:** every existing r_executor tool grows a required `db_id` parameter. Unknown `db_id` returns a clear error listing valid IDs. Calls without `db_id` are rejected. Single-DB runs now also pass `db_id` explicitly — no implicit default — which keeps the agent-facing surface uniform.

| Today | New |
|---|---|
| `execute_r(code)` | `execute_r(db_id, code)` |
| `query_db(sql)` | `query_db(db_id, sql)` |
| `list_tables()` | `list_tables(db_id)` |
| `describe_table(name)` | `describe_table(db_id, name)` |
| `dump_schema()` | `dump_schema(db_id)` |
| `run_profiler(code)` | `run_profiler(db_id, code)` |

**Session isolation:** each DB gets its own R subprocess (today's pattern, repeated per DB). A crash or hang in one session does not affect the others — the server catches the failure, marks the session dead, and lets the coordinator decide whether to retry. Sessions restart on demand.

**`run.sh` session config:** when any selected DB is online, `run.sh` generates `.mcp-session.json` with a single `r_executor` entry whose `args` list every online DB's config path:

```json
"r_executor": {
  "command": "python",
  "args": ["tools/r_executor_server.py",
           "--config", "databases/nhanes.yaml",
           "--config", "databases/mimic_iv.yaml"],
  "env": {}
}
```

## Executive summary

The summary worker reads across all DB subdirectories and produces one integrated document at `results/{ta}/summary.md`:

1. **Run overview** — therapeutic area, DBs attempted, per-DB status (completed / awaiting_results / skipped / failed) with reasons.
2. **Shared evidence landscape** — one paragraph drawn from `01_literature_scan.md` and `02_evidence_gaps.md`.
3. **Feasibility matrix** — rows are PICO questions, columns are DBs, cells indicate feasible / infeasible / not-assessed. Makes cross-DB replication opportunities visible at a glance.
4. **Per-protocol results** — grouped by PICO question. When the same question ran on multiple DBs, results appear side-by-side with a short consistency note (effect directions agree or disagree, CI overlap).
5. **Replication findings** — for every question executed on two or more DBs, whether effect estimates were consistent, and any divergence worth investigating.
6. **Cross-protocol multiple-comparison correction** — Benjamini-Yekutieli FDR applied across every primary effect estimate from every DB together. Per-protocol reports continue to present uncorrected p-values; the summary is the only place FDR is applied, because it is the only place with the full hypothesis set.
7. **Limitations and caveats** — per-DB limitations (e.g., "NHANES results apply only to the civilian non-institutionalized US population") plus cross-DB limitations (e.g., "MIMIC-IV ICU is not comparable to PCORnet ambulatory; divergent effects may reflect population differences, not treatment differences").

**Scoping:** skipped and failed DBs appear in §1 with the reason but do not contribute to §3–§6. DBs in `awaiting_results` appear in the feasibility matrix but are flagged as pending in §4. Replication analysis (§5) only covers DBs that actually executed.

## Agent-instruction updates

- `COORDINATOR.md` — add a "Multi-DB runs" section covering phase-major orchestration, per-DB agent_state tracking, and `db_triage.json` handling. Clarify that Phase 1 runs once but Phase 2–4 iterate DBs. Instruct workers to pass `db_id` to every r_executor call.
- `WORKER.md` — note that feasibility, protocol, and execution workers are told exactly one DB ID, and every r_executor call must include that `db_id`. Literature workers are unchanged.
- `REVIEW.md` — reviewers receive the same DB ID their worker received and apply it identically.
- `REPORT_WRITER.md` — input JSON path now lives under a DB subdirectory.

## Files touched

- `run.sh` — argument parsing, triage logic, `--list-dbs` / `--show-db`, `.mcp-session.json` generation for N configs, coordinator prompt with `db_triage.json` reference.
- `tools/r_executor_server.py` — repeatable `--config`, session registry, `db_id` argument on all tools, per-DB session isolation.
- `COORDINATOR.md`, `WORKER.md`, `REVIEW.md`, `REPORT_WRITER.md` — documentation updates.
- `tests/test_run_sh_multi_db.sh` — unknown ID error, `all` expansion, mixed online+offline selection, all-skipped exit-1, `--list-dbs` and `--show-db` output format, `--db-config` ↔ `--dbs` equivalence.
- `tests/test_r_executor_multi_session.py` — two sessions initialize lazily, crash isolation, unknown `db_id` error, rejection of calls without `db_id`.
- `tests/test_triage.py` — each of the seven dispositions from the triage table produces the right decision and reason.

No changes to `tools/datasource_server.py` (already multi-DB aware via the `id` parameter) or the other MCP servers.

## Manual smoke test

Running `./run.sh "atrial fibrillation" --dbs synthetic_pcornet,nhanes --db-mode online` end-to-end against the checked-in synthetic DB plus NHANES should produce the output structure described in the Output layout section, with both DBs completing Phases 0–4 and a summary that flags any PICO questions feasible on both.

## Backward compatibility matrix

| Invocation | Behavior |
|---|---|
| `./run.sh "topic"` | Public datasets only, unchanged. |
| `./run.sh "topic" --db-config databases/foo.yaml` | Accepted; resolved to `--dbs foo` internally. Output uses the new per-DB nested layout. |
| `./run.sh "topic" --db-config databases/foo.yaml --resume-reports` | Resume reports, nested layout. |
| `./run.sh "topic" --dbs foo` | Single-DB run, nested layout at `results/{topic}/foo/`. |
| `./run.sh "topic" --dbs all` | Multi-DB run across every YAML in `databases/`. |
| `./run.sh "topic" --dbs all --resume-reports` | Iterates every DB subdirectory under `results/{topic}/`. |
| `./run.sh --list-dbs` | Discovery, exit 0. |
| `./run.sh --show-db foo` | Discovery, exit 0. |

**Output-layout note (breaking change for downstream scripts):** all DB-backed runs — including single-DB `--db-config` — now use the nested layout (`results/{topic}/{db_id}/protocols/…`). Previous single-DB runs wrote protocols to a flat `results/{topic}/protocols/`. CLI flags remain backward-compatible, but any downstream tooling that reads protocol files from the flat path must update to the nested path. Public-datasets-only runs (no `--dbs`, no `--db-config`) keep the flat layout.
