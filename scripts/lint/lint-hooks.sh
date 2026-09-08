#!/usr/bin/env bash
set -euo pipefail

# Validate the hook source and run the spade-guard fixture suite.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOKS="$REPO_ROOT/src/hooks/hooks.json"

jq -e '.hooks | keys | all(. == "SessionStart" or . == "SessionEnd" or . == "PreToolUse")' "$HOOKS" >/dev/null \
    || { echo "lint-hooks: unknown hook event in src/hooks/hooks.json" >&2; exit 1; }
for event in SessionStart SessionEnd PreToolUse; do
    jq -e --arg e "$event" '.hooks[$e] | type == "array" and length > 0 and all(.[]; (.hooks | type == "array" and length > 0))' "$HOOKS" >/dev/null \
        || { echo "lint-hooks: $event must be a non-empty array of non-empty hook groups" >&2; exit 1; }
done
jq -e '[.hooks[][] | .hooks[]] | length > 0 and all(.[]; .type == "command" and (.command | type == "string" and length > 0) and (.command | test("spade-guard")))' "$HOOKS" >/dev/null \
    || { echo "lint-hooks: every hook must be a command hook with a non-empty command that runs spade-guard" >&2; exit 1; }
[ -x "$REPO_ROOT/bin/spade-guard" ] || { echo "lint-hooks: bin/spade-guard must be executable" >&2; exit 1; }
bash -n "$REPO_ROOT/bin/spade-guard"

# Malformed registrations must be rejected, so the checks above cannot rot silently.
for bad in '{"hooks":{"PreToolUse":[],"SessionStart":[{"hooks":[{"type":"command","command":"x"}]}],"SessionEnd":[{"hooks":[{"type":"command","command":"x"}]}]}}' \
           '{"hooks":{"PreToolUse":[{"hooks":[{"type":"command","command":""}]}],"SessionStart":[{"hooks":[{"type":"command","command":"x"}]}],"SessionEnd":[{"hooks":[{"type":"command","command":"x"}]}]}}' \
           '{"hooks":{"PreToolUse":[{"hooks":[{"type":"prompt","prompt":"x"}]}],"SessionStart":[{"hooks":[{"type":"command","command":"x"}]}],"SessionEnd":[{"hooks":[{"type":"command","command":"x"}]}]}}'; do
    if printf '%s' "$bad" | jq -e 'all(.hooks[]; type == "array" and length > 0 and all(.[]; (.hooks | type == "array" and length > 0))) and ([.hooks[][] | .hooks[]] | all(.[]; .type == "command" and (.command | type == "string" and length > 0)))' >/dev/null 2>&1; then
        echo "lint-hooks: malformed fixture was accepted: $bad" >&2; exit 1
    fi
done

exec "$REPO_ROOT/tests/hooks/guards.sh"
