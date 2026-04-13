#!/usr/bin/env bash
# =============================================================================
# Auto-Protocol Designer — Launch Script
# =============================================================================
# Launches the coordinator agent, which autonomously orchestrates sub-agents
# through iterative review loops.
#
# Usage:
#   ./run.sh "atrial fibrillation"
#   ./run.sh "atrial fibrillation" --dbs nhanes,mimic_iv
#   ./run.sh "atrial fibrillation" --dbs all --db-mode offline
#   ./run.sh "atrial fibrillation" --db-config databases/my_cdw.yaml
#   ./run.sh "atrial fibrillation" --dbs all --resume-reports
#   ./run.sh --list-dbs
#   ./run.sh --show-db nhanes
#
# Prerequisites:
#   - Claude Code CLI installed (npm install -g @anthropic-ai/claude-code)
#   - Python 3.11+ with: pip install mcp httpx lxml pyyaml
#   - ANTHROPIC_API_KEY set in environment
#   - For online DB mode: R installed with DBI + engine-specific driver
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

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

RESULTS_DIR="results/$(echo "$THERAPEUTIC_AREA" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')"
mkdir -p "$RESULTS_DIR/protocols"

# ---------------------------------------------------------------------------
# Triage: resolve DB_IDS through tools.db_triage and capture disposition.
# ---------------------------------------------------------------------------

TRIAGE_JSON=""
if [[ -n "$DB_IDS" ]]; then

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

# Dry-run stage 1: stop after argument parsing.
if [[ "${AUTOTTE_DRY_RUN:-}" == "1" ]]; then
  echo "AUTOTTE_DRY_RUN — stopping after parse. DB_IDS='$DB_IDS' DB_CONFIG='$DB_CONFIG' MODE='$DB_MODE'"
  if [[ -z "$DB_IDS" && -z "$DB_CONFIG" ]]; then
    echo "Public datasets only."
  elif [[ -n "$TRIAGE_JSON" && -s "$TRIAGE_JSON" ]]; then
    echo "triage written to $TRIAGE_JSON"
  fi
  exit 0
fi

# ---------------------------------------------------------------------------
# Display banner
# ---------------------------------------------------------------------------
echo "============================================="
echo " Auto-Protocol Designer"
echo " Therapeutic area: $THERAPEUTIC_AREA"
if [[ -n "$TRIAGE_JSON" ]]; then
  echo " Databases:        (see triage above / $TRIAGE_JSON)"
else
  echo " Data sources:     Public datasets only"
fi
echo " Max turns/sub-agent: $MAX_TURNS"
echo " Results: $RESULTS_DIR/"
if [[ "$RESUME_REPORTS" == "true" ]]; then
echo " Mode:             RESUME REPORTS (skipping Phases 0-3)"
fi
echo "============================================="
echo ""

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
  if [[ "${AUTOTTE_DRY_RUN:-}" != "2" ]]; then
    trap cleanup_session_config EXIT
  fi
  echo "Generated .mcp-session.json with r_executor for $(echo "$ONLINE_YAML_PATHS" | wc -l | tr -d ' ') online DB(s)."
else
  MCP_CONFIG=".mcp.json"
fi

# Dry-run stage 2: stop after session config generation.
if [[ "${AUTOTTE_DRY_RUN:-}" == "2" ]]; then
  echo "AUTOTTE_DRY_RUN=2 — stopping after MCP session generation."
  exit 0
fi

# ---------------------------------------------------------------------------
# Build tool allowlists
# ---------------------------------------------------------------------------
BASE_TOOLS="mcp__pubmed__search_pubmed,mcp__pubmed__fetch_abstracts"
DATASOURCE_TOOLS="mcp__datasource__list_datasources,mcp__datasource__get_datasource_details,mcp__datasource__get_schema,mcp__datasource__get_profile,mcp__datasource__get_conventions"
CODE_TOOLS="mcp__rxnorm__search_drug,mcp__rxnorm__get_all_related,mcp__rxnorm__get_rxcuis_for_drug,mcp__rxnorm__validate_rxcui_list,mcp__rxnorm__get_drug_class_members,mcp__rxnorm__lookup_rxcui,mcp__clinical_codes__search_loinc,mcp__clinical_codes__get_loinc_details,mcp__clinical_codes__find_related_loincs,mcp__clinical_codes__search_icd10,mcp__clinical_codes__get_icd10_hierarchy,mcp__clinical_codes__search_hcpcs,mcp__clinical_codes__lookup_hcpcs"
FILE_TOOLS="Bash,Read,Write,Edit,WebSearch,WebFetch"

R_EXECUTOR_TOOLS=""
if [[ -n "$ONLINE_YAML_PATHS" ]]; then
  R_EXECUTOR_TOOLS=",mcp__r_executor__execute_r,mcp__r_executor__query_db,mcp__r_executor__list_tables,mcp__r_executor__describe_table,mcp__r_executor__dump_schema,mcp__r_executor__run_profiler"
fi

WORKER_TOOLS="${BASE_TOOLS},${DATASOURCE_TOOLS},${CODE_TOOLS},${FILE_TOOLS}${R_EXECUTOR_TOOLS}"
REVIEWER_TOOLS="${BASE_TOOLS},${DATASOURCE_TOOLS},${CODE_TOOLS},${FILE_TOOLS}${R_EXECUTOR_TOOLS}"
REPORT_WRITER_TOOLS="Read,Write,Edit"
COORDINATOR_TOOLS="Bash,Read,Write,Edit"

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

cat <<PROMPT | claude -p \
  --verbose \
  --max-turns 200 \
  --output-format stream-json \
  --mcp-config "$MCP_CONFIG" \
  --allowedTools "$COORDINATOR_TOOLS" \
  2>&1 | python3 tools/stream_viewer.py --label "Coordinator"
You are the coordinator agent for the Auto-Protocol Designer.

Read COORDINATOR.md now for your full instructions.

Your configuration:
- Therapeutic area: "$THERAPEUTIC_AREA"
- Results directory: $RESULTS_DIR
- Max turns per sub-agent: $MAX_TURNS (pass this as --max-turns to sub-agents)
- MCP config: $MCP_CONFIG (pass this as --mcp-config to sub-agents)
$DB_CONTEXT

When launching sub-agents, always pipe through stream_viewer.py with a label:
cat <<'SUBPROMPT' | claude -p --verbose --max-turns \$MAX_TURNS \\
  --output-format stream-json \\
  --mcp-config $MCP_CONFIG \\
  --allowedTools "$WORKER_TOOLS" \\
  2>&1 | python3 tools/stream_viewer.py --label "Worker"
[prompt for sub-agent]
SUBPROMPT

Use --label "Worker" for work agents, --label "Reviewer" for review agents.
Use --allowedTools "$REVIEWER_TOOLS" for reviewers.
For report-writing workers, use --allowedTools "Read,Write,Edit" (they don't need MCP tools).

Note: Sub-agents have access to PubMed, datasource registry, RxNorm, clinical
codes, and ICD-10 MCP tools. You (the coordinator) do not need those tools —
you work through sub-agents.

Begin by reading COORDINATOR.md, then initialize your state files and start
the pipeline.
$([ "$RESUME_REPORTS" = "true" ] && echo "
RESUME MODE: REPORTS ONLY
Skip Phases 0-3. The protocols and analysis scripts already exist.
Check for protocol_NN_results.json files in \$RESULTS_DIR/protocols/.
For each results file found, launch a report-writing worker (read REPORT_WRITER.md).
For each protocol WITHOUT a results file, log a warning and skip it.
Then produce the executive summary.
")
PROMPT
