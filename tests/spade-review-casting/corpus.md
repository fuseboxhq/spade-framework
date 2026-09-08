# /spade-review casting corpus (PS-1692, T1)

A fixed behavioural fixture for the `/spade-review` casting triage. It exists
to prove — behaviourally, not by prose assertion — that the hybrid
cast-on-evidence selector (PS-1692) **discriminates on the evidence a change
actually carries** rather than reflexively casting the same roster.

This file is **single-source**: it lives only here, in the repo, and is **not**
mirrored into the plugin payload (`skills/`, `agents/`) or the global trees
(`~/.claude/…`). It is a validation artefact, not distributed skill surface, so
it can never drift across mirror trees.

It is exercised by the **differential blind-cast** procedure in
[`blind-cast-procedure.md`](./blind-cast-procedure.md): a *separate, blind*
context casts each change below **without** seeing the SKILL.md triage spec, and
its roster is compared against the `expected_cast` here. Divergence is the
failure signal. The corpus author and the blind caster must be different
contexts — that independence is the whole point (PS-1692 Plan-review B1).

Canonical library under test (Bundle A — the 5 existing personas):
`scope-guardian` (SG), `architecture-strategist` (AS), `security-lens` (SL),
`adversarial-reviewer` (AR), `alternatives-analyst` (AA). Bundle B extends the
corpus with the 3 new personas (see T6).

Casting contract being validated:
- **Cast on evidence.** A persona is cast only when the change carries a
  concrete signal for its lane; the cast cites that signal.
- **Floor 3 / signal-ranked soft cap 5.** Never fewer than 3; when more than 5
  lanes fire, the lowest-signal lanes are cut to live-but-unselected, except
  `security-lens`'s raised-bar retention always survives.
- **`security-lens` raised bar.** Dropped only when the change touches no auth,
  secrets, untrusted input, network boundary, IAM, or data sensitivity at all.

---

## Base cases

Each case lists the change, the signals it carries, the `expected_cast` (3–5
personas with the signal that earns each seat), and the excluded lanes with the
reason each is empty (`absent` = no signal at all; `live-but-unselected` = had a
signal but lost the signal-ranked cut under the cap).

### C1 — Webhook handler (external POST + signature verification)
A new HTTP endpoint receives external POSTs and verifies a caller-supplied
signature header against a shared secret.
- **expected_cast:**
  - `security-lens` — untrusted input crosses a trust boundary; signature/secret handling.
  - `adversarial-reviewer` — forged-event / replay failure mode if verification is wrong.
  - `scope-guardian` — acceptance-criteria testability for "events are handled".
- **excluded:**
  - `architecture-strategist` — `absent` (no PATTERNS/ANTI-PATTERNS or compatibility surface named).
  - `alternatives-analyst` — `absent` (point-solution endpoint, no option latitude).
- **cast size:** 3

### C2 — Copy tweak (static marketing-page button label)
Change a button's label text on a public marketing page. No logic, no data, no
auth.
- **expected_cast (floor regime — fewer than 3 lanes carry real evidence, fill to 3 with highest-signal non-security lanes):**
  - `scope-guardian` — does the new copy match the stated intent / any AC.
  - `architecture-strategist` — content/UX convention conformance (weak but present).
  - `adversarial-reviewer` — floor-fill: any second-order wording/ambiguity risk.
- **excluded:**
  - `security-lens` — `absent` (no auth, secrets, input, boundary, IAM, or data — raised-bar drop is satisfied).
  - `alternatives-analyst` — `absent` (no solution latitude in a label change).
- **cast size:** 3 (demonstrates the floor)

### C3 — Schema migration with backfill
A database migration adds a column and backfills it from existing rows on a
live table.
- **expected_cast:**
  - `architecture-strategist` — migration/backfill against PATTERNS; expand-contract discipline.
  - `adversarial-reviewer` — what breaks if the backfill half-completes or the rollback is needed.
  - `scope-guardian` — acceptance-criteria for "migration complete" must be checkable.
- **excluded:**
  - `security-lens` — `absent` *if* the backfilled column is non-sensitive (see near-miss N3 for the sensitive variant).
  - `alternatives-analyst` — `live-but-unselected` (a different migration strategy is conceivable, but lower-signal than the three above).
- **cast size:** 3

### C4 — Pure-frontend component refactor (no new deps, no public API)
Refactor an internal React component for readability; no new dependency, no
exported-surface change, behaviour identical.
- **expected_cast:**
  - `scope-guardian` — is the refactor traceable to the Scope / not gold-plating.
  - `architecture-strategist` — component-convention / PATTERNS conformance.
  - `adversarial-reviewer` — floor-fill: any behaviour-drift risk in an "identical" refactor.
- **excluded:**
  - `security-lens` — `absent` (no security surface).
  - `alternatives-analyst` — `absent` (internal cleanup, no competing approach worth raising).
- **cast size:** 3

### C5 — Multi-system feature (backend + frontend + new dependency + auth)
A new feature spanning a backend endpoint, a frontend surface, a newly-added
third-party dependency, and an auth/permission check.
- **expected_cast (all 5 fire; demonstrates the cap holding at 5):**
  - `scope-guardian` — large multi-surface scope; AC completeness + sizing.
  - `architecture-strategist` — new runtime dependency + cross-surface PATTERNS.
  - `security-lens` — auth/permission boundary + new-dependency supply-chain.
  - `adversarial-reviewer` — cross-system failure modes and blast radius.
  - `alternatives-analyst` — genuine option latitude in how the feature is built.
