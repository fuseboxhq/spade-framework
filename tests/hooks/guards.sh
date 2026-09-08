#!/usr/bin/env bash
set -euo pipefail

# Fixture tests for bin/spade-guard. Each case pipes one hook event into the
# helper inside a throwaway project and asserts allow (empty stdout) or deny.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
GUARD="$REPO_ROOT/bin/spade-guard"
tmp=$(mktemp -d "${TMPDIR:-/tmp}/spade-guard-test.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
project="$tmp/project"
stubs="$tmp/stubs"
mkdir -p "$project/.spade" "$stubs"
session="test-session"
fail=0

write_config() {
    # Arguments: merge policy, deny_stage_all. Writes a minimal .spade/config.
    cat > "$project/.spade/config" <<EOF
mode: local
autonomy:
  default: deliver
  deliver:
    merge: $1
guards:
  deny_stage_all: $2
EOF
}

run_guard() {
    # Arguments: event JSON. Prints the helper's stdout with the test project as root.
    printf '%s' "$1" | CLAUDE_PROJECT_DIR="$project" PATH="$stubs:$PATH" "$GUARD"
}

pre_tool() {
    # Arguments: tool name, tool_input JSON. Prints a PreToolUse event.
    jq -cn --arg tool "$1" --arg session "$session" --argjson input "$2" \
        '{hook_event_name: "PreToolUse", session_id: $session, tool_name: $tool, tool_input: $input}'
}

expect_deny() {
    # Arguments: label, output. Passes when the output is a deny decision.
    if printf '%s' "$2" | jq -e '.hookSpecificOutput.permissionDecision == "deny"' >/dev/null 2>&1; then
        echo "  ok:   deny  $1"
    else
        echo "  FAIL: expected deny for $1, got: ${2:-<empty>}"
        fail=$((fail + 1))
    fi
}

expect_allow() {
    # Arguments: label, output. Passes when the helper stayed silent.
    if [ -z "$2" ]; then
        echo "  ok:   allow $1"
    else
        echo "  FAIL: expected allow for $1, got: $2"
        fail=$((fail + 1))
    fi
}

set_mode() {
    mkdir -p "$project/.spade/guard/$session"
    printf '%s\n' "$1" > "$project/.spade/guard/$session/mode"
}

clear_mode() {
    rm -f "$project/.spade/guard/$session/mode"
}

# gh stub: GH_STUB_VIEW holds the JSON `gh pr view` returns.
cat > "$stubs/gh" <<'EOF'
#!/usr/bin/env bash
case "$*" in
    *"--json number"*) printf '%s\n' "${GH_STUB_NUMBER:-41}" ;;
    *"pr view"*) printf '%s\n' "${GH_STUB_VIEW:-}" ;;
esac
EOF
chmod +x "$stubs/gh"

echo "spade-guard fixture tests"
write_config human false

# Inert outside a SPADE repository.
pre_tool Bash '{"command":"git add -A"}' > "$tmp/inert.json"
out=$(CLAUDE_PROJECT_DIR="$tmp" "$GUARD" < "$tmp/inert.json")
expect_allow "no .spade/config" "$out"

# Session lifecycle.
run_guard "$(jq -cn --arg s "$session" '{hook_event_name:"SessionStart", session_id:$s}')" >/dev/null
[ -f "$project/.spade/guard/$session/live" ] && echo "  ok:   SessionStart writes live marker" || { echo "  FAIL: live marker missing"; fail=$((fail + 1)); }

# Closing an issue is the agent's own call once Evaluate records PASS, so
# no guard stands between it and any tracker state.
expect_allow "parent moved to Done" "$(run_guard "$(pre_tool mcp__linear__save_issue '{"id":"PS-1","state":"Done"}')")"
expect_allow "parent moved to canceled" "$(run_guard "$(pre_tool mcp__linear__save_issue '{"id":"PS-1","state":"canceled"}')")"
expect_allow "sub-issue moved to Done" "$(run_guard "$(pre_tool mcp__linear__save_issue '{"id":"PS-2","state":"Done","parentId":"PS-1"}')")"
expect_allow "parent moved to Delivering" "$(run_guard "$(pre_tool mcp__linear__save_issue '{"id":"PS-1","state":"Delivering"}')")"

