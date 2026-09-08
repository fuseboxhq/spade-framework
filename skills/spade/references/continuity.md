# Run Continuity Contract

Read this reference whenever `/spade` opens, writes, validates, resumes, repairs, or closes a run trace.
The high-level contract is single-sourced in `docs/FRAMEWORK.md` under "Run continuity state".

## State summary schema

Every new checkpoint writes one complete logical summary with schema `spade-run-state/v1`.
The summary is a reconstruction aid and never proves that an external action still exists.

The canonical field order is:

```text
schema: spade-run-state/v1
state_id: <unique opaque state identifier>
previous_state: none | <prior state_id>
run_id: <stable opaque identifier for this run>
scope_id: <Linear issue identifier or local stable Scope id>
scope_revision: <authoritative revision token or exact content digest>
autonomy_level: deliver | plan | scope | stub
phase: scope | plan | approve | deliver | evaluate | complete
completed_checkpoints: none | <ordered comma-separated checkpoint names>
current_work: none | bundle:<bundle-id> | task:<task-id>
repository: <canonical remote URL or explicit local repository identifier>
branch: none | <branch name>
base_sha: none | <full commit SHA>
head_sha: none | <full commit SHA>
pull_request: none | <authoritative PR identifier and recorded state>
last_verification: none | <recorded_at, head_sha, command or native tool, concise result>
halt_reason: none | <tripwire, human gate, abort, or stale-state class>
next_action: <one bounded action and boundary>
recorded_at: <UTC ISO 8601 timestamp>
```

Every field is required, including fields whose value is `none`.
Writers must not add multiline values, raw transcript excerpts, secrets, credentials, cookies, tokens, authentication state, or full learning drafts.
Identifiers are correctness joins, not authorization or trust primitives.

`state_id` is unique per snapshot.
`run_id` remains stable from `run:start` until the selected autonomy level reaches its terminal halt or complete state.
`previous_state` must point to the immediately preceding snapshot in that run.
Two successor snapshots that name the same `previous_state` are a contradictory fork and cannot be selected automatically.

`scope_revision` records the tracker-provided revision for the exact Scope body when one exists.
When the tracker cannot provide a body revision, record an exact digest of the normalized Scope content or local Scope file.
A status timestamp that also changes for comments or workflow transitions is not a Scope-body revision by itself.

`completed_checkpoints` is ordered and may contain only checkpoint names defined by the orchestrator contract.
A `*:start` event without the corresponding `*:done` is incomplete and never appears as completed.
`next_action` names one permitted action such as `start:review`, `rerun:plan`, `gate:approve`, `continue:bundle:<id>`, `repair:confirm`, `restart:<boundary>`, `cancel`, or `complete`.

## Logical persistence by mode

All three modes expose the same fields and validation behavior.
Only the persistence transport differs.

### Linear

Append one immutable comment containing one complete summary at every checkpoint.
Use an exact `SPADE-RUN-STATE v1` heading so the comments can be distinguished from ordinary discussion and `HALTED:` records.
Retain earlier snapshots as history.
Select the newest structurally complete snapshot by authoritative tracker creation order and comment identifier, then verify its `previous_state` chain.
Reject unknown schemas, broken chains, sibling successors, or two snapshots that claim the same authoritative order.
Use the state id and event id as stable idempotency keys for one checkpoint attempt.
Identical retry comments with the same identifiers and content are benign under newest-well-formed-wins selection, but the same identifiers with different content are contradictory.
On contradiction, halt without appending or overwriting and surface the conflict for the bounded repair path.
After a timed-out append, read for those identifiers before retrying; retry only when absent and reuse the same identifiers.

### Local

Write `.spade/runs/<scope-key>.md`, where `<scope-key>` is the lowercase Linear issue identifier when present or the local Scope's stable `id`.
The key must satisfy the Local Layout slug grammar before it reaches the filesystem.
A legacy Scope without a stable safe key is not auto-resumable and must use restart or cancel.

The file contains exactly one current-summary region:

```markdown
<!-- SPADE-RUN-STATE-START v1 -->
[the complete field block]
<!-- SPADE-RUN-STATE-END -->
```

Create one marker pair when the run file is absent.
Replace only the content between one well-formed marker pair on subsequent checkpoints.
Refuse missing, mismatched, nested, or duplicate markers without modifying the file.
Malformed markers are repairable only when the retained event history and authoritative current artefacts prove one exact marker correction.
Preview that correction and require human confirmation before replacing the summary region; otherwise preserve the file and offer restart or cancel.

