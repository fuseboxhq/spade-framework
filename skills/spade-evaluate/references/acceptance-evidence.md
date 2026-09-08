# Acceptance Evidence Contract

Read this reference completely for every full-loop Evaluate run.
Quick-path evaluation continues to use its separate PR-audit contract.

The evidence matrix makes completion falsifiable criterion by criterion.
It supplements current Delivery Review; it does not create a phase, replace project-native tools, or transfer the verdict from the human.

## Establish the evaluated head

Read the current Delivery Review report first.
Require:

- `review_kind: delivery`;
- `status: complete`;
- an isolated dispatch mode rather than `degraded`;
- both axes completed;
- one exact `base_sha` and `head_sha`; and
- the current delivered head still equal to the report's `head_sha`.

If any condition fails, invoke `/spade-review` in Delivery Review mode and use the new report.
If a complete fixed-range review still cannot be produced, keep the evaluation open and do not recommend PASS.

The evaluated head is the Delivery Review `head_sha`.
Every repository-bound command and UI run must be produced against that head.

## Classify every criterion once

Assign exactly one primary class to every acceptance criterion:

### `diff-verifiable`

Use when the criterion can be proven completely from the reviewed repository diff and static artefacts.
Examples include a required configuration key, documented contract, migration declaration, or removed forbidden call.

Evidence names the fixed base/head range and cites files, lines, or hunks.
Do not use this class when the criterion claims runtime behavior, deployed state, or human judgement.

### `runtime-verifiable`

Use when code must execute or render to prove the criterion.
Examples include API behavior, error handling, data flow, performance, browser interaction, and UI appearance.

Evidence records:

- the exact command or project-native tool action;
- the evaluated head SHA;
- the execution time;
- exit status or equivalent result;
- a concise result tied to the criterion; and
- retained artefacts when the claim needs them.

### `external-state`

Use when the authoritative truth lives outside the repository and delivered runtime.
Examples include a production setting, vendor configuration, deployed scheduler, stakeholder-owned system, or physical device state.

Evidence must be a fresh authoritative read from that system or a named trusted record.
A repository declaration, deployment command, or screenshot of a different environment does not prove external state.
When the authoritative read is unavailable, set the row to `open` and name the missing access or evidence.

### `human-only`

Use when completion is inherently a human judgement or confirmation rather than a mechanical fact.
Examples include subjective content approval, legal sign-off, stakeholder acceptance, or a physical observation only the human can make.

Record the named human confirmation and its date when supplied.
Until then, set the row to `open`.
The agent never fabricates, predicts, or self-approves this evidence.

## Freshness rules

Evidence is fresh only when it proves the final evaluated state.

- Diff evidence must name the current Delivery Review range.
- Runtime commands must run during the current Evaluate pass against the evaluated head.
- A command result copied from an older commit, earlier review, CI run for another head, or pre-fix working tree is stale.
- A later commit invalidates every prior head-bound command, browser artefact, and Delivery Review report.
- External-state evidence must be recent enough for the criterion's risk and volatility, and its observation time must be recorded.
- Human confirmation applies only to the exact criterion and delivered state the human reviewed.

Stale evidence remains visible for context but cannot satisfy a row.
Record the old head or time and the required rerun.

## UI evidence is claim-specific

Use the project's native browser and QA tools.
SPADE does not bundle or prescribe a browser runtime.

Select evidence based on the criterion:

- visual appearance or layout: rendered browser state plus screenshot;
- interaction or navigation: browser workflow or accessibility snapshot plus the resulting state;
- request count, payload, or failure: network evidence;
- absence or presence of client errors: console evidence;
- combined user flow: the smallest combination above that proves the whole claim.

Do not require UI evidence for a backend-only criterion.
Do not use a screenshot alone to prove network behavior or an error-free console.
At authentication, MFA, device approval, or another human security checkpoint, stop and leave the criterion open until the human completes it.

## Matrix row contract

Create exactly one row per acceptance criterion and preserve Scope order.

| Field | Contract |
|---|---|
| Criterion | Verbatim Scope text |
| Class | One of the four locked values |
| Evidence | File/hunk, command and concise result, authoritative external read, or human confirmation |
| Head / freshness | Evaluated head and `fresh`/`stale`, observation time for external state, or `not applicable` for human-only evidence |
| Status | `satisfied`, `open`, or `failed` |
| Verdict | `Pass`, `Partial`, or `Fail` |
| Open gap | `None` or the exact missing, stale, or contradictory evidence |

Use `open` when evidence is missing, stale, external, or awaiting human confirmation without proving the criterion false.
Use `failed` when current evidence demonstrates that delivered behavior contradicts the criterion.

## Synthesize review and evidence

Keep these inputs separate until each is complete:

1. Scope-conformance axis findings.
2. Engineering-standards axis findings.
3. Acceptance-evidence matrix rows.
4. Required repository check results at the evaluated head.

Then produce the agent recommendation:

- Recommend **FAIL** when a criterion failed, a blocking finding remains, the approach is fundamentally wrong, or the delivered behavior is unsafe.
- Recommend **PARTIAL** when any row is open or stale, a major finding remains, a review axis is incomplete, required checks are not current and passing, or a bounded fix can close the gap.
- Recommend **PASS** only when every row is satisfied, Delivery Review is current and pass-eligible, required repository checks pass at the evaluated head, and no unresolved finding makes the work unfit to ship.

A standards-only defect cannot disappear because every Scope criterion passed.
A green lint or test run cannot satisfy a missing Scope criterion without criterion-specific evidence.

Minor findings do not mechanically prohibit PASS.
State their shipping relevance so the human can decide whether they are acceptable.

## Human-owned verdict

Present the agent recommendation and its evidence, then ask the human through `AskUserQuestion` to select exactly one existing verdict:

- `PASS - ready to ship`
- `PARTIAL - fixes needed`
- `FAIL - rework required`

The agent must not preselect, record, or imply the human's choice.
If PASS is not evidence-supported, label it unsupported and explain why before asking.

Evaluate and the move to Done follow the recorded verdict; the human owns Ship.
An agent may operate the merge control only after the existing explicit post-Evaluate authorization and a fresh head/check revalidation.

## Persistence

Include the current Delivery Review summary and complete evidence matrix in the evaluation report.
Persist it through the existing Linear or local-mode evaluation path.
Name stale evidence and open human or external rows explicitly so a later Evaluate pass can refresh only what changed without treating the prior report as current.

## What this contract must never do

- Omit an acceptance criterion from the matrix.
- Classify runtime behavior as diff-verifiable merely because code exists.
- Accept test, UI, or review evidence from another head.
- Infer production or vendor state from repository configuration.
- Demand browser ceremony for work with no UI criterion.
- Let either Delivery Review axis suppress the other.
- Turn an agent recommendation into the final human verdict.
- Mark Done without a recorded PASS behind it, or merge, deploy, or ship outside the merge policy and the existing human-owned gates.
