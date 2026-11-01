#!/usr/bin/env bash
set -euo pipefail

# Checks `setup --hooks` against a throwaway HOME: the guard entries land with
# an absolute command, other settings survive, a rerun does not duplicate, and
# the registered command really denies a merge.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tmp=$(mktemp -d "${TMPDIR:-/tmp}/spade-setup-hooks.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
home="$tmp/home"
mkdir -p "$home/.claude"
fail=0

check() {
    # Arguments: label, then a command that must succeed.
    label="$1"; shift
    if "$@" >/dev/null; then echo "  ok:   $label"; else echo "  FAIL: $label"; fail=$((fail + 1)); fi
}

cat > "$home/.claude/settings.json" <<'JSON'
{"theme": "dark", "hooks": {"PreToolUse": [{"matcher": "Bash", "hooks": [{"type": "command", "command": "other-hook"}]}]}}
JSON

echo "setup --hooks"
HOME="$home" "$REPO_ROOT/setup" --host claude --hooks >/dev/null
HOME="$home" "$REPO_ROOT/setup" --host claude --hooks >/dev/null
settings="$home/.claude/settings.json"

check "other settings kept" jq -e '.theme == "dark"' "$settings"
check "other hook kept" jq -e '[.hooks.PreToolUse[].hooks[].command] | index("other-hook") != null' "$settings"
for event in SessionStart SessionEnd PreToolUse; do
    check "$event has exactly one guard entry after a rerun" \
        jq -e --arg e "$event" '[.hooks[$e][] | select(any(.hooks[]; .command | test("spade-guard")))] | length == 1' "$settings"
done
check "commands are absolute, not plugin-relative" \
    jq -e --arg g "\"$home/.spade/bin/spade-guard\"" '[.hooks[][] | .hooks[] | select(.command | test("spade-guard")) | .command] | all(. == $g)' "$settings"

project="$tmp/project"
mkdir -p "$project/.spade"
printf 'mode: local\nautonomy:\n  deliver:\n    merge: human\n' > "$project/.spade/config"
command=$(jq -r '[.hooks.PreToolUse[] | .hooks[] | select(.command | test("spade-guard")) | .command][0]' "$settings")
decision=$(jq -cn '{hook_event_name:"PreToolUse",session_id:"s",tool_name:"Bash",tool_input:{command:"gh pr merge 41"}}' \
    | CLAUDE_PROJECT_DIR="$project" bash -c "$command" | jq -r '.hookSpecificOutput.permissionDecision // ""')
check "registered command denies a merge under the human policy" [ "$decision" = deny ]

echo "setup-hooks: $fail failure(s)"
[ "$fail" -eq 0 ]
