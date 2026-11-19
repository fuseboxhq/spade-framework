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
    # Arguments: merge policy, deny_stage_all, optional merge_partial. Writes a minimal .spade/config.
    cat > "$project/.spade/config" <<EOF
mode: local
autonomy:
  default: deliver
  deliver:
    merge: $1
    merge_partial: ${3:-false}
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

# gh stub: GH_STUB_VIEW holds the JSON `gh pr view` returns, GH_STUB_FILES the
# pages `gh api .../files` returns (default: one ordinary file).
cat > "$stubs/gh" <<'EOF'
#!/usr/bin/env bash
case "$*" in
    *"--json number"*) printf '%s\n' "${GH_STUB_NUMBER:-41}" ;;
    *"pr view"*) printf '%s\n' "${GH_STUB_VIEW:-}" ;;
    *"api --paginate"*"/files"*)
        if [ -n "${GH_STUB_FILES+set}" ]; then printf '%s\n' "$GH_STUB_FILES"
        else printf '%s\n' '[{"filename":"src/app.ts","patch":"+x"}]'; fi ;;
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
[ "$(cat "$project/.spade/guard/$session/repos" 2>/dev/null)" = "$project" ] && echo "  ok:   single repository, SessionStart records only the project" || { echo "  FAIL: single-repository list is not just the project"; fail=$((fail + 1)); }

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
expect_allow "retired unhinged mode is inert, edit db/migrations/001.sql" "$(run_guard "$(pre_tool Edit "{\"file_path\":\"$project/db/migrations/001.sql\"}")")"
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
green='{"isDraft":false,"mergeable":"MERGEABLE","headRefOid":"abc123","changedFiles":1,"statusCheckRollup":[{"conclusion":"SUCCESS"},{"conclusion":"SKIPPED"},{"state":"SUCCESS"}]}'
expect_deny "on-green, no reviewed head recorded" "$(GH_STUB_VIEW="$green" run_guard "$(pre_tool Bash '{"command":"gh pr merge 41 --squash --match-head-commit abc123"}')")"
printf 'abc123\n' > "$project/.spade/guard/reviewed-head-41"
expect_deny "on-green, reviewed head without a verdict" "$(GH_STUB_VIEW="$green" run_guard "$(pre_tool Bash '{"command":"gh pr merge 41 --squash --match-head-commit abc123"}')")"
printf 'abc123 PARTIAL\n' > "$project/.spade/guard/reviewed-head-41"
expect_deny "on-green, PARTIAL verdict" "$(GH_STUB_VIEW="$green" run_guard "$(pre_tool Bash '{"command":"gh pr merge 41 --squash --match-head-commit abc123"}')")"
write_config on-green false true
expect_allow "on-green, PARTIAL verdict with merge_partial" "$(GH_STUB_VIEW="$green" run_guard "$(pre_tool Bash '{"command":"gh pr merge 41 --squash --match-head-commit abc123"}')")"
printf 'abc123 FAIL\n' > "$project/.spade/guard/reviewed-head-41"
expect_deny "on-green, FAIL verdict even with merge_partial" "$(GH_STUB_VIEW="$green" run_guard "$(pre_tool Bash '{"command":"gh pr merge 41 --squash --match-head-commit abc123"}')")"
write_config on-green false
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
# Merge floor: these still need a human merge under on-green.
merge_files() {
    # Arguments: changedFiles count, files JSON. Prints the guard's decision for a pinned PASS merge.
    GH_STUB_VIEW="$(printf '%s' "$green" | jq -c --argjson n "$1" '.changedFiles = $n')" GH_STUB_FILES="$2" \
        run_guard "$(pre_tool Bash '{"command":"gh pr merge 41 --squash --match-head-commit abc123 --body-file pr.md"}')"
}
expect_allow "floor, ordinary code and docs" "$(merge_files 2 '[{"filename":"src/app.ts","patch":"+a"},{"filename":"docs/guide.md","patch":"+b"}]')"
expect_allow "floor, files split across pages" "$(merge_files 2 '[{"filename":"src/a.ts"}][{"filename":"src/b.ts"}]')"
expect_deny "floor, CI workflow" "$(merge_files 1 '[{"filename":".github/workflows/ci.yml","patch":"+x"}]')"
expect_deny "floor, workflow renamed away" "$(merge_files 1 '[{"filename":"docs/ci.yml.off","previous_filename":".github/workflows/ci.yml","status":"renamed"}]')"
expect_deny "floor, secrets" "$(merge_files 1 '[{"filename":"config/.env.production","patch":"+x"}]')"
expect_deny "floor, permission widening" "$(merge_files 1 '[{"filename":".claude/settings.json","patch":"+x"}]')"
expect_deny "floor, production data" "$(merge_files 1 '[{"filename":"scripts/prod/fix_orders.py","patch":"+x"}]')"
expect_allow "floor, auth code merges on-green" "$(merge_files 1 '[{"filename":"src/auth/login.ts","patch":"+x"}]')"
expect_allow "floor, additive SQL migration" "$(merge_files 1 '[{"filename":"db/migrations/002_add_email.sql","patch":"+ALTER TABLE users ADD COLUMN email text;"}]')"
expect_deny "floor, loose match: additive soft-delete column still needs a human" "$(merge_files 1 '[{"filename":"db/migrations/008.sql","patch":"+ALTER TABLE users ADD COLUMN deleted_at timestamp;"}]')"
expect_deny "floor, SQL migration dropping a table" "$(merge_files 1 '[{"filename":"db/migrations/003.sql","patch":"+DROP TABLE users;"}]')"
expect_deny "floor, MySQL MODIFY COLUMN" "$(merge_files 1 '[{"filename":"db/migrations/006.sql","patch":"+ALTER TABLE users MODIFY COLUMN age smallint;"}]')"
expect_deny "floor, Alembic alter_column" "$(merge_files 1 '[{"filename":"alembic/versions/1a2b_x.py","patch":"+    op.alter_column(\"users\", \"email\", type_=sa.String(10))"}]')"
expect_deny "floor, Postgres ALTER without COLUMN" "$(merge_files 1 '[{"filename":"db/migrations/007.sql","patch":"+ALTER TABLE users ALTER email TYPE varchar(10);"}]')"
expect_deny "floor, Django AlterUniqueTogether" "$(merge_files 1 '[{"filename":"app/migrations/0005_x.py","patch":"+        migrations.AlterUniqueTogether(name=\"u\", unique_together=set())"}]')"
expect_deny "floor, Rails remove_column" "$(merge_files 1 '[{"filename":"db/migrate/20261101_x.rb","patch":"+    remove_column :users, :email"}]')"
expect_deny "floor, Alembic drop_table" "$(merge_files 1 '[{"filename":"alembic/versions/1a2b_x.py","patch":"+    op.drop_table(\"users\")"}]')"
expect_deny "floor, Django AlterField" "$(merge_files 1 '[{"filename":"app/migrations/0004_x.py","patch":"+        migrations.AlterField(model_name=\"u\")"}]')"
expect_allow "floor, removed line in a migration is not an added step" "$(merge_files 1 '[{"filename":"db/migrations/004.sql","patch":"-DROP TABLE old;\n+CREATE TABLE t (id int);"}]')"
expect_deny "floor, migration patch unavailable" "$(merge_files 1 '[{"filename":"db/migrations/005.sql"}]')"
expect_deny "floor, fewer files listed than changed" "$(merge_files 101 '[{"filename":"src/app.ts","patch":"+a"}]')"
expect_deny "floor, files call returns nothing" "$(merge_files 1 '')"
expect_deny "floor, gh api error object whose key count matches" "$(merge_files 3 '{"message":"Not Found","documentation_url":"https://docs.github.com/rest","status":"404"}')"
expect_deny "floor, file name with a line break" "$(merge_files 1 '[{"filename":"notes\nreadme.md","patch":"+x"}]')"
write_config on-green false
printf '  human_merge_paths: "billing/**, infra/*.yaml"\n' >> "$project/.spade/config"
expect_deny "floor, owner-listed path" "$(merge_files 1 '[{"filename":"billing/charge.ts","patch":"+x"}]')"
expect_allow "floor, path outside the owner list" "$(merge_files 1 '[{"filename":"src/charge.ts","patch":"+x"}]')"
write_config on-green false
expect_deny "on-green, a second merge chained after a checked one" "$(GH_STUB_VIEW="$green" run_guard "$(pre_tool Bash '{"command":"gh pr merge 41 --squash --match-head-commit abc123; gh pr merge 42 --admin"}')")"
expect_deny "on-green, --repo elsewhere" "$(GH_STUB_VIEW="$green" run_guard "$(pre_tool Bash '{"command":"gh pr merge 41 --repo other/repo --squash --match-head-commit abc123"}')")"
expect_deny "on-green, GH_REPO prefix" "$(GH_STUB_VIEW="$green" run_guard "$(pre_tool Bash '{"command":"GH_REPO=other/repo gh pr merge 41 --squash --match-head-commit abc123"}')")"
expect_deny "on-green, PR URL" "$(GH_STUB_VIEW="$green" run_guard "$(pre_tool Bash '{"command":"gh pr merge https://github.com/other/repo/pull/41 --squash --match-head-commit abc123"}')")"
expect_deny "on-green, --admin" "$(GH_STUB_VIEW="$green" run_guard "$(pre_tool Bash '{"command":"gh pr merge 41 --squash --admin --match-head-commit abc123"}')")"
expect_deny "on-green, pin repeated with another head" "$(GH_STUB_VIEW="$green" run_guard "$(pre_tool Bash '{"command":"gh pr merge 41 --squash --match-head-commit abc123 --match-head-commit def456"}')")"
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

