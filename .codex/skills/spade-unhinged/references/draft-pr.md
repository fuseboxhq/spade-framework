# Unhinged Draft PR audit contract

Read this reference only when safe experiment work will be committed, retained,
shared, or preserved for possible landing.
The always-loaded skill owns routing, the shared path gate, destructive safety,
and bounded exits.
This reference owns the branch-specific Draft PR procedure and audit body.

## Preconditions

Before any commit or Draft PR operation, require all of the following:

1. The concrete experiment remains the exact confirmed intent.
2. The work remains non-shipping and is not approved to land.
3. The complete tracked, staged, unstaged, untracked, and proposed path
   inventory is available without truncation.
4. The canonical shared path gate passed immediately before this boundary.
5. Every destructive action already taken has its own explicit confirmation
   evidence.
6. The worktree contains no ownership conflict or unexplained change.

If any precondition fails, preserve every byte, make no commit or PR mutation,
and return to the applicable bounded exit in the skill.

## Dedicated branch

Committed, retained, or shared experiment work must use a dedicated branch
named `spade-unhinged/<slug>`.
Derive `<slug>` from the confirmed experiment intent using the framework's
canonical slug rules.
Do not reuse a branch from another experiment.

Show the current branch, proposed branch, complete worktree inventory, and the
latest path-gate result.
Ask through request_user_input when available, otherwise a concise direct question with exactly:

- `Create the dedicated experiment branch`;
- `Cancel`.

Do not preselect an option.
On Cancel, preserve every byte and return control.
On Create, create or switch to only the displayed branch, then read the branch
and worktree state back before any commit.
An existing branch is acceptable only when its name and current contents match
this experiment exactly and the human confirms its ownership.

Immediately before the commit, rerun the complete canonical path gate.
Commit only the confirmed safe experiment paths.
Use an ordinary descriptive commit message with no claim of approval,
evaluation, or shipping.

## Draft PR creation

Immediately before PR creation, rerun the complete path gate again.
Resolve and show the exact target branch, experiment branch, current full head
commit, complete changed-path inventory, and verification evidence.
Do not infer any of those values from conversation or an earlier check.

Create only a Draft PR with this exact title shape:

```text
[unhinged] <confirmed experiment intent>
```

Use this body without omitting a field:

```markdown
## Experiment intent

<the exact confirmed experiment>

## Non-shipping boundary

This is a retained or shared disposable experiment.
not approved for merge

## Entry briefing

- Confirmed intent: <intent>
- Briefing acknowledged: yes
- Safety boundaries retained: shared protected-path gate, destructive confirmations, sandbox and permission limits, worktree ownership, and Git discipline

## Initial state

- Branch: <branch at entry>
- Worktree: <clean or dirty>
- Tracked paths: <complete list or none>
- Staged paths: <complete list or none>
- Unstaged paths: <complete list or none>
- Untracked paths: <complete list or none>
- Proposed paths: <complete list>

## Protected-path checks

| Boundary | Evidence time | Complete evaluated inventory | Result |
|---|---|---|---|
| Entry | <UTC time> | <complete paths> | PASS |
| Before first mutation | <UTC time> | <complete paths> | PASS |
| Before each added path | <one row per addition, or none> | <complete paths> | PASS |
| Before commit | <UTC time> | <complete paths> | PASS |
| Before Draft PR | <UTC time> | <complete paths> | PASS |

## Changed paths

<complete final changed-path inventory>

## Destructive confirmations

<action, exact confirmation, and evidence for each action, or none>

## Verification

<commands or project-native checks and observed results>

## Exit state

- Current full head: <commit>
- Draft PR: open
- Shipping route: none
- Next action: discard or close this draft before normal SPADE preservation routing
```

The lowercase exact statement `not approved for merge` must appear on its own
line.
The changed-path inventory and path-check table must be complete, not sampled.
Do not describe missing evidence as passed.

After creation, read the authoritative hosted PR state back.
Require Draft state, the exact `[unhinged]` prefix, the complete body, the
expected branch and head, and an open state.
If read-back fails or differs, report the exact mismatch and do not claim an
audit record exists.

Never convert the PR to ready, approve it, merge it, enable auto-merge, or use
it as Scope, Plan, Approval, Evaluate, merge authorisation, Done, or Ship
evidence.

## Throwaway and shared exits

Uncommitted and unshared work that is actually discarded may exit without a
Draft PR.
Discarding or deleting work remains a destructive operation and requires the
ordinary explicit confirmation when applicable.

A committed, retained, or shared diff cannot complete without a successfully
read-back Draft PR audit.
If hosted PR creation is unavailable or fails, preserve the work, report the
incomplete audit, and stop.
Do not replace the Draft with a local log, tracker item, ordinary PR, or
conversation claim.

## Preservation for landing

An Unhinged Draft PR can never become the shipping PR.
When the human wants to preserve the work for landing, show the current Draft
state, branch, full head, changed paths, and verification.
Ask through request_user_input when available, otherwise a concise direct question with exactly:

- `Close the experiment draft and re-enter SPADE`;
- `Keep the experiment draft open`;
- `Cancel`.

On Keep open or Cancel, do not close, route, or mutate the draft.
On Close, close only the displayed Draft PR, then read its authoritative state
back and require `closed`.
A conversation statement or local branch state is not closure evidence.

After verified closure, re-read the worktree, branch, full head, and complete
diff.
Require the retained work to be unchanged from the audited state.
If it changed, stop and require a fresh path check and updated experiment audit
before any preservation route.

Apply the existing quick gate to the unchanged work.
If every quick criterion passes, route it through `/spade-quick`.
If any criterion fails, route it through a normal human-owned Scope and Plan.
The normal path creates its own audit evidence and retains every ordinary human
gate.

Closing the draft is not approval, evaluation, permission to reuse a commit,
or authorisation to ship.
Evaluate and Done follow the recorded verdict on the normal path, the human
continues to own Ship, and merge remains unavailable until the selected normal
path reaches its own merge gate.
