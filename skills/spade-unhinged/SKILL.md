---
name: spade-unhinged
description: Run one explicitly confirmed, disposable, non-shipping experiment without creating SPADE lifecycle artifacts. Use when someone invokes /spade-unhinged or clearly asks for a throwaway spike, proof of concept, learning experiment, or disposable script they do not intend to land. Routes land-intended work to /spade-quick or the full loop, routes consequential fog to /spade-frontier, and refuses every protected or unclassifiable path with no override.
---

## Update Check

Before doing anything else, run `~/.spade/bin/spade-update-check` using Bash.
Show the output to the user if it is non-empty.
If the script does not exist or fails, skip silently and continue with the skill.

# SPADE Unhinged

`/spade-unhinged` owns one explicitly confirmed, disposable experiment that is
not approved to land or ship.
It suspends SPADE lifecycle ceremony for that experiment only.
It does not suspend security classification, destructive-action confirmation,
sandbox or permission limits, worktree ownership, or Git discipline.

Do not create a Scope, Plan, approval, Linear item, `spade-run-state/v1` record, or learning.
Do not add Unhinged to the `/spade` autonomy picker, configuration defaults,
run-state vocabulary, or automatic routing.
Never merge or mark the draft ready.

## Invocation and routing

Recognise both the explicit `/spade-unhinged` invocation and clear free-text
intent for a throwaway spike, proof of concept, learning experiment, or
disposable script.
Unhinged is never inferred merely because work is small, rushed, or loosely
described.

First obtain one concrete experiment statement that names the observation or
question and the disposable output.
If the request is vague, ask for that statement in free text.
Show the exact statement and require explicit confirmation of the displayed experiment before any repository preflight or mutation.
Confirmation applies to one experiment only.

Before confirmation, classify the intent:

- If the user intends to keep or land a trivial change, route to
  `/spade-quick` and stop Unhinged.
- If the user intends to keep or land non-trivial work, route to a normal Scope
  and full SPADE loop and stop Unhinged.
- If the work contains consequential fog about architecture, product direction,
  dependencies, or boundaries, route to `/spade-frontier` and stop Unhinged.
- Otherwise, continue only after the user confirms the one concrete disposable
  experiment.

Do not create an intent picker.
The human composes the experiment statement in free text and confirms the exact
restatement.

## Canonical protected surface

Read `docs/FRAMEWORK.md` § Security-sensitive path surface before preflight.
That section is the only definition of protected categories.
Do not copy, shorten, reinterpret, or maintain a second path list here.

Classify each path together with its declared purpose against every canonical
category.
Any path that cannot be confidently classified outside every category is
protected.
There is no override.

On any protected or unknown path, state:

> this is not unhinged-eligible - use `/spade-quick` or the full loop

Show every protected or unknown path and its category in the refusal.
For an unknown path, name the fail-closed default as the category.
Return control without mutation and do not offer Continue.

## Read-only preflight

After intent confirmation, use only bounded read-only Git commands through
Bash before the first experiment mutation.
Do not invoke a tracker, network service, package manager, hook, formatter, or
repository script during preflight.

Resolve and show:

- the repository root with `git rev-parse --show-toplevel`;
- the current branch with `git branch --show-current`;
- every tracked change relative to `HEAD` with `git diff --name-only HEAD --`;
- every staged path with `git diff --name-only --cached --`;
- every unstaged path with `git diff --name-only --`;
- every untracked non-ignored path with
  `git ls-files --others --exclude-standard`; and
- the combined status with `git status --porcelain=v1 --untracked-files=all`.

Read the complete tracked, staged, unstaged, and untracked path inventory and
show it with the current branch and every currently proposed experiment path.
Do not truncate, sample, collapse, or hide paths.
Preserve every existing byte and do not guess which change belongs to whom.

Run the canonical classification over the complete current and proposed
inventory before considering branch or dirty-state prompts.
A protected or unknown path refuses immediately.

If every path is safe and either the current branch is `main` or `master`, or
the worktree is dirty, show the complete evidence and ask through
AskUserQuestion with exactly:

- `Continue`;
- `Cancel`.

Do not preselect an option.
On Cancel, return control without mutation.
On Continue, preserve every byte and continue only with the confirmed
experiment.
Continue does not authorise stash, reset, clean, overwrite, branch switching,
permission widening, sandbox bypass, or skipping a destructive confirmation.

## Fixed entry briefing

After a clean safe preflight, or an explicit Continue decision on a safe
primary or dirty worktree, print this complete briefing with the confirmed
intent inserted:

