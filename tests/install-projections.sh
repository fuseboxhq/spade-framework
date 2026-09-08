#!/usr/bin/env bash
set -euo pipefail

# End-to-end fixture for exact Claude and Codex global installation.
# Uses an isolated HOME and never writes to the developer's real host state.

file_digest() {
    # Arguments: regular file path. Prints one SHA-256 digest.
    if [ -x /usr/bin/shasum ]; then
        /usr/bin/shasum -a 256 "$1" | awk '{print $1}'
    elif command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        echo "No SHA-256 implementation is available" >&2
        return 1
    fi
}

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp=$(mktemp -d "${TMPDIR:-/tmp}/spade-install-test.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
home="$tmp/home"
mkdir -p "$home"

assert_manifest() {
    host="$1"
    while IFS='|' read -r kind source destination expected_digest; do
        [ "$kind" = file ] || { echo "FAIL: malformed $host manifest" >&2; exit 1; }
        actual_digest=$(file_digest "$home/$destination")
        cmp "$REPO_ROOT/$source" "$home/$destination" >/dev/null && [ "$actual_digest" = "$expected_digest" ] || {
            echo "FAIL: $host manifest mismatch at $destination" >&2
            exit 1
        }
    done < "$REPO_ROOT/generated/install/$host.manifest"
}

snapshot() {
    find "$home" -type f -exec cksum {} \; | sed "s#$home/##" | LC_ALL=C sort
}

HOME="$home" "$REPO_ROOT/setup" --host all >/dev/null
assert_manifest claude
assert_manifest codex
before=$(snapshot)
HOME="$home" "$REPO_ROOT/setup" --host all >/dev/null
after=$(snapshot)
[ "$before" = "$after" ] || { echo "FAIL: repeated install is not idempotent" >&2; exit 1; }

mkdir -p "$home/.claude/skills/spade-stale"
printf '%s\n' stale > "$home/.claude/skills/spade-stale/SKILL.md"
printf '%s\n' stale > "$home/.claude/skills/spade-review/UNEXPECTED.md"
HOME="$home" "$REPO_ROOT/setup" --host claude >/dev/null
[ ! -e "$home/.claude/skills/spade-stale" ] || { echo "FAIL: stale owned skill survived" >&2; exit 1; }
[ ! -e "$home/.claude/skills/spade-review/UNEXPECTED.md" ] || { echo "FAIL: stale nested file survived" >&2; exit 1; }

outside="$tmp/outside"
mkdir -p "$outside"
rm -rf "$home/.codex"
ln -s "$outside" "$home/.codex"
if HOME="$home" "$REPO_ROOT/setup" --host codex >/dev/null 2>&1; then
    echo "FAIL: symlinked Codex root was accepted" >&2
    exit 1
fi
[ -z "$(find "$outside" -mindepth 1 -print -quit)" ] || { echo "FAIL: install escaped through symlink" >&2; exit 1; }
rm "$home/.codex"

HOME="$home" "$REPO_ROOT/setup" --host codex >/dev/null
assert_manifest codex

if command -v pwsh >/dev/null 2>&1; then
    pshome="$tmp/powershell-home"
    mkdir -p "$pshome"
    HOME="$pshome" pwsh -NoProfile -File "$REPO_ROOT/setup.ps1" -HostTarget all >/dev/null
    original_home="$home"
    home="$pshome"
    assert_manifest claude
    assert_manifest codex
    home="$original_home"
else
    echo "install-projections: pwsh unavailable, PowerShell execution fixture skipped"
fi

grep -q 'codex exec --sandbox read-only --ignore-user-config --ephemeral' "$REPO_ROOT/.codex/skills/spade-research/SKILL.md" || {
    echo "FAIL: Codex researcher confinement command missing" >&2
    exit 1
}
grep -q 'spawn_agent' "$REPO_ROOT/.codex/skills/spade-review/SKILL.md" || {
    echo "FAIL: Codex persona dispatch mapping missing" >&2
    exit 1
}
grep -q 'Task' "$REPO_ROOT/.claude/skills/spade-review/SKILL.md" || {
    echo "FAIL: Claude persona dispatch mapping missing" >&2
    exit 1
}

if command -v codex >/dev/null 2>&1; then
    codex_home="$tmp/codex-home"
    expected_version=$(sed -n 's/^version: //p' "$REPO_ROOT/src/CAPABILITIES.md" | head -n 1)
    mkdir -p "$codex_home"
    CODEX_HOME="$codex_home" codex plugin marketplace add "$REPO_ROOT" --json >/dev/null
    CODEX_HOME="$codex_home" codex plugin add spade-framework@spade-framework --json > "$tmp/codex-install.json"
    grep -q "\"version\": \"$expected_version\"" "$tmp/codex-install.json" || {
        echo "FAIL: isolated Codex plugin install did not expose v$expected_version" >&2
        exit 1
    }
else
    echo "install-projections: codex unavailable, live plugin ingestion fixture skipped"
fi

echo "install-projections: all fixtures passed"