# Session repositories (PS-3305). The guard records the session's repositories
# at the first SessionStart and judges each call by the one it targets.
echo "session repositories"
nl='
'

expect_deny_reason() {
    # Arguments: label, text the reason must contain, output. Passes when the
    # output is a deny decision whose reason contains the text.
    if printf '%s' "$3" | jq -e --arg want "$2" '.hookSpecificOutput.permissionDecision == "deny" and (.hookSpecificOutput.permissionDecisionReason | contains($want))' >/dev/null 2>&1; then
        echo "  ok:   deny  $1"
    else
        echo "  FAIL: expected deny for $1 with a reason containing '$2', got: ${3:-<empty>}"
        fail=$((fail + 1))
    fi
}

check() {
    # Arguments: label, then a command. Passes when the command succeeds.
    label="$1"; shift
    if "$@"; then echo "  ok:   $label"; else echo "  FAIL: $label"; fail=$((fail + 1)); fi
}

absent() {
    # Arguments: paths. Succeeds when none of them exists.
    for p in "$@"; do [ ! -e "$p" ] || return 1; done
}

same_text() {
    # Arguments: file, expected text. Succeeds when the file holds exactly that text.
    [ -f "$1" ] && [ "$(cat "$1")" = "$2" ]
}

make_repo() {
    # Arguments: folder, merge policy (or none), deny_stage_all, optional .git
    # kind: dir (default), file (a worktree), or none (a fixture). Writes a
    # repository with a minimal .spade/config.
    mkdir -p "$1/.spade"
    case "${4:-dir}" in
        dir) mkdir -p "$1/.git" ;;
        file) printf 'gitdir: /elsewhere/.git/worktrees/x\n' > "$1/.git" ;;
    esac
    {
        printf 'mode: local\nautonomy:\n  deliver:\n'
        [ "$2" = none ] || printf '    merge: %s\n' "$2"
        printf 'guards:\n  deny_stage_all: %s\n' "$3"
    } > "$1/.spade/config"
}

guard_at() {
    # Arguments: session folder, event JSON. Prints the helper's stdout with
    # that folder as the session folder.
    printf '%s' "$2" | CLAUDE_PROJECT_DIR="$1" PATH="$stubs:$PATH" "$GUARD"
}

session_event() {
    # Arguments: event name, optional SessionStart source. Prints the event.
    jq -cn --arg e "$1" --arg s "$session" --arg src "${2:-startup}" '{hook_event_name:$e, session_id:$s, source:$src}'
}

arm() {
    # Arguments: repository, mode. Writes that repository's mode marker.
    mkdir -p "$1/.spade/guard/$session"
    printf '%s\n' "$2" > "$1/.spade/guard/$session/mode"
}

# A parent with its own config: the list lives in the parent and names the
# child and grandchild repositories, never a fixture without .git or a hidden folder.
pc="$tmp/pc"
make_repo "$pc" human false none
make_repo "$pc/web" on-green false
make_repo "$pc/libs/core" human false file
make_repo "$pc/fixture" on-green false none
make_repo "$pc/.hidden" on-green false
guard_at "$pc" "$(session_event SessionStart)" >/dev/null
check "parent with a config, live in the parent" test -f "$pc/.spade/guard/$session/live"
check "parent with a config, list names parent, child, and worktree grandchild" same_text "$pc/.spade/guard/$session/repos" "$pc$nl$pc/web$nl$pc/libs/core"
check "parent with a config, nothing written in the children" absent "$pc/web/.spade/guard" "$pc/libs/core/.spade/guard" "$pc/fixture/.spade/guard" "$pc/.hidden/.spade/guard"

# A parent without a config: the markers go only in the children.
pn="$tmp/pn"
make_repo "$pn/a" on-green false
make_repo "$pn/b" human true
make_repo "$pn/c" on-green false none
guard_at "$pn" "$(session_event SessionStart)" >/dev/null
check "parent without a config, live and list in each child" test -f "$pn/a/.spade/guard/$session/live" -a -f "$pn/b/.spade/guard/$session/live"
check "parent without a config, both copies name both children" same_text "$pn/a/.spade/guard/$session/repos" "$pn/a$nl$pn/b"
check "parent without a config, second copy matches" same_text "$pn/b/.spade/guard/$session/repos" "$pn/a$nl$pn/b"
check "parent without a config, nothing written in the parent or a fixture" absent "$pn/.spade" "$pn/c/.spade/guard"

# A session at ~ never writes into the ~/.spade install clone.
home="$tmp/home"
make_repo "$home/.spade" on-green false
make_repo "$home/work" human false
guard_at "$home" "$(session_event SessionStart)" >/dev/null
check "home session, list in the child repository" test -f "$home/work/.spade/guard/$session/repos"
check "home session, nothing written in ~/.spade" absent "$home/.spade/guard" "$home/.spade/.spade/guard"
home_only="$tmp/home-only"
make_repo "$home_only/.spade" on-green false
guard_at "$home_only" "$(session_event SessionStart)" >/dev/null
check "home with only ~/.spade, nothing written" absent "$home_only/.spade/guard" "$home_only/.spade/.spade/guard"

# A folder with nothing nearby stays inert and writes nothing.
nothing="$tmp/nothing"
make_repo "$nothing/notes" on-green true none
mkdir -p "$nothing/a/b/c"
make_repo "$nothing/a/b/c" on-green true
guard_at "$nothing" "$(session_event SessionStart)" >/dev/null
check "nothing nearby, nothing written" absent "$nothing/.spade" "$nothing/notes/.spade/guard" "$nothing/a/b/c/.spade/guard"
expect_allow "nothing nearby, git add -A" "$(guard_at "$nothing" "$(pre_tool Bash '{"command":"git add -A"}')")"

# A later SessionStart (compact, resume, clear) never grows the list, so a
# repository created mid-session does not join it.
make_repo "$pn/d" on-green false
guard_at "$pn" "$(session_event SessionStart compact)" >/dev/null
check "compact after git init, the new repository gets no markers" absent "$pn/d/.spade/guard"
check "compact after git init, the list does not grow" same_text "$pn/a/.spade/guard/$session/repos" "$pn/a$nl$pn/b"
make_repo "$pc/late" on-green false
guard_at "$pc" "$(session_event SessionStart resume)" >/dev/null
check "resume after git init under a parent with a config, the list does not grow" same_text "$pc/.spade/guard/$session/repos" "$pc$nl$pc/web$nl$pc/libs/core"