Keep timestamped event history outside the summary region.
Each event has a unique event id, UTC time, checkpoint name, and concise redacted result.
Append an event only when its id is absent so a repeated write is idempotent.

### Hybrid

Write the immutable tracker snapshot first.
After tracker success, mirror the same logical summary and event locally using the local rules.
A mirror failure produces one warning and does not roll back or weaken the tracker record.
A tracker-write failure aborts the checkpoint and must not create a local-only successor.

## Checkpoint write procedure

Write a new summary whenever the run records a stage boundary or changes the current bundle, task, branch, PR, verification, halt, or next allowed action.
Required boundaries include `run:start`; every `scope:*`, `review:*`, and `plan:*` event; approval; `delivery:base`; bundle and task start or completion; PR open or merge; optional-review outcome; required-check outcome; Delivery Review start or completion; tripwire halt; abort; selected autonomy-level halt; and run completion.

When an invocation starts against an existing Scope, structurally load its latest state before writing anything.
When new work has no Scope identity yet, keep only a provisional in-session `run_id` and do not persist a partial summary.
Immediately after the Scope artefact obtains its stable identity, write `run:start` and the first complete summary together.

For every checkpoint:

1. Re-read the current canonical snapshot and require that its `state_id` still equals the writer's expected predecessor.
2. Create one unique event id and one unique successor `state_id` with `previous_state` set to that predecessor.
3. Apply the completed-checkpoint and current-state transition without marking a `*:start` event complete.
4. Redact and bound every free-text result before persistence.
5. Persist the event and complete successor through the resolved mode's transport.
6. Re-read the persisted successor and verify its fields, markers where applicable, predecessor, and event id before advancing to the next stage.

In Linear, place the event line and complete snapshot in one immutable comment so a checkpoint cannot leave a summary without its event.
In local mode, build the complete replacement in a same-directory temporary file, verify the one marker pair and unique event id, then rename it over the run file.
Delete an uncommitted temporary file after a failed verification, but never alter the prior valid run file.
In hybrid mode, complete and verify the Linear write before attempting the local mirror.

A concurrent successor, tracker-write failure, malformed local file, failed read-back, or changed expected predecessor halts the run before the next stage.
Never retry by appending a second competing summary.

## Status read contract

`/spade-status` reads continuity state but does not validate external claims and does not mutate the run.
It classifies the newest structurally readable state as:

- `validation required` when a supported complete snapshot names a resumable next action;
- `halted` when `halt_reason` is set and human input or repair is required;
- `complete` when `next_action: complete` agrees with the terminal checkpoint;
- `legacy restart required` when trace history exists without a v1 summary;
- `invalid` when the summary is malformed, unsupported, forked, or unsafe; or
- `not recorded` when no continuity artefact exists.

Display the recorded phase, current work, last verification freshness, halt reason, and next action concisely.
Prefix any recorded next action with `unvalidated` until `/spade` completes live validation.
Never turn status output into permission to continue.

## Structural validation

Before consulting live systems:

1. Require exactly one supported schema and every required field.
2. Require valid value vocabularies, full commit SHAs when present, one-line redacted evidence, and a UTC timestamp.
3. Require one unbroken state chain for the selected `run_id`.
4. Require completed checkpoints to be ordered and compatible with `phase` and `next_action`.
5. Reject unsafe content rather than copying it into a repaired snapshot.

Structural validity permits live validation.
It never permits continuation on its own.

## Live validation

After structural validation, reconstruct the run from authoritative current systems in this order:

Apply only the checks required through the selected recorded boundary.
`none` is valid for artefacts that the run has not reached yet: Scope- and Plan-stage resumes legitimately lack delivery branches, base or head commits, current delivery work, PRs, and head-bound verification, and must not be classified stale for those absences.
Repository identity and worktree checks still apply when repository context is recorded, while delivery-specific branch, range, PR, and verification checks begin only when the corresponding checkpoint claims those artefacts.

