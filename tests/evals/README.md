# SPADE evals

The lints check structure; these check behaviour.
Each scenario runs a real agent on a small fixture repository with this checkout's skills, then a second agent grades the outcome against the scenario's criteria.
They cost model tokens, so they run by hand, not in CI.

```bash
./scripts/project-hosts.sh
./tests/evals/run.sh                        # every scenario
./tests/evals/run.sh plan-level             # one scenario
```

Results (the agent's final message, the repository state, and the grade) land in `tests/evals/results/<timestamp>/`, which is gitignored.
The runner uses a scratch `CLAUDE_CONFIG_DIR` holding only this checkout's skills and agents, so skills installed in `~/.claude` do not leak in; it reuses your sign-in by symlinking `~/.claude/.credentials.json` (override with `CLAUDE_CREDENTIALS`) and deletes the scratch directory afterwards.

## Scenarios

A scenario is a Markdown file in `scenarios/` with three sections:

- `## Setup` (optional): one bash block run in the fixture repository before the prompt.
- `## Prompt`: exactly what the human types.
- `## Pass when`: the criteria the grader checks, each one observable in the final message or the repository.

Keep scenarios few and sharp: each one should catch a behaviour a skill change could plausibly break.
When you change a skill, run the scenarios it touches before and after, and put both results in the PR.