# Copies of the list that disagree are treated as tampered.
cp "$pn/b/.spade/guard/$session/repos" "$tmp/pn-b-repos"
printf '%s\n' "$pn/d" >> "$pn/b/.spade/guard/$session/repos"
expect_deny_reason "copies disagree, merge" "disagree" "$(guard_at "$pn" "$(pre_tool Bash '{"command":"gh pr merge 41 --squash --match-head-commit abc123"}')")"
expect_allow "copies disagree, unarmed edit" "$(guard_at "$pn" "$(pre_tool Edit "{\"file_path\":\"$pn/a/README.md\"}")")"
arm "$pn/a" deliver
expect_deny_reason "copies disagree, armed edit" "disagree" "$(guard_at "$pn" "$(pre_tool Edit "{\"file_path\":\"$pn/a/README.md\"}")")"
cp "$tmp/pn-b-repos" "$pn/b/.spade/guard/$session/repos"
rm -f "$pn/a/.spade/guard/$session/mode"
expect_allow "copies agree, unarmed edit" "$(guard_at "$pn" "$(pre_tool Edit "{\"file_path\":\"$pn/a/README.md\"}")")"

# Without jq, a session folder with no config stays inert rather than blocking.
nojq_out=$(printf '%s' "$(pre_tool Bash '{"command":"git add -A"}')" | CLAUDE_PROJECT_DIR="$pn" PATH="$tmp/nojq" bash "$GUARD" 2>&1) \
    && [ -z "$nojq_out" ] && echo "  ok:   parent without a config, missing jq is inert" \
    || { echo "  FAIL: parent without a config, missing jq should be inert, got: $nojq_out"; fail=$((fail + 1)); }

# Working directory. A second gh stub records the folder each gh call ran in,
# then hands over to the stub above.
pwd_stubs="$tmp/pwd-stubs"
gh_log="$tmp/gh-pwd.log"
mkdir -p "$pwd_stubs"
cat > "$pwd_stubs/gh" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$PWD" >> "$gh_log"
exec "$stubs/gh" "\$@"
EOF
chmod +x "$pwd_stubs/gh"

bash_event() {
    # Arguments: command, optional hook cwd. Prints a Bash PreToolUse event.
    jq -cn --arg c "$1" --arg cwd "${2:-}" --arg s "$session" \
        '{hook_event_name:"PreToolUse", session_id:$s, tool_name:"Bash", tool_input:{command:$c}} + (if $cwd == "" then {} else {cwd:$cwd} end)'
}

run_bash() {
    # Arguments: session folder, command, optional hook cwd. Prints the
    # guard's decision, with gh calls recorded in gh_log.
    : > "$gh_log"
    bash_event "$2" "${3:-}" | CLAUDE_PROJECT_DIR="$1" HOME="${STUB_HOME:-$HOME}" PATH="$pwd_stubs:$stubs:$PATH" "$GUARD"
}

gh_ran_in() {
    # Arguments: session folder, command, optional hook cwd. Prints the
    # folder the first gh call ran in, or "gh never ran: <decision>".
    decision=$(run_bash "$@")
    if [ -s "$gh_log" ]; then head -n 1 "$gh_log"; else printf 'gh never ran: %s' "${decision:-allow}"; fi
}

expect_ran_in() {
    # Arguments: label, expected folder, actual. Passes on an exact match.
    if [ "$3" = "$2" ]; then echo "  ok:   ran in ${2#"$tmp"/}  $1"
    else echo "  FAIL: $1: expected gh to run in $2, got: $3"; fail=$((fail + 1)); fi
}

# A session folder with a config (merge: human) and child repositories on
# on-green, so gh runs only when the merge resolves to a child.
rs="$tmp/rs"
make_repo "$rs" human false none
make_repo "$rs/web" on-green true
make_repo "$rs/web/ui" on-green false
make_repo "$rs/api" on-green false
guard_at "$rs" "$(session_event SessionStart)" >/dev/null
pin="--squash --match-head-commit abc123"

# The everyday forms resolve to the repository they name.
expect_ran_in "cd child && merge" "$rs/web" "$(gh_ran_in "$rs" "cd web && gh pr merge 41 $pin")"
expect_ran_in "the deepest recorded repository wins" "$rs/web/ui" "$(gh_ran_in "$rs" "cd web/ui && gh pr merge 41 $pin")"
mkdir -p "$rs/web/src/deep"
expect_ran_in "a folder inside a child resolves to the child" "$rs/web" "$(gh_ran_in "$rs" "cd web/src/deep && gh pr merge 41 $pin")"
expect_ran_in "absolute cd" "$rs/api" "$(gh_ran_in "$rs" "cd $rs/api && gh pr merge 41 $pin")"
expect_ran_in "hook cwd in a child" "$rs/api" "$(gh_ran_in "$rs" "gh pr merge 41 $pin" "$rs/api")"
expect_ran_in "relative cd from the hook cwd" "$rs/api" "$(gh_ran_in "$rs" "cd ../api && gh pr merge 41 $pin" "$rs/web")"
expect_ran_in "cd --" "$rs/web" "$(gh_ran_in "$rs" "cd -- web && gh pr merge 41 $pin")"
expect_ran_in "cd -L" "$rs/api" "$(gh_ran_in "$rs" "cd -L api && gh pr merge 41 $pin")"
expect_ran_in "cd ~" "$rs/web" "$(STUB_HOME="$rs/web" gh_ran_in "$rs" "cd ~ && gh pr merge 41 $pin")"
expect_ran_in "cd ~/path" "$rs/web/ui" "$(STUB_HOME="$rs/web" gh_ran_in "$rs" "cd ~/ui && gh pr merge 41 $pin")"
expect_ran_in "two cds joined by &&" "$rs/web/ui" "$(gh_ran_in "$rs" "cd web && cd ui && gh pr merge 41 $pin")"
expect_ran_in "a line continuation after &&" "$rs/web" "$(gh_ran_in "$rs" "cd web && \\${nl}gh pr merge 41 $pin")"
expect_ran_in "a newline after &&" "$rs/web" "$(gh_ran_in "$rs" "cd web &&${nl}gh pr merge 41 $pin")"
expect_deny_reason "no cd, the session folder's policy" "merge policy is 'human'" "$(run_bash "$rs" "gh pr merge 41 $pin")"

# Every form the guard does not model makes the directory unknown, and the merge denies.
for unknown_form in "cd web; gh pr merge 41 $pin" \
                    "cd web${nl}gh pr merge 41 $pin" \
                    "cd web || true && gh pr merge 41 $pin" \
                    "true || cd web && gh pr merge 41 $pin" \
                    "ls | cd web && gh pr merge 41 $pin" \
                    "cd web && false || gh pr merge 41 $pin" \
                    "cd web & gh pr merge 41 $pin" \
                    'cd "$D" && gh pr merge 41 --squash --match-head-commit abc123' \
                    'cd $(echo web) && gh pr merge 41 --squash --match-head-commit abc123' \
                    'cd `echo web` && gh pr merge 41 --squash --match-head-commit abc123' \
                    "cd - && gh pr merge 41 $pin" \
                    "cd ~bob && gh pr merge 41 $pin" \
                    "cd web/* && gh pr merge 41 $pin" \
                    "cd && gh pr merge 41 $pin" \
                    "cd web ui && gh pr merge 41 $pin" \
                    "pushd web && gh pr merge 41 $pin" \
                    "popd && gh pr merge 41 $pin" \
                    "builtin cd web && gh pr merge 41 $pin" \
                    "command cd web && gh pr merge 41 $pin" \
                    "{ cd web; } && gh pr merge 41 $pin" \
                    "eval \"cd web\" && gh pr merge 41 $pin" \
                    "source ./go.sh && gh pr merge 41 $pin" \
                    "env -C web gh pr merge 41 $pin" \
                    "cd -P web && gh pr merge 41 $pin" \
                    "cd web && git fetch origin && gh pr merge 41 $pin" \
                    "cd web && echo y | gh pr merge 41 $pin" \
                    "CDPATH=$rs cd web && gh pr merge 41 $pin" \
                    "cd $rs/api && (cd $rs/web && true) && gh pr merge 41 $pin" \
                    'x=$(cd web && pwd) && gh pr merge 41 --squash --match-head-commit abc123' \
                    'echo $(cd web && gh pr merge 41 --squash --match-head-commit abc123)'; do
    expect_deny_reason "unknown directory: $(printf '%s' "$unknown_form" | tr '\n' '~')" "working directory is unknown" "$(run_bash "$rs" "$unknown_form")"
done

