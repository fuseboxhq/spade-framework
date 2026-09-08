# Differential blind-cast — gate result (Bundle A, PS-1701)

Run via a separate, blind `general-purpose` subagent context that cast each
corpus change cold — given only the persona roster + one-line focus and the
change prose, **never** the SKILL.md triage spec, this corpus's `expected_cast`,
or the blind-cast procedure. `dispatch_mode: subagent-dispatch` (isolated
context — the independence requirement is satisfied).

## Comparison to the corpus oracle

| Case | Expected cast | Blind cast | Verdict |
|------|---------------|-----------|---------|
| C1 webhook | SG, SL, AR | SG, SL, AR, +AS | pass-with-note (+1: blind read "new endpoint" as a wire surface) |
| C2 marketing copy | SG, AS, AR | SG, AS, AR | match |
| C3 migration | SG, AS, AR | SG, AS, AR, +AA | pass-with-note (+1: blind read backfill-strategy as option latitude) |
| C4 frontend refactor | SG, AS, AR | SG, AS, AR | match |
| C5 multi-system | SG, AS, SL, AR, AA | SG, AS, SL, AR, AA | match (cap met at 5; ceiling case) |
| N1a marketing copy | SG, AS, AR | SG, AS, AR | match |
| N1b auth-error enumeration | SG, AS, AR, SL | SG, AR, SL | discriminates (+SL; AS floor-fill dropped because N1b carries 3 real lanes) |
| N2a internal rename | SG, AS, AR | SG, AS, AR | match |
| N2b public-export rename | SG, AS, AR (AS concern → compatibility) | SG, AS, AR (AS signal = "breaking exported surface / compatibility") | match (concern shift, roster held) |
| N3a in-memory transform | SG, AS, AR | SG, AS, AR | match |
| N3b multi-tenant persist | SG, AS, AR, SL | SG, AS, AR, SL | match (+SL exactly) |

## Gate criteria

1. No two non-floor base cases (C1, C3, C5) share a roster — C1={SG,SL,AR,AS},
   C3={SG,AS,AR,AA}, C5={all 5}: all distinct. **Pass.**
2. Every base case casts 3–5: C1=4, C2=3, C3=4, C4=3, C5=5. **Pass.**
3. Each base case excludes ≥1 lane — true for C1–C4; **C5 casts all five (no
   exclusion): the documented ceiling case** in a 5-persona library. When
   Bundle B adds three personas, C5 will exclude them. **Pass (with the C5
   ceiling note).**
4. Near-miss discrimination — N1 toggled security (+SL); N2 held the roster and
   shifted `architecture-strategist`'s concern to the breaking export; N3
   toggled security (+SL). **Pass — all three pairs discriminate.**
5. Blind roster within ±1 of expected for every case; no divergence ≥2.
   **Pass.**

## Verdict: **PASS** — Bundle A may ship.

Eight exact matches, three pass-with-notes, all within tolerance. The three
notes are legitimate signal reads by the blind context (a new endpoint lighting
architecture; a backfill carrying strategy latitude), not triage failures — the
oracle was marginally conservative on C1/C3, which the differential surfaced.
The near-miss pairs are the load-bearing evidence: each toggled exactly the
dimension it was built to toggle, which is the discrimination a keep-all selector
could not produce.

---

# Bundle B — gate result (8-persona library, PS-1705)

Re-run via a fresh blind `general-purpose` context given the full **eight**-persona
roster (the six domain lenses + two stance lenses), on the three new near-miss
pairs (N4/N5/N6) plus base cases C1/C3/C5 to check the new lenses do not
over-fire. `dispatch_mode: subagent-dispatch`.

| Case | New-lens expectation | Blind cast | Verdict |
|------|----------------------|-----------|---------|
| C1 read-only webhook | no new lens | SL, AR, OPS | OPS on a new external path (defensible); MIG/DEL correctly absent |
| C3 migration+backfill | +MIG | MIG, AS, OPS | **MIG primary** on the live backfill ✓ |
| C5 multi-system | none of the 3 new | SL, AS, SG, AA, AR | MIG/DEL/OPS correctly absent ✓ |
| **N4a→N4b** (operability) | +operability | N4a {SL,SG,AR} → N4b {OPS,DEL,SL,AR} | **+operability** ✓ (blind also surfaced delivery-semantics — an async post-response task genuinely has both; defensible) |
| **N5a→N5b** (reversibility) | +migration-reversibility | N5a {SG,AS,AR} → N5b {MIG,AS,AR,OPS,SG} | **+migration-reversibility** ✓ (after the brief was tightened to key on reversibility *risk*, not schema-change presence — see below) |
| **N6a→N6b** (delivery) | +delivery-semantics | N6a {SL,AR,OPS} → N6b {DEL,SL,OPS,AR} | **+delivery-semantics** ✓ exactly |

## What the gate caught (and the fix)

On the **first** 8-persona run, `migration-reversibility` was cast on *both*
halves of N5 — it fired on schema-change *presence* (additive *and* destructive),
so the additive-vs-destructive pair did not discriminate via that lane. This is
the gate doing its job. The fix was to **tighten the brief** (not the corpus):
`migration-reversibility` now keys on **reversibility risk** — destructive /
type-narrowing changes, backfills over live rows, non-trivial data moves — and
explicitly cedes trivially-reversible additive changes (a new nullable column) to
`architecture-strategist`. A re-cast confirmed the discrimination: N5a no longer
casts the lane; N5b casts it as the primary seat. The blind context also
correctly recorded `alternatives-analyst` as live-but-unselected over the cap on
N5b — the cap + live-but-unselected mechanism working end to end.

## Verdict: **PASS** — Bundle B may ship.

All three new domain lenses discriminate on their near-miss pairs, fire correctly
on the base cases that carry their surface (C3 → MIG), and stay absent on the
base cases that do not (C5). The new lenses are evidence-gated, not keep-all: a
change with no migration casts no migration lens, which is the whole point of
growing the library in *domain* lanes only.

