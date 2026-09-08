# Review Report Contract

Read this reference completely when constructing or persisting a Scope, Plan,
or Full Review report.
Delivery Review uses the separate fixed-range contract in
`delivery-review.md` because its two axes and range metadata are not a persona
cast.
## Report envelope (v3.1.0)

The merged report carries a top-level envelope so downstream tooling
can parse the report without inspecting the Markdown prose. The
envelope appears as a `json` code block immediately after the banner
(see Presenting the Report below) and MUST be valid JSON.

```json
{
  "schema_version": "3.1.0",
  "dispatch_mode": "subagent-dispatch",
  "cast": [
    {"name": "scope-guardian", "origin": "canonical", "concern": "acceptance-criteria testability for 'events are handled'"},
    {"name": "architecture-strategist", "origin": "canonical", "concern": "handler bypasses the PATTERNS request-validation middleware"},
    {"name": "security-lens", "origin": "canonical", "concern": "caller signature verified against the shared secret at the trust boundary"},
    {"name": "adversarial-reviewer", "origin": "canonical", "concern": "forged-event / replay failure mode"},
    {"name": "idempotency-auditor", "origin": "ad-hoc", "concern": "duplicate-delivery handling in the queue consumer"}
  ],
  "dropped": [
    {"name": "alternatives-analyst", "reason": "option latitude exists (push vs poll) but ranked below the five cast lanes under the signal-ranked cap — live-but-unselected"}
  ],
  "casting_rationale": "Webhook + queue change carried six live lanes; cast the five highest-signal (scope, architecture, security, adversarial, + an idempotency lens) and cut the alternatives analyst to live-but-unselected under the cap.",
  "personas_completed": 5,
  "findings_total": 0
}
```

Here six lanes carried a signal; the five highest were cast and the
sixth (`alternatives-analyst`) was cut to *live-but-unselected* under the
cap, plus one ad-hoc. **Every persona that is cast OR live-but-unselected
appears; a lane with no signal at all appears in neither array** — that
bounded accounting is what lets the canonical library grow without the
envelope growing with it. The cast is five (at the soft cap);
`security-lens` is cast because the change touches a trust boundary.

Required fields:

- `schema_version` — the string `"3.1.0"` for this contract. v3.1.0
  (PS-1692) is the **cast-on-evidence** redesign: casting is positive
  (each seat earned by a signal named in `cast[].concern`), bounded by a
  floor of three and a signal-ranked soft cap of five, and `dropped[]`
  now records the **notable exclusions** (live-but-unselected lanes plus
  any `security-lens` drop) rather than every uncast canonical persona.
  This is an **additive, minor** bump: the `cast[]` / `dropped[]` /
  `casting_rationale` / `dispatch_mode` field **shapes are unchanged** from
  v3.0.0, so a v3.0.0 consumer still parses every field. What changed is a
  **semantic relaxation** of one accounting rule: v3.0.0 required every
  canonical persona to appear in exactly one of `cast` or `dropped`; v3.1.0
  replaces that totality invariant with **"every persona that is cast OR
  live-but-unselected (plus any dropped `security-lens`) appears; an
  absent lane appears in neither"** — so a consumer that *validated*
  `cast + dropped == full canonical roster` must drop that assertion (no
  known consumer does; the report is read by a human and a gitignored
  `.spade/reviews/` file). v3.0.0 was the dynamic-casting redesign
  (v1.13.0) that replaced the fixed `personas_spawned` integer with the
  `cast[]` / `dropped[]` trio. Earlier contracts: `2.1.0` the five-persona
  fixed panel (M-1248/M-1293); `2.0.0` the four-persona M-994 redesign
  (`nit` dropped from `severity`, `confidence` recast to `high | low`,
  merge-side confidence filter removed). The **finding shape is
  unchanged** from 2.x — a 2.x consumer still parses every finding object.
  This is the **report-envelope** contract version, independent of the
  framework's `.spade/version` and of the fragment-marker mechanism
  `/spade-update` uses to rewrite consumer skill files.