# Protected-path guard by mode.
clear_mode
expect_allow "no marker, edit src/auth/login.ts" "$(run_guard "$(pre_tool Edit "{\"file_path\":\"$project/src/auth/login.ts\"}")")"
set_mode quick
expect_deny "quick, edit src/auth/login.ts" "$(run_guard "$(pre_tool Edit "{\"file_path\":\"$project/src/auth/login.ts\"}")")"
expect_deny "quick, write .github/workflows/ci.yml" "$(run_guard "$(pre_tool Write "{\"file_path\":\"$project/.github/workflows/ci.yml\"}")")"
expect_deny "quick, edit AGENTS.md" "$(run_guard "$(pre_tool Edit "{\"file_path\":\"$project/AGENTS.md\"}")")"
expect_allow "quick, edit README.md" "$(run_guard "$(pre_tool Edit "{\"file_path\":\"$project/README.md\"}")")"
set_mode unhinged
expect_deny "unhinged, edit db/migrations/001.sql" "$(run_guard "$(pre_tool Edit "{\"file_path\":\"$project/db/migrations/001.sql\"}")")"
set_mode deliver
expect_allow "deliver, edit src/auth/login.ts" "$(run_guard "$(pre_tool Edit "{\"file_path\":\"$project/src/auth/login.ts\"}")")"
expect_allow "deliver, edit AGENTS.md" "$(run_guard "$(pre_tool Edit "{\"file_path\":\"$project/AGENTS.md\"}")")"
expect_deny "deliver, write .env.production" "$(run_guard "$(pre_tool Write "{\"file_path\":\"$project/.env.production\"}")")"
expect_deny "deliver, edit .spade/config" "$(run_guard "$(pre_tool Edit "{\"file_path\":\"$project/.spade/config\"}")")"
expect_deny "deliver, edit .claude/settings.json" "$(run_guard "$(pre_tool Edit "{\"file_path\":\"$project/.claude/settings.json\"}")")"
expect_deny "deliver, edit bin/spade-guard" "$(run_guard "$(pre_tool Edit "{\"file_path\":\"$project/bin/spade-guard\"}")")"
expect_deny "deliver, notebook in data/production" "$(run_guard "$(pre_tool NotebookEdit "{\"notebook_path\":\"$project/data/production/fix.ipynb\"}")")"
expect_deny "deliver, traversal to .spade/config" "$(run_guard "$(pre_tool Edit "{\"file_path\":\"$project/tmp/../.spade/config\"}")")"
expect_deny "deliver, relative traversal to .spade/config" "$(run_guard "$(pre_tool Edit "{\"file_path\":\"docs/../.spade/config\"}")")"
expect_deny "deliver, shipped plugin guard copy" "$(run_guard "$(pre_tool Edit "{\"file_path\":\"$project/plugins/spade-framework/scripts/spade-guard\"}")")"
expect_deny "deliver, path escaping the project" "$(run_guard "$(pre_tool Write "{\"file_path\":\"$project/../elsewhere/notes.md\"}")")"
expect_allow "deliver, dotted segments inside a safe path" "$(run_guard "$(pre_tool Edit "{\"file_path\":\"$project/docs/./guide/../README.md\"}")")"
clear_mode

# Path classification: the project fixture above has .spade/config but no
# src/CAPABILITIES.md and no src/skills, so it stands in for a consumer repo.
# A second fixture carries the framework's own layout.
framework="$tmp/framework"
mkdir -p "$framework/.spade/guard/$session" "$framework/src/skills"
cp "$project/.spade/config" "$framework/.spade/config"
printf 'version: 9.9.9\n' > "$framework/src/CAPABILITIES.md"

classify() {
    # Arguments: root, mode, path. Prints the guard's decision for a Write.
    printf '%s\n' "$2" > "$1/.spade/guard/$session/mode"
    jq -cn --arg p "$1/$3" --arg s "$session" \
        '{hook_event_name:"PreToolUse",session_id:$s,tool_name:"Write",tool_input:{file_path:$p}}' \
        | CLAUDE_PROJECT_DIR="$1" PATH="$stubs:$PATH" "$GUARD"
}

