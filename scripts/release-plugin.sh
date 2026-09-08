#!/usr/bin/env bash
set -euo pipefail

# Create a release commit whose version claims derive from CAPABILITIES.md.
# Release provenance is the exact commit fetched from the canonical remote.

usage() {
    # Contract: print the release helper interface.
    echo "Usage: $0 [--dry-run] <new-version>" >&2
}

fail() {
    # Contract: terminate before mutation with one actionable error.
    echo "release-plugin: $*" >&2
    exit 1
}

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then DRY_RUN=1; shift; fi
[ "$#" -eq 1 ] || { usage; exit 2; }
NEW_VERSION="$1"
printf '%s' "$NEW_VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || fail "version must be MAJOR.MINOR.PATCH"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"
CANONICAL_REMOTE="$(awk '/^canonical_remote:/{print $2; exit}' src/CAPABILITIES.md)"
CURRENT_VERSION="$(awk '/^version:/{print $2; exit}' src/CAPABILITIES.md)"
[ "$CANONICAL_REMOTE" = "https://github.com/fuseboxhq/spade-framework.git" ] || fail "canonical remote authority is unexpected"
[ "$(git remote get-url origin 2>/dev/null || true)" = "$CANONICAL_REMOTE" ] || fail "origin is not the canonical remote"
[ "$(git branch --show-current)" = "main" ] || fail "releases must start on main"
[ -z "$(git status --porcelain)" ] || fail "working tree must be completely clean"
git fetch --quiet origin main
[ "$(git rev-parse HEAD)" = "$(git rev-parse refs/remotes/origin/main)" ] || fail "main does not equal freshly fetched origin/main"
git rev-parse "refs/tags/v$NEW_VERSION" >/dev/null 2>&1 && fail "tag v$NEW_VERSION already exists"
awk -v old="$CURRENT_VERSION" -v new="$NEW_VERSION" '
    function weight(v, p) { split(v,p,"."); return p[1]*1000000000000 + p[2]*1000000 + p[3] }
    BEGIN { exit !(weight(new) > weight(old)) }
' || fail "new version must be greater than $CURRENT_VERSION"
grep -Fq "## [$NEW_VERSION]" CHANGELOG.md || fail "CHANGELOG.md has no $NEW_VERSION release entry"
awk -F'|' -v old="$CURRENT_VERSION" -v new="$NEW_VERSION" '$0 !~ /^#/ && $1 == old && $2 == new {found++} END {exit found != 1}' migrations/manifest.tsv || fail "migration manifest needs one $CURRENT_VERSION to $NEW_VERSION unit"

if [ "$DRY_RUN" -eq 1 ]; then
    echo "release-plugin: dry run passed"
    echo "  canonical-remote: $CANONICAL_REMOTE"
    echo "  base-commit: $(git rev-parse HEAD)"
    echo "  version: $CURRENT_VERSION -> $NEW_VERSION"
    exit 0
fi

tmp="src/CAPABILITIES.md.tmp.$$"
awk -v version="$NEW_VERSION" '
    /^version:/ && !done {$0="version: " version; done=1}
    /^published_versions:/ && !published {$0=$0 "," version; published=1}
    {print}
' src/CAPABILITIES.md > "$tmp"
mv "$tmp" src/CAPABILITIES.md
./scripts/project-hosts.sh
./scripts/project-hosts.sh --check
./scripts/lint/run-all.sh

git add src/CAPABILITIES.md .spade/version .claude-plugin .codex-plugin .agents/plugins \
    plugins/spade-framework .claude .codex skills agents generated/install scripts/spade-* setup setup.ps1
git commit -m "spade plugin v$NEW_VERSION"
RELEASE_COMMIT="$(git rev-parse HEAD)"
git tag "v$NEW_VERSION" "$RELEASE_COMMIT"

echo "release-plugin: release commit and tag created locally"
echo "  approved-commit: $RELEASE_COMMIT"
echo "  tag: v$NEW_VERSION"
echo "Human approval must name this exact commit before pushing it and the tag."
