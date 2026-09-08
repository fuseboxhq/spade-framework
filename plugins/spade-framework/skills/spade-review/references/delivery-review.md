# Delivery Review Contract

Read this reference completely when `/spade-review` resolves Delivery Review mode.

Delivery Review examines work after code or other reviewable artefacts exist.
It extends the existing review skill rather than adding a phase or a new shipping framework.
The report is advisory evidence for Evaluate, and the human retains the final PASS, PARTIAL, or FAIL decision.

## Required inputs

Gather these inputs before dispatching either axis:

- The original Scope with every acceptance criterion.
- The approved Plan, including its task cards and delivery bundles.
- The delivered branch, hosted pull request, or committed local head.
- Applicable repository instructions and engineering standards, including `AGENTS.md`, `ARCHITECTURE.md`, `PATTERNS.md`, `ANTI-PATTERNS.md`, and project-native lint and test commands when present.
- Any delivery evidence already recorded, labelled with the commit that produced it.

Read the Plan from the tracker first and the local fallback second, following the existing Plan read contract.
Tracker mode determines where Scope and Plan data live; it never changes the git range under review.

## Resolve one immutable range

Resolve the range once at the start of the review and record exact full commit SHAs.
Never review a moving branch name, cached summary, or PR URL without resolving it to commits.

Use this precedence:

1. **Hosted pull request.**
   Use the project-native PR tool to read the exact base and head commit SHAs.
   Record `range_source: hosted-pr` and the PR identifier.
2. **Recorded delivery bundle.**
   Use the base SHA recorded before delivery began and resolve the current committed bundle head.
   Record `range_source: delivery-record` and the bundle identifier.
3. **Committed local branch.**
   Resolve the intended target branch from project configuration, the approved Plan, or an explicit human instruction.
   Compute its merge base with the committed local head and record `range_source: local-merge-base` plus the target ref used.

Record:

```json
{
  "base_sha": "<full commit sha>",
  "head_sha": "<full commit sha>",
  "range_source": "hosted-pr|delivery-record|local-merge-base",
  "source_ref": "<pr, bundle, or target ref>",
  "captured_at": "<ISO-8601 timestamp>",
  "diff_command": "git diff --find-renames <base_sha>..<head_sha>"
}
```

Verify that both commits exist locally or are available through the project-native hosted review tool.
Verify that the base is an ancestor of the head or is the explicitly recorded merge base.
Generate one changed-file list and one diff for `base_sha..head_sha`.

An uncommitted working tree cannot produce reusable Delivery Review evidence because its content has no `head_sha`.
The agent may describe the working diff as provisional, but the report status is `incomplete` and cannot support PASS until the work is committed and reviewed again.

## Dispatch exactly two independent axes

Dispatch both axes through `spawn_agent with a self-contained prompt and no inherited conversation` in parallel when the host supports it.
Use sequential isolated contexts when parallel dispatch is unavailable.
Record the existing dispatch vocabulary:

- `subagent-dispatch` for parallel independent contexts;
- `sequential-inproc` for separate isolated contexts run one at a time; or
- `degraded` when no isolated path exists.

`degraded` is not independent Delivery Review.
Persist what happened honestly, mark the report `incomplete`, and do not let Evaluate use it to support PASS.

Both axes receive the same range metadata, changed-file list, and exact diff.
Neither axis receives the other axis's prompt, prose summary, findings, or intermediate reasoning.

### Axis 1: Scope and acceptance-criteria conformance

Give this axis:

- The project and Scope context.
- Every acceptance criterion verbatim.
- The approved Plan and its task cards.
- The fixed range metadata and exact diff.
- Delivery evidence, clearly distinguished from evidence Evaluate still needs to refresh.

Its only concern is whether the delivered range implements the whole Scope without silent omissions or out-of-scope expansion.
It checks Plan-to-diff traceability, every acceptance criterion, every card's "Done when" outcome, error and edge behavior named by the Scope, and whether delivered behavior is actually usable across the necessary layers.
It does not review general code style, architecture preferences, or repository standards unless they directly demonstrate Scope non-conformance.

### Axis 2: Repository engineering-standard conformance

Give this axis:

- The project context.
- Applicable repository instructions and engineering-standard documents.
- The project-native lint and test contract.
- The fixed range metadata and exact diff.
- Current delivery commands and results, with their producing head SHAs.

Its only concern is whether the delivered range meets the repository's engineering bar independent of Scope completion.
It checks architecture and pattern alignment, anti-pattern violations, correctness and edge cases not waived by the Scope, maintainability, security, dependency policy, relevant documentation, and the required native checks.
It does not receive acceptance-criterion verdicts or the Scope axis findings.
A defect remains reportable even when every acceptance criterion passes.

