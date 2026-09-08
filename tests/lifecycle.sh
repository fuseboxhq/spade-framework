#!/usr/bin/env bash
set -euo pipefail

# Exercise every supported historical start plus fail-closed lifecycle states.

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
LIFECYCLE="$REPO_ROOT/bin/spade-lifecycle"
PUBLISHED="$(awk '/^published_versions:/{print $2; exit}' "$REPO_ROOT/src/CAPABILITIES.md")"
CURRENT="$(awk '/^version:/{print $2; exit}' "$REPO_ROOT/src/CAPABILITIES.md")"
HISTORICAL="$REPO_ROOT/tests/fixtures/lifecycle/historical.tsv"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
if ! command -v pandoc >/dev/null 2>&1; then
    mkdir -p "$tmp/tools"
    printf '#!/usr/bin/env bash\nprintf "pandoc 3.1.0\\n"\n' > "$tmp/tools/pandoc"
    chmod +x "$tmp/tools/pandoc"
    PATH="$tmp/tools:$PATH"
    export PATH
fi

make_consumer() {
    # Contract: create one clean consumer from an immutable release-derived tree.
    root="$1"
    version="$2"
    fixture_version="${3:-$version}"
    cp -R "$REPO_ROOT/tests/fixtures/lifecycle/releases/$fixture_version/." "$root/"
    printf 'spade_version=%s\n' "$version" > "$root/.spade/version"
    git -C "$root" init -q -b main
    git -C "$root" config user.email test@example.com
    git -C "$root" config user.name Test
    git -C "$root" add .
    git -C "$root" commit -qm fixture
}

