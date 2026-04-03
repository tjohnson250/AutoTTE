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
#   ./run.sh "type 2 diabetes" 75        # custom max turns for sub-agents
#
# Prerequisites:
#   - Claude Code CLI installed (npm install -g @anthropic-ai/claude-code)
#   - Python 3.11+ with: pip install mcp httpx lxml
#   - ANTHROPIC_API_KEY set in environment
# =============================================================================

set -euo pipefail

THERAPEUTIC_AREA="${1:?Usage: ./run.sh \"therapeutic area\" [max_turns_per_sub_agent]}"
MAX_TURNS="${2:-50}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

RESULTS_DIR="results/$(echo "$THERAPEUTIC_AREA" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')"
mkdir -p "$RESULTS_DIR/protocols"

echo "============================================="
echo " Auto-Protocol Designer"
echo " Therapeutic area: $THERAPEUTIC_AREA"
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
  2>&1 | python3 tools/stream_viewer.py
You are the coordinator agent for the Auto-Protocol Designer.

Read COORDINATOR.md now for your full instructions.

Your configuration:
- Therapeutic area: "$THERAPEUTIC_AREA"
- Results directory: $RESULTS_DIR
- Max turns per sub-agent: $MAX_TURNS (pass this as --max-turns to sub-agents)

Begin by reading COORDINATOR.md, then initialize your state files and launch
the first sub-agent (literature discovery).

When launching sub-agents, always use this pattern:
cat <<'SUBPROMPT' | claude -p --verbose --max-turns $MAX_TURNS \\
  --allowedTools "mcp__pubmed__search_pubmed,mcp__pubmed__fetch_abstracts,mcp__pubmed__query_dataset_registry,mcp__pubmed__get_dataset_details,Bash,Read,Write,Edit,WebSearch,WebFetch"
[prompt for sub-agent]
SUBPROMPT

Note: The sub-agents have access to PubMed MCP tools. You (the coordinator)
do not need those tools — you work through sub-agents.
PROMPT
