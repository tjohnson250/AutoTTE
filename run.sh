#!/usr/bin/env bash
# =============================================================================
# Auto-Protocol Designer — Launch Script
# =============================================================================
# Launches the state machine controller that orchestrates independent
# Claude Code agents through iterative review loops.
#
# Usage:
#   ./run.sh "atrial fibrillation"
#   ./run.sh "type 2 diabetes" 50        # custom max turns per agent pass
#   ./run.sh "atrial fibrillation" --resume  # resume from saved state
#
# Prerequisites:
#   - Claude Code CLI installed (npm install -g @anthropic-ai/claude-code)
#   - Python 3.11+ with: pip install mcp httpx lxml
#   - ANTHROPIC_API_KEY set in environment
# =============================================================================

set -euo pipefail

THERAPEUTIC_AREA="${1:?Usage: ./run.sh \"therapeutic area\" [max_turns_per_pass] [--resume]}"

# Check for --resume flag in any position
RESUME=""
MAX_TURNS="50"
for arg in "${@:2}"; do
  if [[ "$arg" == "--resume" ]]; then
    RESUME="--resume"
  elif [[ "$arg" =~ ^[0-9]+$ ]]; then
    MAX_TURNS="$arg"
  fi
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "============================================="
echo " Auto-Protocol Designer"
echo " Therapeutic area: $THERAPEUTIC_AREA"
echo " Max turns/pass:   $MAX_TURNS"
echo " Mode:             ${RESUME:-new run}"
echo "============================================="
echo ""

python3 tools/controller.py \
  --area "$THERAPEUTIC_AREA" \
  --max-turns "$MAX_TURNS" \
  $RESUME
