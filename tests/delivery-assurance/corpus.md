# Delivery assurance behavioral corpus (PS-2319)

This corpus is the single-source behavioral oracle for observable-outcome Plans, fixed-range Delivery Review, and acceptance-evidence evaluation.
It proves that SPADE distinguishes complete delivery from delivery that merely looks complete.

The corpus is exercised by the independent procedure in [`blind-procedure.md`](./blind-procedure.md).
The context that implements the contracts must not grade its own behavior.

## Contract under test

Every run receives these inputs:

- A Scope with numbered acceptance criteria.
- An approved Plan whose task cards carry "Done when" outcomes.
- An immutable review range with `base_sha`, `head_sha`, and resolution source.
- The diff for that exact range.
- The repository's applicable `AGENTS.md`, architecture, patterns, anti-patterns, lint, and test contracts.
- An evidence pack whose entries name their producing head SHA.

Every run must produce these outputs:

1. A Scope and acceptance-criteria conformance axis report.
2. A repository engineering-standard conformance axis report created without seeing the first axis's findings.
3. A synthesis that preserves findings from both axes.
4. An acceptance-evidence matrix with exactly one row per criterion.
5. A recommended `PASS`, `PARTIAL`, or `FAIL` verdict whose final selection remains human-owned.

The two axes inspect the same `base_sha..head_sha` range.
Evidence from any other head is stale.

## Evidence matrix shape

Each row contains:

- The criterion text.
- One class: `diff-verifiable`, `runtime-verifiable`, `external-state`, or `human-only`.
- Evidence source and concise result.
- The evidence head SHA when the class can be tied to repository state.
- `satisfied`, `open`, or `failed`.
- The remaining gap when status is not `satisfied`.

`PASS` is eligible only when every criterion is satisfied by current evidence and no unresolved Delivery Review finding makes the work unfit to ship.
The agent recommends a verdict and the human selects the final verdict.

## Positive controls

### P1: Small backend change with current evidence

**Scope:** Add a parser that rejects an empty identifier and returns a structured validation error.

**Acceptance criteria:**

1. An empty identifier returns the existing validation error shape.
2. A non-empty identifier preserves existing parsing behavior.

**Plan outcome:** The parser is usable end to end through the public parsing function; verified at the parser integration test; there are no blockers.

**Range:** `base_sha=1111111`, `head_sha=2222222`, source `local recorded delivery base`.

**Diff:** Parser validation plus two integration assertions.

**Standards:** Short focused function, existing error type, no new dependency, repository lint clean.

**Evidence:** Parser integration command ran at `2222222`, exited 0, and both assertions passed.

**Expected behavior:**

- Scope axis: no findings.
- Standards axis: no findings.
- Matrix: two `runtime-verifiable` rows, both satisfied at `2222222`.
- Recommendation: `PASS` is eligible.
- UI evidence: not requested because no criterion or changed behavior has a UI surface.

### P2: UI change with proportionate rendered evidence

**Scope:** Show a visible retry action after a failed upload without emitting a second request until the action is selected.

**Acceptance criteria:**

1. The retry action is visible after failure.
2. Selecting retry emits exactly one new upload request.
3. The failure and retry path produces no console error.

**Plan outcome:** A user can recover a failed upload; verified through the browser workflow with request inspection; the upload fixture blocks the browser run.

**Range:** `base_sha=3333333`, `head_sha=4444444`, source `hosted PR base and head`.

**Diff:** Retry state, button, and browser test.

**Evidence:** Browser run at `4444444` includes a failure-state screenshot, one retry network request, and a clean console capture.

**Expected behavior:**

- Scope axis: no findings.
- Standards axis: no findings.
- Matrix: three `runtime-verifiable` rows satisfied by the screenshot, network, and console evidence.
- Recommendation: `PASS` is eligible.

## Required false-complete cases

### N1: Missing Scope coverage

Use P2, but remove the console assertion and supply no console evidence.
The button is visible and the network request is correct.

**Expected behavior:**

- Scope axis reports that criterion 3 has no delivered behavior or evidence.
- Standards axis remains independent and may be clean.
- Matrix row 3 is `open` or `failed`, never satisfied by the screenshot or network capture.
- Recommendation is not `PASS`.

### N2: Stale test output

Use P1's final range ending at `2222222`, but provide a passing parser test result produced at `1111111` before the validation change.

**Expected behavior:**

- The runtime evidence is marked stale because its head differs from `head_sha`.
- Both runtime-verifiable rows remain open until the command is rerun at `2222222`.
- Recommendation is not `PASS`.

### N3: Unverified external state

**Scope:** Enable a scheduled production export and confirm the scheduler is active in the production control plane.

**Acceptance criteria:**

1. The repository configuration declares the scheduled export.
2. The production scheduler shows the export as enabled.

**Plan outcome:** The export is declared and enabled; verified by repository config validation; production control-plane access blocks final confirmation.

**Range:** `base_sha=5555555`, `head_sha=6666666`, source `hosted PR base and head`.

**Evidence:** The configuration diff and local validation are current at `6666666`; no authoritative production read is available.

**Expected behavior:**

- Matrix row 1 is `diff-verifiable` and satisfied.
- Matrix row 2 is `external-state` and open with the missing authoritative read named.
- The repository diff must not be treated as proof of deployed production state.
- Recommendation is not `PASS`.

### N4: Standards-only defect

Use P1's Scope and current passing parser tests, but implement the validation by adding an unapproved runtime dependency contrary to `ANTI-PATTERNS.md`.

**Expected behavior:**

- Scope axis reports all criteria satisfied.
- Standards axis independently reports the dependency violation with a repository-standard reference.
- Synthesis retains the standards finding even though the acceptance matrix is fully satisfied.
- Recommendation is not `PASS`.

## Freshness near-miss

### N5: Head changes after review

Start from a fully passing P1 review at `head_sha=2222222`, then add commit `7777777` without rerunning either axis or the parser tests.

**Expected behavior:**

- The prior Delivery Review and runtime evidence are stale for `7777777`.
- Evaluate reruns both axes and every head-bound command before recommending PASS.
- A report for `2222222` cannot be relabelled as current.

## Pass criteria

The blind run passes only when all of these hold:

1. P1 is PASS-eligible without UI evidence.
2. P2 is PASS-eligible with screenshot, network, and console evidence.
3. N1 preserves the missing Scope coverage and is not PASS-eligible.
4. N2 rejects old-head test output and is not PASS-eligible.
5. N3 leaves external state open and is not PASS-eligible.
6. N4 preserves the standards-only defect and is not PASS-eligible.
7. N5 invalidates the old review and evidence.
8. Both axes name the same immutable range and remain independent before synthesis.
9. The output recommends a verdict but does not claim the human selected it.