- `dispatch_mode` — one of `subagent-dispatch`, `sequential-inproc`,
  `degraded`. Same value as the banner line.
- `cast` — the personas actually spawned, in spawn order. Each entry:
  - `name` — the persona's identifier (a canonical persona name, or the
    ad-hoc persona's kebab-case name).
  - `origin` — `"canonical"` (one of the eight default personas) or
    `"ad-hoc"` (invented by triage for this change).
  - `concern` — a short phrase naming the **signal** in this change that
    earned the persona its seat. This is the cast-on-evidence audit
    trail; a seat with no signal behind its `concern` is not earned.
  The cast length is the panel size; it is **never fewer than three** and
  **never more than five** except where `security-lens`'s raised-bar
  retention requires a sixth seat (see Cast-on-evidence, the floor, and
  the soft cap). Do not hard-code a count — it is `cast.length`.
- `dropped` — the **notable exclusions**, not every uncast persona. An
  entry appears here only when a canonical lane was (a) **live but
  unselected** — the change lit it, but it lost the signal-ranked cut
  under the cap — or (b) **`security-lens` dropped for any reason**, whose
  raised bar makes every security exclusion audit-worthy. Each entry:
  `name` (the canonical persona) and `reason` (the one-line cause; for a
  cap-cut, say so). A canonical lane the change simply does not light is
  **absent**: it appears in neither `cast` nor `dropped` (a notable
  absence may be named in `casting_rationale`). An empty `dropped` array
  means no lane was cap-cut and `security-lens` was cast — **not** that
  every canonical persona was cast. Ad-hoc personas never appear in
  `dropped`.
- `casting_rationale` — a single line summarising the cast decision: what
  was cast and why, what was cut under the cap, and any notable absence.
  Human-readable; the per-persona detail lives in `cast[].concern` and
  `dropped[].reason`. This is where a genuinely-absent lane is named when
  naming it aids the reader, since absent lanes carry no `dropped[]` entry.
- `personas_completed` — the number of cast personas whose
  `spade-findings` block parsed successfully. Count them; do not
  estimate. If a persona's JSON block failed to parse, its prose still
  shows in the report but it does NOT increment this counter.
  `personas_completed <= cast.length`.
- `findings_total` — the number of findings in the merged report:
  literally the length of the final merged list, counted after
  convergence merging. Do not estimate.

The v2.x envelope carried `personas_spawned` (a fixed integer, `5` since
M-1293); v3.0.0 replaced it with `cast[]` / `dropped[]`, and v3.1.0
(PS-1692) kept those fields but made casting evidence-driven and
`dropped[]` bounded to the notable exclusions. The v1.1 envelope's
`findings_filtered_low_confidence` field was already removed in v2.0.0
(no merge-side confidence filter).

Per-persona finding shape is **unchanged** since v2.0.0: `severity` is
`blocking | major | minor` and `confidence` is a `high | low` string.
Neither dynamic casting (v3.0.0) nor cast-on-evidence (v3.1.0) touched the
finding object — only how the roster is chosen and recorded. If a future
version changes finding shape, bump `schema_version` (a major bump if it
breaks existing parsers).

## Presenting the Report

A panel run produces two artefacts: a **tiered inline report** written
to the terminal, and a **full report** persisted to a file. The inline
report is a digest — it leads with the signal and fits on a screen; the
full report is the complete audit record.

### The dispatch-mode banner and envelope

Both artefacts begin with a **dispatch-mode banner** (the value you
recorded during spawning) and the **report envelope** JSON. The banner
line (`Dispatch mode: <value>`) is ALWAYS the first line of output,
before any prose, the envelope JSON, or the section title — so a
`head -n 1` or a regex scan of the top-of-report surfaces the mode
without parsing the envelope.