1. **Capability:** read the installed capability version and require support for the recorded schema and every checkpoint named in the snapshot.
2. **Tracker and Scope:** read the parent issue or local Scope, confirm its stable identity, and compare the exact authoritative body revision with `scope_revision`.
3. **Plan and tasks:** read the canonical Plan, its revision, delivery bundles, task set, task statuses, and delivery modes; require them to match the approval and completed checkpoints.
4. **Approval and halt:** read the approval attribution and Plan revision it covers; when resuming a tripwire, require a durable human resolution that names the halted decision.
5. **Repository:** resolve the current repository identity, intended target, recorded base, current branch, and full head commits from Git rather than names or cached summaries.
6. **Worktree:** read the complete tracked and untracked worktree state; a non-clean result enters the dirty-worktree procedure and cannot pass this step by assumption.
7. **Current work:** reconcile the recorded bundle or task with the Plan, task status, branch range, and worktree.
8. **Pull request:** when present, use the project's authoritative hosted-PR read to verify identity, open or closed state, base, head, merge status, and required checks.
   When the recorded PR reference is missing, search authoritatively by the recorded branch, base, and head before classifying recovery.
   Exactly one exact match may enter evidence-proven repair; zero or multiple matches require restart or cancel.
9. **Verification:** require the recorded command or project-native tool result to target the current recorded head and to remain fresh under the Evaluate evidence rules.

Record the observed value and source for every check in the in-session validation report.
Do not copy credentials, full command output, private learning content, or unredacted tracker bodies into the next snapshot.

A branch name does not prove a branch exists.
A PR URL does not prove the PR exists or still names the same commits.
A task status does not prove its code or verification exists.
A trace, Plan, approval comment, cached session summary, or prior successful command does not substitute for the live reads above.

## Boundary selection and continuation

Select the highest safe boundary only after all prerequisites through that boundary pass live validation.
Never skip an incomplete `*:start` event or convert it to `*:done` from intent.

- After `scope:done`, the next boundary is Scope review.
- After current `review:done`, the next boundary is Plan generation.
- After `plan:done`, the next boundary is the existing Approve gate.
- After approval of that exact Plan revision, the next boundary is `delivery:base` or the first incomplete approved task.
- During delivery, the next boundary is the recorded incomplete bundle or task only when its branch, base, range, and worktree agree.
- After PR open, the next boundary is the first missing or stale required check, optional-review outcome, or Delivery Review step.
- After current complete Delivery Review, the next boundary is the open-PR human Evaluate gate.
- After a resolved tripwire, the next boundary is the halted stage only when the durable resolution and all affected live state agree.

Show a concise validation matrix and ask through `AskUserQuestion` with exactly two choices:

- `Continue from <boundary>`;
- `Cancel`.

Do not preselect Continue.
On Continue, write and verify one successor snapshot that records the human choice, preserved autonomy level, selected boundary, and refreshed evidence before performing the next mutation.
On Cancel, write only the cancel audit event and stop.

If the invocation requests an autonomy level different from the active run, do not silently upgrade, downgrade, or splice histories.
Treat it as a restart decision under the recovery contract.

## Already-completed work

When live state proves the selected autonomy level already reached its defined halt point, report that halt and the next human-owned gate without replaying a phase or writing duplicate external actions.
When live Scope, tasks, evaluation, and PR state prove the whole run complete, report `complete` and do not prompt to continue.
An open PR, a merged PR, and a Done state are distinct and must never be collapsed from the trace alone.

## Fail-closed recovery

Classify every failed structural or live check before asking the human to act:

- `missing` means a required summary field, canonical artefact, branch, PR, task, or evidence source does not exist;
- `malformed` means the supported summary cannot be parsed or violates its field, marker, ordering, or redaction contract;
- `unsupported` means the installed capability cannot interpret the schema or checkpoint vocabulary;
- `stale` means a once-valid reference or verification no longer describes the current authoritative state;
- `contradictory` means two authoritative or recorded facts cannot both be true; and
- `dirty-worktree` means tracked, staged, untracked, or other relevant local modifications require ownership classification.

Surface the exact failed check, recorded value, observed value, authoritative source, and why continuation is unsafe.
Never collapse several failures into a generic stale-state message.

After classification, offer only the applicable choices through `AskUserQuestion`:

- `Inspect without changes` when more evidence may clarify a malformed, unsafe, stale, or contradictory state but does not yet prove a repair;
- `Inspect and repair` only when live evidence proves one exact correction to non-authoritative recorded metadata;
- `Restart from <boundary>` at the last boundary whose human-owned intent and prerequisites remain valid; and
- `Cancel`.