state_path() {
    # Contract: resolve the helper state path for one fixture worktree.
    root="$1"
    name="$2"
    git_dir=$(git -C "$root" rev-parse --git-dir)
    case "$git_dir" in /*) : ;; *) git_dir="$root/$git_dir" ;; esac
    printf '%s/spade-lifecycle-%s\n' "$git_dir" "$name"
}

while IFS='|' read -r version release_commit; do
    [ -n "$version" ] && [ "${version#\#}" = "$version" ] || continue
    consumer="$tmp/consumer-$version"
    mkdir -p "$consumer"
    make_consumer "$consumer" "$version"
    before_intent=""
    [ ! -f "$consumer/INTENT.md" ] || before_intent="$(file_digest "$consumer/INTENT.md")"
    if "$LIFECYCLE" migrate --install-root "$REPO_ROOT" --consumer-root "$consumer" --tracker-mode local >/dev/null; then
        actual="$(sed -n 's/^spade_version=//p' "$consumer/.spade/version")"
        if [ "$actual" = "$CURRENT" ]; then pass "historical start $version reaches $CURRENT"; else fail "historical start $version ended at $actual"; fi
    else
        fail "historical start $version migrates"
        continue
    fi
    if rerun_output=$("$LIFECYCLE" migrate --install-root "$REPO_ROOT" --consumer-root "$consumer" --tracker-mode local) && printf '%s\n' "$rerun_output" | grep -q "CURRENT|version=$CURRENT"; then
        pass "uncommitted current state $version reruns idempotently"
    else
        fail "current state $version reruns idempotently"
    fi
    if ! grep -q '^consumer-owned prefix$' "$consumer/AGENTS.md" || ! grep -q '^consumer-owned suffix$' "$consumer/AGENTS.md"; then
        fail "historical start $version preserves consumer-owned agent content"
    fi
    if [ -n "$before_intent" ] && [ "$(file_digest "$consumer/INTENT.md")" != "$before_intent" ]; then
        fail "historical start $version preserves existing human intent bytes"
    fi
done < "$HISTORICAL"

bad="$tmp/malformed"
mkdir -p "$bad"
make_consumer "$bad" 1.2.0
sed -i.bak '/SPADE-FRAMEWORK-END/d' "$bad/AGENTS.md"
rm "$bad/AGENTS.md.bak"
git -C "$bad" add . && git -C "$bad" commit -qm malformed
set +e
"$LIFECYCLE" migrate --install-root "$REPO_ROOT" --consumer-root "$bad" --tracker-mode local >/dev/null 2>&1
rc=$?
set -e
if [ "$rc" -eq 1 ] && grep -q '^spade_version=1.2.0$' "$bad/.spade/version" && [ -z "$(git -C "$bad" status --porcelain)" ]; then
    pass "failed unit leaves the consumer unchanged and resumable"
else
    fail "failed unit rollback contract"
fi

invalid_mode="$tmp/invalid-mode"
mkdir -p "$invalid_mode"
make_consumer "$invalid_mode" 1.6.1
printf 'mode: bogus\nmode: local\n' >> "$invalid_mode/.spade/config"
git -C "$invalid_mode" add . && git -C "$invalid_mode" commit -qm invalid-mode
set +e
"$LIFECYCLE" migrate --install-root "$REPO_ROOT" --consumer-root "$invalid_mode" --tracker-mode local >/dev/null 2>&1
rc=$?
set -e
if [ "$rc" -eq 2 ] && grep -q '^spade_version=1.6.1$' "$invalid_mode/.spade/version"; then
    pass "duplicate or invalid tracker modes fail before commit"
else
    fail "invalid tracker mode migration contract"
fi

malicious="$tmp/malicious-journal"
mkdir -p "$malicious"
make_consumer "$malicious" 1.1.0
victim="$tmp/victim"
printf 'preserve\n' > "$victim"
malicious_journal=$(state_path "$malicious" transaction)
mkdir -p "$malicious_journal/staged" "$malicious_journal/backup/present"
printf 'replacement\n' > "$malicious_journal/staged/payload"
printf '1.1.0|1.1.1|pin|../../../victim|%s|1.1.0||../../../victim|\n' "$CURRENT" > "$malicious_journal/record"
set +e
"$LIFECYCLE" migrate --install-root "$REPO_ROOT" --consumer-root "$malicious" --tracker-mode local >/dev/null 2>&1
rc=$?
set -e
if [ "$rc" -eq 2 ] && grep -q '^preserve$' "$victim"; then
    pass "consumer-controlled journal paths cannot escape the worktree"
else
    fail "malicious journal path contract"
fi

unknown="$tmp/unknown"
mkdir -p "$unknown"
make_consumer "$unknown" 0.9.0 1.0.0
set +e
"$LIFECYCLE" migrate --install-root "$REPO_ROOT" --consumer-root "$unknown" --tracker-mode local >/dev/null 2>&1
rc=$?
set -e
if [ "$rc" -eq 2 ]; then pass "below-floor version fails unsupported"; else fail "below-floor version returned $rc"; fi

dirty="$tmp/dirty"
mkdir -p "$dirty"
make_consumer "$dirty" 2.0.1
printf 'dirty\n' >> "$dirty/AGENTS.md"
set +e
"$LIFECYCLE" migrate --install-root "$REPO_ROOT" --consumer-root "$dirty" --tracker-mode local >/dev/null 2>&1
rc=$?
set -e
if [ "$rc" -eq 2 ]; then pass "dirty worktree fails before mutation"; else fail "dirty worktree returned $rc"; fi

downgrade="$tmp/downgrade"
mkdir -p "$downgrade"
make_consumer "$downgrade" "$CURRENT"
set +e
"$LIFECYCLE" migrate --install-root "$REPO_ROOT" --consumer-root "$downgrade" --to 2.0.1 --tracker-mode local >/dev/null 2>&1
rc=$?
set -e
if [ "$rc" -eq 2 ] && [ -z "$(git -C "$downgrade" status --porcelain)" ]; then
    pass "downgrade route fails unsupported before mutation"
else
    fail "downgrade route contract"
fi

resumable="$tmp/resumable"
mkdir -p "$resumable"
make_consumer "$resumable" 1.1.0
printf 'spade_version=1.1.1\n' > "$resumable/.spade/version"
fingerprint="$(file_digest "$resumable/.spade/version")"
{
    printf '%s|%s|%s\n' '1.1.0' "$CURRENT" '.spade/version'
    printf '%s|%s\n' '.spade/version' "$fingerprint"
} > "$(state_path "$resumable" checkpoint)"
if "$LIFECYCLE" migrate --install-root "$REPO_ROOT" --consumer-root "$resumable" --tracker-mode local >/dev/null \
    && grep -q "^spade_version=$CURRENT$" "$resumable/.spade/version" \
    && [ ! -e "$(state_path "$resumable" checkpoint)" ]; then
    pass "verified checkpoint resumes the remaining route"
else
    fail "verified checkpoint resume contract"
fi

interrupted="$tmp/interrupted"
mkdir -p "$interrupted"
make_consumer "$interrupted" 1.1.0
journal=$(state_path "$interrupted" transaction)
mkdir -p "$journal/staged/.spade" "$journal/backup/present/.spade"
printf 'spade_version=1.1.1\n' > "$journal/staged/.spade/version"
cp "$interrupted/.spade/version" "$journal/backup/present/.spade/version"
mkdir -p "$journal/backup/absent/.spade"
printf '1.1.0|1.1.1|pin|.spade/version|%s|1.1.0||.spade/version|\n' "$CURRENT" > "$journal/record"
if recovery_output=$("$LIFECYCLE" migrate --install-root "$REPO_ROOT" --consumer-root "$interrupted" --tracker-mode local) \
    && printf '%s\n' "$recovery_output" | grep -q '^RECOVERED|action=rollback|version=1.1.0$' \
    && grep -q "^spade_version=$CURRENT$" "$interrupted/.spade/version" \
    && [ ! -e "$journal" ]; then
    pass "persisted interrupted unit rolls back and resumes"
else
    fail "persisted interrupted unit recovery contract"
fi

tampered="$tmp/tampered-journal"
mkdir -p "$tampered"
make_consumer "$tampered" 1.1.0
tampered_journal=$(state_path "$tampered" transaction)
mkdir -p "$tampered_journal/staged/.spade" "$tampered_journal/backup/present/.spade" "$tampered_journal/backup/absent"
printf 'spade_version=1.1.1\n' > "$tampered_journal/staged/.spade/version"
printf 'spade_version=1.2.0\n' > "$tampered_journal/backup/present/.spade/version"
printf '1.1.0|1.1.1|pin|.spade/version|%s|1.1.0||.spade/version|\n' "$CURRENT" > "$tampered_journal/record"
set +e
"$LIFECYCLE" migrate --install-root "$REPO_ROOT" --consumer-root "$tampered" --tracker-mode local >/dev/null 2>&1
rc=$?
set -e
if [ "$rc" -eq 2 ] && grep -q '^spade_version=1.1.0$' "$tampered/.spade/version"; then
    pass "tampered in-bound journal backups fail before mutation"
else
    fail "tampered journal backup contract"
fi

install="$tmp/install"
mkdir -p "$install"
for path in src bin .claude .codex skills migrations fragments; do cp -R "$REPO_ROOT/$path" "$install/$path"; done
git -C "$install" init -q -b main
git -C "$install" config user.email test@example.com
git -C "$install" config user.name Test
git -C "$install" add .
git -C "$install" commit -qm fixture
git -C "$install" remote add origin https://github.com/fuseboxhq/spade-framework.git
historical_diagnostics_ok=1
while IFS='|' read -r version release_commit; do
    [ -n "$version" ] && [ "${version#\#}" = "$version" ] || continue
    "$install/bin/spade-lifecycle" diagnose --install-root "$install" --consumer-root "$tmp/consumer-$version" --host auto >/dev/null || historical_diagnostics_ok=0
done < "$HISTORICAL"
if [ "$historical_diagnostics_ok" -eq 1 ]; then pass "every migrated historical state passes diagnostics"; else fail "post-migration historical diagnostics"; fi
healthy="$tmp/diagnostic-consumer"
mkdir -p "$healthy"
make_consumer "$healthy" "$CURRENT"
if output=$("$install/bin/spade-lifecycle" diagnose --install-root "$install" --consumer-root "$healthy" --host auto); then
    for check in remote-identity installed-revision install-worktree helper-inventory claude-skills claude-personas codex-skills codex-personas tracker-mode consumer-version AGENTS-fragment CLAUDE-fragment renderer; do
        if printf '%s\n' "$output" | grep -q "|$check|"; then pass "diagnostics report $check"; else fail "diagnostics omit $check"; fi
    done
else
    fail "healthy diagnostics exit zero"
fi
for name in AGENTS CLAUDE; do
    sed -i.bak "s/SPADE-FRAMEWORK-START v$CURRENT/SPADE-FRAMEWORK-START v1.0.0/" "$healthy/$name.md"
    rm "$healthy/$name.md.bak"
done
git -C "$healthy" add . && git -C "$healthy" commit -qm stale-markers
set +e
stale_fragment_output=$("$install/bin/spade-lifecycle" diagnose --install-root "$install" --consumer-root "$healthy" --host auto 2>&1)
rc=$?
set -e
if [ "$rc" -eq 1 ] && printf '%s\n' "$stale_fragment_output" | grep -q '^ERROR|AGENTS-fragment|'; then
    pass "diagnostics reject markers older than the required fragment refresh"
else
    fail "stale fragment diagnostic contract"
fi
content_drift="$tmp/content-drift"
mkdir -p "$content_drift"
make_consumer "$content_drift" "$CURRENT"
awk '
    /^<!-- SPADE-FRAMEWORK-START / {print; print "MALICIOUS OVERRIDE"; inside=1; next}
    /^<!-- SPADE-FRAMEWORK-END -->$/ && inside {inside=0; print; next}
    !inside {print}
' "$content_drift/AGENTS.md" > "$content_drift/AGENTS.md.tmp"
mv "$content_drift/AGENTS.md.tmp" "$content_drift/AGENTS.md"
git -C "$content_drift" add . && git -C "$content_drift" commit -qm content-drift
set +e
content_drift_output=$("$install/bin/spade-lifecycle" diagnose --install-root "$install" --consumer-root "$content_drift" --host auto 2>&1)
rc=$?
set -e
if [ "$rc" -eq 1 ] && printf '%s\n' "$content_drift_output" | grep -q '^ERROR|AGENTS-fragment|'; then
    pass "diagnostics reject modified framework-owned fragment content"
else
    fail "framework fragment content diagnostic contract"
fi

global_home="$tmp/global-home"
mkdir -p "$global_home/.spade"
cp -R "$REPO_ROOT/." "$global_home/.spade/"
rm -rf "$global_home/.spade/.git" "$global_home/.spade/.agents" "$global_home/.spade/.codex/agents" "$global_home/.spade/.claude/settings.local.json"
git -C "$global_home/.spade" init -q -b main
git -C "$global_home/.spade" config user.email test@example.com
git -C "$global_home/.spade" config user.name Test
git -C "$global_home/.spade" add . && git -C "$global_home/.spade" commit -qm approved-source
git -C "$global_home/.spade" remote add origin https://github.com/fuseboxhq/spade-framework.git
global_sha=$(git -C "$global_home/.spade" rev-parse HEAD)
if HOME="$global_home" SPADE_APPROVED_SHA="$global_sha" "$global_home/.spade/setup" --host all >/dev/null \
    && global_output=$(HOME="$global_home" "$global_home/.spade/bin/spade-lifecycle" diagnose --install-root "$global_home/.spade" --host auto) \
    && printf '%s\n' "$global_output" | grep -q '^OK|installed-revision|'; then
    pass "setup supports an approved source-equals-destination clone"
else
    fail "approved source-equals-destination install contract"
fi

projected_home="$tmp/projected-home"
mkdir -p "$projected_home"
approved_source="$tmp/approved-source"
mkdir -p "$approved_source"
cp -R "$REPO_ROOT/." "$approved_source/"
rm -rf "$approved_source/.git" "$approved_source/.agents" "$approved_source/.codex/agents" "$approved_source/.claude/settings.local.json"
git -C "$approved_source" init -q -b main
git -C "$approved_source" config user.email test@example.com
git -C "$approved_source" config user.name Test
git -C "$approved_source" add . && git -C "$approved_source" commit -qm approved-source
git -C "$approved_source" remote add origin https://github.com/fuseboxhq/spade-framework.git
approved_sha=$(git -C "$approved_source" rev-parse HEAD)
if HOME="$projected_home" SPADE_APPROVED_SHA="$approved_sha" "$approved_source/setup" --host all >/dev/null \
    && projected_output=$(HOME="$projected_home" "$projected_home/.spade/bin/spade-lifecycle" diagnose --install-root "$projected_home/.spade" --host auto) \
    && printf '%s\n' "$projected_output" | grep -q "^OK|installed-revision|.*observed=$approved_sha,$approved_sha"; then
    pass "diagnostics validate approved external global provenance"
else
    fail "approved global projection provenance contract"
fi
printf '\nmodified\n' >> "$projected_home/.codex/skills/spade/SKILL.md"
set +e
projection_drift=$(HOME="$projected_home" "$projected_home/.spade/bin/spade-lifecycle" diagnose --install-root "$projected_home/.spade" --host codex 2>&1)
rc=$?
set -e
if [ "$rc" -eq 2 ] && printf '%s\n' "$projection_drift" | grep -q '^ERROR|codex-projection-integrity|'; then
    pass "global diagnostics detect modified payload contents"
else
    fail "global payload integrity diagnostic contract"
fi

plugin="$tmp/codex-plugin"
cp -R "$REPO_ROOT/plugins/spade-framework" "$plugin"
set +e
plugin_output=$("$plugin/scripts/spade-lifecycle" diagnose --install-root "$plugin" --host codex 2>&1)
rc=$?
set -e
if [ "$rc" -eq 2 ] && printf '%s\n' "$plugin_output" | grep -q '^OK|codex-plugin-integrity|' \
    && printf '%s\n' "$plugin_output" | grep -q '^ERROR|installed-revision|'; then
    pass "plugin diagnostics verify payload but fail closed without manager provenance"
else
    fail "plugin provenance diagnostic contract"
fi
printf '\nmodified\n' >> "$plugin/skills/spade/SKILL.md"
set +e
plugin_drift=$("$plugin/scripts/spade-lifecycle" diagnose --install-root "$plugin" --host codex 2>&1)
rc=$?
set -e
if [ "$rc" -eq 2 ] && printf '%s\n' "$plugin_drift" | grep -q '^ERROR|codex-plugin-integrity|'; then
    pass "plugin diagnostics reject modified payload contents"
else
    fail "plugin payload drift contract"
fi

set +e
unsupported_output=$("$install/bin/spade-lifecycle" diagnose --install-root "$install" --consumer-root "$unknown" --host auto 2>&1)
rc=$?
set -e
if [ "$rc" -eq 2 ] && printf '%s' "$unsupported_output" | grep -q '^ERROR|consumer-version|'; then
    pass "diagnostics distinguish unsupported consumer state"
else
    fail "diagnostic unsupported exit contract"
fi

malformed="$tmp/malformed-consumer"
mkdir -p "$malformed"
make_consumer "$malformed" "$CURRENT"
printf 'spade_version=not-a-version\n' > "$malformed/.spade/version"
git -C "$malformed" add . && git -C "$malformed" commit -qm malformed-version
set +e
malformed_output=$("$install/bin/spade-lifecycle" diagnose --install-root "$install" --consumer-root "$malformed" --host auto 2>&1)
rc=$?
set -e
if [ "$rc" -eq 2 ] && printf '%s\n' "$malformed_output" | grep -q '^ERROR|consumer-version|' \
    && ! printf '%s\n' "$malformed_output" | grep -q 'unbound variable'; then
    pass "diagnostics report malformed consumer pins as unsupported"
else
    fail "malformed consumer pin diagnostic contract"
fi

git -C "$install" remote set-url origin https://secret-token@example.com/repo.git
set +e
redacted=$("$install/bin/spade-lifecycle" diagnose --install-root "$install" --host auto 2>&1)
rc=$?
set -e
if [ "$rc" -eq 1 ] && ! printf '%s' "$redacted" | grep -q 'secret-token' && printf '%s' "$redacted" | grep -q 'https://\[redacted\]@example.com/repo.git'; then
    pass "diagnostics redact remote credentials and return drift"
else
    fail "diagnostic redaction contract"
fi

echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
