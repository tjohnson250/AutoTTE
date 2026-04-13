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
# Parse DB config if provided
# ---------------------------------------------------------------------------
DB_ID=""
DB_NAME=""
DB_CDM=""
DB_ENGINE=""
DB_SCHEMA_PREFIX=""
DB_ONLINE="false"

if [[ -n "$DB_CONFIG" ]]; then
  if [[ ! -f "$DB_CONFIG" ]]; then
    echo "ERROR: DB config file not found: $DB_CONFIG" >&2
    exit 1
  fi

  # Parse YAML using Python (pyyaml is a dependency)
  eval "$(python3 -c "
import yaml, sys
with open('$DB_CONFIG') as f:
    c = yaml.safe_load(f)
print(f'DB_ID={c.get(\"id\", \"\")}')
print(f'DB_NAME=\"{c.get(\"name\", \"\")}\"')
print(f'DB_CDM={c.get(\"cdm\", \"\")}')
print(f'DB_ENGINE={c.get(\"engine\", \"\")}')
print(f'DB_SCHEMA_PREFIX=\"{c.get(\"schema_prefix\", \"\")}\"')
print(f'DB_ONLINE={str(c.get(\"online\", False)).lower()}')
")"

  # Apply mode override
  if [[ -n "$DB_MODE" ]]; then
    if [[ "$DB_MODE" == "offline" ]]; then
      DB_ONLINE="false"
    elif [[ "$DB_MODE" == "online" ]]; then
      DB_ONLINE="true"
    fi
  fi
fi

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
if [[ -n "$DB_CONFIG" ]]; then
echo " Database:         $DB_NAME ($DB_ID)"
echo " CDM:              $DB_CDM"
echo " Engine:           $DB_ENGINE"
echo " Mode:             $([ "$DB_ONLINE" = "true" ] && echo "ONLINE" || echo "OFFLINE")"
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
# Build MCP session config for online mode
# ---------------------------------------------------------------------------
MCP_CONFIG_FLAG=""
cleanup_session_config() {
  rm -f "$SCRIPT_DIR/.mcp-session.json"
}

if [[ "$DB_ONLINE" == "true" && -n "$DB_CONFIG" ]]; then
  # Generate session-specific MCP config with r_executor
  python3 -c "
import json
with open('.mcp.json') as f:
    config = json.load(f)
config['mcpServers']['r_executor'] = {
    'command': 'python',
    'args': ['tools/r_executor_server.py', '--config', '$DB_CONFIG'],
    'env': {}
}
with open('.mcp-session.json', 'w') as f:
    json.dump(config, f, indent=2)
"
  MCP_CONFIG=".mcp-session.json"
  trap cleanup_session_config EXIT
  echo "Generated .mcp-session.json with r_executor for online mode."
  echo ""
else
  MCP_CONFIG=".mcp.json"
fi

# ---------------------------------------------------------------------------
# Build tool allowlists
# ---------------------------------------------------------------------------
BASE_TOOLS="mcp__pubmed__search_pubmed,mcp__pubmed__fetch_abstracts"
DATASOURCE_TOOLS="mcp__datasource__list_datasources,mcp__datasource__get_datasource_details,mcp__datasource__get_schema,mcp__datasource__get_profile,mcp__datasource__get_conventions"
CODE_TOOLS="mcp__rxnorm__search_drug,mcp__rxnorm__get_all_related,mcp__rxnorm__get_rxcuis_for_drug,mcp__rxnorm__validate_rxcui_list,mcp__rxnorm__get_drug_class_members,mcp__rxnorm__lookup_rxcui,mcp__clinical_codes__search_loinc,mcp__clinical_codes__get_loinc_details,mcp__clinical_codes__find_related_loincs,mcp__clinical_codes__search_icd10,mcp__clinical_codes__get_icd10_hierarchy,mcp__clinical_codes__search_hcpcs,mcp__clinical_codes__lookup_hcpcs"
FILE_TOOLS="Bash,Read,Write,Edit,WebSearch,WebFetch"

R_EXECUTOR_TOOLS=""
if [[ "$DB_ONLINE" == "true" ]]; then
  R_EXECUTOR_TOOLS=",mcp__r_executor__execute_r,mcp__r_executor__query_db,mcp__r_executor__list_tables,mcp__r_executor__describe_table,mcp__r_executor__dump_schema,mcp__r_executor__run_profiler"
fi

WORKER_TOOLS="${BASE_TOOLS},${DATASOURCE_TOOLS},${CODE_TOOLS},${FILE_TOOLS}${R_EXECUTOR_TOOLS}"
REVIEWER_TOOLS="${BASE_TOOLS},${DATASOURCE_TOOLS},${CODE_TOOLS},${FILE_TOOLS}${R_EXECUTOR_TOOLS}"
REPORT_WRITER_TOOLS="Read,Write,Edit"
COORDINATOR_TOOLS="Bash,Read,Write,Edit"

# ---------------------------------------------------------------------------
# Build coordinator prompt
# ---------------------------------------------------------------------------
DB_CONTEXT=""
if [[ -n "$DB_CONFIG" ]]; then
  DB_CONTEXT="
Database configuration:
- Config file: $DB_CONFIG
- Database ID: $DB_ID
- Database name: $DB_NAME
- CDM type: $DB_CDM
- Engine: $DB_ENGINE
- Schema prefix: $DB_SCHEMA_PREFIX
- Mode: $([ "$DB_ONLINE" = "true" ] && echo "ONLINE (agents can query the database)" || echo "OFFLINE (agents work from schema dump and data profile)")

When launching sub-agents for this database:
- Tell workers the database ID ('$DB_ID'), CDM type, engine, and schema prefix.
- Tell workers to call get_schema('$DB_ID'), get_profile('$DB_ID'), and
  get_conventions('$DB_ID') from the datasource MCP server to get database
  details. Do NOT reference hardcoded file paths.
- Tell workers to read and apply ALL database conventions before writing any
  SQL or R code. Conventions are hard requirements, not suggestions.
$([ "$DB_ONLINE" = "true" ] && echo "- Tell workers they have online access and can use execute_r() and query_db()
  to validate their work against the live database.
- During Phase 0 (Data Source Onboarding), check if schema dump and data profile
  exist. If not, use dump_schema() and run_profiler() to generate them." || echo "- Workers do NOT have online database access. They must work from the schema
  dump and data profile files.")"
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
