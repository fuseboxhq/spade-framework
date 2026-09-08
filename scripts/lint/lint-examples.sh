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

require_in_scope '\*\*Intent:\*\*' "Intent section"
require_in_scope '\*\*Acceptance Criteria:\*\*' "Acceptance Criteria section"
require_in_scope '\*\*Constraints:\*\*' "Constraints section"

# --- Example plan ----------------------------------------------------------

if [ ! -f "$PLAN" ]; then
    echo "lint-examples: missing $PLAN" >&2
    exit 2
fi

# Every task must be one complete card: What / Done when / How / Verify /
# Needs+Blocks / Who, in that fixed order, with no field missing. The How
# field must open with a delivery approach from the locked vocabulary.
#
# An awk pass tracks per-task state: at each "#### Task " heading (and EOF)
# it reports any card field not seen since the previous heading, and emits
# every How value on stderr for the vocabulary check.

missing_fields=$(
    awk '
      function has_value(value, lower) {
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
          lower = tolower(value)
          if (value == "" || value == "...") return 0
          if (value ~ /^<[^>]+>$/ || value ~ /^\[[^]]+\]$/) return 0
          if (lower ~ /^(tbd|todo|placeholder|replace[ -]?me)([[:space:][:punct:]].*)?$/) return 0
          return 1
      }
      function field_value(line, label) {
          sub("^-[[:space:]]+\\*\\*" label ":\\*\\*[[:space:]]*", "", line)
          return line
      }
      function check_task() {
          if (!in_task) return
          if (!seen_what) print "What|" current_title
          if (!seen_done) print "Done when|" current_title
          if (!seen_how) print "How|" current_title
          if (!seen_verify) print "Verify|" current_title
          if (!seen_needs) print "Needs/Blocks|" current_title
          if (!seen_who) print "Who|" current_title
      }
      /^#### Task / {
          check_task()
          in_task = 1
          seen_what = seen_done = seen_how = seen_verify = seen_needs = seen_who = 0
          current_title = $0
          next
      }
      /^-[[:space:]]+\*\*What:\*\*/ && in_task { seen_what = has_value(field_value($0, "What")) }
      /^-[[:space:]]+\*\*Done when:\*\*/ && in_task { seen_done = has_value(field_value($0, "Done when")) }
      /^-[[:space:]]+\*\*How:\*\*/ && in_task {
          line = $0
          sub(/^-[[:space:]]+\*\*How:\*\*[[:space:]]*/, "", line)
          seen_how = has_value(line)
          print "VALUE:" line > "/dev/stderr"
      }
      /^-[[:space:]]+\*\*Verify:\*\*/ && in_task { seen_verify = has_value(field_value($0, "Verify")) }
      /^-[[:space:]]+\*\*Needs:\*\*/ && in_task && /\*\*Blocks:\*\*/ { seen_needs = 1 }
      /^-[[:space:]]+\*\*Who:\*\*/ && in_task { seen_who = 1 }
      END { check_task() }
    ' "$PLAN" 2>/tmp/spade-lint-approaches.$$
)

if [ -n "$missing_fields" ]; then
    while IFS='|' read -r component task; do
        echo "  FAIL: example-plan.md task missing card field $component: $task"
        fail=$((fail + 1))
    done <<< "$missing_fields"
else
    echo "  ok:   example-plan.md every task is a complete card"
fi

# Validate the delivery-approach vocabulary: the first word of every How
# value must be one of the locked approaches (case-insensitive).
vocab_re='^(test-first|characterization-first|refactor-first|spike|straight-through)$'
bad_vocab=0
while IFS= read -r line; do
    value="${line#VALUE:}"
    # The approach clause is everything before the first dash or parenthesis.
    clause="${value%% -*}"
    clause="${clause%%(*}"
    first="$(echo "$clause" | awk '{print tolower($1)}')"
    first="${first%%[^a-z-]*}"   # strip trailing punctuation
    if ! echo "$first" | grep -qE "$vocab_re"; then
        echo "  FAIL: example-plan.md How does not open with a delivery approach: '$value'"
        bad_vocab=$((bad_vocab + 1))
        continue
    fi
    # In a combined approach ("characterization-first on X, test-first on Y")
    # every approach-shaped token must be in the vocabulary.
    for token in $(echo "$clause" | tr ' ,;' '\n\n\n' | tr '[:upper:]' '[:lower:]' | grep -E -- '-first$|-through$|^spike$' || true); do
        if ! echo "$token" | grep -qE "$vocab_re"; then
            echo "  FAIL: example-plan.md approach token not in vocabulary: '$token' (in value: '$value')"
            bad_vocab=$((bad_vocab + 1))
        fi
    done
done < /tmp/spade-lint-approaches.$$
rm -f /tmp/spade-lint-approaches.$$

if [ "$bad_vocab" -eq 0 ]; then
    echo "  ok:   example-plan.md every How opens with a locked delivery approach"
else
    fail=$((fail + bad_vocab))
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
