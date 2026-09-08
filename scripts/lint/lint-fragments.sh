#!/usr/bin/env bash
set -euo pipefail

# SPADE Framework — fragments lint
#
# Fragment files under fragments/ are the raw CONTENT that
# spade-marker-replace wraps with SPADE-FRAMEWORK-START / END markers
# when it inserts them into a consumer repo. They must therefore NOT
# contain any SPADE-FRAMEWORK markers themselves — embedding a marker in
# a fragment would produce a malformed block after insertion.
#
# Checks:
#   1. fragments/ directory exists and contains at least one .md file.
#   2. Every fragments/*.md is non-empty and contains no
#      SPADE-FRAMEWORK-START or SPADE-FRAMEWORK-END line.
#   3. The .spade/version file exists and carries a spade_version=X.Y.Z
#      line. (Version drift between fragments and the pin is covered in
#      Bundle E's migration test.)
#   4. Agent policy surfaces do not restore an absolute AI merge ban and
#      the installed skill mirrors remain byte-identical.
#
# Exit codes:
#   0  clean
#   1  violation found
#   2  fragments/ directory missing or empty

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FRAG_DIR="$REPO_ROOT/fragments"
VERSION_FILE="$REPO_ROOT/.spade/version"

fail=0

if [ ! -d "$FRAG_DIR" ]; then
    echo "lint-fragments: missing fragments directory: $FRAG_DIR" >&2
    exit 2
fi

shopt -s nullglob
fragments=("$FRAG_DIR"/*.md)
shopt -u nullglob

if [ "${#fragments[@]}" -eq 0 ]; then
    echo "lint-fragments: no *.md fragments found in $FRAG_DIR" >&2
    exit 2
fi

for frag in "${fragments[@]}"; do
    rel="${frag#"$REPO_ROOT"/}"
    if [ ! -s "$frag" ]; then
        echo "  FAIL: $rel is missing or empty"
        fail=$((fail + 1))
        continue
    fi
    if grep -qE '^<!-- SPADE-FRAMEWORK-(START|END)' "$frag"; then
        echo "  FAIL: $rel contains a SPADE-FRAMEWORK marker (fragments must be raw content only)"
        fail=$((fail + 1))
    else
        echo "  ok:   $rel has no internal markers"
    fi
done

if [ ! -f "$VERSION_FILE" ]; then
    echo "  FAIL: .spade/version is missing"
    fail=$((fail + 1))
elif ! grep -qE '^spade_version=[0-9]+\.[0-9]+\.[0-9]+$' "$VERSION_FILE"; then
    echo "  FAIL: .spade/version does not carry spade_version=X.Y.Z"
    fail=$((fail + 1))
else
    version_line=$(grep -E '^spade_version=' "$VERSION_FILE")
    echo "  ok:   .spade/version pins $version_line"
fi

policy_files=(
    "$REPO_ROOT/AGENTS.md"
    "$REPO_ROOT/ANTI-PATTERNS.md"
    "$REPO_ROOT/docs/FRAMEWORK.md"
    "$REPO_ROOT/fragments/AGENTS-section.md"
    "$REPO_ROOT/skills/spade/SKILL.md"
    "$REPO_ROOT/skills/spade-approve/SKILL.md"
)

policy_files_readable=true
for policy_file in "${policy_files[@]}"; do
    if [ ! -r "$policy_file" ]; then
        echo "  FAIL: required policy file is missing or unreadable: ${policy_file#"$REPO_ROOT"/}"
        fail=$((fail + 1))
        policy_files_readable=false
    fi
done

if [ "$policy_files_readable" = true ]; then
    if grep -Ein '(Deliver|AI agents?|agents?|AI).*(never|must not|may not|cannot).*merge|only humans?.*merge|merge.*(human-only|reserved for humans)' "${policy_files[@]}"; then
        echo "  FAIL: agent policy restores an absolute AI merge prohibition"
        fail=$((fail + 1))
    else
        echo "  ok:   agent policy permits explicitly requested merges"
    fi
fi

for skill in spade spade-approve spade-update; do
    if ! cmp -s "$REPO_ROOT/skills/$skill/SKILL.md" "$REPO_ROOT/.claude/skills/$skill/SKILL.md"; then
        echo "  FAIL: skills/$skill/SKILL.md differs from its .claude mirror"
        fail=$((fail + 1))
    else
        echo "  ok:   $skill skill mirror is byte-identical"
    fi
done

echo
echo "lint-fragments: $fail failure(s)"
[ "$fail" -eq 0 ] || exit 1
