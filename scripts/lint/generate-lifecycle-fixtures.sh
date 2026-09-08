#!/usr/bin/env bash
set -euo pipefail

# Materialize normalized consumer fixtures from immutable release commits.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INDEX="$REPO_ROOT/tests/fixtures/lifecycle/historical.tsv"
OUTPUT="$REPO_ROOT/tests/fixtures/lifecycle/releases"

while IFS='|' read -r version release_commit; do
    [ -n "$version" ] && [ "${version#\#}" = "$version" ] || continue
    fixture="$OUTPUT/$version"
    mkdir -p "$fixture/.spade"
    printf 'spade_version=%s\n' "$version" > "$fixture/.spade/version"
    git -C "$REPO_ROOT" show "$release_commit:.spade/config" > "$fixture/.spade/config"
    # Tracker identity is the maintainer's, not the release's: placeholder it.
    sed -E -i.bak \
        -e 's#^(  team: ).*$#\1Example Team#' \
        -e 's#https://linear\.app/[^/]+/#https://linear.app/example/#g' \
        -e 's#https://horizon\.[^/]+/#https://horizon.example.com/#g' \
        "$fixture/.spade/config"
    rm -f "$fixture/.spade/config.bak"
    for name in AGENTS CLAUDE; do
        {
            printf 'consumer-owned prefix\n\n'
            printf '<!-- SPADE-FRAMEWORK-START v%s -->\n' "$version"
            git -C "$REPO_ROOT" show "$release_commit:fragments/$name-section.md"
            printf '<!-- SPADE-FRAMEWORK-END -->\n\n'
            printf 'consumer-owned suffix\n'
        } > "$fixture/$name.md"
    done
    case "$version" in
        3.1.0|3.2.0)
            sed -i.bak 's|# - Plans are persisted locally under .spade/plans/ in addition to Linear comments.|# - In linear mode, Linear is canonical; .spade/plans/ is fallback-only when the tracker cannot accept a Plan.|' "$fixture/.spade/config"
            sed -i.bak 's/Revertable as one commit/Reversible as one commit/' "$fixture/AGENTS.md"
            rm -f "$fixture/.spade/config.bak" "$fixture/AGENTS.md.bak"
            ;;
    esac
    if git -C "$REPO_ROOT" cat-file -e "$release_commit:INTENT.md" 2>/dev/null; then
        git -C "$REPO_ROOT" show "$release_commit:INTENT.md" > "$fixture/INTENT.md"
    else
        rm -f "$fixture/INTENT.md"
    fi
    printf '%s\n' "$release_commit" > "$fixture/.release-commit"
done < "$INDEX"

echo "lifecycle-fixtures: materialized release-derived consumer states"
