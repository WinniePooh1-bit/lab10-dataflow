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

run_expected_failure() {
  local log="$1"
  set +e
  mvn -B test 2>&1 | tee "$log"
  local code=${PIPESTATUS[0]}
  set -e
  printf '\nMaven exit code: %s\n' "$code" | tee -a "$log"
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
run_expected_failure "$RESULTS/mvn-test-M1.txt"

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
run_expected_failure "$RESULTS/mvn-test-M2.txt"

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
run_expected_failure "$RESULTS/mvn-test-M3.txt"

restore_source
trap - EXIT