# Stage-all reads the config of the repository it runs in, including git -C.
# Only web sets deny_stage_all.
expect_allow "stage-all in the session folder" "$(run_bash "$rs" "git add -A")"
expect_deny "stage-all after cd child" "$(run_bash "$rs" "cd web && git add -A")"
expect_deny "stage-all from a hook cwd in the child" "$(run_bash "$rs" "git add -A" "$rs/web")"
expect_deny "stage-all with git -C child" "$(run_bash "$rs" "git -C web add -A")"
expect_allow "stage-all with git -C another child" "$(run_bash "$rs" "git -C api add -A")"
expect_allow "stage-all with git -C relative to a cd" "$(run_bash "$rs" "cd web && git -C ../api add -A")"
expect_allow "stage-all in the deepest repository" "$(run_bash "$rs" "cd web/ui && git add -A")"
expect_deny "stage-all with git -C back up to its parent" "$(run_bash "$rs" "cd web/ui && git -C .. add -A")"
expect_deny "the second of two stage-alls" "$(run_bash "$rs" "cd api && git add -A && cd ../web && git add --all")"
expect_deny "stage-all with an unreadable git -C, denied because a recorded repository sets deny_stage_all" "$(run_bash "$rs" 'git -C "$X" add -A')"

# Merges are judged by the repository they run in.
only_ran_in() {
    # Arguments: folder. Succeeds when gh ran at least once and every call ran there.
    [ -s "$gh_log" ] && [ "$(sort -u "$gh_log")" = "$1" ]
}
green_merge() {
    # Arguments: session folder, command, optional view JSON. Prints the
    # guard's decision with gh reporting the given PR state (default green).
    GH_STUB_VIEW="${3:-$green}" run_bash "$1" "$2"
}
green_merge_at() {
    # Arguments: session folder, command, hook cwd. Prints the guard's
    # decision for a green PR with the merge run from that cwd.
    GH_STUB_VIEW="$green" run_bash "$1" "$2" "$3"
}
failing='{"isDraft":false,"mergeable":"MERGEABLE","headRefOid":"abc123","changedFiles":1,"statusCheckRollup":[{"conclusion":"FAILURE"}]}'

# AC 2: a parent session with no merge policy merges a child PR under the
# child's on-green rules, and gh runs in the child.
ac2="$tmp/ac2"
make_repo "$ac2" none false none
make_repo "$ac2/svc" on-green false
guard_at "$ac2" "$(session_event SessionStart)" >/dev/null
expect_deny_reason "parent with no merge policy, child with no recorded Evaluate" "no recorded Evaluate for PR 41 ($ac2/svc/.spade/guard/reviewed-head-41)" "$(green_merge "$ac2" "cd svc && gh pr merge 41 $pin")"
check "parent with no merge policy, the denied check ran gh in the child" only_ran_in "$ac2/svc"
printf 'abc123 PASS\n' > "$ac2/.spade/guard/reviewed-head-41"
expect_deny_reason "a reviewed head recorded in the parent does not count for the child" "no recorded Evaluate" "$(green_merge "$ac2" "cd svc && gh pr merge 41 $pin")"
mkdir -p "$ac2/svc/.spade/guard"
printf 'abc123 PASS\n' > "$ac2/svc/.spade/guard/reviewed-head-41"
expect_allow "parent with no merge policy, child on-green, every condition holds" "$(green_merge "$ac2" "cd svc && gh pr merge 41 $pin")"
check "parent with no merge policy, every gh call ran in the child" only_ran_in "$ac2/svc"
expect_deny_reason "parent with no merge policy, child on-green, failing check" "has no checks or a check that is not SUCCESS" "$(green_merge "$ac2" "cd svc && gh pr merge 41 $pin" "$failing")"
expect_deny_reason "parent with no merge policy, child on-green, unpinned" "pin the merge exactly once" "$(green_merge "$ac2" "cd svc && gh pr merge 41 --squash")"
expect_deny_reason "parent with no merge policy, the parent's own merge" "merge policy is 'human'" "$(green_merge "$ac2" "gh pr merge 41 $pin")"

# The same from a parent without any config.
printf 'abc123 PASS\n' > "$pn/a/.spade/guard/reviewed-head-41"
expect_allow "parent without a config, child on-green, every condition holds" "$(green_merge "$pn" "cd a && gh pr merge 41 $pin")"
check "parent without a config, every gh call ran in the child" only_ran_in "$pn/a"
expect_deny_reason "parent without a config, child under human" "merge policy is 'human'" "$(green_merge "$pn" "cd b && gh pr merge 41 $pin")"

# PS-3283, both directions: the child's policy decides, not the session folder's.
mkdir -p "$rs/web/.spade/guard"
printf 'abc123 PASS\n' > "$rs/web/.spade/guard/reviewed-head-41"
expect_allow "PS-3283, human parent, on-green child merges" "$(green_merge "$rs" "cd web && gh pr merge 41 $pin")"
check "PS-3283, human parent, gh ran in the child" only_ran_in "$rs/web"
og="$tmp/og"
make_repo "$og" on-green false none
make_repo "$og/legacy" human false
guard_at "$og" "$(session_event SessionStart)" >/dev/null
printf 'abc123 PASS\n' > "$og/.spade/guard/reviewed-head-41"
mkdir -p "$og/legacy/.spade/guard"
printf 'abc123 PASS\n' > "$og/legacy/.spade/guard/reviewed-head-41"
expect_deny_reason "PS-3283, on-green parent, human child denies" "merge policy is 'human'" "$(green_merge "$og" "cd legacy && gh pr merge 41 $pin")"
check "PS-3283, on-green parent, gh never ran for the human child" test ! -s "$gh_log"
expect_allow "PS-3283, on-green parent, its own merge still merges" "$(green_merge "$og" "gh pr merge 41 $pin")"
check "PS-3283, on-green parent, its own merge ran gh in the parent" only_ran_in "$og"

# Cross-repository merges stay closed from a child too.
for elsewhere_form in "cd web && gh pr merge 41 -R other/repo $pin" \
                      "cd web && gh pr merge 41 --repo other/repo $pin" \
                      "cd web && gh pr merge 41 --repo=other/repo $pin" \
                      "cd web && GH_REPO=other/repo gh pr merge 41 $pin" \
                      "cd web && gh pr merge https://github.com/other/repo/pull/41 $pin"; do
    expect_deny_reason "on-green child, $elsewhere_form" "drop -R, --repo, GH_REPO, or a PR URL" "$(green_merge "$rs" "$elsewhere_form")"
done

# Unknown and outside: a session folder without a config has no policy to fall back on.
expect_deny_reason "parent without a config, unknown directory" "working directory is unknown" "$(green_merge "$pn" 'cd "$X" && gh pr merge 41 --squash --match-head-commit abc123')"
expect_deny_reason "parent without a config, merge in the session folder itself" "outside every repository recorded for this session" "$(green_merge "$pn" "gh pr merge 41 $pin")"
expect_deny_reason "parent without a config, merge after cd /tmp" "outside every repository recorded for this session" "$(green_merge "$pn" "cd /tmp && gh pr merge 41 $pin")"
expect_deny_reason "parent without a config, merge in a repository created mid-session" "outside every repository recorded for this session" "$(green_merge "$pn" "cd d && gh pr merge 41 $pin")"

# Single-repository regressions the review raised: still judged by the project's config.
expect_deny_reason "single repository, cd /tmp && merge --repo" "drop -R, --repo, GH_REPO, or a PR URL" "$(green_merge "$project" "cd /tmp && gh pr merge 41 --repo other/repo $pin")"
expect_allow "single repository, cd /tmp && merge, as before" "$(green_merge "$project" "cd /tmp && gh pr merge 41 $pin")"
check "single repository, cd /tmp && merge still runs gh in the project" only_ran_in "$project"
write_config on-green true
expect_deny "single repository, git --git-dir … add -A" "$(run_bash "$project" "git --git-dir /elsewhere/.git add -A")"
expect_deny "single repository, git --work-tree= … add ." "$(run_bash "$project" "git --work-tree=/elsewhere add .")"
expect_deny "single repository, cd /tmp && git add -A" "$(run_bash "$project" "cd /tmp && git add -A")"
write_config on-green false

# Stage-all without a config at the session folder: b sets deny_stage_all, a does not.
expect_deny "parent without a config, stage-all in the child that denies it" "$(run_bash "$pn" "cd b && git add -A")"
expect_allow "parent without a config, stage-all in the child that allows it" "$(run_bash "$pn" "cd a && git add -A")"
expect_allow "parent without a config, stage-all outside every repository" "$(run_bash "$pn" "git add -A")"
expect_deny_reason "parent without a config, stage-all in an unknown directory" "working directory is unknown" "$(run_bash "$pn" "git --git-dir x/.git add -A")"