## Axis output contract

Each axis returns a short prose summary followed by a JSON code block labelled `spade-delivery-findings`.
The array contains at most five findings from that axis.

```json
[
  {
    "axis": "scope-conformance|engineering-standards",
    "severity": "blocking|major|minor",
    "confidence": "high|low",
    "category": "<short axis-owned category>",
    "message": "one or two lines",
    "refs": ["<scope criterion, plan task, file:line, or standard reference>"]
  }
]
```

Severity means:

- `blocking`: the delivered work is unsafe, fundamentally incomplete, or wrong to ship.
- `major`: a material defect or evidence gap that should be fixed before PASS.
- `minor`: a bounded concern that does not by itself make the work unfit to ship.

Malformed output is not repaired.
Preserve the axis prose, report the parse failure, and mark that axis incomplete.

## Synthesis without suppression

Wait for both axes before synthesizing.
Keep every finding from both axes.
If both axes identify the same underlying concern, show convergence with `also_flagged_by`, but retain the originating axis and the sharper message.
Do not merge merely related findings.
Never drop an engineering-standard finding because Scope criteria passed, and never drop missing Scope behavior because repository checks are green.

Sort by severity, then convergence.
Confidence is display metadata, not a sort key.

Set `pass_eligible` to `false` when any of these hold:

- either axis is incomplete;
- dispatch mode is `degraded`;
- the range is provisional or stale;
- any unresolved `blocking` or `major` finding remains.

`pass_eligible` is an evidence statement, not the final Evaluate verdict.
The human may still select PARTIAL or FAIL based on the combined evaluation record.

## Delivery Review report envelope

Every inline and persisted Delivery Review report starts with a valid JSON envelope:

```json
{
  "schema_version": "1.0.0",
  "review_kind": "delivery",
  "dispatch_mode": "subagent-dispatch",
  "status": "complete",
  "range": {
    "base_sha": "<full sha>",
    "head_sha": "<full sha>",
    "range_source": "hosted-pr",
    "source_ref": "PR 123",
    "captured_at": "2026-07-13T12:00:00Z",
    "diff_command": "git diff --find-renames <base_sha>..<head_sha>"
  },
  "axes": [
    {"name": "scope-conformance", "status": "completed", "findings": 0},
    {"name": "engineering-standards", "status": "completed", "findings": 1}
  ],
  "findings_total": 1,
  "pass_eligible": false
}
```

`status` is `complete`, `incomplete`, or `stale`.
The two axis entries always appear in the fixed order above.
Counts are exact after convergence synthesis.

## Bounded presentation and persistence

The inline report contains, in order:

1. `Delivery review: <dispatch_mode>` as the first line.
2. The envelope JSON.
3. `DELIVERY REVIEW` as the section title.
4. The fixed base/head range and its source.
5. Each axis's prose summary verbatim.
6. Every convergence finding.
7. Every blocking finding and enough major findings to keep the total detailed finding budget near seven.
8. A count for undisplayed major findings.
9. A count for minor findings, which are never expanded inline.
10. The `pass_eligible` value and reasons when false.
11. The full report path.

Persist the full report to `.spade/reviews/<slug>-delivery-<date>.md`.
Use the existing collision rule and never overwrite a prior run.
The full report includes the envelope, range, both verbatim axis summaries, every finding, synthesis, and pass-eligibility reasons.
Persistence failure is surfaced but does not erase the inline report.

## Freshness check

Immediately before returning the report, resolve the delivery head again from the same source.
If it differs from `head_sha`, mark the report `stale`, set `pass_eligible: false`, and name both SHAs.
Do not silently rerange one axis or relabel old findings.
A new head requires a complete rerun of both axes against the unchanged base and the new head.

## Standalone versus Evaluate invocation

When Delivery Review is invoked standalone, present the report and ask the existing advisory action question: act on findings, continue as-is, or discuss further.
When invoked by Deliver or Evaluate, return the report without a separate verdict prompt so the calling flow can continue.
Evaluate owns evidence classification and asks the human for the final fixed-option PASS, PARTIAL, or FAIL decision.

## What Delivery Review must never do

- Review different ranges on the two axes.
- Pass one axis's findings into the other axis before it finishes.
- Infer that green tests prove every Scope criterion.
- Infer that Scope completion waives repository engineering standards.
- Accept a branch name, cached test summary, or old report as current-head evidence.
- Claim independent axes when dispatch mode is `degraded`.
- Select the Evaluate verdict, mark the Scope Done, merge, or deploy. Review reports; Evaluate decides.
