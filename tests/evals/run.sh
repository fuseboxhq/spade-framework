#!/usr/bin/env bash
set -euo pipefail

# Run SPADE behavioural evals against the skills in this checkout.
#
# Usage: tests/evals/run.sh [scenario ...]   (no argument runs every scenario)
# Needs: the `claude` CLI signed in, and projections regenerated with
#        scripts/project-hosts.sh.
# Each scenario runs in a scratch git repository built from tests/evals/fixture
# with a scratch CLAUDE_CONFIG_DIR that holds only this checkout's skills and
# agents, so globally installed skills cannot leak in. Sign-in is reused by
# symlinking ~/.claude/.credentials.json into that scratch directory; nothing is
# copied, and the scratch directory is deleted afterwards.
# A second `claude -p` grades the outcome against the scenario's "Pass when".
# Results land in tests/evals/results/<timestamp>/ (gitignored).
# Exit codes: 0 every scenario passed, 1 a scenario failed, 2 bad usage.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
EVALS="$REPO_ROOT/tests/evals"
CREDENTIALS="${CLAUDE_CREDENTIALS:-$HOME/.claude/.credentials.json}"
results="$EVALS/results/$(date +%Y%m%d-%H%M%S)"

command -v claude >/dev/null || { echo "evals: the claude CLI is not installed" >&2; exit 2; }
[ -d "$REPO_ROOT/.claude/skills/spade" ] || { echo "evals: run scripts/project-hosts.sh first" >&2; exit 2; }

section() {
    # Arguments: scenario file, heading. Prints the section body without its heading.
    awk -v want="## $2" '$0 == want {on=1; next} /^## / {on=0} on' "$1"
}

setup_script() {
    # Arguments: scenario file. Prints the first bash block of its Setup section.
    section "$1" Setup | awk '/^```bash$/ {on=1; next} /^```$/ {if (on) exit} on'
}

build_repo() {
    # Arguments: destination. Creates the fixture repository with SPADE fragments.
    local repo="$1" version name
    version=$(awk '/^version:/ {print $2; exit}' "$REPO_ROOT/src/CAPABILITIES.md")
    cp -R "$EVALS/fixture" "$repo"
    printf 'spade_version=%s\n' "$version" > "$repo/.spade/version"
    for name in AGENTS CLAUDE; do
        { printf '<!-- SPADE-FRAMEWORK-START v%s -->\n' "$version"
          cat "$REPO_ROOT/fragments/$name-section.md"
          printf '<!-- SPADE-FRAMEWORK-END -->\n'; } > "$repo/$name.md"
    done
    git -C "$repo" init -q -b main
    git -C "$repo" add -A
    git -C "$repo" -c user.name=eval -c user.email=eval@example.com commit -qm "Fixture"
}

evidence() {
    # Arguments: repository. Prints the repository state the grader judges.
    local repo="$1"
    echo "## Branches and commits"; git -C "$repo" log --all --oneline --decorate
    echo; echo "## Working tree"; git -C "$repo" status --short
    echo; echo "## Changes against the fixture commit"; git -C "$repo" diff "$(git -C "$repo" rev-list --max-parents=0 HEAD)" --stat
    echo; echo "## .spade files"
    find "$repo/.spade" -type f ! -path '*/guard/*' | sort | while read -r f; do
        echo "### ${f#"$repo"/}"; cat "$f"; echo
    done
    for f in greet.sh test.sh .env; do
        [ -f "$repo/$f" ] && { echo "### $f"; cat "$repo/$f"; echo; }
    done
    echo "## ./test.sh"; (cd "$repo" && ./test.sh 2>&1) || true
}

run_scenario() {
    # Arguments: scenario name. Runs, grades, and records one scenario; returns 1 on FAIL.
    local name="$1" file="$EVALS/scenarios/$1.md" scratch out verdict
    [ -f "$file" ] || { echo "evals: no scenario $name" >&2; return 2; }
    scratch=$(mktemp -d "${TMPDIR:-/tmp}/spade-eval.XXXXXX")
    chmod 700 "$scratch"
    out="$results/$name"
    mkdir -p "$out" "$scratch/config"
    ln -s "$CREDENTIALS" "$scratch/config/.credentials.json"
    cp -R "$REPO_ROOT/.claude/skills" "$scratch/config/skills"
    cp -R "$REPO_ROOT/.claude/agents" "$scratch/config/agents"
    build_repo "$scratch/repo"
    (cd "$scratch/repo" && git config user.name eval && git config user.email eval@example.com && bash -c "$(setup_script "$file")")

    (cd "$scratch/repo" && CLAUDE_CONFIG_DIR="$scratch/config" claude -p "$(section "$file" Prompt)" \
        --dangerously-skip-permissions --output-format text > "$out/transcript.md" 2>&1) || true
    evidence "$scratch/repo" > "$out/evidence.md"

    CLAUDE_CONFIG_DIR="$scratch/config" claude -p --output-format text > "$out/grade.md" 2>&1 <<EOF || true
You are grading one run of an AI coding agent. Judge only against the criteria.
Reply with PASS or FAIL alone on the first line, then one line per criterion saying met or not met and why.

# Criteria
$(section "$file" "Pass when")

# The agent's final message
$(cat "$out/transcript.md")

# Repository state after the run
$(cat "$out/evidence.md")
EOF
    rm -rf "$scratch"
    verdict=$(head -n 1 "$out/grade.md" | tr -d '[:space:]*')
    echo "$verdict  $name"
    [ "$verdict" = PASS ]
}

scenarios=("$@")
[ "${#scenarios[@]}" -gt 0 ] || scenarios=($(ls "$EVALS/scenarios" | sed 's/\.md$//'))
failed=0
for scenario in "${scenarios[@]}"; do
    run_scenario "$scenario" || failed=1
done
echo "evals: results in ${results#"$REPO_ROOT"/}"
exit "$failed"