# Edits are judged by the repository that holds the file.
edit_at() {
    # Arguments: session folder, file path. Prints the guard's decision for an Edit.
    guard_at "$1" "$(pre_tool Edit "$(jq -cn --arg p "$2" '{file_path:$p}')")"
}
disarm() {
    # Arguments: repositories. Removes their mode markers.
    for r in "$@"; do rm -f "$r/.spade/guard/$session/mode"; done
}

# A child armed from a parent session gets the child's own classification.
arm "$pn/a" quick
expect_deny "parent without a config, armed child quick, its auth code" "$(edit_at "$pn" "$pn/a/src/auth/login.ts")"
expect_allow "parent without a config, armed child quick, its README" "$(edit_at "$pn" "$pn/a/README.md")"
expect_deny_reason "armed child, a sibling repository" "outside the armed repository $pn/a" "$(edit_at "$pn" "$pn/b/README.md")"
expect_deny_reason "armed child, the parent folder" "outside the armed repository $pn/a" "$(edit_at "$pn" "$pn/notes.md")"
disarm "$pn/a"
expect_allow "parent without a config, nothing armed, a sibling repository" "$(edit_at "$pn" "$pn/b/src/auth/login.ts")"
arm "$rs/web" deliver
expect_deny "parent with a config, armed child deliver, the child's .spade/config" "$(edit_at "$rs" "$rs/web/.spade/config")"
expect_deny "parent with a config, armed child deliver, the child's bin/spade-guard" "$(edit_at "$rs" "$rs/web/bin/spade-guard")"
expect_allow "parent with a config, armed child deliver, its auth code" "$(edit_at "$rs" "$rs/web/src/auth/login.ts")"
expect_deny_reason "armed child, a sibling under a parent with a config" "outside the armed repository $rs/web" "$(edit_at "$rs" "$rs/api/README.md")"
expect_deny_reason "armed child, a file in the parent" "outside the armed repository $rs/web" "$(edit_at "$rs" "$rs/README.md")"
disarm "$rs/web"

# An armed parent keeps today's protection over a child, and gains the child's own.
mkdir -p "$rs/api/src/skills"
printf 'version: 9.9.9\n' > "$rs/api/src/CAPABILITIES.md"
arm "$rs" deliver
expect_deny "armed parent deliver, a child's .claude/settings.json, as today" "$(edit_at "$rs" "$rs/web/.claude/settings.json")"
expect_deny "armed parent deliver, a child's .spade/config, by the child's rules" "$(edit_at "$rs" "$rs/web/.spade/config")"
expect_allow "armed parent deliver, a child's ordinary code" "$(edit_at "$rs" "$rs/web/src/app.ts")"
arm "$rs" quick
expect_deny "armed parent quick, a framework-layout child's skill" "$(edit_at "$rs" "$rs/api/src/skills/x/SKILL.md")"
expect_deny "armed parent quick, a child's auth code" "$(edit_at "$rs" "$rs/web/src/auth/login.ts")"
expect_allow "armed parent quick, a child's README" "$(edit_at "$rs" "$rs/web/README.md")"
disarm "$rs"

# Planted configs never become repositories, even with a .git beside them.
guard_at "$project" "$(session_event SessionStart)" >/dev/null
for planted in .claude bin; do
    make_repo "$project/$planted" on-green false
done
set_mode deliver
expect_deny "planted .claude/.spade/config, .claude/settings.json still protected" "$(edit_at "$project" "$project/.claude/settings.json")"
expect_deny "planted bin/.spade/config, bin/spade-guard still protected" "$(edit_at "$project" "$project/bin/spade-guard")"
rm -rf "$project/.claude" "$project/bin"

# A nested fixture config is classified relative to the root, as today.
make_repo "$project/fixtures/x" on-green false none
set_mode quick
expect_allow "nested fixture config, its AGENTS.md is not a root governance file" "$(edit_at "$project" "$project/fixtures/x/AGENTS.md")"
set_mode deliver
expect_allow "nested fixture config, the fixture's config is not the root config" "$(edit_at "$project" "$project/fixtures/x/.spade/config")"
clear_mode

# A mode marker counts only at a recorded repository's own .spade/guard.
mkdir -p "$project/sub/.spade/guard/$session" "$pn/.spade/guard/$session" "$pn/c/.spade/guard/$session" "$pn/d/.spade/guard/$session"
for decoy in "$project/sub" "$pn" "$pn/c" "$pn/d"; do
    printf 'quick\n' > "$decoy/.spade/guard/$session/mode"
done
expect_allow "decoy mode in a subfolder of the project is ignored" "$(edit_at "$project" "$project/sub/src/auth/login.ts")"
expect_allow "decoy mode in a session folder without a config is ignored" "$(edit_at "$pn" "$pn/a/src/auth/login.ts")"
expect_allow "decoy mode in a fixture without .git is ignored" "$(edit_at "$pn" "$pn/c/src/auth/login.ts")"
expect_allow "mode in a repository created mid-session is ignored" "$(edit_at "$pn" "$pn/d/src/auth/login.ts")"
rm -rf "$project/sub" "$pn/.spade" "$pn/c/.spade/guard" "$pn/d/.spade/guard"

# Every deny that depends on a config names the config it read (PS-3283).
expect_deny_reason "names the child's config, human policy" "(read $og/legacy/.spade/config)" "$(green_merge "$og" "cd legacy && gh pr merge 41 $pin")"
expect_deny_reason "names the session folder's config, human policy" "(read $rs/.spade/config)" "$(green_merge "$rs" "gh pr merge 41 $pin")"
expect_deny_reason "names the child's config, failing check" "(read $ac2/svc/.spade/config)" "$(green_merge "$ac2" "cd svc && gh pr merge 41 $pin" "$failing")"
printf 'abc123 PARTIAL\n' > "$ac2/svc/.spade/guard/reviewed-head-41"
expect_deny_reason "names the child's config, PARTIAL without merge_partial" "merge_partial is true in .spade/config. (read $ac2/svc/.spade/config)" "$(green_merge "$ac2" "cd svc && gh pr merge 41 $pin")"
printf 'abc123 PASS\n' > "$ac2/svc/.spade/guard/reviewed-head-41"
expect_deny_reason "names the child's config, merge floor" "(read $rs/web/.spade/config)" "$(GH_STUB_FILES='[{"filename":".github/workflows/ci.yml","patch":"+x"}]' green_merge "$rs" "cd web && gh pr merge 41 $pin")"
expect_deny_reason "names the child's config, stage-all" "(read $rs/web/.spade/config)" "$(run_bash "$rs" "cd web && git add -A")"
expect_deny_reason "names the child's config, stage-all in an unknown directory" "(read $pn/b/.spade/config)" "$(run_bash "$pn" "git --git-dir x/.git add -A")"
write_config on-green true
expect_deny_reason "names the project's config, single-repository stage-all" "(read $project/.spade/config)" "$(run_bash "$project" "git add -A")"
write_config on-green false

