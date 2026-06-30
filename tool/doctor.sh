#!/usr/bin/env bash
# Prints the toolchain + project environment, like `jaspr doctor`.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "═══ Toolchain ═══"
command -v dart && dart --version
echo
command -v jaspr >/dev/null 2>&1 && jaspr doctor 2>/dev/null || echo "jaspr CLI: not installed (only needed for serve/build)"
echo
echo "═══ Workspace members ═══"
awk '/^workspace:/{flag=1;next} /^[a-z]/{flag=0} flag{gsub(/^[[:space:]]*- /,"");print}' pubspec.yaml
echo
echo "═══ pub get status ═══"
dart pub deps --no-dev 2>/dev/null | head -1 || echo "run 'make pub-get' first"
