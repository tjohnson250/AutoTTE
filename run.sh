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
# Prerequisites:
#   - Claude Code CLI installed (npm install -g @anthropic-ai/claude-code)
#   - Python 3.11+ with: pip install mcp httpx lxml
#   - ANTHROPIC_API_KEY set in environment
# =============================================================================

set -euo pipefail

THERAPEUTIC_AREA="${1:?Usage: ./run.sh \"therapeutic area\" [--cdw|--both] [max_turns]}"

# Parse optional flags
TARGET="public"
MAX_TURNS="50"
for arg in "${@:2}"; do
  case "$arg" in
    --cdw)  TARGET="cdw" ;;
    --both) TARGET="both" ;;
    *)      MAX_TURNS="$arg" ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

RESULTS_DIR="results/$(echo "$THERAPEUTIC_AREA" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')"
mkdir -p "$RESULTS_DIR/protocols"

echo "============================================="
echo " Auto-Protocol Designer"
echo " Therapeutic area: $THERAPEUTIC_AREA"
echo " Protocol target:  $TARGET"
echo " Max turns/sub-agent: $MAX_TURNS"
echo " Results: $RESULTS_DIR/"
echo "============================================="
echo ""

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

Protocol target "$TARGET" means:
- "public": generate protocols targeting public datasets (MIMIC-IV, NHANES, etc.)
- "cdw": generate protocols targeting the PCORnet CDW (MS SQL Server). Workers
  must read CDW_DBO_database_schema.txt and write T-SQL in their R scripts.
  Use analysis_plan_template_cdw.R as the structural reference.
- "both": generate protocols for both public data and the CDW where feasible.

Begin by reading COORDINATOR.md, then initialize your state files and launch
the first sub-agent (literature discovery).

When launching sub-agents, always pipe through stream_viewer.py with a label:
cat <<'SUBPROMPT' | claude -p --verbose --max-turns $MAX_TURNS \\
  --output-format stream-json \\
  --allowedTools "mcp__pubmed__search_pubmed,mcp__pubmed__fetch_abstracts,mcp__pubmed__query_dataset_registry,mcp__pubmed__get_dataset_details,Bash,Read,Write,Edit,WebSearch,WebFetch" \\
  2>&1 | python3 tools/stream_viewer.py --label "Worker"
[prompt for sub-agent]
SUBPROMPT

Use --label "Worker" for work agents, --label "Reviewer" for review agents.

Note: The sub-agents have access to PubMed MCP tools. You (the coordinator)
do not need those tools — you work through sub-agents.
PROMPT