# Skills decide whether guards are live, and where reviewed-head goes, from
# the same recorded list (docs/FRAMEWORK.md § Mechanical guards). These
# helpers follow that rule as written, against what SessionStart recorded.
recorded_list() {
    # Arguments: folder. Prints the nearest .spade/guard/<session>/repos at or above it.
    d="$1"
    while :; do
        [ -f "$d/.spade/guard/$session/repos" ] && { printf '%s\n' "$d/.spade/guard/$session/repos"; return 0; }
        [ "$d" != / ] && [ -n "$d" ] || return 1
        d=$(dirname "$d")
    done
}
skill_live() {
    # Arguments: folder. Succeeds when the nearest folder at or above it that
    # holds .git or .spade/config is itself in the recorded list.
    d="$1"
    while [ ! -e "$d/.git" ] && [ ! -f "$d/.spade/config" ]; do
        [ "$d" != / ] || return 1
        d=$(dirname "$d")
    done
    list=$(recorded_list "$d") || return 1
    grep -qxF "$d" "$list"
}
skill_not_live() { ! skill_live "$1"; }
session_repo_for() {
    # Arguments: folder. Prints the deepest recorded repository that holds it.
    list=$(recorded_list "$1") || return 1
    best=""
    while IFS= read -r r; do
        case "$1" in "$r"|"$r"/*) [ "${#r}" -gt "${#best}" ] && best="$r" ;; esac
    done < "$list"
    printf '%s\n' "$best"
}
check "live: a listed child under a parent with a config" skill_live "$pc/web"
check "live: a folder inside a listed child" skill_live "$pc/web/src/app"
check "live: a listed child under a parent without a config" skill_live "$pn/a"
check "live: the parent with a config itself" skill_live "$pc"
check "not live: a repository created mid-session under a parent with a config" skill_not_live "$pc/late"
make_repo "$pc/.claude/worktrees/x" on-green false file
check "not live: a worktree added mid-session under .claude/worktrees" skill_not_live "$pc/.claude/worktrees/x"
check "not live: a folder inside that worktree" skill_not_live "$pc/.claude/worktrees/x/src"
make_repo "$project/.claude/worktrees/x" on-green false file
check "not live: an in-repo .claude/worktrees/x in a single repository" skill_not_live "$project/.claude/worktrees/x"
set_mode deliver
expect_deny "the guard still judges an in-repo worktree's edits as part of the project" "$(edit_at "$project" "$project/.claude/worktrees/x/.claude/settings.json")"
clear_mode
rm -rf "$project/.claude"

# A session folder below its git top level: the folder is live, and
# reviewed-head goes in it, where the guard reads it.
mono="$tmp/mono"
mkdir -p "$mono/.git"
make_repo "$mono/sub" on-green false none
guard_at "$mono/sub" "$(session_event SessionStart)" >/dev/null
check "live: a session folder below its git top level" skill_live "$mono/sub"
check "live: a folder inside that session folder" skill_live "$mono/sub/pkg"
check "not live: the git top level above the session folder" skill_not_live "$mono"
check "reviewed-head location: the session folder, not the git top level" test "$(session_repo_for "$mono/sub/pkg")" = "$mono/sub"
printf 'abc123 PASS\n' > "$(session_repo_for "$mono/sub/pkg")/.spade/guard/reviewed-head-41"
expect_allow "the guard reads reviewed-head where the skill rule wrote it" "$(green_merge "$mono/sub" "gh pr merge 41 $pin" "$green" )"
check "reviewed-head location: a listed child for a merge run in it" test "$(session_repo_for "$pn/a/src")" = "$pn/a"

# Delivery Review findings (PS-3305). Each evasion first, then the everyday
# form it must leave alone.
echo "delivery review findings"

expect_deny_without() {
    # Arguments: label, text the reason must contain, text it must not
    # contain, output. Passes when the output is a deny whose reason contains
    # the first text and not the second.
    if printf '%s' "$4" | jq -e --arg want "$2" --arg not "$3" '.hookSpecificOutput.permissionDecision == "deny" and (.hookSpecificOutput.permissionDecisionReason | contains($want) and (contains($not) | not))' >/dev/null 2>&1; then
        echo "  ok:   deny  $1"
    else
        echo "  FAIL: expected deny for $1 with '$2' and without '$3', got: ${4:-<empty>}"
        fail=$((fail + 1))
    fi
}

# A cd inside a shell comment never moves the directory. The session folder
# is human with deny_stage_all; the recorded child is on-green without it.
cm="$tmp/cm"
make_repo "$cm" human true none
make_repo "$cm/green" on-green false
guard_at "$cm" "$(session_event SessionStart)" >/dev/null
mkdir -p "$cm/green/.spade/guard"
printf 'abc123 PASS\n' > "$cm/green/.spade/guard/reviewed-head-5"
expect_deny "a cd inside a comment, stage-all" "$(run_bash "$cm" "# note; cd green &&${nl}git add -A")"
expect_deny_reason "a cd inside a comment, merge" "working directory is unknown" "$(green_merge "$cm" "# note; cd green &&${nl}gh pr merge 5 --match-head-commit abc123")"
expect_allow "cd child && stage-all, the child's rule" "$(run_bash "$cm" "cd green && git add -A")"
expect_allow "cd child && merge, the child's on-green rules" "$(green_merge "$cm" "cd green && gh pr merge 5 --match-head-commit abc123")"
check "cd child && merge ran gh in the child" only_ran_in "$cm/green"

# Forms outside the allow-list make the directory unknown. From a hook cwd in
# web (on-green, reviewed) each of these really runs the merge in api.
# A folder literally named `\..` makes the backslash form below run in api.
mkdir -p "$rs/api/\\../web"
for unmodelled in '$c ../api && gh pr merge 41 --squash --match-head-commit abc123' \
                  "cd \$'\\x2e\\x2e/api' && gh pr merge 41 $pin" \
                  'cd "`echo ../api`" && gh pr merge 41 --squash --match-head-commit abc123' \
                  'cd "../api/\../web" && gh pr merge 41 --squash --match-head-commit abc123' \
                  "find ../api/.spade -maxdepth 0 -execdir gh pr merge 41 $pin \\;" \
                  "pnpm -C ../api exec gh pr merge 41 $pin" \
                  "yarn --cwd ../api exec gh pr merge 41 $pin" \
                  "git -C ../api bisect run gh pr merge 41 $pin" \
                  "command eval 'cd ../api' && gh pr merge 41 $pin" \
                  "builtin eval 'cd ../api' && gh pr merge 41 $pin" \
                  "if eval 'cd ../api'; then gh pr merge 41 $pin; fi" \
                  "trap 'cd ../api' DEBUG; gh pr merge 41 $pin" \
                  "chdir ../api && gh pr merge 41 $pin" \
                  "CDPATH+=$rs; cd api && gh pr merge 41 $pin" \
                  "read CDPATH <<< $rs; cd api && gh pr merge 41 $pin" \
                  "printf -v CDPATH %s $rs; cd api && gh pr merge 41 $pin" \
                  "HOME=$rs/api; cd ~ && gh pr merge 41 $pin" \
                  "cd '~' && gh pr merge 41 $pin" \
                  "cd \\~ && gh pr merge 41 $pin" \
                  "cd \"~/\" && gh pr merge 41 $pin" \
                  "cd -P . && gh pr merge 41 $pin"; do
    expect_deny_reason "outside the allow-list: $unmodelled" "working directory is unknown" "$(STUB_HOME="$rs/web" green_merge_at "$rs" "$unmodelled" "$rs/web")"
done
expect_deny_reason "ambient CDPATH, a relative cd" "working directory is unknown" "$(CDPATH="$rs/api" green_merge_at "$rs" "cd web && gh pr merge 41 $pin" "$rs")"
expect_allow "ambient CDPATH, an absolute cd" "$(CDPATH="$rs/api" green_merge_at "$rs" "cd $rs/web && gh pr merge 41 $pin" "$rs")"
check "ambient CDPATH, the absolute cd ran gh in the named repository" only_ran_in "$rs/web"
ln -s "$rs/api" "$rs/web/lnk"
expect_deny_reason "a symlinked folder below the repository root" "working directory is unknown" "$(green_merge_at "$rs" "cd web/lnk && gh pr merge 41 $pin" "$rs")"
expect_deny_reason "a hook cwd through a symlinked folder" "working directory is unknown" "$(green_merge_at "$rs" "gh pr merge 41 $pin" "$rs/web/lnk")"
rm -f "$rs/web/lnk"
expect_allow "unquoted cd ~/path, the everyday form" "$(STUB_HOME="$rs" green_merge_at "$rs" "cd ~/web && gh pr merge 41 $pin" "$rs")"
expect_allow "cd -L, the everyday form" "$(green_merge_at "$rs" "cd -L . && gh pr merge 41 $pin" "$rs/web")"
expect_allow "the hook cwd alone, the everyday form" "$(green_merge_at "$rs" "gh pr merge 41 $pin" "$rs/web")"

# A stage-all in an unknown directory denies when any recorded repository
# sets deny_stage_all (web does here), not only by the session folder's rule.
expect_deny_reason "an exported GIT_DIR before a stage-all" "working directory is unknown" "$(run_bash "$rs" "export GIT_DIR=$rs/web/.git; git add -A" "$rs/api")"
expect_allow "stage-all in a child without deny_stage_all, the everyday form" "$(run_bash "$rs" "git add -A" "$rs/api")"

# The hook cwd reaches the walker byte for byte. awk -v would decode the
# backslash escapes in this folder name to /../, judging api instead of web.
decoy="$rs/web/\\057..\\057api"
mkdir -p "$decoy"
expect_deny "a hook cwd with backslash escapes, stage-all by its own repository" "$(run_bash "$rs" "git add -A" "$decoy")"
expect_ran_in "a hook cwd with backslash escapes, merge in its own repository" "$rs/web" "$(gh_ran_in "$rs" "gh pr merge 41 $pin" "$decoy")"
expect_ran_in "a cd after a hook cwd with backslash escapes" "$rs/web" "$(gh_ran_in "$rs" "cd . && gh pr merge 41 $pin" "$decoy")"
rm -rf "$decoy"

# bash enters a cd's lexical folder, but falls back to the physical path when
# that folder is missing. Here api/L links into web, api/Q is missing and
# web/Q exists, so bash ends in web while the lexical walk ends in api.
mkdir -p "$rs/web/sub" "$rs/web/Q"
ln -s "$rs/web/sub" "$rs/api/L"
expect_deny_reason "a cd whose lexical folder is missing, stage-all" "cannot enter as written" "$(run_bash "$rs" "cd api/L/../Q && cd .. && git add -A" "$rs")"
expect_deny_reason "a cd whose lexical folder is missing, merge" "cannot enter as written" "$(green_merge_at "$rs" "cd api/L/../Q && cd .. && gh pr merge 41 $pin" "$rs")"
expect_allow "a cd through a link whose lexical folder exists, the everyday form" "$(run_bash "$rs" "cd api/L/.. && git add -A" "$rs")"
# bash checks every folder in front of a `..`, not only the last, so one cd
# can hide the missing folder: api/Q is missing, and bash ends in web.
expect_deny_reason "one cd hiding a missing folder before .., stage-all" "cannot enter as written" "$(run_bash "$rs" "cd api/L/../Q/.. && git add -A" "$rs")"
expect_deny_reason "one cd hiding a missing folder before .., merge" "cannot enter as written" "$(green_merge_at "$rs" "cd api/L/../Q/.. && gh pr merge 41 $pin" "$rs")"
expect_allow "a cd with .. after folders that exist, the everyday form" "$(run_bash "$rs" "cd api/../api && git add -A" "$rs")"
rm -f "$rs/api/L"
rm -rf "$rs/web/sub" "$rs/web/Q"

# The walker's output separates fields with tabs and lines, so a hook cwd
# whose name holds either is unknown rather than cut short.
tab=$(printf '\t')
mkdir -p "$rs/web/ui$tab" "$rs/web/ui$nl/tmp" "$pn/a$nl""x"
expect_deny_reason "a hook cwd whose name holds a tab, stage-all" "tab or line break" "$(run_bash "$rs" "git add -A" "$rs/web/ui$tab")"
expect_deny_reason "a hook cwd whose name holds a tab, merge" "tab or line break" "$(green_merge_at "$rs" "gh pr merge 41 $pin" "$rs/web/ui$tab")"
expect_deny_reason "a hook cwd whose name holds a line break, stage-all" "tab or line break" "$(run_bash "$rs" "git add -A" "$rs/web/ui$nl/tmp")"
expect_deny_reason "a hook cwd whose name holds a line break, merge outside every repository" "tab or line break" "$(green_merge_at "$pn" "gh pr merge 41 $pin" "$pn/a$nl""x")"
expect_deny_reason "a hook cwd ending in a line break, stage-all" "tab or line break" "$(run_bash "$rs" "git add -A" "$rs/web/ui$nl")"
expect_deny_reason "a hook cwd ending in a line break, merge" "tab or line break" "$(green_merge_at "$rs" "gh pr merge 41 $pin" "$rs/web/ui$nl")"
rm -rf "$rs/web/ui$tab" "$rs/web/ui$nl" "$pn/a$nl""x"

# On a case-insensitive filesystem WEB/.spade/config is web's config, so an
# armed ancestor also classifies the path against the recorded repository
# that matches it without regard to case.
arm "$rs" deliver
expect_deny_reason "armed parent deliver, a child's config spelled in another case" "permission widening" "$(guard_at "$rs" "$(pre_tool Write "$(jq -cn --arg p "$rs/WEB/.spade/config" '{file_path:$p}')")")"
expect_allow "armed parent deliver, a child's README spelled in another case, the everyday form" "$(edit_at "$rs" "$rs/WEB/README.md")"
disarm "$rs"

# The recorded list decides which config a call is judged by, so an armed
# session cannot rewrite it with a file tool, wherever it lives.
arm "$rs" deliver
expect_deny_reason "armed deliver, write the session's repos list" "permission widening" "$(guard_at "$rs" "$(pre_tool Write "$(jq -cn --arg p "$rs/.spade/guard/$session/repos" '{file_path:$p}')")")"
expect_deny_reason "armed deliver, edit the session's repos list" "permission widening" "$(edit_at "$rs" "$rs/.spade/guard/$session/repos")"
expect_allow "armed deliver, another file under .spade/, the everyday form" "$(edit_at "$rs" "$rs/.spade/plans/PS-1.md")"
disarm "$rs"
arm "$pn/a" deliver
expect_deny_reason "armed child deliver, its copy of the repos list" "permission widening" "$(edit_at "$pn" "$pn/a/.spade/guard/$session/repos")"
disarm "$pn/a"
arm "$rs/web" quick
expect_deny_reason "armed child quick, the parent's repos list" "outside the armed repository" "$(edit_at "$rs" "$rs/.spade/guard/$session/repos")"
disarm "$rs/web"

# A single-repository session resolves an unknown directory to the session
# folder, exactly as before.
expect_allow "single repository, unknown directory, merge" "$(green_merge "$project" 'cd "$X" && gh pr merge 41 --squash --match-head-commit abc123')"
check "single repository, unknown directory, gh ran in the project" only_ran_in "$project"
expect_allow "single repository, a command before the merge" "$(green_merge "$project" "git fetch origin && gh pr merge 41 $pin")"
expect_allow "single repository, a comment before the merge" "$(green_merge "$project" "# note; cd x &&${nl}gh pr merge 41 $pin")"

# gh and git aimed elsewhere by the environment are denied like -R.
for env_form in "cd web && GH_HOST=evil.example gh pr merge 41 $pin" \
                "cd web && GIT_DIR=$rs/api/.git gh pr merge 41 $pin" \
                "cd web && GIT_WORK_TREE=$rs/api gh pr merge 41 $pin" \
                "cd web && env GH_HOST=evil.example gh pr merge 41 $pin"; do
    expect_deny_reason "aimed elsewhere: $env_form" "drop -R, --repo, GH_REPO, or a PR URL" "$(green_merge "$rs" "$env_form")"
done
expect_deny "aimed elsewhere: an exported GIT_DIR before the merge" "$(green_merge "$rs" "cd web && export GIT_DIR=$rs/api/.git && gh pr merge 41 $pin")"
expect_deny_reason "single repository, GH_HOST prefix" "drop -R, --repo, GH_REPO, or a PR URL" "$(green_merge "$project" "GH_HOST=evil.example gh pr merge 41 $pin")"
expect_deny_reason "single repository, exported GH_HOST" "drop -R, --repo, GH_REPO, or a PR URL" "$(green_merge "$project" "export GH_HOST=evil.example; gh pr merge 41 $pin")"
expect_deny_reason "single repository, GH_HOST set by printf -v and exported" "drop -R, --repo, GH_REPO, or a PR URL" "$(green_merge "$project" "printf -v GH_HOST %s evil.example; export GH_HOST; gh pr merge 41 $pin")"
expect_allow "single repository, an unrelated environment prefix, the everyday form" "$(green_merge "$project" "GH_PROMPT_DISABLED=1 gh pr merge 41 $pin")"
expect_allow "an unrelated environment prefix, the everyday form" "$(green_merge "$rs" "cd web && GH_PROMPT_DISABLED=1 gh pr merge 41 $pin")"

# A deny names only a config it used: a stage-all check that read a config
# and passed leaves no suffix on a later merge deny.
pz="$tmp/pz"
make_repo "$pz/a" on-green false
make_repo "$pz/b" on-green false
guard_at "$pz" "$(session_event SessionStart)" >/dev/null
expect_deny_without "no stale config name after an unknown stage-all" "working directory is unknown" "(read" "$(run_bash "$pz" 'git -C "$x" add -A; gh pr merge 5')"
expect_deny_without "no stale config name after a known stage-all" "working directory is unknown" "(read" "$(run_bash "$pz" 'git add -A && cd "$x" && gh pr merge 5' "$pz/a")"
expect_deny_without "no config name on an outside-the-repositories deny" "outside every repository" "(read" "$(run_bash "$pz" 'gh pr merge 5; git -C a add -A')"
expect_deny_reason "a deny that reads a config still names it" "(read $pz/a/.spade/config)" "$(green_merge "$pz" "cd a && gh pr merge 5 --match-head-commit abc123")"

# Path normalisation never glob-expands a component against the guard's cwd.
mkdir -p "$tmp/globcwd/a" "$tmp/globcwd/b"
set_mode deliver
expect_deny "deliver, a glob component before .. to .spade/config" "$(cd "$tmp/globcwd" && run_guard "$(pre_tool Write "{\"file_path\":\"$project/*/../.spade/config\"}")")"
expect_deny "deliver, a glob component escaping the project" "$(cd "$tmp/globcwd" && run_guard "$(pre_tool Write "{\"file_path\":\"$project/*/../../outside.txt\"}")")"
expect_allow "deliver, a literal * in a safe file name" "$(cd "$tmp/globcwd" && run_guard "$(pre_tool Write "{\"file_path\":\"$project/docs/*.md\"}")")"
clear_mode