- **excluded:** none (5 live lanes; cap is exactly met, nothing cut).
- **cast size:** 5 (demonstrates the cap ceiling without a cut)

---

## Near-miss pairs (the discrimination test)

Each pair holds everything fixed except **one** dimension; the casts must differ
by **exactly one** persona. A selector that casts the same roster for both halves
of a pair has failed to discriminate (the keep-all collapse PS-1692 targets).

### N1 — copy tweak, security dimension toggled
- **N1a:** copy tweak on a static marketing page (= C2). → cast: `{SG, AS, AR}`.
- **N1b:** copy tweak on an **auth error message** that could reveal whether an
  account exists. → adds `security-lens` (information-disclosure / data-sensitivity).
- **expected delta:** `+security-lens` only. Cast `{SG, AS, AR}` → `{SG, AS, AR, SL}`.

### N2 — internal refactor, public-surface dimension toggled
- **N2a:** rename an internal helper, no exported surface changes (≈ C4). → cast: `{SG, AS, AR}`.
- **N2b:** the same rename, but it **renames a public exported function** other
  repos import. → sharpens `architecture-strategist` onto the `compatibility`
  lane (breaking change), which it already owns — so the roster is the same set
  but the *concern* on `architecture-strategist` shifts from "convention" to
  "breaking compatibility". This pair tests **concern precision**, not roster
  delta: both cast `{SG, AS, AR}`, but AS's `concern` must name the breaking
  export in N2b and not in N2a.
- **expected delta:** roster identical; `architecture-strategist.concern`
  changes to a compatibility/breaking-change phrase in N2b.

### N3 — in-memory transform, data-persistence dimension toggled
- **N3a:** a pure in-memory data transform, result returned to the caller. →
  cast: `{SG, AR}` + one floor-fill to 3 (`AS`), `security-lens` absent.
- **N3b:** the same transform, but the result is **persisted to a shared
  multi-tenant table**. → adds `security-lens` (tenant data-isolation /
  data-sensitivity). 
- **expected delta:** `+security-lens` only. Cast `{SG, AS, AR}` → `{SG, AS, AR, SL}`.

---

## Bundle B — near-miss pairs for the three new domain lenses

Added with the library expansion (PS-1692 Bundle B). The full library is now
eight: the six **domain** lenses SG, AS, SL, **operability (OPS)**,
**migration-reversibility (MIG)**, **delivery-semantics (DEL)**, and the two
**stance** lenses AR, AA. Each pair below toggles exactly one of the three new
lanes.

### N4 — sync vs silent-async, operability dimension toggled
- **N4a:** add a synchronous validation check to an existing API endpoint; it
  returns an error inline on bad input. → cast: `{SG, AS, AR}`; OPS absent
  (failure is observable in the response).
- **N4b:** the same validation moved to an **asynchronous post-response
  background task** that logs failures nowhere and has no alert. → adds
  `operability` (a silent async failure path with no metric/alert/kill-switch).
- **expected delta:** `+operability` only.

### N5 — additive vs destructive migration, reversibility dimension toggled
- **N5a:** add a new **nullable column with a default**, no backfill, no
  existing data touched. → cast: `{SG, AS, AR}`; MIG absent (trivially
  reversible additive change — `architecture-strategist` owns the schema-pattern
  angle).
- **N5b:** **drop an existing column and migrate its data** into a new,
  differently-typed column, backfilling live rows. → adds
  `migration-reversibility` (destructive, backfill on live data, no trivial down
  path).
- **expected delta:** `+migration-reversibility` only.

### N6 — read-only vs side-effecting webhook, delivery-semantics dimension toggled
- **N6a:** a webhook handler that verifies a signature and returns 200; it only
  **reads** data, no side effects. → cast: `{SG, SL, AR}` (security owns the
  trust boundary); DEL absent (idempotent read).
- **N6b:** the same handler now **charges the customer** on receipt. → adds
  `delivery-semantics` (at-least-once delivery + a non-idempotent side effect =
  double-charge risk). Security still casts (the boundary is unchanged).
- **expected delta:** `+delivery-semantics` only. Cast `{SG, SL, AR}` →
  `{SG, SL, AR, DEL}`.

These pairs are the discrimination evidence for the new lanes: each new lens
must appear on the `b` half and not the `a` half. A selector that casts the new
lens on both halves (or neither) has failed to discriminate.

---

## Pass criteria (checked by the blind-cast gate)

1. **No two base cases (C1–C5) produce an identical roster** — except where the
   floor forces `{SG, AS, AR}` (C2 and C4 may legitimately coincide at the
   floor; that is the floor working, not a failure). The non-floor cases
   (C1, C3, C5) must each differ.
2. **Every base case casts 3–5 personas**, never fewer than 3, never more than 5.
3. **Each base case excludes at least one lane** with a stated `absent` or
   `live-but-unselected` reason.
4. **Each near-miss pair differs as specified** — N1 and N3 by exactly
   `+security-lens`; N2 by `architecture-strategist`'s concern, not the roster;
   N4 by `+operability`; N5 by `+migration-reversibility`; N6 by
   `+delivery-semantics`.
5. **The blind cast (separate context, no triage spec) matches the
   `expected_cast`** for each case within a tolerance of one persona; any
   larger divergence is a finding to resolve before the bundle ships.