Do not show `Inspect and repair` when more than one correction is plausible or when the correction changes Scope intent, acceptance criteria, Plan content, task set, approval, branch contents, delivery range, verification result, or external state.
Sibling snapshots with one predecessor and unsafe secret-bearing snapshots are not repairable metadata.
They may be inspected without changes, but must otherwise restart from the last safe boundary or cancel.
Do not preselect an option.

### Evidence-proven repair

Repair is a metadata correction, not a waiver.
The repair preview names the exact old value, new value, authoritative read, affected successor state, and checks that will rerun.
Require explicit human confirmation of that preview before writing a superseding snapshot.
Preserve the contradicted snapshot as history and link the successor to it.
Never edit an immutable Linear snapshot or erase a local event.

One stale PR URL may be repairable when exactly one authoritative PR has the recorded branch, base, and head.
This exact-match lookup is required after a direct read of the recorded PR reference fails.
Malformed local summary markers may be repairable when the retained event history and authoritative current artefacts prove one exact marker correction without changing state content.
Two plausible PRs, a missing branch, changed commits, changed Scope, changed Plan, or stale approval are not repairable metadata.

### Restart boundaries

- A changed Scope statement, acceptance criterion, or authoritative Scope revision restarts at Scope or Plan and invalidates downstream approval.
- A changed Plan, bundle map, task set, or delivery mode restarts at Plan approval.
- Missing, rejected, or revision-mismatched approval restarts at the Approve gate.
- A missing branch or invalid delivery range restarts at `delivery:base` or the first affected bundle without creating or deleting a branch automatically.
- A changed PR head restarts at required checks and both Delivery Review axes for the new head.
- A missing or ambiguous PR restarts at the PR boundary after preserving the branch and commits.
- Unsupported historical state restarts as a fresh run under the installed contract.

Restart never marks the prior failed stage complete.
It writes the human decision and named boundary, then follows the ordinary contract from that boundary.

## Dirty worktree procedure

Read the complete local state before classifying ownership:

1. Confirm repository identity, current branch, recorded base and head, and active bundle or task.
2. Inventory staged, unstaged, untracked, renamed, deleted, and conflicted paths without modifying them.
3. Read the full diff and the relevant untracked content needed to compare it with the approved task.
4. Compare every changed path and behavior with the recorded bundle, task, branch, base, and expected range.
5. Surface unrelated, ambiguous, unsafe, or secret-bearing content without copying sensitive bytes into continuity state.

When every change is consistent with the recorded current work, show the evidence and ask through `AskUserQuestion` with exactly:

- `Confirm ownership and continue`;
- `Inspect without changes`;
- `Cancel`.

Only the human can confirm that the changes belong to the interrupted run.
On confirmation, record the ownership decision and return to full live validation before continuing.

When any change falls outside the recorded work, do not offer Continue.
Offer inspect, restart without deleting changes, or cancel.
Restart selects a workflow boundary and leaves the worktree byte-for-byte unchanged for explicit human handling.

Never stash, reset, clean, delete, overwrite, switch branches, restore files, discard conflicts, or infer ownership automatically.
Cancel writes only its audit event and performs no repository, tracker, branch, Plan, task, or PR mutation.

## Durable refusal

Persist the failure classification and human decision as a successor snapshot or durable `HALTED:` record through the canonical mode path.
Do not include raw sensitive values.
A later invocation must re-read that decision and rerun affected live checks rather than bypassing or repeatedly asking the same resolved question.

## Learning decision checkpoints

Deliver and Evaluate may pause for `/spade-learn`'s human route after one evidence-backed candidate passes its gate.
Before the route is chosen, continuity state may record only `learning-decision-pending` as the halt reason and `gate:learning-route` as the next action.
Do not record the draft, evidence body, tags, learning body, private path, or sensitive match detail.

After the choice, record only one content-free outcome defined by `/spade-learn`'s candidate contract and continue from the same delivery or evaluation boundary.
`candidate:none` causes no prompt and no learning write.
A skipped or failed learning write does not rewrite the evaluation verdict or mark delivery incomplete, but any partial archive-and-replace result remains visible and halts that learning operation for human repair.

## Historical traces

Timestamped v3.0 traces without a `spade-run-state/v1` summary remain readable audit history.
Do not synthesize a v1 summary from them and do not rewrite them silently.
Offer restart under the installed contract or cancel.

## Behavioral gate

The fixed fixtures live in `tests/spade-continuity/corpus.md`.
Run `tests/spade-continuity/blind-procedure.md` in a fresh isolated context before release whenever this contract or any consuming skill changes.
