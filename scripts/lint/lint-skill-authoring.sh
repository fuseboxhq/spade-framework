#!/usr/bin/env bash
set -uo pipefail

# Structural checks on the canonical skills, agents, and fragments.
#
# Checks inventory, context budgets, host adapters, projections, version
# claims, and `docs/FRAMEWORK.md` section references. It deliberately does not
# pin skill wording: behaviour is checked by the manual evals in tests/evals/.
# Exit 0 when every check passes; exit 1 on any violation.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="$REPO_ROOT/src/CAPABILITIES.md"
fail=0

field() {
    # Arguments: key. Prints one flat frontmatter value from CAPABILITIES.md.
    awk -v key="$1" 'NR==1 && $0=="---"{fm=1;next} fm && $0=="---"{exit} fm && index($0,key ":")==1{sub("^[^:]+:[[:space:]]*","");print}' "$MANIFEST"
}

check() {
    # Arguments: exit status of a test, description. Records one result.
    if [ "$1" -eq 0 ]; then
        echo "  ok:   $2"
    else
        echo "  FAIL: $2"
        fail=$((fail + 1))
    fi
}

[ -f "$MANIFEST" ] || { echo "  FAIL: missing src/CAPABILITIES.md"; exit 1; }

# Inventory: canonical sources match the manifest exactly.
declared_skills=$(field skills | tr ',' '\n' | LC_ALL=C sort)
actual_skills=$(find "$REPO_ROOT/src/skills" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | LC_ALL=C sort)
[ "$declared_skills" = "$actual_skills" ]; check $? "skill directories match CAPABILITIES.md"
declared_agents=$( { field review_personas | tr ',' '\n'; field researcher; } | LC_ALL=C sort)
actual_agents=$(find "$REPO_ROOT/src/agents" -maxdepth 1 -type f -name '*.md' -exec basename {} .md \; | LC_ALL=C sort)
[ "$declared_agents" = "$actual_agents" ]; check $? "agent files match CAPABILITIES.md"
for helper in $(field helpers | tr ',' ' '); do
    [ -f "$REPO_ROOT/bin/$helper" ]; check $? "helper bin/$helper exists"
done

# Context budgets.
skill_budget=$(field skill_budget_bytes)
fragment_budget=$(field fragment_budget_bytes)
for file in "$REPO_ROOT"/src/skills/*/SKILL.md; do
    size=$(wc -c < "$file" | tr -d ' ')
    [ "$size" -le "$skill_budget" ]; check $? "${file#"$REPO_ROOT"/} is $size bytes (budget $skill_budget)"
done
for file in "$REPO_ROOT"/fragments/*.md; do
    size=$(wc -c < "$file" | tr -d ' ')
    [ "$size" -le "$fragment_budget" ]; check $? "${file#"$REPO_ROOT"/} is $size bytes (budget $fragment_budget)"
done

# Every reference file is routed from its skill.
while IFS= read -r ref; do
    skill_dir=$(dirname "$(dirname "$ref")")
    grep -Fq "references/$(basename "$ref")" "$skill_dir/SKILL.md"; check $? "${ref#"$REPO_ROOT"/} is routed from its SKILL.md"
done < <(find "$REPO_ROOT/src/skills" -path '*/references/*' -type f | LC_ALL=C sort)

# Every `docs/FRAMEWORK.md` § reference names a real heading.
python3 - "$REPO_ROOT" <<'PY' || fail=$((fail + 1))
import pathlib, re, sys
root = pathlib.Path(sys.argv[1])
headings = {m.group(1).strip() for m in re.finditer(r"^#{2,4} (.+)$", (root / "docs/FRAMEWORK.md").read_text(), re.M)}
sources = list((root / "src").rglob("*.md")) + list((root / "fragments").glob("*.md")) + [root / "AGENTS.md", root / "docs/FRAMEWORK.md"]
bad = []
for path in sources:
    for ref in re.findall(r"§ ([A-Z][A-Za-z -]*[A-Za-z])", path.read_text()):
        if ref not in headings:
            bad.append(f"{path.relative_to(root)}: § {ref}")
for item in bad:
    print(f"  FAIL: unknown FRAMEWORK section {item}")
if not bad:
    print("  ok:   every FRAMEWORK.md § reference resolves")
sys.exit(1 if bad else 0)
PY

# Wording current models do not need, and host leakage.
prose=("$REPO_ROOT/src" "$REPO_ROOT/fragments" "$REPO_ROOT/docs/FRAMEWORK.md" "$REPO_ROOT/AGENTS.md")
! grep -R -n -i -E 'think (hard|harder|carefully|step by step)|reason carefully|ultrathink' "${prose[@]}"; check $? "no think-hard instructions"
! grep -R -n -E '(Opus|Sonnet|Haiku|Fable) [0-9]|GPT-[0-9]' "${prose[@]}"; check $? "no pinned model names"
! grep -R -n -E 'Bash tool|Claude Code workflow author' "$REPO_ROOT"/src/skills/*/SKILL.md; check $? "skill bodies carry no host-specific execution wording"
! grep -R -n '—' "${prose[@]}"; check $? "no em dashes"

# Host adapters: seven fixed tokens each, no workflow behaviour.
for host in claude codex; do
    rows=$(grep -c '^| `SPADE_[A-Z_]*` |' "$REPO_ROOT/src/hosts/$host.md" || true)
    [ "$rows" -eq 7 ]; check $? "$host adapter has seven token rows"
done
! grep -R -n -E 'merge gate|approval gate|evaluation gate|bypass.*gate|(^|[^A-Z])(MUST|NEVER)([^A-Z]|$)' "$REPO_ROOT/src/hosts"; check $? "host adapters carry no gate behaviour"
! grep -R -n '{{SPADE_' "$REPO_ROOT/.claude" "$REPO_ROOT/.codex" "$REPO_ROOT/skills" "$REPO_ROOT/agents"; check $? "projections contain no unresolved host tokens"
"$REPO_ROOT/scripts/project-hosts.sh" --check; check $? "projections match canonical source"

# Version claims agree with the manifest.
version=$(field version)
[ "$(sed -n 's/^spade_version=//p' "$REPO_ROOT/.spade/version")" = "$version" ]; check $? ".spade/version is $version"
grep -q "\"version\": \"$version\"" "$REPO_ROOT/.claude-plugin/plugin.json"; check $? "Claude plugin is $version"
grep -q "\"version\": \"$version\"" "$REPO_ROOT/.codex-plugin/plugin.json"; check $? "Codex plugin is $version"
grep -q "version-$version-green" "$REPO_ROOT/README.md"; check $? "README badge is $version"
grep -q "## \[$version\]" "$REPO_ROOT/CHANGELOG.md"; check $? "CHANGELOG has $version"
grep -q "framework is at v$version" "$REPO_ROOT/INTENT.md"; check $? "INTENT maturity is $version"
grep -q "SPADE Framework v$version" "$REPO_ROOT/docs/FRAMEWORK.md"; check $? "FRAMEWORK footer is $version"
skills=$(field skills | tr ',' '\n' | wc -l | tr -d ' ')
rows=$(grep -E -c '^\| `/(spade|leads|unslop)' "$REPO_ROOT/README.md" || true)
[ "$rows" -eq "$skills" ]; check $? "README skill table lists $skills skills"

echo
echo "lint-skill-authoring: $fail failure(s)"
[ "$fail" -eq 0 ] || exit 1