The section title depends on dispatch mode:

- When `dispatch_mode` is `subagent-dispatch` or `sequential-inproc`,
  the title is `PANEL SECOND OPINION`.
- When `dispatch_mode` is `degraded`, the title is
  `SINGLE-CONTEXT SIMULATION (degraded)`. You MUST NOT use the words
  "panel" or "multi-persona" anywhere in a degraded report's header or
  framing prose — see "What This Skill Must Never Do" below.

**Degraded-detection check.** The dispatch mode is asserted in three
places that MUST agree: the banner's first line, the envelope's
`dispatch_mode` field, and the section title (`PANEL SECOND OPINION`
for a real panel; `SINGLE-CONTEXT SIMULATION (degraded)` for a degraded
run). A reader — or a downstream tool — confirms a run was a genuine
multi-context panel by checking that all three agree and none say
`degraded`. If the three disagree, the report is malformed. This
three-point agreement is the stated check that a degraded run can never
be silently presented as a panel; it holds in the inline report and the
persisted file alike.

### The tiered inline report

The inline report shows, in order:

1. The banner and the envelope JSON.
2. The section title.
3. **The cast line** — who was cast and who was dropped, so the human
   sees the coverage decision at a glance. Mark ad-hoc personas with
   `(ad-hoc)`; name each drop with its reason. (See the worked shape
   below.)
4. **Persona summaries** — each persona's prose summary, verbatim.
   Never summarise a persona's prose in your own words; the whole point
   is that the human sees each independent view unfiltered.
5. **Convergence** — every merged finding with a non-empty
   `also_flagged_by` array, shown in full. Convergence is the cast's
   strongest signal, so it leads the findings.
6. **Blocking and major findings.** Every `blocking` finding is shown
   in full, always — blocking is never suppressed or collapsed. `major`
   findings then fill an inline budget of roughly 5–7 findings total
   (the convergence and blocking findings already shown count toward
   that budget). `major` findings beyond the budget are not printed
   individually — they collapse to a count line:
   `+N more major finding(s) — see full report`.
7. **Minor findings** never print individually inline. They collapse to
   a single count line: `N minor finding(s) — see full report`.
8. A pointer to the persisted full report: `Full report: <path>`.

Inline shape when dispatch mode is `subagent-dispatch` (or
`sequential-inproc`):

```
Dispatch mode: subagent-dispatch

```json
{"schema_version":"3.1.0","dispatch_mode":"subagent-dispatch",
 "cast":[{"name":"scope-guardian","origin":"canonical","concern":"acceptance-criteria testability"},
         {"name":"architecture-strategist","origin":"canonical","concern":"patterns drift"},
         {"name":"security-lens","origin":"canonical","concern":"webhook trust boundary"},
         {"name":"adversarial-reviewer","origin":"canonical","concern":"failure modes"},
         {"name":"idempotency-auditor","origin":"ad-hoc","concern":"duplicate delivery in the queue consumer"}],
 "dropped":[{"name":"alternatives-analyst","reason":"option latitude present but cut under the cap — live-but-unselected"}],
 "casting_rationale":"Webhook+queue change: four canonical lanes plus an idempotency lens; alternatives analyst cut to live-but-unselected under the cap.",
 "personas_completed":5,"findings_total":14}
