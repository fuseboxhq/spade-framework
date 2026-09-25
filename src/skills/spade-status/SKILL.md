---
name: spade-status
description: List active SPADE Scopes or inspect one Scope's phase, Plan progress, branch and PR state, and human blockers. Use when someone asks what is active, where work stands, what is blocked, or what should happen next.
---

## Update Check

Before doing anything else, run `~/.spade/bin/spade-update-check` using {{SPADE_SHELL}}.
Show the output to the user if it is non-empty.
If the script does not exist or fails, skip silently and continue with the skill.

## Mode Resolution

Resolve the operating mode once from `docs/FRAMEWORK.md` § Operating modes before calling `list_issues` or reading local Scope files.
The resolved mode selects Linear or `.spade/scopes/` as the source of record.

# SPADE status

This skill is read-only.
Do not repair metadata, change tracker state, or treat a reported next step as permission to act.

Read `.spade/config` when present for the Linear team and project.
If explicit `linear` mode cannot reach Linear, say so, continue from local files, and record the fallback under **Found**.

## No Scope argument

List every active Scope grouped in this order:

1. Scoped
2. Planning
3. Approval
4. Delivering
5. Evaluating

In Linear mode, use `list_issues` for the configured team and project and include issues in those statuses.
Ignore Done and unrelated issues.

In local mode, read `.spade/scopes/*.md`, parse the flat frontmatter, and group files by `status`.
Use the filename slug or `name` as the Scope key.
Do not rewrite missing or malformed frontmatter.
Show malformed active candidates under **Found** instead of guessing their phase.

For each Scope, show its key, title, phase, Plan progress, branch or PR state when discoverable, and the current human blocker.
Use one short table per non-empty status group.
If there is no active work, say so plainly.

## One Scope argument

Resolve an exact Scope by Linear identifier, local `name`, or filename slug.
If more than one Scope matches, stop and ask which one the human means.

Show:

- the Scope key and title;
- its current phase;
- Plan checklist progress;
- branch and PR state;
- what is blocked on the human;
- the next recorded unchecked task or lifecycle action.

### Plan progress

Read `.spade/plans/<scope-key>.md`.
Count task checkboxes as complete (`- [x]` or `- [X]`) or open (`- [ ]`).
Report `N/M tasks complete` and name the first open task.
If the Plan is absent, report `No Plan`.
If a differently named Plan appears related, report it under **Found** and do not infer that it is canonical.

### Branch and PR state

Inspect local Git branches and the current branch for an exact Scope key or slug match.
When the repository has a GitHub remote and `gh` is available, inspect matching open and closed PRs without changing them.
Prefer a PR that links the Scope or whose head branch matches the resolved branch.
Report the branch name and one of `no PR`, `draft`, `open`, `merged`, or `closed`.
Say `not found` when no reliable match exists.

### Human blocker

Read the Scope, Plan, current status, and PR state for explicit gates.
Typical blockers are Plan approval in Approval, a recorded Halt, requested human input, or human merge after a PASS.
Do not invent a blocker from an incomplete task.
Report `nothing recorded` when the files and tracker show none.

## Output

Keep the status compact.
End with the framework run summary:

- **Blocked on me**: the human decisions or approvals, or `nothing`.
- **Changed**: `nothing (read-only status)`.
- **Found**: malformed, missing, stale, fallback, or ambiguous state, or `nothing`.
