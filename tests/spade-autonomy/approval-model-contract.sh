#!/usr/bin/env bash
set -euo pipefail

# Pin the v5.0.0 approval model: the new clauses are present and the revoked
# clauses are gone across every governing surface. Pairs with tests/hooks/guards.sh,
# which pins the guard helper's behaviour, so prose and check cannot drift apart.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fail=0

require_literal() {
    # Arguments: repo-relative file, literal, label.
    if grep -Fq -- "$2" "$REPO_ROOT/$1"; then
        echo "  ok:   $3"
    else
        echo "  FAIL: $3 (missing in $1)"
        fail=$((fail + 1))
    fi
}

require_absent() {
    # Arguments: repo-relative file, literal, label.
    if grep -Fq -- "$2" "$REPO_ROOT/$1"; then
        echo "  FAIL: $3 (revoked clause still present in $1)"
        fail=$((fail + 1))
    else
        echo "  ok:   $3"
    fi
}

echo "approval-model contract"

# FRAMEWORK.md is the single definition.
require_literal docs/FRAMEWORK.md '### Mechanical guards' 'FRAMEWORK defines mechanical guards once'
require_literal docs/FRAMEWORK.md '**Merge by policy.**' 'Deliver level merges by policy'
require_literal docs/FRAMEWORK.md 'autonomy.deliver.merge: on-green' 'Ship names the on-green policy'
require_literal docs/FRAMEWORK.md '### Fewer prompts by default' 'Asking the Human lists the removed prompts'
require_literal docs/FRAMEWORK.md 'The interview is **draft-first**.' 'Nailed defines draft-first scoping'
require_literal docs/FRAMEWORK.md 'the agent records that verdict itself' 'Evaluate is agent-recorded when fully verifiable'
require_literal docs/FRAMEWORK.md '.spade/guard/<session_id>/live' 'guards-live marker is defined'
require_literal docs/FRAMEWORK.md '**How a path is matched.**' 'FRAMEWORK states the guard matches whole words'
require_literal docs/FRAMEWORK.md "**The framework's own layout is not a consumer's.**" 'FRAMEWORK scopes the framework-layout paths'
require_absent docs/FRAMEWORK.md 'no `autonomy.*` setting may infer or pre-authorize a merge' 'merge pre-authorisation ban revoked'
require_absent docs/FRAMEWORK.md 'A security-path change is never' 'blanket security-path halt revoked'
require_absent docs/FRAMEWORK.md 'and offers no override.' 'Deliver tripwire no-override wording revoked'
require_literal docs/FRAMEWORK.md 'There is no override, allowlist escape, or workflow-specific relaxation.' 'surface itself keeps fail-closed wording'

# Agent operating rules and consumer fragments.
require_literal AGENTS.md '## Mechanical Guards' 'AGENTS carries the guard section'
require_literal AGENTS.md 'autonomy.deliver.merge' 'AGENTS names the merge policy key'
require_absent AGENTS.md 'The human owns the final PASS, PARTIAL, or FAIL verdict' 'AGENTS human-only verdict revoked'
require_literal fragments/AGENTS-section.md '## Mechanical Guards' 'AGENTS fragment carries the guard section'
require_literal fragments/AGENTS-section.md 'autonomy.deliver.merge' 'AGENTS fragment names the merge policy key'
require_absent fragments/AGENTS-section.md 'The human owns the final verdict, Done, and Ship.' 'AGENTS fragment human-only verdict revoked'
require_literal fragments/CLAUDE-section.md 'mechanical guard' 'CLAUDE fragment names the guards'
require_absent fragments/CLAUDE-section.md 'The human owns the final Evaluate verdict, Done, and Ship.' 'CLAUDE fragment human-only verdict revoked'
require_absent CLAUDE.md 'The human owns the final Evaluate verdict, Done, and Ship.' 'repo CLAUDE.md human-only verdict revoked'
require_literal ANTI-PATTERNS.md '**Do not disarm or route around a mechanical guard.**' 'ANTI-PATTERNS forbids disarming guards'
require_literal PATTERNS.md 'bin/spade-guard' 'PATTERNS names the guard exception'

# v5.1.0: closing a Scope follows the recorded verdict, not a human gate.
# Scan the whole canonical tree rather than a list of files, because the first
# pass at this change fixed the sections it edited and left the same rule
# standing in six others.
# Match Done the issue state, not the adjective, so an ordinary sentence about a
# human owning something while a task "is done" cannot trip this. Every leading
# word allows a sentence-initial capital. Kept on one line: an earlier version
# of this used a line continuation, got its backslashes doubled by an edit, and
# passed vacuously for two commits.
stale_pattern='[Nn]ever mark (a|the) parent issue|[Oo]nly humans (do this|transition)|[Hh]umans? owns?[^.]*Done|[Hh]uman-owned Done|[Hh]umans own this transition|[Ll]eave the final move to .done. to the human|owns the final verdict, Done|[Hh]uman transitions the parent|[TtAa]?h?e? ?[Hh]uman (moves|transitions|marks)[^.]*Done|forbids AI from marking a parent issue Done|[Dd]o not mark a parent Scope issue as Done|[Hh]umans own the edges \(intent, Done|Evaluate \(Human\)|own Evaluate, Done, and Ship'
stale_paths="$REPO_ROOT/AGENTS.md $REPO_ROOT/CLAUDE.md $REPO_ROOT/README.md $REPO_ROOT/INTENT.md $REPO_ROOT/ANTI-PATTERNS.md $REPO_ROOT/ARCHITECTURE.md $REPO_ROOT/PATTERNS.md $REPO_ROOT/docs $REPO_ROOT/fragments $REPO_ROOT/src $REPO_ROOT/bin"

