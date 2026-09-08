#!/usr/bin/env bash
set -euo pipefail

# Verify the fixed handoff command contract, opaque prompts, and collision guard.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAUNCHER="$REPO_ROOT/bin/spade-handoff-launch"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }
expect_rc() { if [ "$1" = "$2" ]; then pass "$3 (rc=$2)"; else fail "$3 (expected rc=$1, got rc=$2)"; fi; }

tmp="$(mktemp -d)"
agent_tmp="$(mktemp -d "$REPO_ROOT/.spade-handoff-test.XXXXXX")"
trap 'rm -rf "$tmp" "$agent_tmp"' EXIT
mkdir -p "$agent_tmp/bin"
printf '#!/usr/bin/env bash\nexit 0\n' > "$agent_tmp/bin/claude"
printf '#!/usr/bin/env bash\nexit 0\n' > "$agent_tmp/bin/amp"
chmod +x "$agent_tmp/bin/claude" "$agent_tmp/bin/amp"
export PATH="$agent_tmp/bin:/usr/bin:/bin"
AMP_REAL="$(cd "$agent_tmp/bin" && pwd -P)/amp"
CLAUDE_REAL="$(cd "$agent_tmp/bin" && pwd -P)/claude"

pwn_cmdsub="$tmp/PWNED_CMDSUB"
pwn_backtick="$tmp/PWNED_BACKTICK"
printf 'injection $(touch %s) and `touch %s`; "quoted"\n' "$pwn_cmdsub" "$pwn_backtick" > "$tmp/payload.txt"
printf 'deliver the plan\n' > "$tmp/plain.txt"

run_launcher() {
    local stdin_file="$1"
    shift
    set +e
    OUT="$("$LAUNCHER" "$@" < "$stdin_file" 2>&1)"
    RC=$?
    set -e
}

echo "Case 1: Claude command is fixed and prompt is opaque"
run_launcher "$tmp/payload.txt" --terminal iterm --cwd "$tmp" --agent claude --dry-run
expect_rc 0 "$RC" "Claude dry run"
if [ ! -e "$pwn_cmdsub" ] && [ ! -e "$pwn_backtick" ]; then pass "prompt metacharacters were not executed"; else fail "prompt metacharacters executed"; fi
printf '%s' "$OUT" | grep -qF "$CLAUDE_REAL --permission-mode acceptEdits \"\$_spade_prompt\"" && pass "Claude uses the fixed interactive argv" || fail "Claude argv drifted"

echo "Case 2: Amp command and prompt transport are fixed"
run_launcher "$tmp/plain.txt" --terminal terminal --cwd "$tmp" --agent amp --autonomous --dry-run
expect_rc 0 "$RC" "Amp dry run"
printf '%s' "$OUT" | grep -qF "printf '%s' \"\$_spade_prompt\" | exec $AMP_REAL --dangerously-allow-all" && pass "Amp uses fixed stdin transport and autonomy flag" || fail "Amp contract drifted"

echo "Case 3: arbitrary commands and flags are rejected"
run_launcher "$tmp/plain.txt" --terminal iterm --cwd "$tmp" --agent /bin/sh --dry-run
expect_rc 1 "$RC" "arbitrary agent"
run_launcher "$tmp/plain.txt" --terminal iterm --cwd "$tmp" --agent claude -- --eval bad
expect_rc 1 "$RC" "arbitrary trailing argv"

echo "Case 4: same-worktree collision is guarded"
git init -q "$tmp/worktree"
run_launcher "$tmp/plain.txt" --terminal iterm --cwd "$tmp/worktree" --invoked-from "$tmp/worktree" --agent claude --dry-run
expect_rc 4 "$RC" "same worktree refused"
run_launcher "$tmp/plain.txt" --terminal iterm --cwd "$tmp/worktree" --invoked-from "$tmp/worktree" --agent claude --force-same-worktree --dry-run
expect_rc 0 "$RC" "explicit collision override"

echo "Case 5: symlinked agent resolution is rejected"
rm -f "$agent_tmp/bin/claude"
ln -s /bin/echo "$agent_tmp/bin/claude"
run_launcher "$tmp/plain.txt" --terminal iterm --cwd "$tmp" --agent claude --dry-run
expect_rc 3 "$RC" "symlinked binary"

echo "Case 5b: writable executable paths and aliased worktrees are constrained"
mkdir -p "$agent_tmp/group-writable"
printf '#!/usr/bin/env bash\nexit 0\n' > "$agent_tmp/group-writable/claude"
chmod 775 "$agent_tmp/group-writable" "$agent_tmp/group-writable/claude"
PATH="$agent_tmp/group-writable:/usr/bin:/bin"
export PATH
run_launcher "$tmp/plain.txt" --terminal iterm --cwd "$tmp" --agent claude --dry-run
expect_rc 3 "$RC" "group-writable agent path"
PATH="$agent_tmp/bin:/usr/bin:/bin"
export PATH
mkdir -p "$tmp/real-parent/target"
ln -s "$tmp/real-parent" "$tmp/aliased-parent"
run_launcher "$tmp/plain.txt" --terminal iterm --cwd "$tmp/aliased-parent/target" --agent amp --dry-run
expect_rc 0 "$RC" "symlinked parent is canonicalized"
canonical_target=$(cd "$tmp/real-parent/target" && pwd -P)
printf '%s' "$OUT" | grep -qF "cwd: $canonical_target" && pass "canonical target path is persisted" || fail "target path remained aliased"

echo "Case 6: invalid or missing required values fail"
run_launcher "$tmp/plain.txt" --terminal bad --cwd "$tmp" --agent amp --dry-run
expect_rc 1 "$RC" "invalid terminal"
run_launcher "$tmp/plain.txt" --terminal iterm --agent amp --dry-run
expect_rc 1 "$RC" "missing cwd"
: > "$tmp/empty.txt"
run_launcher "$tmp/empty.txt" --terminal iterm --cwd "$tmp" --agent amp --dry-run
expect_rc 1 "$RC" "empty prompt"

echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
