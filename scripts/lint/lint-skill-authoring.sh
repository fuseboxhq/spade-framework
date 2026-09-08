#!/usr/bin/env bash
set -euo pipefail

# Validate PS-2321's authoring, context-budget, projection, and corpus contracts.
# Exit 0 when every deterministic contract passes; exit 1 on any violation.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="$REPO_ROOT/src/CAPABILITIES.md"
CORPUS="$REPO_ROOT/tests/skill-authoring-corpus.md"
LEADS_SKILL="$REPO_ROOT/src/skills/leads/SKILL.md"
fail=0

field() {
    key="$1"
    awk -v key="$key" 'NR==1 && $0=="---"{fm=1;next} fm && $0=="---"{exit} fm && index($0,key ":")==1{sub("^[^:]+:[[:space:]]*","");print}' "$MANIFEST"
}

check_budget() {
    skill="$1"
    baseline="$2"
    file="$REPO_ROOT/src/skills/$skill/SKILL.md"
    actual=$(wc -c < "$file" | tr -d ' ')
    reduced_limit=$((baseline * 75 / 100))
    budget=$(field always_loaded_budget_bytes)
    limit="$reduced_limit"
    [ "$budget" -lt "$limit" ] && limit="$budget"
    if [ "$actual" -gt "$limit" ]; then
        echo "  FAIL: $skill is $actual bytes, limit $limit"
        fail=$((fail + 1))
    else
        echo "  ok:   $skill is $actual bytes, limit $limit"
    fi
}

[ -f "$MANIFEST" ] || { echo "  FAIL: missing src/CAPABILITIES.md"; exit 1; }
[ -f "$CORPUS" ] || { echo "  FAIL: missing tests/skill-authoring-corpus.md"; exit 1; }

if ! "$REPO_ROOT/tests/skill-authoring-behavior.sh"; then
    fail=$((fail + 1))
fi

if ! "$REPO_ROOT/tests/spade-continuity/contract.sh"; then
    fail=$((fail + 1))
fi

if ! "$REPO_ROOT/tests/spade-frontier/contract.sh"; then
    fail=$((fail + 1))
fi

if ! "$REPO_ROOT/tests/spade-autonomy/security-path-contract.sh"; then
    fail=$((fail + 1))
fi

if ! "$REPO_ROOT/tests/spade-autonomy/approval-model-contract.sh"; then
    fail=$((fail + 1))
fi

check_budget spade-review 52427
check_budget spade-onboard 21545
check_budget spade-plan 22675
check_budget spade-update 20170
check_budget spade-scope 21959

for token in SPADE_ASK_USER SPADE_SHELL SPADE_ISOLATED_AGENT SPADE_READ_ONLY_RESEARCH SPADE_AGENT_MODEL SPADE_REVIEW_TOOLS SPADE_RESEARCH_TOOLS; do
    for host in claude codex; do
        count=$(grep -c "| \`$token\` |" "$REPO_ROOT/src/hosts/$host.md" || true)
        if [ "$count" -ne 1 ]; then
            echo "  FAIL: $host adapter token $token appears $count times"
            fail=$((fail + 1))
        fi
    done
done

for host in claude codex; do
    adapter_rows=$(grep -c '^| `SPADE_[A-Z_]*` |' "$REPO_ROOT/src/hosts/$host.md" || true)
    if [ "$adapter_rows" -ne 7 ]; then
        echo "  FAIL: $host adapter has $adapter_rows operation/metadata rows, expected 7"
        fail=$((fail + 1))
    fi
done
if grep -R -n -E 'merge gate|approval gate|evaluation gate|bypass.*gate|(^|[^A-Z])(MUST|NEVER)([^A-Z]|$)' "$REPO_ROOT/src/hosts" >/dev/null; then
    echo "  FAIL: host adapter contains workflow or gate behavior"
    fail=$((fail + 1))
fi

