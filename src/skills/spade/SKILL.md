---
name: spade
description: Entry point for SPADE work. Takes one piece of work from a raw ask as far as the autonomy level allows (Deliver, Plan, Scope, or Stub), halting only on a tripwire, and resumes a Scope already in flight. Use when someone says "spade this", "let's scope and plan X", "take this through SPADE", "new work", "carry on with <scope>", or invokes /spade. Routes small work to /spade-quick.
---

## Update Check

Before doing anything else, run `~/.spade/bin/spade-update-check` using {{SPADE_SHELL}}.
Show the output to the user if it is non-empty.
If the script does not exist or fails, skip silently and continue with the skill.

## Mode Resolution

Read `.spade/config` and resolve `mode:` per `references/FRAMEWORK.md` § Operating modes.
With no config, suggest `/spade-onboard` and work as `local` meanwhile.

# SPADE

You run the loop in `references/FRAMEWORK.md`; read § Autonomy levels, § Tripwires, and § The Deliver level before starting.
You call `/spade-scope`, `/spade-plan`, `/spade-review`, `/spade-evaluate`, and `/spade-quick`; each owns its own step, so do not redo their work here.
Done means the chosen level reached its halt point, or a tripwire halted it and the halt is recorded.

## 1. Resume or start

If the ask names a Scope that already has `.spade/plans/<scope-key>.md`, resume it.
Read the Plan's approval line, checkboxes, and Halts; check the branch, its commits, and the PR against them.
When they agree, carry on from the first unticked task at the level already recorded, and say where you are picking up.
When they disagree (tasks ticked with no matching commits, a missing branch, a PR closed, the Scope edited since approval, uncommitted changes you cannot account for), stop and show the mismatch.
Never stash, reset, delete, or overwrite work to make a resume fit.

## 2. Pick the level

Use the flag (`--deliver`, `--plan`, `--scope`, `--stub`), else `autonomy.default`, else ask once through `{{SPADE_ASK_USER}}` with the options Deliver, Plan, Scope, Stub.

## 3. Route small work

Unless the level is Stub, check the fast-track line (`references/FRAMEWORK.md` § Fast-track).
If the work is quick-sized, hand it to `/spade-quick` and stop.

## 4. Run the level

- **Stub.** Create the work item with a title and a one-line placeholder (a Linear issue, or a stub Scope file in `local` mode), then stop.
- **Scope.** Run `/spade-scope` and stop when the Scope is locked.
- **Plan.** Run `/spade-scope`, then `/spade-plan`, then `/spade-review` on the Scope and Plan together. Stop at the human approval `/spade-plan` asks for.
- **Deliver.** Follow `references/FRAMEWORK.md` § The Deliver level step by step. Run `/spade-plan` knowing the Deliver level approves it, so it only writes the Plan.

While delivering, tick each task in the Plan file as it finishes and commit the file with the work, so the Plan is always the true state of the run.
For broad mechanical work, hand slices to isolated agents through `{{SPADE_ISOLATED_AGENT}}`, each in its own worktree, and check each one's evidence before accepting it.

## 5. Tripwires and halts

Check the tripwires at each step.
Absent a tripwire, keep going without asking: pick obvious defaults, note them in the PR body's list of calls you made, and move on.
On a tripwire, record it in the Plan's Halts section (and as a comment on the Scope issue in `linear` mode), ask the human through `{{SPADE_ASK_USER}}`, and wait.
A guard deny is a halt too: record it, give the reason, and do not retry the write another way.
Under Deliver, remove `.spade/guard/$CLAUDE_CODE_SESSION_ID/mode` on every exit.

## 6. Finish

End with the run summary (`references/FRAMEWORK.md` § Run summary), naming the level and where it stopped.
