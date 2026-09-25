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
#   1. examples/example-scope.md has **Intent:** and the Acceptance criteria,
#      Constraints, and Out of scope headings /spade-scope writes.
#   2. examples/example-plan.md has an approval line, Approach with rejected
#      forks, Risks, Tasks, and Halts, and every task is a checkbox line that
#      says "done when" and "verify with" (docs/FRAMEWORK.md § Plan).
#   3. templates/INTENT.md and examples/example-intent.md carry the INTENT.md
#      schema: last_reviewed plus Problem, Users, What it does, Success,
#      Non-goals, and Maturity.
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

# --- INTENT.md template + example ------------------------------------------
#
# The six section headings + the last_reviewed frontmatter key are the locked
# INTENT.md conformance schema (SPADE v1.7, M-951). Both the distributable
# template and the worked example must carry every element. Changing this set
# requires a new Scope.

INTENT_TEMPLATE="$REPO_ROOT/templates/INTENT.md"
INTENT_EXAMPLE="$REPO_ROOT/examples/example-intent.md"

intent_require() {
    local file="$1"
    local label="$2"
    local pattern="$3"
    local desc="$4"
    if grep -qE "$pattern" "$file"; then
        echo "  ok:   $label has $desc"
    else
        echo "  FAIL: $label missing $desc (pattern: $pattern)"
        fail=$((fail + 1))
    fi
}

for intent_pair in "INTENT template:$INTENT_TEMPLATE" "INTENT example:$INTENT_EXAMPLE"; do
    intent_label="${intent_pair%%:*}"
    intent_file="${intent_pair#*:}"

    if [ ! -f "$intent_file" ]; then
        echo "lint-examples: missing $intent_file" >&2
        exit 2
    fi

    intent_require "$intent_file" "$intent_label" '^last_reviewed:' 'last_reviewed frontmatter key'
    intent_require "$intent_file" "$intent_label" '^## Problem[[:space:]]*$' 'Problem section'
    intent_require "$intent_file" "$intent_label" '^## Users[[:space:]]*$' 'Users section'
    intent_require "$intent_file" "$intent_label" '^## What it does[[:space:]]*$' 'What it does section'
    intent_require "$intent_file" "$intent_label" '^## Success[[:space:]]*$' 'Success section'
    intent_require "$intent_file" "$intent_label" '^## Non-goals[[:space:]]*$' 'Non-goals section'
    intent_require "$intent_file" "$intent_label" '^## Maturity[[:space:]]*$' 'Maturity section'
done

echo
echo "lint-examples: $fail failure(s)"
[ "$fail" -eq 0 ] || exit 1
