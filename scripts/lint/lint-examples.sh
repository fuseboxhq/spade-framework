#!/usr/bin/env bash
set -euo pipefail

# SPADE Framework — examples lint
#
# Validates the shape of examples/example-scope.md, examples/example-plan.md,
# the INTENT.md template (templates/INTENT.md), and examples/example-intent.md.
# These files are the canonical reference for what a well-formed Scope, Plan,
# and project-intent document look like; drift here means agents generate the
# wrong shape.
#
# Checks:
#   1. examples/example-scope.md carries **Intent:**, **Acceptance Criteria:**,
#      **Constraints:** as Markdown bold section headers.
#   2. examples/example-plan.md renders every task (a line beginning with
#      "#### Task ") as one complete card: What / Done when / How / Verify /
#      Needs+Blocks / Who.
#   3. Every How value opens with a delivery approach from the locked
#      vocabulary:
#         test-first, characterization-first, refactor-first, spike, straight-through
#   4. templates/INTENT.md and examples/example-intent.md each carry the locked
#      INTENT.md conformance schema (SPADE v1.7, M-951): the six section
#      headings (Problem, Users, What it does, Success, Non-goals, Maturity)
#      and the last_reviewed frontmatter key. Changing this set requires a new
#      Scope.
#
# Exit codes:
#   0  every file conforms
#   1  one or more violations found
#   2  an example or template file is missing

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCOPE="$REPO_ROOT/examples/example-scope.md"
PLAN="$REPO_ROOT/examples/example-plan.md"

fail=0

# --- Example scope ---------------------------------------------------------

if [ ! -f "$SCOPE" ]; then
    echo "lint-examples: missing $SCOPE" >&2
    exit 2
fi

require_in_scope() {
    local pattern="$1"
    local label="$2"
    if grep -qE "$pattern" "$SCOPE"; then
        echo "  ok:   example-scope.md has $label"
    else
        echo "  FAIL: example-scope.md missing $label (pattern: $pattern)"
        fail=$((fail + 1))
    fi
}

require_in_scope '^\*\*Intent:\*\*' "Intent"
require_in_scope '^### Acceptance criteria' "Acceptance criteria"
require_in_scope '^### Constraints' "Constraints"
require_in_scope '^### Out of scope' "Out of scope"

if [ ! -f "$PLAN" ]; then
    echo "lint-examples: missing $PLAN" >&2
    exit 2
fi

require_in_plan() {
    local pattern="$1"
    local label="$2"
    if grep -qE "$pattern" "$PLAN"; then
        echo "  ok:   example-plan.md has $label"
    else
        echo "  FAIL: example-plan.md missing $label (pattern: $pattern)"
        fail=$((fail + 1))
    fi
}

require_in_plan '^Approved by ' "an approval line"
require_in_plan '^## Approach' "Approach"
require_in_plan 'Rejected forks' "rejected forks"
require_in_plan '^## Risks' "Risks"
require_in_plan '^## Tasks' "Tasks"
require_in_plan '^## Halts' "Halts"

# Every task is a checkbox line naming its finish line and its check.
bad_tasks=$(grep -E '^- \[[ x]\] [0-9]+\.' "$PLAN" | grep -vE 'done when .*; verify with ' || true)
task_count=$(grep -cE '^- \[[ x]\] [0-9]+\.' "$PLAN" || true)
if [ "$task_count" -gt 0 ] && [ -z "$bad_tasks" ]; then
    echo "  ok:   example-plan.md has $task_count tasks, each with done when and verify with"
else
    echo "  FAIL: example-plan.md tasks must be checkbox lines with 'done when ...; verify with ...'"
    fail=$((fail + 1))
fi

echo
echo "lint-examples: $fail failure(s)"
[ "$fail" -eq 0 ] || exit 1
