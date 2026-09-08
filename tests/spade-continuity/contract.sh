#!/usr/bin/env bash
set -euo pipefail

# Validate the deterministic shape of PS-2322's continuity contract and corpus.
# Behavioral decisions remain gated by blind-procedure.md in an isolated context.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REFERENCE="$REPO_ROOT/src/skills/spade/references/continuity.md"
SKILL="$REPO_ROOT/src/skills/spade/SKILL.md"
FRAMEWORK="$REPO_ROOT/docs/FRAMEWORK.md"
CORPUS="$REPO_ROOT/tests/spade-continuity/corpus.md"
PROCEDURE="$REPO_ROOT/tests/spade-continuity/blind-procedure.md"
RESULT="$REPO_ROOT/tests/spade-continuity/blind-result.md"
CANDIDATES="$REPO_ROOT/src/skills/spade-learn/references/candidate-capture.md"
fail=0

require_file() {
    file="$1"
    if [ -f "$file" ]; then
        echo "  ok:   ${file#"$REPO_ROOT"/} exists"
    else
        echo "  FAIL: ${file#"$REPO_ROOT"/} is missing"
        fail=$((fail + 1))
    fi
}

require_once() {
    file="$1"
    literal="$2"
    label="$3"
    count=$(grep -Fxc "$literal" "$file" || true)
    if [ "$count" -eq 1 ]; then
        echo "  ok:   $label"
    else
        echo "  FAIL: $label appears $count times"
        fail=$((fail + 1))
    fi
}

for file in "$REFERENCE" "$CANDIDATES" "$CORPUS" "$PROCEDURE" "$RESULT"; do
    require_file "$file"
done

for field in \
    schema state_id previous_state run_id scope_id scope_revision autonomy_level \
    phase completed_checkpoints current_work repository branch base_sha head_sha \
    pull_request last_verification halt_reason next_action recorded_at; do
    count=$(grep -Ec "^${field}:" "$REFERENCE" || true)
    if [ "$count" -eq 1 ]; then
        echo "  ok:   state field $field"
    else
        echo "  FAIL: state field $field appears $count times"
        fail=$((fail + 1))
    fi
done

require_once "$SKILL" 'Read `references/continuity.md` completely before opening, writing, validating, resuming, repairing, or closing a run trace.' "spade routes continuity operations to the reference"
require_once "$SKILL" '## Checkpoint persistence' "spade owns one checkpoint-persistence route"
require_once "$FRAMEWORK" '### Run continuity state' "framework owns one continuity section"
require_once "$REFERENCE" '<!-- SPADE-RUN-STATE-START v1 -->' "local start marker is single-sourced"
require_once "$REFERENCE" '<!-- SPADE-RUN-STATE-END -->' "local end marker is single-sourced"

for prefix_and_count in A:6 B:6 C:12 D:9 E:6 F:12; do
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
    grep -Fq "### $mode" "$REFERENCE" || {
        echo "  FAIL: continuity reference lacks $mode persistence"
        fail=$((fail + 1))
    }
done

grep -Fq 'fresh isolated context' "$PROCEDURE" || {
    echo "  FAIL: blind procedure lacks isolated-context requirement"
    fail=$((fail + 1))
}
grep -Fq 'src/skills/spade-learn/references/candidate-capture.md' "$PROCEDURE" || {
    echo "  FAIL: blind procedure does not provide the candidate contract for section F"
    fail=$((fail + 1))
}
grep -Fq 'PASS: all 51 cases match' "$RESULT" || {
    echo "  FAIL: blind result does not record the 51-case pass"
    fail=$((fail + 1))
}

grep -Fq 'Status is read-only and structural' "$REPO_ROOT/src/skills/spade-status/SKILL.md" || {
    echo "  FAIL: spade-status does not preserve the unvalidated read boundary"
    fail=$((fail + 1))
}
grep -Fq 'Read `../spade/references/continuity.md` completely before classifying a run summary.' "$REPO_ROOT/src/skills/spade-status/SKILL.md" || {
    echo "  FAIL: spade-status does not route to the canonical continuity reference"
    fail=$((fail + 1))
}

for validation_anchor in \
    '**Capability:**' '**Tracker and Scope:**' '**Plan and tasks:**' \
    '**Approval and halt:**' '**Repository:**' '**Worktree:**' \
    '**Current work:**' '**Pull request:**' '**Verification:**'; do
    grep -Fq "$validation_anchor" "$REFERENCE" || {
        echo "  FAIL: live validation lacks $validation_anchor"
        fail=$((fail + 1))
    }
done

grep -Fq 'Continue from <boundary>' "$REFERENCE" || {
    echo "  FAIL: continuity reference lacks bounded Continue choice"
    fail=$((fail + 1))
}
grep -Fq 'When live state proves the selected autonomy level already reached its defined halt point' "$REFERENCE" || {
    echo "  FAIL: continuity reference lacks already-completed handling"
    fail=$((fail + 1))
}

for recovery_class in missing malformed unsupported stale contradictory dirty-worktree; do
    grep -Fq "\`$recovery_class\` means" "$REFERENCE" || {
        echo "  FAIL: recovery contract lacks $recovery_class classification"
        fail=$((fail + 1))
    }
done

for forbidden_action in stash reset clean delete overwrite 'switch branches'; do
    grep -Fq "$forbidden_action" "$REFERENCE" || {
        echo "  FAIL: dirty-worktree contract lacks $forbidden_action refusal"
        fail=$((fail + 1))
    }
done

grep -Fq 'Confirm ownership and continue' "$REFERENCE" || {
    echo "  FAIL: dirty-worktree contract lacks human ownership confirmation"
    fail=$((fail + 1))
}
grep -Fq 'Repair is a metadata correction, not a waiver.' "$REFERENCE" || {
    echo "  FAIL: recovery contract does not bound repair"
    fail=$((fail + 1))
}

for category in failed-assumption recurring-pitfall project-constraint useful-pattern learning-correction; do
    grep -Fq "\`$category\`" "$CANDIDATES" || {
        echo "  FAIL: candidate contract lacks $category"
        fail=$((fail + 1))
    }
done

for outcome in candidate:none candidate:skipped candidate:duplicate-no-write candidate:captured-public candidate:captured-private candidate:updated-active candidate:archived-and-replaced; do
    grep -Fq "\`$outcome\`" "$CANDIDATES" || {
        echo "  FAIL: candidate contract lacks $outcome outcome"
        fail=$((fail + 1))
    }
done

grep -Fq 'read `references/candidate-capture.md` completely' "$REPO_ROOT/src/skills/spade-learn/SKILL.md" || {
    echo "  FAIL: spade-learn does not route candidate evidence to its reference"
    fail=$((fail + 1))
}
grep -Fq 'Learning capture never changes the recorded verdict' "$REPO_ROOT/src/skills/spade-evaluate/SKILL.md" || {
    echo "  FAIL: Evaluate candidate capture weakens the verdict boundary"
    fail=$((fail + 1))
}

echo
echo "spade-continuity-contract: $fail failure(s)"
[ "$fail" -eq 0 ] || exit 1