```

PANEL SECOND OPINION
════════════════════════════════════════════════════════════

Cast: scope-guardian, architecture-strategist, security-lens,
adversarial-reviewer, +idempotency-auditor (ad-hoc)
Dropped (notable): alternatives-analyst (option latitude present but cut under the cap — live-but-unselected)

Summary from each persona (their own words, verbatim):

  scope-guardian:           <prose summary>
  architecture-strategist:  <prose summary>
  security-lens:            <prose summary>
  adversarial-reviewer:     <prose summary>
  idempotency-auditor:      <prose summary>

(The cast is dynamic — list exactly the personas you spawned, canonical
and ad-hoc. In a Scope Review where the alternatives-analyst is cast, its
line reads "no pre-committed solution found" unless the Scope embedded
one.)

Convergence — independent personas on the same concern:

  [major, also_flagged_by ×2] security-lens — <message>
    refs: Plan Task 2
    also_flagged_by: [adversarial-reviewer, architecture-strategist]

Findings — every blocking in full; major up to the inline budget:

  [blocking] architecture-strategist — <message>
    refs: ANTI-PATTERNS.md#..., Plan Task 4
  [major]    scope-guardian — <message>
    refs: Plan Task 3
  +3 more major finding(s) — see full report.
  9 minor finding(s) — see full report.

Full report: .spade/reviews/m-994-2026-05-17.md

════════════════════════════════════════════════════════════
```

Inline shape when dispatch mode is `degraded`:

```
Dispatch mode: degraded

```json
{"schema_version":"3.1.0","dispatch_mode":"degraded",
 "cast":[{"name":"scope-guardian","origin":"canonical","concern":"acceptance-criteria testability"},
         {"name":"security-lens","origin":"canonical","concern":"webhook trust boundary"},
         {"name":"adversarial-reviewer","origin":"canonical","concern":"forged-event failure mode"},
         {"name":"idempotency-auditor","origin":"ad-hoc","concern":"duplicate delivery in the queue consumer"}],
 "dropped":[],
 "casting_rationale":"Narrow change: scope/security/adversarial canonical lanes plus an idempotency lens; the architecture and alternatives lanes were absent (no signal) so carry no dropped[] entry.",
 "personas_completed":4,"findings_total":14}
```

SINGLE-CONTEXT SIMULATION (degraded)
════════════════════════════════════════════════════════════

This report was produced by re-prompting a single model context with
each persona's priming in turn — it is NOT a multi-context review.
Consumers relying on independence between reviewers should treat
findings as lower-confidence than the headline severity suggests.

Cast: scope-guardian, security-lens, adversarial-reviewer,
+idempotency-auditor (ad-hoc)
Dropped (notable): none — the architecture and alternatives lanes were absent (no signal), so carry no entry

Summary from each persona-prompted run (verbatim):

  scope-guardian:           <prose summary>
  security-lens:            <prose summary>
  adversarial-reviewer:     <prose summary>
  idempotency-auditor:      <prose summary>

Convergence — runs that landed on the same concern:

  ...

Findings — every blocking in full; major up to the inline budget:

  ...
  +N more major finding(s) — see full report.
  N minor finding(s) — see full report.

Full report: .spade/reviews/m-994-2026-05-17.md

════════════════════════════════════════════════════════════
```

### The persisted full report

On **every** panel run — `degraded` runs included — write the full
report to a file under `.spade/reviews/`:

- **Path:** `.spade/reviews/<slug>-<date>.md`. `<slug>` is the reviewed
  Scope or Plan's tracker identifier lower-cased (e.g. `m-994`), or a
  short kebab-case slug derived from its title when there is no
  identifier; `<date>` is `YYYY-MM-DD`.
- **Collision rule:** if that path already exists — a repeat run of the
  same slug on the same date — append a numeric suffix:
  `<slug>-<date>-2.md`, then `-3`, and so on. Never overwrite an
  existing review file; each run is its own audit record.
- **Contents:** the banner, the envelope, the section title, the cast
  and dropped lists, every persona's prose summary verbatim, **every**
  merged finding at every severity shown in full (the file is not tiered
  — it is the complete record), and the cross-model synthesis.
- `.spade/reviews/` is gitignored by default; the review file is a
  local audit artefact, not committed output.

Create `.spade/reviews/` lazily on the first write; do not pre-create
it. The inline report's `Full report:` pointer names the file just
written. If the write fails, say so plainly inline
(`Full report: write failed — <reason>`) and continue — a failed
persistence write never aborts the review; the inline digest stands.
