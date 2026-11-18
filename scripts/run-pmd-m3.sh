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

python3 - <<'PY'
from pathlib import Path
p = Path("src/main/java/mn/edu/must/sqat/DataFlowTargets.java")
s = p.read_text(encoding="utf-8")
old = "        int score = 0;"
assert s.count(old) == 1
p.write_text(s.replace(old, "        int total = present + best;\n" + old, 1), encoding="utf-8")
PY

printf 'M3 source mutation: add unread local total = present + best\nRule: PMD UnusedLocalVariable\nCommand: mvn -B pmd:pmd\n\n' | tee "$RESULTS/pmd-M3.txt"
mvn -B pmd:pmd 2>&1 | tee -a "$RESULTS/pmd-M3.txt"

# Preserve the generated report beside the Maven log, regardless of the renderer's filename.
mapfile -t REPORTS < <(find target -type f \( -name 'pmd.txt' -o -name 'pmd.xml' -o -name 'pmd.html' \) -print | sort)
if [[ ${#REPORTS[@]} -eq 0 ]]; then
  echo "PMD did not create a report file." | tee -a "$RESULTS/pmd-M3.txt"
  exit 1
fi
for report in "${REPORTS[@]}"; do
  printf '\n===== %s =====\n' "$report" | tee -a "$RESULTS/pmd-M3.txt"
  cat "$report" | tee -a "$RESULTS/pmd-M3.txt"
done

if ! grep -Eiq 'UnusedLocalVariable|total.*unused|unused.*total' "$RESULTS/pmd-M3.txt"; then
  echo "PMD report did not show the expected unread total local variable." >&2
  exit 1
fi

restore_source
trap - EXIT