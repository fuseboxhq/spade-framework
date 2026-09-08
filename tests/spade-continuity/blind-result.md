# PS-2322 continuity blind result

## Mechanism

The blind deciders ran as fresh isolated collaboration agents with no inherited conversation context.
They received only the canonical continuity contracts and case inputs without identifiers' expected values, corpus pass criteria, prior answers, the Plan, or Git history.
The initial run tested commit `2c24259cc1d3eaa8d8a166b2b4b0ef4a6ce3e645`.
The final affected-case run tested the contract content committed as `e4d117e7425db8be87ade5f703009625375bfb61`.
The PS-2420 affected-case rerun tested working-tree input digest `6da5b8e6aaca13745d8ef75eb271cf1353ba3cbde56d8b899f9325515a1d44ab`.

## Initial 51-case run

| Case | Result | Note |
|---|---|---|
| A1 | match | Complete structure still required full live validation. |
| A2 | match | Missing Scope revision failed malformed. |
| A3 | match | Unsupported schema failed closed. |
| A4 | divergence | The decider correctly refused the fork but omitted the oracle's repair option. |
| A5 | divergence | The decider correctly rejected unsafe content but omitted the oracle's redaction repair. |
| A6 | match | Legacy history required a fresh restart. |
| B1 | match | Linear persistence remained immutable. |
| B2 | match | Local persistence remained idempotent. |
| B3 | divergence | The decider refused malformed markers but omitted conditional repair. |
| B4 | match | Tracker success survived mirror failure. |
| B5 | match | Tracker failure blocked the checkpoint. |
| B6 | match | Tracker ordering selected the newest valid chain. |
| C1 | match | Incomplete Scope authoring reran. |
| C2 | match | Completed Scope advanced to review. |
| C3 | match | Incomplete review reran. |
| C4 | match | Completed review advanced to Plan. |
| C5 | match | Incomplete Plan generation reran. |
| C6 | match | Completed Plan halted at Approve. |
| C7 | match | Valid approval advanced to the delivery base. |
| C8 | match | Active delivery required branch and worktree validation. |
| C9 | match | Open PR work resumed at stale or missing checks and review. |
| C10 | match | Deliver halt reported the human Evaluate gate. |
| C11 | match | Evaluated and merged work reported complete without replay. |
| C12 | match | A resolved tripwire required affected-state revalidation. |
| D1 | match | Fully corroborated state offered Continue or Cancel. |
| D2 | match | Changed Scope invalidated downstream approval. |
| D3 | match | Changed Plan returned to Plan approval. |
| D4 | match | Missing or stale approval returned to Approve. |
| D5 | match | Missing branch returned to a delivery boundary. |
| D6 | match | Changed PR head invalidated checks and both review axes. |
| D7 | divergence | The decider returned to the PR boundary without naming the exact-match repair search. |
| D8 | match | Stale verification reran against the current head. |
| D9 | match | Unsupported state required a fresh restart. |
| E1 | match | Exact PR metadata repair required preview and confirmation. |
| E2 | divergence | The decider correctly refused ambiguous repair but omitted inspect without changes. |
| E3 | match | Matching dirty work required ownership confirmation. |
| E4 | match | Unrelated dirty work refused continuation and preserved bytes. |
| E5 | match | Cancel wrote only the audit event. |
| E6 | match | Substantive state could not be repaired as metadata. |
| F1 | match | Failed assumption produced a gated candidate. |
| F2 | match | Recurring pitfall produced one deduplicated candidate. |
| F3 | match | New project constraint produced a candidate. |
| F4 | match | Reusable high-seam pattern produced a candidate. |
| F5 | match | Contradicted learning entered the refresh rules. |
| F6 | match | Ordinary success recorded no candidate. |
| F7 | match | Public duplicate required deduplication. |
| F8 | match | Private duplicate remained protected. |
| F9 | match | Public-safe approval wrote only the approved public learning. |
| F10 | match | Private approval wrote only the approved private learning. |
| F11 | match | Skip wrote no learning. |
| F12 | match | Generic low-signal text produced no candidate. |

## Divergence retry and correction

A second fresh context reproduced divergences A4, A5, B3, D7, and E2.
A4 and A5 exposed oracle expectations that conflicted with the approved policy limiting repair to exact non-authoritative metadata.
Their expected results now require inspect without changes, restart, or cancel and prohibit repair.
The canonical contract now distinguishes inspect without changes from repair, makes one exact marker correction conditionally repairable, and requires an authoritative exact branch-base-head search after a recorded PR lookup fails.

## Final affected and shared-pair run

| Case | Result | Note |
|---|---|---|
| A4 | match | Forked siblings allowed inspect, restart, or cancel and prohibited repair. |
| A5 | match | Unsafe state allowed redacted inspect, restart, or cancel and prohibited repair. |
| B3 | match | Marker repair required one exact correction and human confirmation. |
| D1 | match | Valid state still offered continuation from the highest safe boundary. |
| D2 | match | Scope changes still invalidated downstream state. |
| D3 | match | Plan changes still returned to Plan approval. |
| D4 | match | Approval failures still halted at Approve. |
| D5 | match | Missing branch still returned to delivery base or the affected bundle. |
| D6 | match | New PR head still invalidated checks and review. |
| D7 | match | Missing PR reference required exact-match search before repair or restart. |
| D8 | match | Stale verification still reran at the current head. |
| D9 | match | Unsupported state still required a fresh restart. |
| E1 | match | One exact PR remained repairable only after confirmation. |
| E2 | match | Ambiguous PRs allowed inspect without changes, restart, or cancel. |
| E6 | match | Substantive changes remained ineligible for repair. |

## PS-2420 affected-case rerun

Fresh isolated native `fork_turns=none` deciders reran the cases affected by Linear retry idempotency, hybrid mirror authority, and boundary-conditional live validation.

| Case | Result | Note |
|---|---|---|
| A4 | match | Sibling successors remained contradictory, while only identical retry records were benign. |
| B1 | match | Linear Plan completion used stable retry identifiers and required read-before-retry. |
| B2 | match | Local event persistence remained idempotent. |
| B4 | match | Tracker success remained canonical despite mirror failure. |
| B5 | match | Tracker failure created no local successor. |
| B6 | match | Authoritative tracker order selected the newest valid chain. |
| C1 | match | Incomplete Scope authoring reran without requiring future delivery artefacts. |
| C2 | match | Completed Scope advanced to review without branch, PR, or verification evidence. |
| C5 | match | Incomplete Plan generation reran without misclassifying absent delivery artefacts as stale. |
| C6 | match | Completed Plan halted at Approve with delivery artefacts legitimately absent. |
| C7 | match | Valid approval advanced to delivery base while later delivery artefacts remained absent. |
| C9 | match | An opened PR required the now-applicable authoritative PR and head evidence. |
| C10 | match | Completed Delivery Review preserved the human Evaluate halt. |
| C11 | match | Evaluated and merged work remained complete without replay. |
| D1 | match | Fully corroborated state still offered the highest safe continuation boundary. |

## Verdict

PASS: all 51 cases match the final expected action classes, and the revised recovery rule passes every affected case and shared discriminating pair.
The PS-2420 wording changes also pass every affected case and relevant discriminating pair.
No decider guessed external state, authorized a silent learning write, or permitted destructive dirty-worktree handling.
