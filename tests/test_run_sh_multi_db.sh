#!/usr/bin/env bash
# Shell tests for run.sh multi-DB CLI. We short-circuit before the
# actual `claude -p` invocation by intercepting via AUTOTTE_DRY_RUN=1
# (run.sh must honor this env var to exit after printing the resolved
# plan). No Claude API calls happen in these tests.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$SCRIPT_DIR"

PASS=0
FAIL=0

assert_contains() {
  local needle="$1" haystack="$2" desc="$3"
  if printf "%s" "$haystack" | grep -qF -- "$needle"; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc — expected to find: $needle"
    echo "         actual output:"
    printf "%s" "$haystack" | sed 's/^/           /'
    FAIL=$((FAIL + 1))
  fi
}

assert_exit_code() {
  local expected="$1" actual="$2" desc="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "  PASS: $desc (exit $actual)"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc — expected exit $expected, got $actual"
    FAIL=$((FAIL + 1))
  fi
}

echo "Test 1: --list-dbs prints a table and exits 0"
OUT=$(./run.sh --list-dbs 2>&1); RC=$?
assert_exit_code 0 "$RC" "exit 0"
assert_contains "ID" "$OUT" "contains header"
assert_contains "nhanes" "$OUT" "mentions nhanes"

echo "Test 2: --show-db <id> prints one DB"
OUT=$(./run.sh --show-db nhanes 2>&1); RC=$?
assert_exit_code 0 "$RC" "exit 0"
assert_contains "nhanes" "$OUT" "mentions nhanes"
assert_contains "Default:" "$OUT" "shows default mode"

echo "Test 3: --show-db with unknown id exits non-zero"
OUT=$(./run.sh --show-db no_such_db 2>&1); RC=$?
[[ "$RC" != "0" ]] && { echo "  PASS: unknown id exits non-zero"; PASS=$((PASS + 1)); } \
  || { echo "  FAIL: unknown id should exit non-zero"; FAIL=$((FAIL + 1)); }

echo "Test 4: --dbs + --db-config together is an error"
OUT=$(./run.sh "topic" --dbs nhanes --db-config databases/nhanes.yaml 2>&1); RC=$?
[[ "$RC" != "0" ]] && { echo "  PASS: rejected"; PASS=$((PASS + 1)); } \
  || { echo "  FAIL: should have errored"; FAIL=$((FAIL + 1)); }
assert_contains "cannot combine" "$OUT" "error message explains the conflict"

echo "Test 5: --dbs with unknown id exits non-zero"
OUT=$(AUTOTTE_DRY_RUN=1 ./run.sh "topic" --dbs no_such_db 2>&1); RC=$?
[[ "$RC" != "0" ]] && { echo "  PASS: rejected"; PASS=$((PASS + 1)); } \
  || { echo "  FAIL: should have errored"; FAIL=$((FAIL + 1)); }

echo "Test 6: --dbs all with AUTOTTE_DRY_RUN=1 exits 0 and prints triage"
OUT=$(AUTOTTE_DRY_RUN=1 ./run.sh "topic" --dbs all 2>&1); RC=$?
assert_exit_code 0 "$RC" "dry-run exits 0"
assert_contains "triage" "$OUT" "mentions triage or db_triage"

echo "Test 7: --db-config legacy path resolves to nested layout"
OUT=$(AUTOTTE_DRY_RUN=1 ./run.sh "topic" --db-config databases/nhanes.yaml 2>&1); RC=$?
assert_exit_code 0 "$RC" "exit 0"
assert_contains "nhanes" "$OUT" "nhanes selected"

echo "Test 8: public-datasets mode still works"
OUT=$(AUTOTTE_DRY_RUN=1 ./run.sh "topic" 2>&1); RC=$?
assert_exit_code 0 "$RC" "exit 0"
assert_contains "Public datasets" "$OUT" "banner mentions public datasets"

echo "Test 9: --dbs multi with online DBs writes multi-config r_executor to .mcp-session.json"
OUT=$(AUTOTTE_DRY_RUN=2 ./run.sh "topic" --dbs nhanes,synthetic_pcornet --db-mode online 2>&1); RC=$?
assert_exit_code 0 "$RC" "exit 0"
if [[ -f ".mcp-session.json" ]]; then
  SESSION_CONFIGS=$(python3 -c "
import json
with open('.mcp-session.json') as f:
    c = json.load(f)
args = c['mcpServers']['r_executor']['args']
count = sum(1 for a in args if a == '--config')
print(count)
")
  assert_contains "2" "$SESSION_CONFIGS" "two --config args in .mcp-session.json"
  rm -f .mcp-session.json
else
  echo "  FAIL: .mcp-session.json not created"; FAIL=$((FAIL + 1))
fi

echo "Test 10: --dbs offline-only does NOT create .mcp-session.json"
rm -f .mcp-session.json
OUT=$(AUTOTTE_DRY_RUN=2 ./run.sh "topic" --dbs secure_pcornet_cdw 2>&1); RC=$?
if [[ ! -f ".mcp-session.json" ]]; then
  echo "  PASS: no .mcp-session.json written for offline-only run"; PASS=$((PASS + 1))
else
  echo "  FAIL: .mcp-session.json should not exist when no DB is online"; FAIL=$((FAIL + 1))
  rm -f .mcp-session.json
fi

echo "Test 11: AUTOTTE_DRY_RUN=3 prints the coordinator prompt with multi-DB context"
rm -f .mcp-session.json
OUT=$(AUTOTTE_DRY_RUN=3 ./run.sh "topic" --dbs nhanes,synthetic_pcornet --db-mode online 2>&1); RC=$?
assert_exit_code 0 "$RC" "exit 0"
assert_contains "db_triage.json" "$OUT" "prompt references db_triage.json"
assert_contains "Multi-DB run" "$OUT" "prompt mentions Multi-DB run"
assert_contains "nhanes" "$OUT" "prompt lists nhanes"
assert_contains "synthetic_pcornet" "$OUT" "prompt lists synthetic_pcornet"
rm -f .mcp-session.json

echo "Test 12: AUTOTTE_DRY_RUN=3 for single DB still prints prompt"
OUT=$(AUTOTTE_DRY_RUN=3 ./run.sh "topic" --dbs nhanes 2>&1); RC=$?
assert_exit_code 0 "$RC" "exit 0"
assert_contains "Single-DB run" "$OUT" "prompt mentions Single-DB run"
assert_contains "nhanes" "$OUT" "prompt lists nhanes"
rm -f .mcp-session.json

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ "$FAIL" == "0" ]] && exit 0 || exit 1