# Ordinary application files in a consumer repo must not read as protected.
for ordinary in src/pages/Dashboard.tsx src/lib/keyboard.ts src/queue/processor.ts \
                src/img/preprocessor.py src/lib/tokenizer.ts src/parser/tokenize.go \
                docs/tokenization.md src/db/oracle.ts src/util/hashmap.ts \
                src/lib/miami-tz.ts src/components/BarChart.tsx; do
    expect_allow "consumer quick, $ordinary" "$(classify "$project" quick "$ordinary")"
done

# The words that genuinely name the surface still classify.
for protected in src/auth/login.ts src/auth/access-token.ts config/secrets/api.enc \
                 .env.production src/crypto/sign.ts infra/iam-policy.json k8s/rbac.yaml \
                 db/schema.ts db/migrations/001.sql .github/workflows/ci.yml \
                 terraform/net.tf helm/app/values.yaml CHANGELOG.md AGENTS.md \
                 CLAUDE.md docs/FRAMEWORK.md; do
    expect_deny "consumer quick, $protected" "$(classify "$project" quick "$protected")"
done

# The framework's own layout is governance only inside the framework repository.
for layout in src/skills/spade/SKILL.md skills/spade/SKILL.md agents/spade-researcher.md \
              bin/spade-update-check setup setup.ps1 fragments/AGENTS-section.md; do
    expect_allow "consumer quick, $layout" "$(classify "$project" quick "$layout")"
    expect_deny "framework quick, $layout" "$(classify "$framework" quick "$layout")"
done
expect_allow "framework quick, README.md" "$(classify "$framework" quick README.md)"

# camelCase is idiomatic in the stacks this runs against, so a glued term must
# still classify.
for camel in src/auth/accessToken.ts src/api/refreshToken.ts src/lib/sessionSecretStore.ts src/lib/jwtLoader.ts; do
    expect_deny "consumer quick, $camel" "$(classify "$project" quick "$camel")"
done

# Well-known credential files carry no category word at all.
for credential in .ssh/authorized_keys .ssh/id_rsa .ssh/id_ed25519 .npmrc .netrc .pgpass \
                  kubeconfig deploy/cluster.kubeconfig config/api-keys.json src/lib/signing-key.pem; do
    expect_deny "consumer quick, $credential" "$(classify "$project" quick "$credential")"
done

# The word `key` must not swallow ordinary names built from it.
for keyish in src/lib/keyboard.ts src/ui/HotkeyBar.tsx src/lib/keymap.json; do
    expect_allow "consumer quick, $keyish" "$(classify "$project" quick "$keyish")"
done

# Deliver mode still narrows, but a glued secret and a credential file reach it.
expect_deny "consumer deliver, src/auth/accessToken.ts" "$(classify "$project" deliver src/auth/accessToken.ts)"
expect_deny "consumer deliver, .ssh/id_rsa" "$(classify "$project" deliver .ssh/id_rsa)"
expect_allow "consumer deliver, src/lib/keyboard.ts" "$(classify "$project" deliver src/lib/keyboard.ts)"

# An acronym running into a word must separate too.
for acronym in src/db/DBCredentials.ts src/lib/SSHKeyLoader.ts src/lib/AWSSecretManager.ts \
               src/policy/IAMPolicy.ts src/net/TLSCertStore.ts; do
    expect_deny "consumer quick, $acronym" "$(classify "$project" quick "$acronym")"
done

# `key` on its own is an ordinary database word; it only reads as a credential
# next to one.
for ordinary_key in src/db/primaryKey.ts src/db/foreignKey.ts src/models/sortKey.ts src/db/partitionKey.ts; do
    expect_allow "consumer quick, $ordinary_key" "$(classify "$project" quick "$ordinary_key")"
    expect_allow "consumer deliver, $ordinary_key" "$(classify "$project" deliver "$ordinary_key")"
