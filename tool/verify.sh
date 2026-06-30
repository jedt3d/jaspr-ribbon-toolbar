#!/usr/bin/env bash
# The CI gate: format check + analyze + test. Exits non-zero on the first failure.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "╔══ 1/3  dart format (check) ═══════════════════════════════╗"
dart format --output=none --set-exit-if-changed packages

echo "╔══ 2/3  dart analyze --fatal-infos ════════════════════════╗"
dart analyze packages --fatal-infos

echo "╔══ 3/3  dart test (all members) ══════════════════════════╗"
bash tool/test.sh

echo "╔══ verify: ALL GREEN ═════════════════════════════════════╗"
