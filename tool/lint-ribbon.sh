#!/usr/bin/env bash
# Validates one or more .ribbon JSON bundles via the jaspr_ribbon_lsp CLI.
# Usage: tool/lint-ribbon.sh path/to/a.ribbon [more.ribbon ...]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
LSP="packages/jaspr_ribbon_lsp"

if [ "$#" -eq 0 ]; then
  echo "Usage: $0 <file.ribbon> [more.ribbon ...]" >&2
  exit 64
fi

status=0
for f in "$@"; do
  echo "── validating $f ──"
  if (cd "$LSP" && dart run bin/jaspr_ribbon_lsp.dart --validate-stdin) < "$f"; then
    :
  else
    status=1
  fi
done
exit $status