done
for credential_key in config/api-keys.json src/auth/apiKey.ts src/lib/privateKey.ts deploy/service-account-key.json; do
    expect_deny "consumer quick, $credential_key" "$(classify "$project" quick "$credential_key")"
done

# A context word must be credential-specific. Ordinary storage and permission
# key names must survive Deliver, where a false deny halts an unattended run.
for storage_key in src/session/keys.ts src/store/sessionKeys.ts src/store/rootKeys.ts src/access/permissionKeys.ts; do
    expect_allow "consumer deliver, $storage_key" "$(classify "$project" deliver "$storage_key")"
done
for real_key in src/auth/apiKey.ts src/lib/privateKey.ts deploy/service-account-key.json; do
    expect_deny "consumer deliver, $real_key" "$(classify "$project" deliver "$real_key")"
done

# A `service` layer directory is not a credential context; a service-account
# file is, and is named directly.
for service_layer in src/service/i18n/translationKeys.ts internal/service/routes/routeKeys.go src/service/cache/queryKeys.ts; do
    expect_allow "consumer deliver, $service_layer" "$(classify "$project" deliver "$service_layer")"
done
for service_account in gcp/service-account.json k8s/serviceaccount.yaml; do
    expect_deny "consumer deliver, $service_account" "$(classify "$project" deliver "$service_account")"
done

# Unhinged mode carries the same full surface as quick.
for ordinary in src/pages/Dashboard.tsx src/lib/keyboard.ts src/queue/processor.ts; do
    expect_allow "consumer unhinged, $ordinary" "$(classify "$project" unhinged "$ordinary")"
done
for protected in src/auth/login.ts .env.production AGENTS.md; do
    expect_deny "consumer unhinged, $protected" "$(classify "$project" unhinged "$protected")"
done

# Every term the Scope names, each on a path where only that term can match.
for term in src/api/api_token.ts config/tokens/rotate.ts src/oauth/client.ts \
            src/auth/sso-callback.ts security/acl.ts src/lib/deployment.ts \
            scripts/deploy-app.sh db/migrate-users.ts; do
    expect_deny "consumer quick, $term" "$(classify "$project" quick "$term")"
done

# Deliver mode still narrows to the three hard categories, and the words that
# used to over-match no longer reach it.
for allowed in src/lib/tokenizer.ts src/queue/processor.ts src/auth/login.ts db/schema.ts AGENTS.md; do
    expect_allow "consumer deliver, $allowed" "$(classify "$project" deliver "$allowed")"
done
for denied in .env.production data/production/fix.ipynb .spade/config .claude/settings.json; do
    expect_deny "consumer deliver, $denied" "$(classify "$project" deliver "$denied")"
done
rm -f "$project/.spade/guard/$session/mode"