# Delivery Review findings, round 2 (PS-3305). From a hook cwd in api, which
# allows stage-all, each of these really stages in web, which denies it.
mkdir -p "$rs/web/\\../api" "$rs/web/sub" "$rs/api/src" "$tmp/rs-out"
ln -s "$rs/web/sub" "$rs/api/lnk"
ln -s "$rs/web" "$tmp/rs-out/l2"
for stage_form in "cd \$'\\x2e\\x2e/web' && git add -A" \
                  "git -C \$'..\\x2fweb' add -A" \
                  'cd "`echo ../web`" && git add -A' \
                  'git -C "`echo ../web`" add -A' \
                  'cd "../web/\../api" && git add -A' \
                  'find ../web/.spade -maxdepth 0 -execdir git add -A \;' \
                  'pnpm -C ../web exec git add -A' \
                  'yarn --cwd ../web exec git add -A' \
                  'git -C ../web bisect run git add -A' \
                  "cd $tmp/rs-out/l2 && git add -A" \
                  "git -C $tmp/rs-out/l2 add -A" \
                  'git -C lnk/.. add -A'; do
    expect_deny_reason "stage-all really in web: $stage_form" "working directory is unknown" "$(run_bash "$rs" "$stage_form" "$rs/api")"
done
# The shell rewrites these words, so they are never read as a literal path.
expect_deny_reason "an ANSI-C quoted cd is not literal" "cannot read literally" "$(run_bash "$rs" "cd \$'\\x2e\\x2e/web' && git add -A" "$rs/api")"
expect_deny_reason "a backtick inside double quotes is not literal" "cannot read literally" "$(run_bash "$rs" 'cd "`echo ../web`" && git add -A' "$rs/api")"
expect_deny_reason "a backslash inside double quotes is not literal" "cannot read literally" "$(run_bash "$rs" 'cd "../web/\../api" && git add -A' "$rs/api")"
# The everyday forms stay allowed.
expect_allow "stage-all after cd ../api from web" "$(run_bash "$rs" "cd ../api && git add -A" "$rs/web")"
expect_allow "stage-all after a double-quoted cd from web" "$(run_bash "$rs" 'cd "../api" && git add -A' "$rs/web")"
expect_allow "stage-all with git -C ../api from web" "$(run_bash "$rs" "git -C ../api add -A" "$rs/web")"
expect_deny "an ANSI-C quoted flag is still a stage-all" "$(run_bash "$rs" "git add \$'-A'" "$rs/web")"
expect_deny "an ANSI-C quoted command word is still a stage-all" "$(run_bash "$rs" "\$'git' add -A" "$rs/web")"
for prefix in "command" "time" "nice" "nice -n 5" "nice -n5" "env GIT_PAGER=cat" "GIT_PAGER=cat" "GIT_PAGER=cat command"; do
    expect_allow "stage-all behind $prefix" "$(run_bash "$rs" "$prefix git add -A" "$rs/api")"
