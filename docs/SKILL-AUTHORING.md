# SPADE Skill Authoring

How to write and change SPADE skills and agents.
The only editable behaviour sources are under `src/`; everything under `.claude/`, `.codex/`, `skills/`, `agents/`, `hooks/`, `plugins/`, and `generated/` is a projection.

## What a skill says

A skill states the goal, what done looks like, and the hard lines, then trusts the model with the steps.
Current models already know how to write code, run tests, interview someone, and review a diff, so a skill spends its words on what they cannot know: this framework's contracts, the repository's gotchas, and where the human must decide.

- **Description.** Written for the model deciding whether to trigger the skill: what it does and the phrases that should invoke it.
- **Done means.** One sentence naming an observable end state: a file at a path, a tracker state, a command result, or a recorded halt.
- **Hard lines.** Only rules that genuinely hold every time. If a rule is deterministic, prefer a guard in `bin/spade-guard` to a sentence.
- **Say it once.** A rule defined in `docs/FRAMEWORK.md` is linked with `§ <section>`, not restated. `lint-skill-authoring.sh` checks every `§` reference resolves.
- **No reasoning prompts.** No "think hard", "reason carefully", or step-by-step instructions; set effort instead.
- **No pinned models.** Skills name roles (`spade-reviewer`), not model versions.
- **Interfaces over examples.** A short template or schema beats a worked example, which narrows what the model tries.

## Context budgets

Every `SKILL.md` stays under `skill_budget_bytes` and every consumer fragment under `fragment_budget_bytes` in `src/CAPABILITIES.md`.
Material that only some runs need goes in `references/<name>.md` with one explicit trigger in the `SKILL.md`; the lint rejects an unrouted reference.

## Host adapters

Skills use fixed tokens (`{{SPADE_ASK_USER}}`, `{{SPADE_SHELL}}`, `{{SPADE_ISOLATED_AGENT}}`, `{{SPADE_READ_ONLY_RESEARCH}}`, and the agent metadata tokens) that `src/hosts/claude.md` and `src/hosts/codex.md` translate.
Adapters translate operations only; they never carry workflow rules or change a gate.

## Checking behaviour

The lints check structure, not wording.
Behaviour is checked with the manual evals in `tests/evals/`: run the scenarios a change could affect before and after, and put the results in the PR.

## Contributor workflow

1. Edit `src/`, the docs, or the tooling.
2. Run `./scripts/project-hosts.sh` to regenerate every projection.
3. Run `./scripts/lint/run-all.sh`.
4. Run the affected evals from `tests/evals/`.
5. Review the canonical diff; the generated diff is evidence, not a second review surface.
