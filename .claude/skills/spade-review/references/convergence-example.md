# Convergence Worked Example

Read this reference only when implementing or debugging convergence merging.
### Worked example

This is a **Plan Review** of corpus case **C1** — a webhook handler that
verifies a caller-supplied signature. Cast-on-evidence cast a **selective
three**: `scope-guardian` (acceptance-criteria testability),
`security-lens` (the trust boundary), and `adversarial-reviewer`
(forged-event failure mode). The `architecture-strategist` lane was
**absent** (the change names no PATTERNS / ANTI-PATTERNS surface) and the
`alternatives-analyst` lane was **absent** (a point-solution endpoint with
no option latitude) — so neither was cast, and neither carries a
`dropped[]` entry. The five findings below come from the three cast
personas (refs omitted for brevity):

```json
[
  {"persona": "security-lens", "severity": "major", "confidence": "high",
   "category": "trust-boundary",
   "message": "Task 2's webhook handler trusts the caller-supplied signature header without verifying it against the shared secret."},
  {"persona": "adversarial-reviewer", "severity": "major", "confidence": "high",
   "category": "hidden-assumption",
   "message": "The Plan assumes the webhook caller is already authenticated upstream; if that assumption is wrong, Task 2 processes forged events."},
  {"persona": "scope-guardian", "severity": "minor", "confidence": "high",
   "category": "acceptance-criteria",
   "message": "Acceptance criterion 3 ('events are handled') states no success condition and is not testable."},
  {"persona": "adversarial-reviewer", "severity": "minor", "confidence": "high",
   "category": "integration-blind-spot",
   "message": "No retry or backoff is described for the downstream call in Task 4."},
  {"persona": "scope-guardian", "severity": "minor", "confidence": "low",
   "category": "gold-plating",
   "message": "Task 5 adds a config flag for an export format the Scope does not mention."}
]
```

The merge produces **four** findings:

1. The **security-lens** and **adversarial-reviewer** findings describe
   the *same underlying concern* — Task 2's webhook trusts an unverified
   caller — even though they were filed under two different categories
   (`trust-boundary`, `hidden-assumption`). They converge into one
   finding: keep one of the two (both `major`) and set
   `also_flagged_by: ["adversarial-reviewer"]`. (Had the change also
   bypassed a mandated middleware, `architecture-strategist` would have
   been cast and likely converged here too — three lanes on one concern
   is the panel's strongest signal — but that PATTERNS surface is absent
   in C1, so its lane was never cast.)
2. The **scope-guardian** `acceptance-criteria` finding is a *distinct
   concern* (an untestable criterion) — it stays on its own.
3. The second **adversarial-reviewer** finding is also *distinct* (a
   missing retry path on a different task). It stays separate and is
   **not** merged with finding 1, even though both came from
   adversarial-reviewer — convergence is about the concern, not the
   persona.
4. The **scope-guardian** `gold-plating` finding is the reserved-slot
   absorbed-remit finding — a *distinct concern*, so it stays on its
   own.

Nothing is dropped: there is no merge-side confidence filter.

Sorted by severity, then convergence: finding 1 (`major`,
`also_flagged_by` length 1) → then the three `minor` findings (2, 3,
4), whose order among themselves is not significant — `confidence` is
a display annotation, not a tiebreak. The envelope records a `cast` of
the three cast personas, `dropped: []` (no lane was cap-cut and
`security-lens` was cast — the two absent lanes carry no entry, and are
named in `casting_rationale`), `personas_completed: 3`, and
`findings_total: 4`.
