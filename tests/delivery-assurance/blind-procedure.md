# Delivery assurance blind behavioral procedure (PS-2319)

This procedure validates the behavior in [`corpus.md`](./corpus.md) from a fresh isolated context.
It is a documented behavioral gate because SPADE skill behavior is prose and the repository forbids a runtime that duplicates it.

## Independence requirement

The blind evaluator must be a different context from the context that authored or changed the delivery-assurance contracts.
If no isolated-context path is available, the gate is not satisfied.
Do not replace it with a same-context walkthrough and call that independent evidence.

## Inputs for the blind evaluator

Give the evaluator only:

1. The canonical or projected `/spade-plan`, `/spade-review`, `/spade`, and `/spade-evaluate` contracts under test, including any references those contracts route to for delivery assurance.
2. The case inputs from `corpus.md`: Scope, Plan outcome, immutable range, diff summary, repository standards, and supplied evidence.
3. The instruction below.

Do not provide the case's `Expected behavior` section or the corpus `Pass criteria` section.

```text
Run the SPADE delivery-assurance procedure for each supplied case.
Resolve one immutable base/head range and use it for both independent review axes.
Return the Scope/acceptance axis findings, then the repository-standards axis findings, then their synthesis.
Return one acceptance-evidence matrix row per criterion with class, evidence, evidence head where applicable, status, and open gap.
Recommend PASS, PARTIAL, or FAIL without selecting the human-owned final verdict.
Do not infer evidence that was not supplied.
```

## Procedure

1. Copy each case into a separate input without its expected outcome.
2. Run the blind evaluator in a fresh isolated context.
3. Record its two axis reports, matrix, recommendation, and range metadata.
4. Compare the result with that case's expected behavior.
5. Record each case as `match`, `pass-with-note`, or `divergence`.

A `pass-with-note` may differ in `PARTIAL` versus `FAIL` severity when both make the case ineligible for PASS and the reasoning is sound.
It may not omit a finding, accept stale evidence, invent external evidence, or collapse one review axis into the other.

## Gate verdict

**PASS** requires every positive control to be PASS-eligible and every negative or near-miss case to preserve its named failure.
Both axes must use the same recorded range and must be produced before synthesis.
The final verdict must remain explicitly human-owned.

**FAIL** applies when any false-complete case is reported as complete, an axis is missing, the axes use different ranges, stale evidence is accepted, external state is inferred from repository state, or the evaluator claims to own the final verdict.

## Evidence record

Retain this compact record in the delivery handoff or PR evidence:

```text
Delivery assurance blind corpus: PASS|FAIL
Context mode: <isolated mode>
Cases: P1=<result> P2=<result> N1=<result> N2=<result> N3=<result> N4=<result> N5=<result>
Axis independence: PASS|FAIL
Fixed-range consistency: PASS|FAIL
Human verdict ownership: PASS|FAIL
Notes: <only material divergences or pass-with-note differences>
```
