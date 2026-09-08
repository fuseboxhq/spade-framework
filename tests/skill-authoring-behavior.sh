#!/usr/bin/env bash
set -euo pipefail

# Execute the per-skill characterization contracts in the PS-2321 corpus.
# Every positive control must match the canonical skill, and deleting its exact
# load-bearing anchor must make that contract reject the seeded mutation.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTRACTS="$REPO_ROOT/tests/skill-authoring-contracts.tsv"
MANIFEST="$REPO_ROOT/src/CAPABILITIES.md"
tmp=$(mktemp -d "${TMPDIR:-/tmp}/spade-authoring-behavior.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

fail=0
behavior_count=0
completion_count=0

while IFS='|' read -r skill class anchor; do
    case "$skill" in ""|'# '*) continue ;; esac
    source_file="$REPO_ROOT/src/skills/$skill/SKILL.md"
    mutated="$tmp/$skill-$class.md"
    if [ ! -f "$source_file" ]; then
        echo "  FAIL: contract names missing skill: $skill"
        fail=$((fail + 1))
        continue
    fi
    if ! grep -Fq "$anchor" "$source_file"; then
        echo "  FAIL: $skill/$class positive control lost anchor: $anchor"
        fail=$((fail + 1))
        continue
    fi
    awk -v anchor="$anchor" '
        !removed && index($0, anchor) {
            $0 = substr($0, 1, index($0, anchor) - 1) substr($0, index($0, anchor) + length(anchor))
            removed = 1
        }
        { print }
        END { if (!removed) exit 1 }
    ' "$source_file" > "$mutated"
    if grep -Fq "$anchor" "$mutated"; then
        echo "  FAIL: $skill/$class negative mutation was accepted"
        fail=$((fail + 1))
    fi
    if [ "$class" = "terminating_completion" ]; then
        completion_count=$((completion_count + 1))
    else
        behavior_count=$((behavior_count + 1))
    fi
done < "$CONTRACTS"

matrix_rows=$(grep -c '^| spade' "$REPO_ROOT/tests/skill-authoring-corpus.md" || true)
non_applicable=$(grep '^| spade' "$REPO_ROOT/tests/skill-authoring-corpus.md" | grep -o 'N/A-[A-Z0-9-]*' | wc -l | tr -d ' ')
expected_behavior=$((matrix_rows * 5 - non_applicable))
expected_completion=$(sed -n 's/^skills:[[:space:]]*//p' "$MANIFEST" | tr ',' '\n' | wc -l | tr -d ' ')
expected_matrix=$(sed -n 's/^critical_skills:[[:space:]]*//p' "$MANIFEST" | tr ',' '\n' | wc -l | tr -d ' ')

[ "$behavior_count" -eq "$expected_behavior" ] || { echo "  FAIL: expected $expected_behavior applicable behavior contracts, got $behavior_count"; fail=$((fail + 1)); }
[ "$completion_count" -eq "$expected_completion" ] || { echo "  FAIL: expected $expected_completion terminating-completion contracts, got $completion_count"; fail=$((fail + 1)); }
[ "$matrix_rows" -eq "$expected_matrix" ] || { echo "  FAIL: expected $expected_matrix critical-skill matrix rows, got $matrix_rows"; fail=$((fail + 1)); }
[ "$non_applicable" -eq 2 ] || { echo "  FAIL: expected 2 reasoned non-applicable cells, got $non_applicable"; fail=$((fail + 1)); }

echo "skill-authoring-behavior: $behavior_count behavior and $completion_count completion mutations rejected, $fail failure(s)"
[ "$fail" -eq 0 ] || exit 1
