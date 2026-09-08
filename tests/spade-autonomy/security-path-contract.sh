#!/usr/bin/env bash
set -euo pipefail

# Validate the deterministic shared security-path contract and its blind receipt.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FRAMEWORK="$REPO_ROOT/docs/FRAMEWORK.md"
SKILL="$REPO_ROOT/src/skills/spade/SKILL.md"
CORPUS="$REPO_ROOT/tests/spade-autonomy/corpus.md"
PROCEDURE="$REPO_ROOT/tests/spade-autonomy/blind-procedure.md"
RESULT="$REPO_ROOT/tests/spade-autonomy/security-path-result.md"
fail=0

for input in "$FRAMEWORK" "$SKILL" "$CORPUS" "$PROCEDURE" "$RESULT"; do
    if [ ! -r "$input" ]; then
        echo "security-path input is missing or unreadable: ${input#"$REPO_ROOT"/}" >&2
        exit 1
    fi
done

input_digest=$(
    cd "$REPO_ROOT"
    shasum -a 256 \
        docs/FRAMEWORK.md \
        src/skills/spade/SKILL.md \
        tests/spade-autonomy/corpus.md \
        tests/spade-autonomy/blind-procedure.md \
        | shasum -a 256 | awk '{print $1}'
)

require_literal() {
    file="$1"
    literal="$2"
    label="$3"
    if grep -Fq -- "$literal" "$file"; then
        echo "  ok:   $label"
    else
        echo "  FAIL: $label"
        fail=$((fail + 1))
    fi
}

heading_count=$(grep -Fc '### Security-sensitive path surface' "$FRAMEWORK" || true)
if [ "$heading_count" -eq 1 ]; then
    echo "  ok:   one canonical security-sensitive path surface"
else
    echo "  FAIL: expected one canonical security-sensitive path surface, found $heading_count"
    fail=$((fail + 1))
fi

category_count=$(
    awk '
        /^### Security-sensitive path surface$/ { in_surface=1; next }
        in_surface && /^### / { in_surface=0 }
        in_surface && /^[0-9]+\. \*\*/ { count++ }
        END { print count + 0 }
    ' "$FRAMEWORK"
)
if [ "$category_count" -eq 14 ]; then
    echo "  ok:   canonical surface has 14 categories"
else
    echo "  FAIL: canonical surface has $category_count categories, expected 14"
    fail=$((fail + 1))
fi

case_count=$(grep -Ec '^\| H[0-9]+ \|' "$CORPUS" || true)
if [ "$case_count" -eq 29 ]; then
    echo "  ok:   security-path corpus has 29 cases"
else
    echo "  FAIL: security-path corpus has $case_count cases, expected 29"
    fail=$((fail + 1))
fi

require_literal "$FRAMEWORK" 'touches any category in § Security-sensitive path surface.' 'Deliver tripwire #6 references the canonical surface'
require_literal "$SKILL" 'FRAMEWORK.md § Security-sensitive path surface' 'canonical orchestrator references the shared surface'
require_literal "$FRAMEWORK" 'There is no override, allowlist escape, or workflow-specific relaxation.' 'surface has no override'
require_literal "$PROCEDURE" 'The pre-extraction baseline runs H1-H15 against the v3.2.1 inline definition.' 'procedure retains the before baseline'
require_literal "$RESULT" 'Legacy preservation: PASS' 'blind result preserves legacy halts'
require_literal "$RESULT" 'PASS: all 29 security-path cases match' 'blind result covers all cases'

recorded_digest=$(sed -n 's/^Tested working-tree input digest: `\([0-9a-f][0-9a-f]*\)`$/\1/p' "$RESULT")
if [ "$recorded_digest" = "$input_digest" ]; then
    echo "  ok:   blind result matches current contract inputs"
else
    echo "  FAIL: blind result digest is stale (expected $input_digest, found ${recorded_digest:-missing})"
    fail=$((fail + 1))
fi

echo
echo "spade-autonomy-security-path: $fail failure(s)"
[ "$fail" -eq 0 ] || exit 1
