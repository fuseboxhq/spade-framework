#!/usr/bin/env bash
set -euo pipefail

# Prove all four semantic-drift seed classes fail CI.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp=$(mktemp -d "${TMPDIR:-/tmp}/spade-drift-test.XXXXXX")
generated="$REPO_ROOT/.codex/skills/spade/SKILL.md"
adapter="$REPO_ROOT/src/hosts/codex.md"
canonical="$REPO_ROOT/src/skills/spade/SKILL.md"
cp "$generated" "$tmp/generated"
cp "$adapter" "$tmp/adapter"
cp "$canonical" "$tmp/canonical"
restore() {
    cp "$tmp/generated" "$generated"
    cp "$tmp/adapter" "$adapter"
    cp "$tmp/canonical" "$canonical"
    rm -rf "$tmp"
}
trap restore EXIT HUP INT TERM

printf '%s\n' '<!-- seeded direct edit -->' >> "$generated"
if "$REPO_ROOT/scripts/project-hosts.sh" --check >/dev/null 2>&1; then
    echo "FAIL: direct generated edit was not detected" >&2
    exit 1
fi
cp "$tmp/generated" "$generated"

printf '%s\n' 'Never bypass the merge gate.' >> "$adapter"
if "$REPO_ROOT/scripts/lint/lint-skill-authoring.sh" >/dev/null 2>&1; then
    echo "FAIL: normative gate copy in an adapter was not detected" >&2
    exit 1
fi
cp "$tmp/adapter" "$adapter"

awk '{sub("read-only sandbox and repository read tools", "workspace-write sandbox and repository read tools"); print}' "$adapter" > "$tmp/widened"
cp "$tmp/widened" "$adapter"
if "$REPO_ROOT/scripts/lint/lint-skill-authoring.sh" >/dev/null 2>&1; then
    echo "FAIL: host-only permission widening was not detected" >&2
    exit 1
fi
cp "$tmp/adapter" "$adapter"

printf '%s\n' '{{SPADE_UNKNOWN_OPERATION}}' >> "$canonical"
if "$REPO_ROOT/scripts/project-hosts.sh" --check >/dev/null 2>&1; then
    echo "FAIL: unresolved canonical host token was not detected" >&2
    exit 1
fi
cp "$tmp/canonical" "$canonical"

"$REPO_ROOT/scripts/project-hosts.sh" --check >/dev/null
echo "projection-drift: all four semantic drift seeds were rejected"