done
expect_deny_reason "stage-all behind sudo, unknown" "working directory is unknown" "$(run_bash "$rs" "sudo git add -A" "$rs/api")"
expect_deny_reason "stage-all behind an assignment that is not literal, unknown" "working directory is unknown" "$(run_bash "$rs" 'X=$Y git add -A' "$rs/api")"
ln -s "$rs/api/src" "$rs/api/srclink"
expect_allow "a symlinked folder inside the same repository" "$(run_bash "$rs" "cd srclink && git add -A" "$rs/api")"
expect_allow "cd through a symlink and back up, which the shell resolves lexically" "$(run_bash "$rs" "cd lnk/.. && git add -A" "$rs/api")"
expect_deny_reason "a folder that does not exist" "working directory is unknown" "$(run_bash "$rs" "cd nosuch && git add -A" "$rs/api")"

# Merges: the everyday prefixes still read the repository, and gh runs there.
for prefix in "command" "time" "nice -n 5" "env GH_PROMPT_DISABLED=1"; do
    expect_ran_in "merge behind $prefix" "$rs/web" "$(GH_STUB_VIEW="$green" gh_ran_in "$rs" "$prefix gh pr merge 41 $pin" "$rs/web")"
done
expect_ran_in "merge after cd ../web from api" "$rs/web" "$(GH_STUB_VIEW="$green" gh_ran_in "$rs" "cd ../web && gh pr merge 41 $pin" "$rs/api")"
# A symlink outside the session folder into a recorded repository: og is
# on-green and reviewed, legacy is human, and the merge really runs in legacy.
mkdir -p "$tmp/og-out"
ln -s "$og/legacy" "$tmp/og-out/l3"
expect_deny_reason "a symlink outside the session folder into a recorded repository" "working directory is unknown" "$(green_merge "$og" "cd $tmp/og-out/l3 && gh pr merge 41 $pin")"
expect_allow "the on-green parent's own merge, the everyday form" "$(green_merge "$og" "cd $og && gh pr merge 41 $pin")"

# Any mention of GH_REPO, GH_HOST, GIT_DIR or GIT_WORK_TREE in a merge command
# denies, even one that clears it: a positional `unset` / `env -u` exemption
# was forgeable (`export env -u GH_REPO; …`, a continued `unset` line).
for set_form in "unset GIT_DIR GH_HOST && gh pr merge 41 $pin" \
                "env -u GIT_DIR gh pr merge 41 $pin" \
                "env -u GIT_DIR -u GH_HOST gh pr merge 41 $pin" \
                "export env -u GH_REPO; : \${GH_REPO:=o/r}; gh pr merge 41 $pin" \
                "read -r \\
unset GH_HOST <<< \"a evil.example\"; export \\
unset GH_HOST; gh pr merge 41 $pin" \
                "read GH_HOST; gh pr merge 41 $pin" \
                "env -u GIT_DIR GH_HOST=evil.example gh pr merge 41 $pin" \
                "unset GIT_DIR; export GH_HOST; gh pr merge 41 $pin" \
                "GH_HOST+=x gh pr merge 41 $pin" \
                "env GIT_DIR gh pr merge 41 $pin"; do
    expect_deny_reason "single repository, $set_form" "drop -R, --repo, GH_REPO, or a PR URL" "$(green_merge "$project" "$set_form")"
done

# SessionEnd removes the session's markers wherever they were written.
guard_at "$pn" "$(session_event SessionEnd)" >/dev/null
check "parent without a config, SessionEnd removes every child's markers" absent "$pn/a/.spade/guard/$session" "$pn/b/.spade/guard/$session"
guard_at "$pc" "$(session_event SessionEnd)" >/dev/null
check "parent with a config, SessionEnd removes its markers" absent "$pc/.spade/guard/$session"

echo
echo "spade-guard: $fail failure(s)"
[ "$fail" -eq 0 ] || exit 1
