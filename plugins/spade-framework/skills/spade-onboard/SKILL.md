---
name: spade-onboard
description: Onboard or refresh SPADE in a consumer repository. Use when asked to set up SPADE, fill its project context, capture project intent, or add a verified end-to-end change check.
---

# SPADE onboard

Create the minimum durable project context SPADE needs.
The result must be safe to run twice without duplicate markers, config blocks, files, or prompts about already-settled content.

## Refuse self-onboarding

Before reading the provisioning reference or changing anything, run this check:

```bash
if [ -f src/CAPABILITIES.md ] && [ -d src/skills ]; then
  echo "This is the SPADE framework repository; refusing to self-onboard."
  exit 0
fi
```

Both paths must exist for the guard to fire.
If it fires, stop because this repository's root files are the source.

## Mode Resolution

Resolve or confirm `linear` or `local` once from `references/FRAMEWORK.md` § Operating modes before calling `list_teams` or `list_projects`.
Persist that choice in `.spade/config`; a later run preserves a valid existing mode.

## Provision project files

Read `references/project-files.md` completely before writing files.
Resolve the installed version from the nearest regular `CAPABILITIES.md`, with `~/.spade/CAPABILITIES.md` and then `~/.spade/src/CAPABILITIES.md` as global fallbacks.
Use that version for both markers and `.spade/version`.

Create `.spade/scopes/`, `.spade/plans/`, and `.spade/learnings/` when absent.

For a new `.spade/config`, use `request_user_input when available, otherwise a concise direct question` to confirm `linear` when Linear is available and the human selects the team and project.
Otherwise choose `local`.
If Linear is chosen, use `list_teams` and `list_projects` to record the selected names and IDs.
Write the defaults from the reference, including `autonomy.default: deliver`, human merge, the 7 task and 12 file ceiling, and 3 maximum open PRs.
Do not add a handoff block.

On a later run, preserve valid human choices and add only missing required keys.
Do not duplicate YAML keys or replace a configured team or project without human confirmation.

Write `.spade/version` in this exact form:

```text
spade_version=<installed version>
```

Insert or refresh the framework fragments with the installed helper:

```bash
~/.spade/bin/spade-marker-replace \
  "$PWD/AGENTS.md" \
  ~/.spade/fragments/AGENTS-section.md \
  "$SPADE_VERSION"

~/.spade/bin/spade-marker-replace \
  "$PWD/CLAUDE.md" \
  ~/.spade/fragments/CLAUDE-section.md \
  "$SPADE_VERSION"
```

The helper owns the marker contract:

- An absent target is created with one marker pair.
- An unmarked target keeps its content and gains one block.
- One existing block is replaced and restamped.
- Exit 2 means mismatched markers and exit 3 means duplicate blocks.

On exit 2 or 3, leave the target unchanged, show the error, and ask the human to repair the markers.
Never edit around a rejected marker block.

## Learn the project

Read the README, existing project docs, manifests, CI, deployment config, representative source, tests, schemas, and security boundaries.
Find the commands people actually use to build, test, run, and exercise the product.

Separate evidence from intent.
Code and config can prove the current stack and behavior.
They cannot prove who the project serves, why a trade-off was chosen, or what the team refuses to build.

Present a short project understanding and ask the human to correct missing or wrong claims before writing prose that depends on them.

## Write project context

Create `ARCHITECTURE.md`, `PATTERNS.md`, and `ANTI-PATTERNS.md` from the reference templates when absent.
When a file already has project-specific content, preserve it and propose only evidence-backed additions or corrections.
When it is still a template, replace its prompts with confirmed project facts.

Keep these files focused on decisions and gotchas that the repository cannot make obvious:

- `ARCHITECTURE.md` records boundaries, data flow, ownership, deployment constraints, and consequential decisions.
- `PATTERNS.md` records conventions a contributor could otherwise miss and the reasons to follow them.
- `ANTI-PATTERNS.md` records rejected approaches, recurring mistakes, and the reason each is banned.

Do not write a directory tour, dependency inventory, or prose version of the code.
Leave an unknown out or mark it as a question instead of inventing it.

## Compose INTENT.md with the human

The human owns intent.
Draft `INTENT.md` from repository evidence and the conversation, then probe only the gaps that evidence cannot answer.
Cover the problem, users, what the project does, success, non-goals, and maturity.
Never infer a goal or non-goal from implementation alone.

Show the complete draft and obtain human confirmation before creating or materially refreshing `INTENT.md`.
On a later run, preserve confirmed content and update only what the human changes.

## Add project verification when missing

First search the project docs and existing skills for a documented way to verify a change end to end.
Do nothing when a usable procedure already exists.

If it is missing, derive exact build, test, run, and app-driving commands from repository evidence.
Resolve placeholders such as ports, URLs, fixtures, credentials, and expected visible outcomes.
Run safe commands when practical, but do not claim an unobserved flow works.

Show the proposed verification procedure and use `request_user_input when available, otherwise a concise direct question` to confirm every command before writing it.
After confirmation, write the reference template to both `.claude/skills/verify/SKILL.md` and `.agents/skills/verify/SKILL.md` with the confirmed commands.
Create parent directories as needed.
Never overwrite an existing verification skill without explicit approval.

## Finish

Verify that both marker files contain exactly one matching block, required config keys occur once, `.spade/version` matches the installed version, project docs contain no invented claims, and any verification skill has confirmed commands.
Report the chosen mode and every file created, refreshed, preserved, or skipped.

End with:

- **Blocked on me**: unanswered intent, verification, or marker decisions, or `nothing`.
- **Changed**: the files written or refreshed.
- **Found**: unknowns, existing conflicts, or missing verification evidence, or `nothing`.