# Stage-all guard.
expect_allow "git add -A with deny_stage_all off" "$(run_guard "$(pre_tool Bash '{"command":"git add -A"}')")"
write_config human true
expect_deny "git add -A" "$(run_guard "$(pre_tool Bash '{"command":"git add -A"}')")"
expect_deny "git add --all after cd" "$(run_guard "$(pre_tool Bash '{"command":"cd x && git add --all && git commit"}')")"
expect_deny "git add ." "$(run_guard "$(pre_tool Bash '{"command":"git add . "}')")"
expect_allow "git add explicit path" "$(run_guard "$(pre_tool Bash '{"command":"git add AGENTS.md docs/FRAMEWORK.md"}')")"
expect_allow "git add path ending in .md" "$(run_guard "$(pre_tool Bash '{"command":"git add ./README.md"}')")"
expect_deny "git add with a quoted flag" "$(run_guard "$(pre_tool Bash '{"command":"git add \"-A\""}')")"
expect_deny "git add with a single-quoted flag" "$(run_guard "$(pre_tool Bash "{\"command\":\"git add '-A'\"}")")"
expect_deny "git add behind a -c global option" "$(run_guard "$(pre_tool Bash '{"command":"git -c core.pager=cat add -A"}')")"
expect_deny "git add behind an env assignment" "$(run_guard "$(pre_tool Bash '{"command":"GIT_DIR=x git add -A"}')")"
expect_deny "git add -- ." "$(run_guard "$(pre_tool Bash '{"command":"git add -- ."}')")"
expect_allow "a command that merely mentions git add -A" "$(run_guard "$(pre_tool Bash '{"command":"echo \"git add -A\""}')")"
expect_allow "git add with a quoted path" "$(run_guard "$(pre_tool Bash '{"command":"git add \"docs/my file.md\""}')")"
expect_allow "a commit message that mentions the flag" "$(run_guard "$(pre_tool Bash '{"command":"git commit -m \"we removed git add -A from the docs\""}')")"
expect_deny "git add with a backslash-escaped flag" "$(run_guard "$(pre_tool Bash '{"command":"git add \\-A"}')")"
expect_deny "git add with an ANSI-C quoted flag" "$(run_guard "$(pre_tool Bash "$(jq -cn --arg c "git add \$'-A'" '{command:$c}')")")"
expect_deny "git add behind a backslash-escaped name" "$(run_guard "$(pre_tool Bash '{"command":"\\git add -A"}')")"
expect_deny "git add behind env" "$(run_guard "$(pre_tool Bash '{"command":"env git add -A"}')")"
expect_deny "git add behind command" "$(run_guard "$(pre_tool Bash '{"command":"command git add -A"}')")"
expect_deny "git add behind sudo" "$(run_guard "$(pre_tool Bash '{"command":"sudo git add -A"}')")"
expect_deny "git add behind xargs" "$(run_guard "$(pre_tool Bash '{"command":"xargs git add -A"}')")"
expect_allow "xargs git add with explicit paths" "$(run_guard "$(pre_tool Bash '{"command":"git status --porcelain | xargs git add --"}')")"
expect_deny "git add behind a wrapper with its own flag" "$(run_guard "$(pre_tool Bash '{"command":"sudo -n git add -A"}')")"
expect_deny "git add behind nice and its value flag" "$(run_guard "$(pre_tool Bash '{"command":"nice -n 10 git add -A"}')")"
expect_deny "git add behind xargs and its own flag" "$(run_guard "$(pre_tool Bash '{"command":"xargs -I{} git add -A"}')")"
expect_allow "a plain git status" "$(run_guard "$(pre_tool Bash '{"command":"git status"}')")"
expect_deny "a chained stage-all after an escaped quote" "$(run_guard "$(pre_tool Bash "$(jq -cn --arg c 'git commit -m "say \\"hi\\""; git add -A' '{command:$c}')")")"
expect_deny "a chained stage-all after an escaped quote and &&" "$(run_guard "$(pre_tool Bash "$(jq -cn --arg c 'git commit -m "a \\"b\\" c" && git add --all' '{command:$c}')")")"
expect_allow "a commit message containing an escaped quote" "$(run_guard "$(pre_tool Bash "$(jq -cn --arg c 'git commit -m "say \\"hi\\""' '{command:$c}')")")"
expect_allow "a substitution mentioned inside single quotes" "$(run_guard "$(pre_tool Bash "$(jq -cn --arg c "git commit -m 'note \$(git add -A) here'" '{command:$c}')")")"
expect_allow "a single-quoted substitution echoed as text" "$(run_guard "$(pre_tool Bash "$(jq -cn --arg c "echo '\$(git add -A)'" '{command:$c}')")")"
expect_deny "a substitution the shell would really run" "$(run_guard "$(pre_tool Bash "$(jq -cn --arg c 'git commit -m "note $(git add -A) here"' '{command:$c}')")")"
expect_deny "a contraction before a real substitution" "$(run_guard "$(pre_tool Bash "$(jq -cn --arg c 'git commit -m "note: don'"'"'t run $(git add -A) here"' '{command:$c}')")")"
expect_allow "a contraction in an ordinary message" "$(run_guard "$(pre_tool Bash "$(jq -cn --arg c 'git commit -m "don'"'"'t break this"' '{command:$c}')")")"

# Merge guard.
write_config human false
expect_deny "gh pr merge under human policy" "$(run_guard "$(pre_tool Bash '{"command":"gh pr merge 41 --squash"}')")"
expect_deny "gh api merge under human policy" "$(run_guard "$(pre_tool Bash '{"command":"gh api -X PUT repos/o/r/pulls/41/merge"}')")"
expect_deny "gh pr merge behind a backslash-escaped name" "$(run_guard "$(pre_tool Bash '{"command":"\\gh pr merge 41 --squash"}')")"
expect_deny "gh pr merge with a quoted command name" "$(run_guard "$(pre_tool Bash '{"command":"\"gh\" pr merge 41"}')")"
expect_deny "gh pr merge behind env" "$(run_guard "$(pre_tool Bash '{"command":"env gh pr merge 41"}')")"
expect_deny "gh pr merge behind a wrapper with its own flag" "$(run_guard "$(pre_tool Bash '{"command":"sudo -n gh pr merge 41"}')")"
expect_deny "gh pr merge behind env with its own flag" "$(run_guard "$(pre_tool Bash '{"command":"env -i gh pr merge 41"}')")"
expect_deny "a chained merge after an escaped quote" "$(run_guard "$(pre_tool Bash "$(jq -cn --arg c 'gh pr comment 41 -b "note \\"q\\""; gh pr merge 41 --squash' '{command:$c}')")")"
expect_allow "a command that merely mentions gh pr merge" "$(run_guard "$(pre_tool Bash '{"command":"echo \"gh pr merge 41\""}')")"
expect_allow "gh pr view is not a merge" "$(run_guard "$(pre_tool Bash '{"command":"gh pr view 41"}')")"
write_config on-green false
green='{"isDraft":false,"mergeable":"MERGEABLE","headRefOid":"abc123","statusCheckRollup":[{"conclusion":"SUCCESS"},{"conclusion":"SKIPPED"},{"state":"SUCCESS"}]}'
expect_deny "on-green, no reviewed head recorded" "$(GH_STUB_VIEW="$green" run_guard "$(pre_tool Bash '{"command":"gh pr merge 41 --squash --match-head-commit abc123"}')")"
printf 'abc123\n' > "$project/.spade/guard/reviewed-head-41"
expect_deny "on-green, reviewed head without a verdict" "$(GH_STUB_VIEW="$green" run_guard "$(pre_tool Bash '{"command":"gh pr merge 41 --squash --match-head-commit abc123"}')")"
printf 'abc123 PARTIAL\n' > "$project/.spade/guard/reviewed-head-41"
expect_deny "on-green, PARTIAL verdict" "$(GH_STUB_VIEW="$green" run_guard "$(pre_tool Bash '{"command":"gh pr merge 41 --squash --match-head-commit abc123"}')")"
printf 'abc123 PASS\n' > "$project/.spade/guard/reviewed-head-41"
expect_deny "on-green, merge not pinned to the reviewed head" "$(GH_STUB_VIEW="$green" run_guard "$(pre_tool Bash '{"command":"gh pr merge 41 --squash"}')")"
expect_allow "on-green, PASS, green checks, pinned to reviewed head" "$(GH_STUB_VIEW="$green" run_guard "$(pre_tool Bash '{"command":"gh pr merge 41 --squash --match-head-commit abc123"}')")"
expect_deny "on-green, pin is only a prefix of the reviewed head" "$(GH_STUB_VIEW="$green" run_guard "$(pre_tool Bash '{"command":"gh pr merge 41 --squash --match-head-commit abc123456789extra"}')")"
expect_deny "on-green, pin text is a decoy inside a quoted argument" "$(GH_STUB_VIEW="$green" run_guard "$(pre_tool Bash '{"command":"gh pr merge 41 --squash -t \"see --match-head-commit abc123 in the docs\""}')")"
expect_allow "on-green, pin written with an equals sign" "$(GH_STUB_VIEW="$green" run_guard "$(pre_tool Bash '{"command":"gh pr merge 41 --squash --match-head-commit=abc123"}')")"
expect_deny "on-green, pin supplied by a command substitution" "$(GH_STUB_VIEW="$green" run_guard "$(pre_tool Bash "$(jq -cn --arg c 'gh pr merge 41 --squash --match-head-commit $(git rev-parse HEAD)' '{command:$c}')")")"
expect_allow "on-green, quoted pin to the reviewed head" "$(GH_STUB_VIEW="$green" run_guard "$(pre_tool Bash '{"command":"gh pr merge 41 --squash --match-head-commit \"abc123\""}')")"
expect_allow "on-green, PR resolved from current branch" "$(GH_STUB_VIEW="$green" GH_STUB_NUMBER=41 run_guard "$(pre_tool Bash '{"command":"gh pr merge --squash --match-head-commit=abc123"}')")"
printf 'def456 PASS\n' > "$project/.spade/guard/reviewed-head-41"
expect_deny "on-green, head moved after review" "$(GH_STUB_VIEW="$green" run_guard "$(pre_tool Bash '{"command":"gh pr merge 41 --squash --match-head-commit def456"}')")"
printf 'abc123 PASS\n' > "$project/.spade/guard/reviewed-head-41"
expect_deny "on-green, draft PR" "$(GH_STUB_VIEW='{"isDraft":true,"mergeable":"MERGEABLE","headRefOid":"abc123","statusCheckRollup":[{"conclusion":"SUCCESS"}]}' run_guard "$(pre_tool Bash '{"command":"gh pr merge 41 --match-head-commit abc123"}')")"
expect_deny "on-green, failing check" "$(GH_STUB_VIEW='{"isDraft":false,"mergeable":"MERGEABLE","headRefOid":"abc123","statusCheckRollup":[{"conclusion":"SUCCESS"},{"conclusion":"FAILURE"}]}' run_guard "$(pre_tool Bash '{"command":"gh pr merge 41 --match-head-commit abc123"}')")"
expect_deny "on-green, pending check" "$(GH_STUB_VIEW='{"isDraft":false,"mergeable":"MERGEABLE","headRefOid":"abc123","statusCheckRollup":[{"status":"IN_PROGRESS"}]}' run_guard "$(pre_tool Bash '{"command":"gh pr merge 41 --match-head-commit abc123"}')")"
expect_deny "on-green, empty rollup" "$(GH_STUB_VIEW='{"isDraft":false,"mergeable":"MERGEABLE","headRefOid":"abc123","statusCheckRollup":[]}' run_guard "$(pre_tool Bash '{"command":"gh pr merge 41 --match-head-commit abc123"}')")"
expect_deny "on-green, not mergeable" "$(GH_STUB_VIEW='{"isDraft":false,"mergeable":"CONFLICTING","headRefOid":"abc123","statusCheckRollup":[{"conclusion":"SUCCESS"}]}' run_guard "$(pre_tool Bash '{"command":"gh pr merge 41 --match-head-commit abc123"}')")"
expect_deny "on-green, gh returns nothing" "$(GH_STUB_VIEW='' run_guard "$(pre_tool Bash '{"command":"gh pr merge 41 --match-head-commit abc123"}')")"
expect_deny "on-green, glab merge unsupported" "$(run_guard "$(pre_tool Bash '{"command":"glab mr merge 7"}')")"

# Missing jq denies loudly.
mkdir -p "$tmp/nojq"
for t in bash sh awk sed grep head tr date mkdir rm cat printf; do
    p=$(command -v "$t" 2>/dev/null) && ln -sf "$p" "$tmp/nojq/$t" || true
done
if printf '%s' "$(pre_tool Bash '{"command":"ls"}')" | CLAUDE_PROJECT_DIR="$project" PATH="$tmp/nojq" bash "$GUARD" 2>/dev/null; then
    echo "  FAIL: missing jq should exit 2"
    fail=$((fail + 1))
else
    echo "  ok:   missing jq exits non-zero"
fi

# SessionEnd cleans up.
run_guard "$(jq -cn --arg s "$session" '{hook_event_name:"SessionEnd", session_id:$s}')" >/dev/null
[ ! -d "$project/.spade/guard/$session" ] && echo "  ok:   SessionEnd removes session dir" || { echo "  FAIL: session dir survived SessionEnd"; fail=$((fail + 1)); }

echo
echo "spade-guard: $fail failure(s)"
[ "$fail" -eq 0 ] || exit 1
