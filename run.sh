#!/usr/bin/env bash
# =============================================================================
# Auto-Protocol Designer — Launch Script
# =============================================================================
# Launches the coordinator agent, which autonomously orchestrates sub-agents
# through iterative review loops. No hardcoded state machine — the coordinator
# decides when to advance, revise, or backtrack.
#
# Usage:
#   ./run.sh "atrial fibrillation"
#   ./run.sh "atrial fibrillation" --cdw        # target PCORnet CDW
#   ./run.sh "atrial fibrillation" --both       # target public data + CDW
#   ./run.sh "type 2 diabetes" --cdw 75         # custom max turns
#
#   # With a custom DB connection string:
#   ./run.sh "atrial fibrillation" --cdw \
#     --db-connect 'con <- DBI::dbConnect(odbc::odbc(), "SQLODBCD17CDM")'
#
# Prerequisites:
#   - Claude Code CLI installed (npm install -g @anthropic-ai/claude-code)
#   - Python 3.11+ with: pip install mcp httpx lxml
#   - ANTHROPIC_API_KEY set in environment
# =============================================================================

set -euo pipefail

THERAPEUTIC_AREA="${1:?Usage: ./run.sh \"therapeutic area\" [--cdw|--both] [--db-connect 'R code'] [max_turns]}"

# Parse optional flags
TARGET="public"
MAX_TURNS="50"
DB_CONNECT=""
SKIP_NEXT=false
for i in $(seq 2 $#); do
  if $SKIP_NEXT; then
    SKIP_NEXT=false
    continue
  fi
  arg="${!i}"
  case "$arg" in
    --cdw)  TARGET="cdw" ;;
    --both) TARGET="both" ;;
    --db-connect)
      next_i=$((i + 1))
      DB_CONNECT="${!next_i}"
      SKIP_NEXT=true
      ;;
    *)
      if [[ "$arg" =~ ^[0-9]+$ ]]; then
        MAX_TURNS="$arg"
      fi
      ;;
  esac
done

# Default DB connection if --cdw or --both but no --db-connect provided
if [[ ("$TARGET" == "cdw" || "$TARGET" == "both") && -z "$DB_CONNECT" ]]; then
  DB_CONNECT='con <- DBI::dbConnect(odbc::odbc(), Driver = "ODBC Driver 17 for SQL Server", Server = "YOUR_SERVER", Database = "CDW", Trusted_Connection = "yes")'
  echo "⚠  No --db-connect provided. Using placeholder. Pass your connection code:"
  echo "   ./run.sh \"$THERAPEUTIC_AREA\" --cdw --db-connect 'con <- DBI::dbConnect(...)'"
  echo ""
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

RESULTS_DIR="results/$(echo "$THERAPEUTIC_AREA" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')"
mkdir -p "$RESULTS_DIR/protocols"

echo "============================================="
echo " Auto-Protocol Designer"
echo " Therapeutic area: $THERAPEUTIC_AREA"
echo " Protocol target:  $TARGET"
if [[ -n "$DB_CONNECT" ]]; then
echo " DB connection:    $DB_CONNECT"
fi
echo " Max turns/sub-agent: $MAX_TURNS"
echo " Results: $RESULTS_DIR/"
echo "============================================="
echo ""

# Build the DB connection context block for the coordinator prompt
DB_CONTEXT=""
if [[ -n "$DB_CONNECT" ]]; then
  DB_CONTEXT="
Database connection: Workers generating CDW protocols MUST use this exact
R code to connect to the database (do NOT use the placeholder in the template):

  $DB_CONNECT

Pass this connection code verbatim to any worker generating CDW R scripts.
The worker should replace the connect_cdw() function body in their R output
with this exact line."
fi

# The coordinator is a long-running Claude Code session.
# It reads COORDINATOR.md for its instructions and launches sub-agents
# by calling claude -p in bash. It has full autonomy over the workflow.

cat <<PROMPT | claude -p \
  --verbose \
  --max-turns 200 \
  --output-format stream-json \
  --allowedTools "Bash,Read,Write,Edit" \
  2>&1 | python3 tools/stream_viewer.py --label "Coordinator"
You are the coordinator agent for the Auto-Protocol Designer.

Read COORDINATOR.md now for your full instructions.

Your configuration:
- Therapeutic area: "$THERAPEUTIC_AREA"
- Protocol target: $TARGET
- Results directory: $RESULTS_DIR
- Max turns per sub-agent: $MAX_TURNS (pass this as --max-turns to sub-agents)
$DB_CONTEXT

Protocol target "$TARGET" means:
- "public": generate protocols targeting public datasets (MIMIC-IV, NHANES, etc.)
- "cdw": generate protocols targeting the PCORnet CDW (MS SQL Server). Workers
  must read CDW_DBO_database_schema.txt and write T-SQL in their R scripts.
  Use analysis_plan_template_cdw.R as the structural reference.
- "both": generate protocols for both public data and the CDW where feasible.

Begin by reading COORDINATOR.md, then initialize your state files and launch
the first sub-agent (literature discovery).

When launching sub-agents, always pipe through stream_viewer.py with a label:
cat <<'SUBPROMPT' | claude -p --verbose --max-turns \$MAX_TURNS \\
  --output-format stream-json \\
  --allowedTools "mcp__pubmed__search_pubmed,mcp__pubmed__fetch_abstracts,mcp__pubmed__query_dataset_registry,mcp__pubmed__get_dataset_details,mcp__rxnorm__search_drug,mcp__rxnorm__get_all_related,mcp__rxnorm__get_rxcuis_for_drug,mcp__rxnorm__validate_rxcui_list,mcp__rxnorm__get_drug_class_members,mcp__rxnorm__lookup_rxcui,mcp__clinical_codes__search_loinc,mcp__clinical_codes__get_loinc_details,mcp__clinical_codes__find_related_loincs,mcp__clinical_codes__search_icd10,mcp__clinical_codes__get_icd10_hierarchy,mcp__clinical_codes__search_hcpcs,mcp__clinical_codes__lookup_hcpcs,Bash,Read,Write,Edit,WebSearch,WebFetch" \\
  2>&1 | python3 tools/stream_viewer.py --label "Worker"
[prompt for sub-agent]
SUBPROMPT

Use --label "Worker" for work agents, --label "Reviewer" for review agents.

Note: The sub-agents have access to PubMed MCP tools. You (the coordinator)
do not need those tools — you work through sub-agents.
PROMPT
