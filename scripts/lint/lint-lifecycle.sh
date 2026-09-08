#!/usr/bin/env bash
set -euo pipefail

# Validate lifecycle authority, migration coverage, and executable behavior.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
python3 "$REPO_ROOT/scripts/lint/validate-lifecycle.py"
"$REPO_ROOT/tests/lifecycle.sh"
if rg -n '^[[:space:]]*(cd .*&& )?git([^[:space:]]*[[:space:]]+)*pull([[:space:]]|$)' "$REPO_ROOT/src/skills/spade-update"; then
    echo "lint-lifecycle: unbounded git pull is forbidden" >&2
    exit 1
fi
echo "lint-lifecycle: passed"
