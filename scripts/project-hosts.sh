#!/usr/bin/env bash
set -euo pipefail

# Deterministically project canonical SPADE skills and agents into every host.
#
# Arguments: no argument writes projections; --check compares without writing.
# Outputs: generated Claude/Codex payloads and exact global-install manifests.
# Side effects: write mode replaces only the fixed generated roots listed below.
# Exit codes: 0 success, 1 validation or drift failure, 2 invalid invocation.
# Safety: all sources must be regular non-symlink files and every destination is
# a fixed child of this repository. No path is accepted from user input.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ROOT="$REPO_ROOT/src"
MODE="write"

case "${1:-}" in
    "") ;;
    --check) MODE="check" ;;
    *) echo "Usage: $0 [--check]" >&2; exit 2 ;;
esac

fail() {
    # Contract: print one actionable error and terminate without partial writes.
    echo "project-hosts: $*" >&2
    exit 1
}

frontmatter_value() {
    # Contract: print one flat YAML frontmatter value from CAPABILITIES.md.
    # Arguments: key. Side effects: none. Exit 1 when absent or duplicated.
    key="$1"
    value=$(awk -v key="$key" '
        NR == 1 && $0 == "---" { in_fm=1; next }
        in_fm && $0 == "---" { exit }
        in_fm && index($0, key ":") == 1 { sub("^[^:]+:[[:space:]]*", ""); print }
    ' "$SOURCE_ROOT/CAPABILITIES.md")
    [ -n "$value" ] || fail "missing manifest field: $key"
    printf '%s\n' "$value"
}

adapter_value() {
    # Contract: print the projection text for one fixed host token.
    # Arguments: host, token. Side effects: none. Exit 1 when absent.
    host="$1"
    token="$2"
    value=$(awk -F'|' -v token="$token" '
        $2 ~ token {
            value=$3
            sub(/^[[:space:]]+/, "", value)
            sub(/[[:space:]]+$/, "", value)
            print value
            exit
        }
    ' "$SOURCE_ROOT/hosts/$host.md")
    [ -n "$value" ] || fail "missing $host adapter token: $token"
    printf '%s\n' "$value"
}

validate_sources() {
    # Contract: reject symlinks, non-regular entries, and undeclared inventory.
    # Arguments: none. Side effects: none.
    [ -f "$SOURCE_ROOT/CAPABILITIES.md" ] || fail "missing capability manifest"
    [ -d "$SOURCE_ROOT/skills" ] || fail "missing canonical skills"
    [ -d "$SOURCE_ROOT/agents" ] || fail "missing canonical agents"
    [ -f "$SOURCE_ROOT/hooks/hooks.json" ] || fail "missing canonical hooks"
    if find "$SOURCE_ROOT" -type l -print | grep -q .; then
        fail "canonical source contains a symlink"
    fi
    if find "$SOURCE_ROOT" ! -type d ! -type f -print | grep -q .; then
        fail "canonical source contains a non-regular entry"
    fi

    declared=$(frontmatter_value skills | tr ',' '\n' | LC_ALL=C sort)
    actual=$(find "$SOURCE_ROOT/skills" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | LC_ALL=C sort)
    [ "$declared" = "$actual" ] || fail "skill inventory differs from CAPABILITIES.md"

    personas=$(frontmatter_value review_personas | tr ',' '\n' | LC_ALL=C sort)
    actual_personas=$(find "$SOURCE_ROOT/agents" -maxdepth 1 -type f -name 'spade-review-*.md' -exec basename {} .md \; | LC_ALL=C sort)
    [ "$personas" = "$actual_personas" ] || fail "persona inventory differs from CAPABILITIES.md"
}

assert_repo_destination() {
    # Contract: reject symlinked ancestors for one fixed repo-relative output.
    # Arguments: repo-relative path. Side effects: none.
    local relative="$1"
    local current="$REPO_ROOT"
    local old_ifs="$IFS"
    local component
    IFS='/'
    for component in $relative; do
        [ -n "$component" ] || continue
        current="$current/$component"
        if [ -L "$current" ]; then
            IFS="$old_ifs"
            fail "generated destination component is a symlink: $relative"
        fi
    done
    IFS="$old_ifs"
}

render_file() {
    # Contract: replace only the four allowlisted host tokens in one Markdown file.
    # Arguments: host, source, destination. Side effects: writes destination.
    # Exit 1 when any unresolved SPADE token remains.
    host="$1"
    source_file="$2"
    destination_file="$3"
    ask=$(adapter_value "$host" SPADE_ASK_USER)
    shell=$(adapter_value "$host" SPADE_SHELL)
    isolated=$(adapter_value "$host" SPADE_ISOLATED_AGENT)
    research=$(adapter_value "$host" SPADE_READ_ONLY_RESEARCH)
    agent_model=$(adapter_value "$host" SPADE_AGENT_MODEL)
    review_tools=$(adapter_value "$host" SPADE_REVIEW_TOOLS)
    research_tools=$(adapter_value "$host" SPADE_RESEARCH_TOOLS)
    mkdir -p "$(dirname "$destination_file")"
    awk -v ask="$ask" -v shell="$shell" -v isolated="$isolated" -v research="$research" -v agent_model="$agent_model" -v review_tools="$review_tools" -v research_tools="$research_tools" '
        {
            gsub(/\{\{SPADE_ASK_USER\}\}/, ask)
            gsub(/\{\{SPADE_SHELL\}\}/, shell)
            gsub(/\{\{SPADE_ISOLATED_AGENT\}\}/, isolated)
            gsub(/\{\{SPADE_READ_ONLY_RESEARCH\}\}/, research)
            gsub(/\{\{SPADE_AGENT_MODEL\}\}/, agent_model)
            gsub(/\{\{SPADE_REVIEW_TOOLS\}\}/, review_tools)
            gsub(/\{\{SPADE_RESEARCH_TOOLS\}\}/, research_tools)
            print
        }
    ' "$source_file" > "$destination_file"
    if grep -q '{{SPADE_' "$destination_file"; then
        fail "unresolved host token in ${source_file#"$REPO_ROOT"/}"
    fi
}

render_skills() {
    # Contract: render every canonical skill file for one host, preserving paths.
    # Arguments: host, destination root. Side effects: writes only below root.
    host="$1"
    destination_root="$2"
    find "$SOURCE_ROOT/skills" -type f | LC_ALL=C sort | while IFS= read -r source_file; do
        relative=${source_file#"$SOURCE_ROOT/skills/"}
        render_file "$host" "$source_file" "$destination_root/$relative"
    done
    printf '%s\n' '# Generated by scripts/project-hosts.sh. Edit src/ only.' > "$destination_root/GENERATED.md"
}

render_agents() {
    # Contract: render canonical agent metadata for one host.
    # Arguments: host, destination root. Side effects: writes only below root.
    host="$1"
    destination_root="$2"
    mkdir -p "$destination_root"
    find "$SOURCE_ROOT/agents" -maxdepth 1 -type f -name '*.md' | LC_ALL=C sort | while IFS= read -r source_file; do
        render_file "$host" "$source_file" "$destination_root/$(basename "$source_file")"
    done
    printf '%s\n' '# Generated by scripts/project-hosts.sh. Edit src/ only.' > "$destination_root/GENERATED.md"
}

write_codex_manifest() {
    # Contract: emit the validated Codex plugin manifest from the capability version.
    # Arguments: destination file. Side effects: writes destination.
    destination_file="$1"
    skills_path="${2:-./.codex/skills/}"
    version=$(frontmatter_value version)
    mkdir -p "$(dirname "$destination_file")"
    {
        printf '{\n'
        printf '  "name": "spade-framework",\n'
        printf '  "version": "%s",\n' "$version"
        printf '  "description": "SPADE human-AI engineering workflow for Codex",\n'
        printf '  "author": {"name": "Fusebox HQ"},\n'
        printf '  "homepage": "https://github.com/fuseboxhq/spade-framework",\n'
        printf '  "repository": "https://github.com/fuseboxhq/spade-framework",\n'
        printf '  "license": "MIT",\n'
        printf '  "keywords": ["spade", "engineering", "workflow"],\n'
        printf '  "skills": "%s",\n' "$skills_path"
        printf '  "interface": {\n'
        printf '    "displayName": "SPADE",\n'
        printf '    "shortDescription": "Auditable Scope to Evaluate engineering workflow",\n'
        printf '    "longDescription": "SPADE provides governed Scope, Plan, Approve, Deliver, and Evaluate workflows with Claude and Codex capability parity.",\n'
        printf '    "developerName": "Fusebox HQ",\n'
        printf '    "category": "Productivity",\n'
        printf '    "capabilities": ["Interactive", "Write"]\n'
        printf '  }\n'
        printf '}\n'
    } > "$destination_file"
}

write_codex_marketplace() {
    # Contract: emit the repo-local Codex marketplace and installable plugin copy.
    # Arguments: generated tree root. Side effects: writes only below .agents/plugins.
    tree="$1"
    marketplace="$tree/.agents/plugins"
    plugin="$tree/plugins/spade-framework"
    mkdir -p "$marketplace" "$plugin/.codex-plugin"
    cp -R "$tree/.codex/skills" "$plugin/skills"
    mkdir -p "$plugin/scripts"
    frontmatter_value helpers | tr ',' '\n' | while IFS= read -r helper; do
        cp "$REPO_ROOT/bin/$helper" "$plugin/scripts/$helper"
        chmod +x "$plugin/scripts/$helper"
    done
    cp "$SOURCE_ROOT/CAPABILITIES.md" "$plugin/CAPABILITIES.md"
    cp -R "$REPO_ROOT/migrations" "$plugin/migrations"
    cp -R "$REPO_ROOT/render" "$plugin/render"
    cp -R "$REPO_ROOT/fragments" "$plugin/fragments"
    cp -R "$REPO_ROOT/templates" "$plugin/templates"
    write_codex_manifest "$plugin/.codex-plugin/plugin.json" "./skills/"
    {
        printf '{\n'
        printf '  "name": "spade-framework",\n'
        printf '  "interface": {"displayName": "SPADE Framework"},\n'
        printf '  "plugins": [\n'
        printf '    {\n'
        printf '      "name": "spade-framework",\n'
        printf '      "source": {"source": "local", "path": "./plugins/spade-framework"},\n'
        printf '      "policy": {"installation": "AVAILABLE", "authentication": "ON_INSTALL"},\n'
        printf '      "category": "Productivity"\n'
        printf '    }\n'
        printf '  ]\n'
        printf '}\n'
    } > "$marketplace/marketplace.json"
    printf '%s\n' '# Generated by scripts/project-hosts.sh. Edit src/ only.' > "$marketplace/GENERATED.md"
}

write_claude_manifests() {
    # Contract: derive every Claude plugin version claim from CAPABILITIES.md.
    # Arguments: generated tree root. Side effects: writes .claude-plugin only.
    tree="$1"
    version=$(frontmatter_value version)
    mkdir -p "$tree/.claude-plugin"
    for name in plugin marketplace; do
        awk -v version="$version" '
            /^[[:space:]]*"version":[[:space:]]*/ {
                indent=$0
                sub(/[^[:space:]].*$/, "", indent)
                comma=($0 ~ /,[[:space:]]*$/ ? "," : "")
                print indent "\"version\": \"" version "\"" comma
                next
            }
            { print }
        ' "$SOURCE_ROOT/manifests/claude-$name.json" > "$tree/.claude-plugin/$name.json"
    done
}

write_version_pin() {
    # Contract: derive the repository consumer pin from CAPABILITIES.md.
    tree="$1"
    mkdir -p "$tree/.spade"
    printf 'spade_version=%s\n' "$(frontmatter_value version)" > "$tree/.spade/version"
}

write_install_manifests() {
    # Contract: list the exact files each global installer owns.
    # Arguments: generated tree root. Side effects: writes two sorted manifests.
    tree="$1"
    mkdir -p "$tree/generated/install"
    : > "$tree/generated/install/claude.manifest"
    : > "$tree/generated/install/codex.manifest"
    find "$tree/.claude/skills" -type f ! -name GENERATED.md | LC_ALL=C sort | while IFS= read -r file; do
        rel=${file#"$tree/.claude/skills/"}
        printf 'file|.claude/skills/%s|.claude/skills/%s|%s\n' "$rel" "$rel" "$(/usr/bin/shasum -a 256 "$file" | awk '{print $1}')" >> "$tree/generated/install/claude.manifest"
    done
    find "$tree/.claude/agents" -type f ! -name GENERATED.md | LC_ALL=C sort | while IFS= read -r file; do
        rel=${file#"$tree/.claude/agents/"}
        printf 'file|.claude/agents/%s|.claude/agents/%s|%s\n' "$rel" "$rel" "$(/usr/bin/shasum -a 256 "$file" | awk '{print $1}')" >> "$tree/generated/install/claude.manifest"
    done
    find "$tree/.codex/skills" -type f ! -name GENERATED.md | LC_ALL=C sort | while IFS= read -r file; do
        rel=${file#"$tree/.codex/skills/"}
        printf 'file|.codex/skills/%s|.codex/skills/%s|%s\n' "$rel" "$rel" "$(/usr/bin/shasum -a 256 "$file" | awk '{print $1}')" >> "$tree/generated/install/codex.manifest"
    done
    frontmatter_value helpers | tr ',' '\n' | while IFS= read -r helper; do
        digest=$(/usr/bin/shasum -a 256 "$REPO_ROOT/bin/$helper" | awk '{print $1}')
        printf 'file|bin/%s|.spade/bin/%s|%s\n' "$helper" "$helper" "$digest" >> "$tree/generated/install/claude.manifest"
        printf 'file|bin/%s|.spade/bin/%s|%s\n' "$helper" "$helper" "$digest" >> "$tree/generated/install/codex.manifest"
    done
    digest=$(/usr/bin/shasum -a 256 "$SOURCE_ROOT/CAPABILITIES.md" | awk '{print $1}')
    printf 'file|src/CAPABILITIES.md|.spade/CAPABILITIES.md|%s\n' "$digest" >> "$tree/generated/install/claude.manifest"
    printf 'file|src/CAPABILITIES.md|.spade/CAPABILITIES.md|%s\n' "$digest" >> "$tree/generated/install/codex.manifest"
    for root in fragments migrations render templates; do
        find "$REPO_ROOT/$root" -type f | LC_ALL=C sort | while IFS= read -r file; do
            rel=${file#"$REPO_ROOT/"}
            digest=$(/usr/bin/shasum -a 256 "$file" | awk '{print $1}')
            printf 'file|%s|.spade/%s|%s\n' "$rel" "$rel" "$digest" >> "$tree/generated/install/claude.manifest"
            printf 'file|%s|.spade/%s|%s\n' "$rel" "$rel" "$digest" >> "$tree/generated/install/codex.manifest"
        done
    done
    LC_ALL=C sort -o "$tree/generated/install/claude.manifest" "$tree/generated/install/claude.manifest"
    LC_ALL=C sort -o "$tree/generated/install/codex.manifest" "$tree/generated/install/codex.manifest"
}

write_plugin_payload_manifests() {
    # Contract: publish exact SHA-256 claims for both host-managed payloads.
    tree="$1"
    claude_manifest="$tree/.claude-plugin/payload.manifest"
    codex_root="$tree/plugins/spade-framework"
    codex_manifest="$codex_root/payload.manifest"
    : > "$claude_manifest"
    for root in skills agents; do
        find "$tree/$root" -type f | LC_ALL=C sort | while IFS= read -r file; do
            rel=${file#"$tree/"}
            printf 'file|%s|%s\n' "$rel" "$(/usr/bin/shasum -a 256 "$file" | awk '{print $1}')" >> "$claude_manifest"
        done
    done
    for file in "$tree/.claude-plugin/plugin.json" "$tree/.claude-plugin/marketplace.json" "$tree/hooks/hooks.json" "$SOURCE_ROOT/CAPABILITIES.md"; do
        case "$file" in
            "$tree"/*) rel=${file#"$tree/"} ;;
            *) rel=src/CAPABILITIES.md ;;
        esac
        printf 'file|%s|%s\n' "$rel" "$(/usr/bin/shasum -a 256 "$file" | awk '{print $1}')" >> "$claude_manifest"
    done
    frontmatter_value helpers | tr ',' '\n' | while IFS= read -r helper; do
        printf 'file|bin/%s|%s\n' "$helper" "$(/usr/bin/shasum -a 256 "$REPO_ROOT/bin/$helper" | awk '{print $1}')" >> "$claude_manifest"
    done
    for root in fragments migrations render templates; do
        find "$REPO_ROOT/$root" -type f | LC_ALL=C sort | while IFS= read -r file; do
            rel=${file#"$REPO_ROOT/"}
            printf 'file|%s|%s\n' "$rel" "$(/usr/bin/shasum -a 256 "$file" | awk '{print $1}')" >> "$claude_manifest"
        done
    done
    LC_ALL=C sort -o "$claude_manifest" "$claude_manifest"
    find "$codex_root" -type f ! -path "$codex_manifest" | LC_ALL=C sort | while IFS= read -r file; do
        rel=${file#"$codex_root/"}
        printf 'file|%s|%s\n' "$rel" "$(/usr/bin/shasum -a 256 "$file" | awk '{print $1}')" >> "$codex_manifest"
    done
    LC_ALL=C sort -o "$codex_manifest" "$codex_manifest"
}

generate_tree() {
    # Contract: build a complete projection in an isolated temporary root.
    # Arguments: temporary root. Side effects: writes only below that root.
    tree="$1"
    mkdir -p "$tree/.claude" "$tree/.codex" "$tree/scripts"
    render_skills claude "$tree/.claude/skills"
    render_agents claude "$tree/.claude/agents"
    cp -R "$tree/.claude/skills" "$tree/skills"
    cp -R "$tree/.claude/agents" "$tree/agents"
    render_skills codex "$tree/.codex/skills"
    mkdir -p "$tree/.codex/skills/spade-review/references/personas"
    for source_file in "$SOURCE_ROOT"/agents/spade-review-*.md; do
        render_file codex "$source_file" "$tree/.codex/skills/spade-review/references/personas/$(basename "$source_file")"
    done
    mkdir -p "$tree/.codex/skills/spade-research/references"
    render_file codex "$SOURCE_ROOT/agents/spade-researcher.md" "$tree/.codex/skills/spade-research/references/researcher.md"
    printf '%s\n' '# Generated by scripts/project-hosts.sh. Edit src/ only.' > "$tree/.codex/GENERATED.md"
    write_codex_manifest "$tree/.codex-plugin/plugin.json"
    write_claude_manifests "$tree"
    # Claude-only mechanical guards. Codex has no hook surface, so the Codex
    # payload carries none; docs/FRAMEWORK.md § Mechanical guards owns the rule.
    mkdir -p "$tree/hooks"
    cp "$SOURCE_ROOT/hooks/hooks.json" "$tree/hooks/hooks.json"
    write_version_pin "$tree"
    write_codex_marketplace "$tree"
    frontmatter_value helpers | tr ',' '\n' | while IFS= read -r helper; do
        [ -f "$REPO_ROOT/bin/$helper" ] || fail "missing helper: bin/$helper"
        [ ! -L "$REPO_ROOT/bin/$helper" ] || fail "helper is a symlink: bin/$helper"
        cp "$REPO_ROOT/bin/$helper" "$tree/scripts/$helper"
        chmod +x "$tree/scripts/$helper"
    done
    write_install_manifests "$tree"
    write_plugin_payload_manifests "$tree"
}

compare_path() {
    # Contract: compare one generated path and add no output on success.
    expected="$1"
    actual="$2"
    label="$3"
    if ! diff -ruN "$expected" "$actual" >/dev/null; then
        echo "  drift: $label" >&2
        return 1
    fi
}

write_projections() {
    # Contract: replace only fixed generated roots after full temp generation.
    tree="$1"
    for path in .claude/skills .claude/agents skills agents hooks .claude-plugin .codex .codex-plugin .agents/plugins plugins/spade-framework generated/install .spade/version; do
        destination="$REPO_ROOT/$path"
        case "$destination" in "$REPO_ROOT"/*) ;; *) fail "unsafe destination" ;; esac
        assert_repo_destination "$path"
        rm -rf "$destination"
        mkdir -p "$(dirname "$destination")"
        cp -R "$tree/$path" "$destination"
    done
    frontmatter_value helpers | tr ',' '\n' | while IFS= read -r helper; do
        destination="$REPO_ROOT/scripts/$helper"
        assert_repo_destination "scripts/$helper"
        cp "$tree/scripts/$helper" "$destination"
        chmod +x "$destination"
    done
}

check_projections() {
    # Contract: fail if any generated root or helper differs from regeneration.
    tree="$1"
    failed=0
    for path in .claude/skills .claude/agents skills agents hooks .claude-plugin .codex .codex-plugin .agents/plugins plugins/spade-framework generated/install .spade/version; do
        compare_path "$tree/$path" "$REPO_ROOT/$path" "$path" || failed=1
    done
    frontmatter_value helpers | tr ',' '\n' | while IFS= read -r helper; do
        compare_path "$tree/scripts/$helper" "$REPO_ROOT/scripts/$helper" "scripts/$helper" || exit 1
    done || failed=1
    [ "$failed" -eq 0 ] || fail "generated projections are stale; run ./scripts/project-hosts.sh"
}

validate_sources
tmp=$(mktemp -d "${TMPDIR:-/tmp}/spade-project-hosts.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
generate_tree "$tmp"

if [ "$MODE" = "check" ]; then
    check_projections "$tmp"
    echo "project-hosts: all projections are current"
else
    write_projections "$tmp"
    echo "project-hosts: generated Claude and Codex projections"
fi
