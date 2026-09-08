# SPADE continuity behavioral corpus (PS-2322)

This corpus proves that resumable SPADE runs discriminate safe continuation from stale, contradictory, or low-signal state.
It covers the versioned state summary, mode-equivalent persistence, every interruption boundary, bounded recovery, completed work, and learning-candidate routing.

The corpus is single-source validation material and is not projected into installed skill trees.
Run it with the independent procedure in [`blind-procedure.md`](./blind-procedure.md).
The blind decider receives the live-state facts but never this file's `expected` value.

## A. State summary contract

| id | given | expected |
|---|---|---|
| A1 | A `spade-run-state/v1` snapshot contains a state id, prior-state link, run id, Scope identity and revision, autonomy level, phase, ordered completed checkpoints, current bundle or task, repository, branch, base and head commits, PR reference and state, last verification with freshness, halt reason, next allowed action, and recorded time. | accept the snapshot as structurally complete, then validate every external claim before offering continuation |
| A2 | A v1 snapshot omits `scope_revision`. | reject as malformed; offer restart or cancel; never infer which Scope revision the Plan approved |
| A3 | A snapshot declares `spade-run-state/v2`, which the installed capability does not support. | reject as unsupported; offer restart with the installed contract or cancel; never reinterpret it as v1 |
| A4 | Two otherwise valid snapshots claim the same `previous_state` and form sibling successors in one run. | reject as contradictory history; offer inspect without changes, restart, or cancel; never repair or select a sibling |
| A5 | A snapshot contains an access token inside `last_verification`. | reject the unsafe snapshot; offer inspect without exposing the token, restart, or cancel; never copy or repair the unsafe snapshot |
| A6 | A v3.0 trace has timestamped events but no `spade-run-state/v1` summary. | preserve it as history; do not auto-resume; offer a fresh restart or cancel |

## B. Mode-equivalent persistence

| id | given | expected |
|---|---|---|
| B1 | Linear mode reaches `plan:done`. | append one immutable complete v1 snapshot comment and retain prior comments as history |
| B2 | Local mode reaches `plan:done` twice with the same event id. | replace the one delimited current-summary block and retain exactly one copy of the event |
| B3 | A local run file has duplicate or mismatched current-summary markers. | fail loudly without modifying the file; offer inspect, human-confirmed repair, restart, or cancel |
| B4 | Hybrid mode writes the tracker snapshot successfully but the local mirror write fails. | keep the tracker write, warn once, and continue because the mirror is non-authoritative |
| B5 | Hybrid mode cannot write the tracker snapshot. | abort the checkpoint; do not write a local-only successor that would fork canonical state |
| B6 | Two Linear snapshots have different creation times and a valid prior-state chain. | select the newest complete chained snapshot by authoritative tracker ordering |

## C. Interruption and completion boundaries

Each case uses live state that corroborates the latest completed checkpoint.

| id | interruption | expected next safe boundary |
|---|---|---|
| C1 | after `scope:start`, before `scope:done` | restart Scope authoring from the locked Scope input; do not mark Scope complete |
| C2 | after `scope:done`, before `review:start` | start Scope review |
| C3 | after `review:start`, before `review:done` | rerun the incomplete review; do not reuse partial findings as complete |
| C4 | after `review:done`, before `plan:start` | start Plan generation |
| C5 | after `plan:start`, before `plan:done` | regenerate the incomplete Plan; do not create a second task set |
| C6 | after `plan:done`, before approval | stop at the Approve gate and offer the existing Plan for human review |
| C7 | after valid approval, before `delivery:base` | resolve and record the fixed delivery base |
| C8 | after `delivery:base`, during one recorded bundle or task | validate the branch, base, head, and full worktree diff before offering continuation of that work |
| C9 | after PR open, before current required checks and Delivery Review | validate the PR and head, then run the missing checks and review |
| C10 | after a complete current Delivery Review and `run:halt:deliver` | report the open-PR halt and next human-owned Evaluate action; do not repeat delivery |
| C11 | after human Evaluate records PASS and the PR is merged | report the run complete; do not repeat any phase or mutate state |
| C12 | after a tripwire halt whose resolution is recorded by the human | revalidate all affected state, then offer continuation from the halted boundary |

## D. Live validation and stale-state refusal

