# Differential blind-cast — the casting validation gate (PS-1692, T1)

This procedure is the **required gate** for the `/spade-review` casting redesign
(PS-1692 Plan-review B1). It exists to break the self-certifying loop a
coordinator-graded corpus would otherwise have: the context that *wrote* the
triage rules must not also be the context that *grades* whether they work.

It is a documented **procedure**, not an executable script — there is no runtime
for the prose triage, and ANTI-PATTERNS.md forbids scripts that duplicate skill
prose. The gate is run by spawning subagents.

## Why blind

A corpus whose `expected_cast` is authored by the same context that then "checks"
the triage proves only self-consistency. The teeth come from a **separate
context that has never seen the triage spec** casting each change cold, then
comparing its roster to the corpus's `expected_cast`. Agreement is then real
evidence the casting signals are legible from the change alone; divergence is a
finding.

## Procedure

For each case in [`corpus.md`](./corpus.md) (base cases C1–C5 **and** both halves
of each near-miss pair N1–N3):

1. **Spawn a blind caster** — a fresh subagent context. Give it:
   - The list of the canonical personas and a one-line focus for each
     (from the persona briefs' `focus:` frontmatter), **but NOT** the SKILL.md
     casting/triage section, the corpus's `expected_cast`, or this file.
   - The change description from the corpus case (the prose only — not the
     expected cast or the excluded-lane reasons).
   - This instruction: *"Cast the 3–5 personas this change actually needs.
     For each, name the concrete signal in the change that earns its seat. Name
     any persona you are deliberately not casting and why. Floor 3, cap 5."*
2. **Collect the blind roster** — the set of personas the blind caster chose,
   plus its per-persona signal phrases.
3. **Compare** to the corpus `expected_cast` for that case:
   - **Roster match** within a tolerance of **one** persona (a single
     extra/missing seat is a pass-with-note; two or more is a divergence).
   - **Near-miss delta** holds: N1 and N3 differ by exactly `+security-lens`
     between their `a` and `b` halves; N2's rosters are identical but
     `architecture-strategist`'s signal phrase names the breaking export only
     in N2b.
   - **Floor/cap** respected: every roster is 3–5.
4. **Record** each case's result (match / pass-with-note / divergence) in the
   review evidence for the delivering issue (PS-1701 / PS-1705).

## Gate verdict

- **Pass** (Bundle A may ship) when: every base case is match or pass-with-note;
  no two non-floor base cases (C1, C3, C5) share a roster; every near-miss delta
  holds; no roster violates floor 3 / cap 5.
- **Fail** (do not ship; sharpen the triage spec in SKILL.md, not the corpus)
  when: any case diverges by ≥2 personas, a near-miss pair fails to discriminate
  (both halves cast the same set where a delta was expected), or a roster breaks
  the floor or cap.

A failing gate means the triage signals are not legible from the change alone —
the fix is the SKILL.md triage wording (T2), never loosening the corpus to make
the gate pass.

## Independence requirement

The blind caster MUST be a separate context from the one that authored the
corpus and the triage spec. In Claude Code this is a subagent spawn
(`subagent-dispatch`). If no isolated-context path is available, the gate is
**not satisfied** — record that the gate could not be run independently rather
than running it in the authoring context and calling it a pass. A same-context
"blind" cast is exactly the self-certification this gate exists to prevent.
