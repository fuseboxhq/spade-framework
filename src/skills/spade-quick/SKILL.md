---
name: spade-quick
description: Fast-track path for small, low-risk changes that should land without a Scope or Plan - bug fixes, tweaks, config nudges, docs, renames. Use when someone asks directly for a small change ("just fix this", "quick tweak", "typo", "rename this"), or when /spade routes small work here. Not for anything that adds a dependency or touches schemas, migrations, auth, crypto, secrets, permissions, or a public interface.
---

## Mode Resolution

Read `.spade/config` if it exists and resolve `mode:` per `docs/FRAMEWORK.md` § Operating modes.
With no config, work as `local` and make no tracker calls.

# SPADE Quick

Deliver one small change with the PR description as the audit record.
Done means: a single-concern commit on a `spade-quick/<slug>` branch, the relevant tests passing, and an open PR that uses the template below.

## Is it quick?

It is quick when it is one concern, fits in one reviewable commit, and existing tests cover the area (extending one is fine).
It is not quick if it adds a dependency, touches a schema, migration, or data layer, touches auth, crypto, secrets, or permissions, or breaks a public interface.
Incidents and anything a reviewer would want to discuss before it lands also go through `/spade`.
Decide yourself and say why in one line; do not ask the human to call it.
If the work grows past these lines mid-flight, stop before committing, say what changed, and recommend `/spade`.

## Steps

1. Arm the guard: through `{{SPADE_SHELL}}`, write `quick` to `.spade/guard/$CLAUDE_CODE_SESSION_ID/mode` before the first edit.
   A guard deny is a halt: show its reason and tell the human the change needs `/spade`.
   Remove the marker when the PR is open or the halt is reported.
2. Make the change on `spade-quick/<issue-id>-<slug>` (or `spade-quick/<slug>`) in one commit.
   Leave nearby code alone.
3. Run the tests that cover the area.
   For a visible change (UI, output, CLI text), check it in the running product and say what you looked at.
4. Open the PR with the template, after the `/unslop` pass on its prose.
5. In `linear` mode, when there is an issue: add `spade:quick` and one `type:*` label (`bug`, `tweak`, `chore`, `docs`, `refactor`), post the PR link, and move it to In Review.
   Close it once the PR merges with green checks.
   A behavioural change without an issue gets one; a docs or comment fix does not need one.
6. End with the run summary: Blocked on me, Changed, Found.

## PR template

```markdown
**Type:** <bug | tweak | chore | docs | refactor>
**SPADE path:** quick
**Linear:** <issue id or "none">

## What and why
<One or two sentences.>

## Verification
- [ ] `<test command>` passes
- [ ] Checked in the product: <what you looked at, or "not behavioural">

## Quick-path check
- [x] One concern, one commit
- [x] No new dependencies
- [x] No schema, migration, or data-layer change
- [x] No auth, crypto, secrets, or permissions change
- [x] No public interface break
```