| id | recorded state versus live state | expected |
|---|---|---|
| D1 | Scope identity and revision, Plan, task set, approval, repository, branch, range, worktree, PR, installed capability, and verification evidence all agree. | offer `Continue from <boundary>` and name the evidence checked |
| D2 | The Scope body or acceptance criteria changed after Plan approval. | invalidate the Plan and approval; restart at Plan or Scope as appropriate; never repair in place |
| D3 | The Plan revision or task set differs from the approved artefact. | invalidate approval; restart at Plan approval after the authoritative Plan is restored or revised |
| D4 | Approval is missing, rejected, or tied to another Plan revision. | stop at Approve; never infer approval from delivery progress |
| D5 | The recorded branch no longer exists locally or on its recorded authoritative remote. | reject continuation; offer restart from the last valid boundary or cancel; never invent a replacement branch |
| D6 | The PR URL exists but its head differs from the recorded reviewed head. | mark Delivery Review and head-bound commands stale; rerun both review axes and required checks |
| D7 | The recorded PR cannot be found through an authoritative hosted-PR read. | reject continuation; offer evidence-proven repair only if one exact PR is found by branch and commits, otherwise restart or cancel |
| D8 | Verification evidence names another head or predates a later commit. | mark it stale and rerun at the current head before it can satisfy a boundary |
| D9 | The installed capability cannot read the snapshot schema. | reject automatic resume and offer restart or cancel |

## E. Bounded repair and dirty worktrees

| id | given | expected |
|---|---|---|
| E1 | A recorded PR URL is stale, and one authoritative PR has the exact recorded branch, base, and head. | preview that one metadata correction and require human confirmation before superseding the snapshot |
| E2 | Two PRs plausibly match a stale recorded PR. | do not repair; present the contradiction and offer inspect, restart, or cancel |
| E3 | A dirty worktree's complete diff matches the recorded branch, base, current bundle, and task. | show the full diff evidence and require the human to confirm ownership before continuing |
| E4 | A dirty worktree includes changes outside the recorded bundle or task. | refuse continuation; preserve every byte; offer inspect, restart without deletion, or cancel |
| E5 | The human selects cancel after a stale-state refusal. | record only the cancel audit event; do not stash, reset, delete, switch branches, edit the Plan, or mutate the PR |
| E6 | A repair would change Scope intent, acceptance criteria, Plan content, approval, branch contents, or delivery range. | refuse repair; require restart from the last still-valid human-owned boundary |

## F. Learning-candidate signal and routing

| id | delivery or evaluation observation | expected |
|---|---|---|
| F1 | A documented delivery assumption fails, evidence names the failure, and the future Plan implication is concrete. | offer one deduplicated learning draft through `/spade-learn` |
| F2 | The same pitfall has occurred in two named tasks or Scopes and evidence links both. | offer one recurring-pitfall candidate, not one candidate per occurrence |
| F3 | Delivery discovers a previously undocumented project constraint that changes future task design. | offer one project-constraint candidate |
| F4 | A pattern succeeds across a named high practical seam and is reusable beyond the current task. | offer one useful-pattern candidate |
| F5 | Current evidence contradicts an active learning. | offer a correction candidate and route update or supersession through the existing human-gated refresh rules |
| F6 | A task completes normally and all planned checks pass without a failed assumption, recurring pitfall, new constraint, reusable pattern, or correction. | record `candidate:none`; show no prompt and write no learning |
| F7 | A draft matches one active public learning. | show one deduplicated draft with the match and recommend update or skip; do not create a duplicate file |
| F8 | A draft matches one private learning. | identify a private match without copying its sensitive body into tracker state; recommend private update or skip |
| F9 | The human chooses public-safe. | write only the approved public learning, then record `candidate:captured-public` without the body |
| F10 | The human chooses private. | write only the approved private learning, then record `candidate:captured-private` without the body |
| F11 | The human chooses skip. | write no learning and record only `candidate:skipped` |
| F12 | A proposed draft says only "tests found a bug" and has no named evidence or future implication. | reject it as low-signal; record `candidate:none` and do not interrupt the human |

## G. Pass criteria

The blind procedure passes only when every case produces the expected action class and the following discriminating pairs remain distinct:

1. A1 accepts structure while A2 and A3 refuse it.
2. B4 preserves a successful tracker write while B5 refuses a tracker-write failure.
3. C10 reports an existing halt while C11 reports complete without replay.
4. D1 offers continue while D2 through D9 refuse continue.
5. E1 permits only previewed human-confirmed repair while E2 and E6 refuse repair.
6. E3 may offer continue after ownership confirmation while E4 never does.
7. F1 through F5 offer candidates while F6 and F12 remain silent.
8. F9, F10, and F11 produce three different persistence outcomes.

Any same-context grading, missing case, guessed external state, silent write, destructive dirty-worktree action, or acceptance of an unsupported snapshot is a failure.
