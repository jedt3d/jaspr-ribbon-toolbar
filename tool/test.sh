#!/usr/bin/env bash
# Runs `dart test` in every workspace member that has a test/ directory.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Members are declared in the root pubspec.yaml `workspace:` block.
members="$(awk '/^workspace:/{flag=1;next} /^[a-z]/{flag=0} flag{gsub(/^[[:space:]]*- /,"");print}' pubspec.yaml)"

status=0
ran=0
for m in $members; do
  if [ -d "$m/test" ]; then
    echo "── dart test: $m ──────────────────────────────────────────"
    (cd "$m" && dart test) || status=1
    ran=$((ran + 1))
  fi
done

if [ "$ran" -eq 0 ]; then
  echo "No packages with tests found." >&2
fi

exit $status