# A silent sweep is worth nothing unless it can still see. Prove it both ways
# before trusting the result below.
if printf '%s\n' 'Never mark a parent issue Done. Only humans do this.' | grep -qE "$stale_pattern"; then
    echo "  ok:   the stale-rule sweep still detects a known violation"
else
    echo "  FAIL: the stale-rule sweep no longer detects a known violation"
    fail=$((fail + 1))
fi
if printf '%s\n' 'The human owns the design review until the migration script is done.' | grep -qE "$stale_pattern"; then
    echo "  FAIL: the stale-rule sweep fires on ordinary prose"
    fail=$((fail + 1))
else
    echo "  ok:   the stale-rule sweep leaves ordinary prose alone"
fi

stale=$(grep -rnE "$stale_pattern" $stale_paths 2>/dev/null || true)
if [ -z "$stale" ]; then
    echo "  ok:   no surviving human-owned-Done rule in the canonical tree"
else
    echo "  FAIL: a human-owned-Done rule survives:"
    printf '%s\n' "$stale" | sed "s|$REPO_ROOT/|          |"
    fail=$((fail + 1))
fi
require_absent docs/FRAMEWORK.md 'guards.completed_states' 'completed-state guard row revoked'
require_absent bin/spade-guard 'guard_linear_completion' 'completed-state guard removed from the helper'
require_literal AGENTS.md 'Done follows the Evaluate verdict' 'AGENTS states Done follows the verdict'
require_literal docs/FRAMEWORK.md 'Whoever records a PASS also moves the issue to Done' 'FRAMEWORK states who closes the issue'
require_literal src/skills/spade-evaluate/SKILL.md 'record the PASS first and close on the strength of it' 'evaluate closes on a recorded PASS'
if jq -e '[.hooks.PreToolUse[].matcher] | all(test("mcp__linear__save_issue") | not)' "$REPO_ROOT/src/hooks/hooks.json" >/dev/null 2>&1; then
    echo "  ok:   hooks no longer match the tracker tool"
else
    echo "  FAIL: src/hooks/hooks.json still matches mcp__linear__save_issue"
    fail=$((fail + 1))
fi

# Skills.
require_literal src/skills/spade/SKILL.md '**Arm the guard.**' 'orchestrator arms the deliver guard'
require_literal src/skills/spade/SKILL.md '**Halt or merge by policy.**' 'orchestrator merges by policy'
require_literal src/skills/spade/SKILL.md 'reviewed-head-<pr>' 'orchestrator records the reviewed head'
require_literal src/skills/spade/SKILL.md 'Record `run:halt:deliver` and stop by default.' 'human policy still halts'
require_absent src/skills/spade/SKILL.md 'Merge without explicit human authorization' 'orchestrator absolute merge ban revoked'
require_literal src/skills/spade-evaluate/SKILL.md '[Recorded by: agent | human]' 'evaluate records who set the verdict'
require_literal src/skills/spade-scope/SKILL.md '**Draft first.**' 'scope is draft-first'
require_absent src/skills/spade-scope/SKILL.md 'File in Linear now' 'scope file-versus-draft prompt removed'
require_absent src/skills/spade-scope/SKILL.md 'Yes, run /spade-review on this' 'scope second-opinion prompt removed'
require_absent src/skills/spade-approve/SKILL.md '- *Yes, run /spade-review*' 'approve second-opinion prompt removed'
require_literal src/skills/spade-quick/SKILL.md '**Arm the guard.**' 'quick arms the guard'
require_absent src/skills/spade-quick/SKILL.md 'Continue on quick path' 'quick eligibility prompt removed'
require_literal src/skills/spade-unhinged/SKILL.md "write \`unhinged\` to" 'unhinged arms the guard'
require_literal src/skills/spade-unhinged/SKILL.md 'There is no override.' 'unhinged keeps its no-override gate'
require_literal src/skills/spade-handoff/SKILL.md 'is standing consent' 'handoff treats config autonomy as consent'
require_absent src/skills/spade-handoff/SKILL.md 'per-invocation yes' 'handoff per-invocation confirm removed'
require_literal src/skills/spade-learn/SKILL.md 'Decide it yourself' 'learn classifies public-safety itself'
require_literal src/skills/spade-onboard/SKILL.md 'default: deliver' 'onboard writes the deliver default'

# This repository dogfoods the guards.
require_literal .spade/config 'default: deliver' 'repo config defaults to Deliver'
require_literal .spade/config 'merge: on-green' 'repo config merges on green'
require_literal .spade/config 'deny_stage_all: true' 'repo config denies stage-all'
if jq -e '[.hooks.PreToolUse[].hooks[].command, .hooks.SessionStart[].hooks[].command, .hooks.SessionEnd[].hooks[].command] | all(test("spade-guard"))' "$REPO_ROOT/.claude/settings.json" >/dev/null 2>&1; then
    echo "  ok:   repo settings register spade-guard hooks"
else
    echo "  FAIL: repo .claude/settings.json does not register spade-guard hooks"
    fail=$((fail + 1))
fi
if awk '/^helpers:/{print}' "$REPO_ROOT/src/CAPABILITIES.md" | grep -q 'spade-guard'; then
    echo "  ok:   CAPABILITIES lists spade-guard as a helper"
else
    echo "  FAIL: CAPABILITIES does not list spade-guard"
    fail=$((fail + 1))
fi
[ -f "$REPO_ROOT/hooks/hooks.json" ] && echo "  ok:   Claude payload carries hooks/hooks.json" || { echo "  FAIL: hooks/hooks.json missing from payload"; fail=$((fail + 1)); }

echo
echo "approval-model contract: $fail failure(s)"
[ "$fail" -eq 0 ] || exit 1