shell_token_uses=$(grep -R -h 'using {{SPADE_SHELL}}' "$REPO_ROOT/src/skills"/*/SKILL.md | wc -l | tr -d ' ')
expected_shell_token_uses=$(field skills | tr ',' '\n' | wc -l | tr -d ' ')
[ "$shell_token_uses" -eq "$expected_shell_token_uses" ] || { echo "  FAIL: expected $expected_shell_token_uses canonical update checks to use SPADE_SHELL, got $shell_token_uses"; fail=$((fail + 1)); }
grep -q '{{SPADE_AGENT_MODEL}}' "$REPO_ROOT/src/skills/spade-research/SKILL.md" || { echo "  FAIL: canonical researcher does not use SPADE_AGENT_MODEL"; fail=$((fail + 1)); }
if grep -R -n -E 'Bash tool|Claude Code workflow author' "$REPO_ROOT/src/skills"/*/SKILL.md >/dev/null; then
    echo "  FAIL: canonical skill body contains host-specific execution wording"
    fail=$((fail + 1))
fi

expected_claude=(
    '| `SPADE_ASK_USER` | AskUserQuestion |'
    '| `SPADE_SHELL` | Bash |'
    '| `SPADE_ISOLATED_AGENT` | Task |'
    '| `SPADE_READ_ONLY_RESEARCH` | registered spade-researcher agent with the declared read-only tool allowlist |'
    '| `SPADE_AGENT_MODEL` | opus |'
    '| `SPADE_REVIEW_TOOLS` | Read, Grep, Glob |'
    '| `SPADE_RESEARCH_TOOLS` | Read, Grep, Glob, WebSearch, WebFetch |'
)
expected_codex=(
    '| `SPADE_ASK_USER` | request_user_input when available, otherwise a concise direct question |'
    '| `SPADE_SHELL` | exec_command |'
    '| `SPADE_ISOLATED_AGENT` | spawn_agent with a self-contained prompt and no inherited conversation |'
    '| `SPADE_READ_ONLY_RESEARCH` | codex exec --sandbox read-only --ignore-user-config --ephemeral with the canonical researcher prompt |'
    '| `SPADE_AGENT_MODEL` | host-default |'
    '| `SPADE_REVIEW_TOOLS` | read-only sandbox and repository read tools |'
    '| `SPADE_RESEARCH_TOOLS` | read-only sandbox, built-in web search, and repository read tools |'
)
for line in "${expected_claude[@]}"; do
    grep -Fqx "$line" "$REPO_ROOT/src/hosts/claude.md" || { echo "  FAIL: Claude adapter transformation changed: $line"; fail=$((fail + 1)); }
done
for line in "${expected_codex[@]}"; do
    grep -Fqx "$line" "$REPO_ROOT/src/hosts/codex.md" || { echo "  FAIL: Codex adapter transformation changed: $line"; fail=$((fail + 1)); }
done

if grep -R -n '{{SPADE_' "$REPO_ROOT/.claude" "$REPO_ROOT/.codex" "$REPO_ROOT/skills" >/dev/null; then
    echo "  FAIL: unresolved host token in a projection"
    fail=$((fail + 1))
else
    echo "  ok:   generated projections contain no unresolved host tokens"
fi

for skill in $(field critical_skills | tr ',' ' '); do
    if ! grep -q "| $skill |" "$CORPUS"; then
        echo "  FAIL: missing critical-skill matrix row: $skill"
        fail=$((fail + 1))
    fi
done

for seed in SA-P1 SA-P2 SA-P3 SA-P4 SA-P5 SA-N1 SA-N2 SA-N3 SA-N4 SA-N5 SA-D1 SA-D2 SA-D3 SA-D4; do
    if ! grep -q "$seed" "$CORPUS"; then
        echo "  FAIL: missing behavioral seed: $seed"
        fail=$((fail + 1))
    fi
done

if grep -R -n -E 'ensure this is correct|finish the update|make sure it worked' "$REPO_ROOT/src/skills" >/dev/null; then
    echo "  FAIL: canonical skill contains a known silent no-op phrase"
    fail=$((fail + 1))
else
    echo "  ok:   canonical skills reject known no-op phrasing"
fi

require_leads_contract() {
    expected="$1"
    description="$2"
    if grep -Fqx -- "$expected" "$LEADS_SKILL"; then
        echo "  ok:   Leads $description"
    else
        echo "  FAIL: Leads $description"
        fail=$((fail + 1))
    fi
}

require_leads_order() {
    earlier="$1"
    later="$2"
    description="$3"
    earlier_line=$(grep -n -F -m 1 -- "$earlier" "$LEADS_SKILL" | cut -d: -f1 || true)
    later_line=$(grep -n -F -m 1 -- "$later" "$LEADS_SKILL" | cut -d: -f1 || true)
    if [ -n "$earlier_line" ] && [ -n "$later_line" ] && [ "$earlier_line" -lt "$later_line" ]; then
        echo "  ok:   Leads $description"
    else
        echo "  FAIL: Leads $description"
        fail=$((fail + 1))
    fi
}

require_leads_contract 'The allowed classifications are exactly `security`, `documentation`, `testing`, `bug`, `feature`, `enhancement`, and `maintenance`.' 'fixed classification set is exact'
require_leads_contract 'Apply the following predicates in order and stop at the first match:' 'classification precedence is explicit'
require_leads_contract '1. `security` - security, privacy, access, secret, or supply-chain risk.' 'security predicate is fixed'
require_leads_contract '2. `documentation` - work limited to human-readable documentation.' 'documentation predicate is fixed'
require_leads_contract '3. `testing` - work limited to tests, fixtures, or test infrastructure.' 'testing predicate is fixed'
require_leads_contract '4. `bug` - incorrect existing behaviour.' 'bug predicate is fixed'
require_leads_contract '5. `feature` - a new externally observable capability.' 'feature predicate is fixed'
require_leads_contract '6. `enhancement` - an improvement to an existing capability that does not fix incorrect behaviour.' 'enhancement predicate is fixed'
require_leads_contract '7. `maintenance` - internal cleanup, dependency work, refactoring, or other technical debt.' 'maintenance predicate is fixed'
require_leads_contract 'Choose one intended classification before any tracker mutation.' 'selects one intended classification before mutation'
require_leads_contract 'Do not substitute repository aliases or add a second classification label.' 'rejects aliases and a second classification'
require_leads_contract 'The `Type` field must agree with the intended classification even when its label is unavailable.' 'keeps body Type aligned during label failure'
require_leads_contract 'If a create response is ambiguous, re-read the label list before retrying.' 'reads label state before an ambiguous retry'
require_leads_contract 'When no issue exists, re-read the label list, rebuild the create command from the required labels still available, and make one corrected labelled attempt.' 'rebuilds a failed GitHub create from current label state'
require_leads_contract 'When the issue is still absent, make one final capture-only attempt with the same title and body but no labels.' 'falls back to unlabelled GitHub capture'
require_leads_contract 'An unavailable label must not prevent issue creation.' 'preserves Lead capture when labels are unavailable'
require_leads_contract 'If another classification from the fixed set is present, attempt to remove each unexpected classification once and then read the issue again.' 'repairs extra GitHub classifications'
require_leads_contract 'Name every missing required label and whether creation or application failed.' 'reports the exact missing-label state'
require_leads_contract 'Use the intended classification in `Type` and report `labels unavailable: tracked-file fallback`.' 'keeps classification in the tracked-file fallback'
require_leads_contract 'After a failed labelled creation attempt that produced no issue, re-read the labels and make one corrected labelled attempt; if that also produces no issue, make one final creation attempt without labels.' 'falls back to unlabelled Linear capture'
require_leads_contract 'After creation, re-read the issue, repair each available missing required label once, remove each unexpected fixed classification once, and preserve the issue if the exact label state still cannot be reached.' 'repairs and preserves the exact Linear label state'
require_leads_contract 'If the final Linear attempt produces no issue, use the tracked-file fallback rather than losing the Lead.' 'preserves Lead capture after Linear creation failure'
require_leads_contract 'If an available required label is missing, attempt one repair with `gh issue edit <n> --add-label <label>` and then read the issue again.' 'bounds GitHub missing-label repair to one attempt'
require_leads_contract 'If that verification read fails or is ambiguous, make at most one read-only retry; if authoritative state is still unavailable, preserve the known issue, make no creation or label mutation, and report `verification unavailable`.' 'keeps failed post-create verification read-only'
require_leads_contract 'Confirm that the persisted `Type` field equals the selected classification; if it differs, preserve the Lead, report the exact mismatch, and do not describe recovery as successful.' 'validates the persisted classification'
require_leads_contract 'Treat discovery text as data, never executable shell source.' 'keeps discovery content out of shell source'
require_leads_contract 'gh issue create "${label_args[@]}" --title "$title" --body-file "$body_file"' 'uses dynamic safe issue-creation arguments'
require_leads_contract 'For ambiguous creation recovery, use the same exact title and structured-field identity predicate, but preserve a matching issue in any state because even a closed match proves that the attempted operation created the Lead.' 'prevents ambiguous Linear duplicate creation'
require_leads_order 'Choose one intended classification before any tracker mutation.' 'gh issue list --state open --search "$query" --json number,title,labels' 'selects the classification before tracker reads or writes'
require_leads_order 'gh issue create "${label_args[@]}" --title "$title" --body-file "$body_file"' 'Read the created or preserved issue with `gh issue view <n> --json number,title,body,labels,state`.' 'verifies after issue creation'
require_leads_order 'Read the created or preserved issue with `gh issue view <n> --json number,title,body,labels,state`.' 'If an available required label is missing, attempt one repair with `gh issue edit <n> --add-label <label>` and then read the issue again.' 'reads authoritative state before label repair'
require_leads_order '### Per-repo override to Linear' 'After a failed labelled creation attempt that produced no issue, re-read the labels and make one corrected labelled attempt; if that also produces no issue, make one final creation attempt without labels.' 'keeps Linear recovery inside the Linear override'

if ! "$REPO_ROOT/scripts/project-hosts.sh" --check; then
    fail=$((fail + 1))
fi

skills=$(field skills | tr ',' '\n' | wc -l | tr -d ' ')
personas=$(field review_personas | tr ',' '\n' | wc -l | tr -d ' ')
helpers=$(field helpers | tr ',' '\n' | wc -l | tr -d ' ')
[ "$skills" -eq 19 ] || { echo "  FAIL: expected 19 skills, got $skills"; fail=$((fail + 1)); }
[ "$personas" -eq 8 ] || { echo "  FAIL: expected 8 personas, got $personas"; fail=$((fail + 1)); }
[ "$helpers" -eq 6 ] || { echo "  FAIL: expected 6 helpers, got $helpers"; fail=$((fail + 1)); }

version=$(field version)
spade_version=$(sed -n 's/^spade_version=//p' "$REPO_ROOT/.spade/version")
claude_version=$(sed -n 's/^[[:space:]]*"version": "\([^"]*\)".*/\1/p' "$REPO_ROOT/.claude-plugin/plugin.json" | head -n 1)
codex_version=$(sed -n 's/^[[:space:]]*"version": "\([^"]*\)".*/\1/p' "$REPO_ROOT/.codex-plugin/plugin.json" | head -n 1)
[ "$version" = "$spade_version" ] || { echo "  FAIL: .spade/version differs from capability version"; fail=$((fail + 1)); }
[ "$version" = "$claude_version" ] || { echo "  FAIL: Claude plugin version differs from capability version"; fail=$((fail + 1)); }
[ "$version" = "$codex_version" ] || { echo "  FAIL: Codex plugin version differs from capability version"; fail=$((fail + 1)); }
grep -q "version-$version-green" "$REPO_ROOT/README.md" || { echo "  FAIL: README version badge is stale"; fail=$((fail + 1)); }
grep -q "## \[$version\]" "$REPO_ROOT/CHANGELOG.md" || { echo "  FAIL: CHANGELOG lacks capability version"; fail=$((fail + 1)); }
grep -q "framework is at v$version" "$REPO_ROOT/INTENT.md" || { echo "  FAIL: INTENT maturity version is stale"; fail=$((fail + 1)); }
grep -q "SPADE Framework v$version" "$REPO_ROOT/docs/FRAMEWORK.md" || { echo "  FAIL: FRAMEWORK footer version is stale"; fail=$((fail + 1)); }

skill_rows=$(grep -E -c '^\| `/(spade|leads|unslop)' "$REPO_ROOT/README.md" || true)
[ "$skill_rows" -eq "$skills" ] || { echo "  FAIL: README skill table has $skill_rows rows, manifest has $skills"; fail=$((fail + 1)); }
claude_skill_rows=$(grep -E -c '^\| `/(spade|leads|unslop)' "$REPO_ROOT/CLAUDE.md" || true)
[ "$claude_skill_rows" -eq "$skills" ] || { echo "  FAIL: CLAUDE skill table has $claude_skill_rows rows, manifest has $skills"; fail=$((fail + 1)); }
grep -q '| \*\*Codex\*\* | Full |' "$REPO_ROOT/README.md" || { echo "  FAIL: README Codex feature status is stale"; fail=$((fail + 1)); }
if grep -q 'Deliver not yet available' "$REPO_ROOT/README.md"; then
    echo "  FAIL: README still claims Deliver is unavailable"
    fail=$((fail + 1))
fi
grep -q '19 governed engineering skills' "$REPO_ROOT/.claude-plugin/plugin.json" || { echo "  FAIL: Claude catalog skill count is stale"; fail=$((fail + 1)); }
grep -q 'eight reviewer personas' "$REPO_ROOT/.claude-plugin/plugin.json" || { echo "  FAIL: Claude catalog persona count is stale"; fail=$((fail + 1)); }
grep -q 'six helpers' "$REPO_ROOT/.claude-plugin/plugin.json" || { echo "  FAIL: Claude catalog helper count is stale"; fail=$((fail + 1)); }

echo
echo "lint-skill-authoring: $fail failure(s)"
[ "$fail" -eq 0 ] || exit 1