```text
UNHINGED MODE
Experiment: <confirmed concrete experiment>
Shipping status: not approved to land or ship
Suspended for this experiment: Scope, Plan, SPADE approval, tracker work items, acceptance criteria, and Evaluate
Still active: the complete Security-sensitive path surface, the ongoing path gate before every required boundary, ordinary destructive-action confirmations, sandbox and permission limits, worktree ownership, and real Git discipline
Audit boundary: committed, retained, or shared work requires a dedicated spade-unhinged/<slug> branch and an [unhinged] Draft PR that states not approved for merge
Exit conditions: cancel; land intent; consequential fog; protected or unknown path; unconfirmed destructive action; verified throwaway completion; or retained-diff audit handoff
```

Do not say or imply that all ceremony or all safety is suspended.
Do not begin experiment mutation until the complete briefing has been printed.

## Ongoing path gate

The entry decision is not a session-wide path approval.
Maintain one current inventory of all tracked and untracked changes plus all
proposed paths and their declared purposes.

Immediately before the first mutation, rerun the complete path gate.
At the same point, through Bash, write `unhinged` to
`.spade/guard/$CLAUDE_CODE_SESSION_ID/mode`.
On the Claude host the mechanical guard then also denies protected-path writes
deterministically (`docs/FRAMEWORK.md` § Mechanical guards); a deny is the
fixed refusal, not something to work around.
Remove that marker at every exit.
Before the first write to every newly proposed path, rerun the complete path gate.
Immediately before commit and again before draft PR creation, rerun the complete path gate.

Each rerun performs the complete bounded Git inventory from read-only preflight,
adds every proposed path that does not exist yet, and classifies the entire set
against `docs/FRAMEWORK.md` § Security-sensitive path surface.
Show the evaluated inventory and result.
Continue only when every current and proposed path is confidently outside all
protected categories.

If a new protected or unknown path appears, stop before its first write.
Show the path and category, print the fixed refusal, and return control.
Do not reinterpret an earlier safe result as permission for the expanded path
set.

## Mutation and safety boundaries

After the immediate pre-mutation rerun passes, perform only the confirmed
experiment.
Do not broaden it into adjacent cleanup, reusable production code, or another
experiment.

Ordinary destructive-action rules remain independent and fully active.
Deletion, overwrite, force-push, history rewrite, branch deletion, production
mutation, or any other destructive action still requires its own explicit
confirmation and must remain within sandbox, permission, path, and ownership
limits.
Experiment confirmation, a primary-branch Continue decision, and a path-gate
PASS are not destructive confirmation.
A destructive confirmation never overrides a protected path, sandbox boundary,
permission limit, or ownership conflict.

If the experiment becomes land-intended, stop before more mutation and classify
the unchanged work through the existing quick gate.
Route it to `/spade-quick` only if every quick criterion passes; otherwise route
to a normal Scope and full SPADE loop.
If consequential fog appears, stop and route to `/spade-frontier`.

## Retained-diff boundary

Uncommitted, unshared work that is genuinely discarded after verification may
exit without a PR audit.
Any commit, retained diff, or shared work must use the Unhinged Draft PR audit
path and a dedicated `spade-unhinged/<slug>` branch.
The complete path gate must pass before commit and again before PR creation.

At this boundary, stop ordinary experiment execution and enter only the
canonical retained-diff procedure.
Read `references/draft-pr.md` completely before creating or switching the
dedicated branch, committing, creating a Draft PR, closing it, or routing
retained work for preservation.
The audit is evidence of a non-shipping experiment, never Scope, Plan,
Approval, Evaluate, merge authorisation, Done, or Ship.
Never merge or mark the draft ready.

## Bounded exits and completion

Unhinged is complete only when exactly one exit below has occurred:

1. **Cancelled.**
   Return control without mutation or lifecycle artifacts.
2. **Refused.**
   Show every protected or unknown path and return control without an override.
3. **Rerouted before entry.**
   Name `/spade-quick`, the normal full loop, or `/spade-frontier`, then stop
   Unhinged.
4. **Stopped mid-run.**
   Preserve every byte, name the new land intent, fog, protected path, unknown
   path, ownership conflict, or unconfirmed destructive action, and return
   control before the unsafe mutation.
5. **Completed as throwaway work.**
   Report the confirmed intent, paths touched, verification performed and its
   result, and the fact that no work was committed, retained, or shared.
6. **Handed to retained-diff audit.**
   Report the current branch, complete changed-path inventory, latest path-gate
   result, and next required audit action.

For every exit, report `Experiment`, `Paths`, `Verification`, `Artifacts`, and
`Next`.
Claim no completion until the applicable mutation boundary, verification, and
artifact checks are observed rather than assumed.
