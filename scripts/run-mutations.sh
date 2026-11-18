#!/usr/bin/env bash
set -euo pipefail

SOURCE="src/main/java/mn/edu/must/sqat/DataFlowTargets.java"
RESULTS="results"
mkdir -p "$RESULTS"
BACKUP="$(mktemp)"
cp "$SOURCE" "$BACKUP"
restore_source() {
  cp "$BACKUP" "$SOURCE"
  rm -f "$BACKUP"
}
trap restore_source EXIT

run_mutation() {
  local log="$1"
  local expected="$2"
  local description="$3"
  printf 'Mutation: %s\nCommand: mvn -B test\n\n' "$description" | tee "$log"
  set +e
  mvn -B test 2>&1 | tee -a "$log"
  local code=${PIPESTATUS[0]}
  set -e
  printf '\nMaven exit code: %s\n' "$code" | tee -a "$log"
  if [[ "$expected" == "fail" && "$code" -eq 0 ]]; then
    echo "Expected this mutation to be killed, but Maven test passed: $description" >&2
    return 1
  fi
  if [[ "$expected" == "pass" && "$code" -ne 0 ]]; then
    echo "Expected this mutation to survive, but Maven test failed: $description" >&2
    return 1
  fi
}

# M1: Missing update — remove the streak increment.
cp "$BACKUP" "$SOURCE"
python3 - <<'PY'
from pathlib import Path
p = Path("src/main/java/mn/edu/must/sqat/DataFlowTargets.java")
s = p.read_text(encoding="utf-8")
old = "                streak = streak + 1;"
assert s.count(old) == 1
p.write_text(s.replace(old, "                // M1: streak update intentionally removed", 1), encoding="utf-8")
PY
run_mutation "$RESULTS/mvn-test-M1.txt" fail "M1: remove streak = streak + 1 (missing update)"

# M2: Wrong variable — use present rather than the current streak.
cp "$BACKUP" "$SOURCE"
python3 - <<'PY'
from pathlib import Path
p = Path("src/main/java/mn/edu/must/sqat/DataFlowTargets.java")
s = p.read_text(encoding="utf-8")
old = "                    best = streak;"
assert s.count(old) == 1
p.write_text(s.replace(old, "                    best = present;", 1), encoding="utf-8")
PY
run_mutation "$RESULTS/mvn-test-M2.txt" pass "M2: replace best = streak with best = present (wrong variable)"

# M3: Dead definition — add an unread local variable after the loop.
cp "$BACKUP" "$SOURCE"
python3 - <<'PY'
from pathlib import Path
p = Path("src/main/java/mn/edu/must/sqat/DataFlowTargets.java")
s = p.read_text(encoding="utf-8")
old = "        int score = 0;"
assert s.count(old) == 1
p.write_text(s.replace(old, "        int total = present + best;\n" + old, 1), encoding="utf-8")
PY
run_mutation "$RESULTS/mvn-test-M3.txt" pass "M3: add unread local total = present + best (dead definition)"

restore_source
trap - EXIT