#!/usr/bin/env bash
set -euo pipefail

# Validate the deterministic shape of PS-2320's frontier contract and corpus.
# Behavioral decisions remain gated by blind-procedure.md in a fresh isolated context.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REFERENCE="$REPO_ROOT/src/skills/spade-frontier/references/map-contract.md"
SKILL="$REPO_ROOT/src/skills/spade-frontier/SKILL.md"
CORPUS="$REPO_ROOT/tests/spade-frontier/corpus.md"
PROCEDURE="$REPO_ROOT/tests/spade-frontier/blind-procedure.md"
RESULT="$REPO_ROOT/tests/spade-frontier/blind-result.md"
fail=0

for input in "$REFERENCE" "$SKILL" "$CORPUS" "$PROCEDURE"; do
    if [ ! -r "$input" ]; then
        echo "frontier input is missing or unreadable: ${input#"$REPO_ROOT"/}" >&2
        exit 1
    fi
done

input_digest=$(
    cd "$REPO_ROOT"
    shasum -a 256 \
        src/skills/spade-frontier/references/map-contract.md \
        src/skills/spade-frontier/SKILL.md \
        tests/spade-frontier/corpus.md \
        tests/spade-frontier/blind-procedure.md \
        | shasum -a 256 | awk '{print $1}'
)

require_file() {
    # Contract: record whether one required frontier artefact exists.
    file="$1"
    if [ -f "$file" ]; then
        echo "  ok:   ${file#"$REPO_ROOT"/} exists"
    else
        echo "  FAIL: ${file#"$REPO_ROOT"/} is missing"
        fail=$((fail + 1))
    fi
}

require_literal() {
    # Contract: require one literal behavior anchor in one canonical file.
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

for file in "$REFERENCE" "$SKILL" "$CORPUS" "$PROCEDURE" "$RESULT"; do
    require_file "$file"
done

for field in schema id name title status revision created updated linear_issue linear_url; do
    count=$(grep -Ec "^${field}:" "$REFERENCE" || true)
    expected=1
    case "$field" in schema|status) expected=2 ;; esac
    if [ "$count" -eq "$expected" ]; then
        echo "  ok:   index field $field"
    else
        echo "  FAIL: index field $field appears $count times, expected $expected"
        fail=$((fail + 1))
    fi
done

for field in schema frontier_id question_id path owner status attribution resolved_at; do
    count=$(grep -Ec "^${field}:" "$REFERENCE" || true)
    expected=1
    case "$field" in schema|status) expected=2 ;; esac
    if [ "$count" -eq "$expected" ]; then
        echo "  ok:   resolution field $field"
    else
        echo "  FAIL: resolution field $field appears $count times, expected $expected"
        fail=$((fail + 1))
    fi
done

for prefix_and_count in A:4 B:5 C:7 D:4 E:4; do
    prefix=${prefix_and_count%%:*}
    expected=${prefix_and_count#*:}
    actual=$(grep -Ec "^\| ${prefix}[0-9]+ \|" "$CORPUS" || true)
    if [ "$actual" -eq "$expected" ]; then
        echo "  ok:   corpus section $prefix has $actual cases"
    else
        echo "  FAIL: corpus section $prefix has $actual cases, expected $expected"
        fail=$((fail + 1))
    fi
done

for mode in Linear Local Hybrid; do
    require_literal "$REFERENCE" "### $mode" "reference defines $mode persistence"
done

for path in research prototype human-decision prerequisite; do
    require_literal "$REFERENCE" "- \`$path\`" "reference defines $path resolution path"
done

require_literal "$REFERENCE" 'One invocation performs exactly one of these branches:' 'one-invocation branch invariant'
require_literal "$REFERENCE" 'Resolve at most one currently visible frontier question' 'one-question progression limit'
require_literal "$REFERENCE" 'Graduation is a bounded postcondition' 'graduation is not a batch mode'
require_literal "$REFERENCE" 'Frontier invocations do not participate in `spade-run-state/v1`.' 'run-state boundary'
require_literal "$REFERENCE" 'It must not use production data or credentials' 'prototype disposal boundary'
require_literal "$REFERENCE" 'Do not create a Plan task beneath the frontier map' 'prerequisite delivery refusal'
require_literal "$PROCEDURE" 'fresh isolated context' 'blind procedure requires isolation'

if [ -f "$SKILL" ]; then
    require_literal "$SKILL" 'Read `references/map-contract.md` completely' 'skill routes to canonical map contract'
    require_literal "$SKILL" 'Do not produce implementation code.' 'skill has explicit implementation refusal'
    require_literal "$SKILL" '## Resolution paths' 'skill routes every resolution path'
    require_literal "$SKILL" 'Run the disposable prototype' 'prototype requires an explicit decision'
    require_literal "$SKILL" 'The recommendation must not be preselected.' 'human decision is not preselected'
    require_literal "$SKILL" 'Do not create a Plan sub-issue' 'prerequisite does not become frontier delivery'
    require_literal "$SKILL" 'Immediately before writing, re-read the canonical index.' 'progression rejects stale state'
    require_literal "$SKILL" 'Resolve no second question in the same invocation.' 'skill enforces one-question progression'
    require_literal "$SKILL" '## Graduation postcondition' 'skill owns bounded graduation'
    require_literal "$SKILL" 'Author these Scopes with /spade-scope' 'graduation preserves Scope authoring'
    require_literal "$SKILL" 'Frontier itself writes no `spade-run-state/v1` record.' 'skill preserves run-state boundary'
fi

require_literal "$REPO_ROOT/src/skills/spade-scope/SKILL.md" '## Frontier handoff for major uncertainty' 'Scope routes meaningful fog to frontier'
require_literal "$REPO_ROOT/src/skills/spade/SKILL.md" 'If `/spade-scope` returns `frontier-handoff`' 'orchestrator ends provisional run at frontier handoff'
require_literal "$REPO_ROOT/docs/FRAMEWORK.md" '## Frontier Discovery' 'framework documents pre-Scope discovery outside the loop'

if [ -f "$RESULT" ]; then
    require_literal "$RESULT" 'PASS: all 24 cases match' 'blind result records all-case pass'
    recorded_digest=$(sed -n 's/^Input digest: `\([0-9a-f][0-9a-f]*\)`$/\1/p' "$RESULT")
    if [ "$recorded_digest" = "$input_digest" ]; then
        echo "  ok:   blind result matches current contract inputs"
    else
        echo "  FAIL: blind result digest is stale (expected $input_digest, found ${recorded_digest:-missing})"
        fail=$((fail + 1))
    fi
fi

echo
echo "spade-frontier-contract: $fail failure(s)"
[ "$fail" -eq 0 ] || exit 1
