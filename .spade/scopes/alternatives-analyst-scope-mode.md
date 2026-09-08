---
name: alternatives-analyst-scope-mode
id: sp-lkfpy6
title: Give alternatives-analyst a narrow scope-mode remit (implicit-solution reframe)
status: scoped
type: feature
phase: scope
created: 2026-06-06
updated: 2026-06-06
origin: ad-hoc
priority: this-cycle
delivery: mostly-ai-delivered
linear_issue: M-1293
panel_review: 2026-06-06 (subagent-dispatch, 7 findings, 0 filtered)
---

## Scope: Give alternatives-analyst a narrow scope-mode remit (implicit-solution reframe)

**Intent:** The `alternatives-analyst` persona (M-1248, v1.9.0) runs only in Plan/Full
reviews, on the premise *"there is no option space to survey before a Plan exists."*
That premise is too strong but not empty. A panel review of the first draft of this
Scope (2026-06-06) confirmed the boundary precisely: an *open-ended* "cheaper / simpler
/ narrower path" lens collapses into the scope-guardian's proportionality remit at scope
stage — but **one** counterfactual genuinely belongs to the analyst and no other persona
owns as a primary remit: a **Scope that has pre-committed to a solution** — a *how*
wearing a Scope's clothes — or an **implicit buy-vs-build**. This Scope gives the analyst
a **narrow scope-mode remit** covering exactly those two cases, fires it silently
otherwise, and adds it to the Scope Review roster. The roster becomes uniform (5 across
all modes); context-conditionality moves from the roster into the persona's brief.

**The litmus that defines the remit.** The narrow remit is the one for which a passing
scope-mode finding can actually be written — distinct from the other four. The worked
example (the originating real-world case): a Scope reads *"build a daemon-side gated
self-audit mechanism."* A valid analyst finding: *"the Scope pre-chose the expensive
branch of a tune-vs-build fork; a materially cheaper path to the same acceptance criteria
is to strengthen the existing steer and test whether prompting alone suffices, building
the mechanism only if it does not — wins on 'cheaper'."* This is **not** the guardian's
"trim the over-built part" and **not** the adversary's "it will not work" — it names the
road not taken. That finding shape is the acceptance definition for AC2.

**Acceptance Criteria:**

1. [ ] The `alternatives-analyst` brief gains a **scope-mode remit** that fires on
   **exactly two** cases and is **silent otherwise**:
   (a) the Scope embeds an **implicitly-chosen solution** (a *how* in the problem
   statement) — name the reframe, or the materially cheaper / lower-risk path to the
   *same acceptance criteria*; and
   (b) an **implicit buy-vs-build** the Scope took without acknowledging the fork.
   The brief explicitly **excludes** open-ended "cheaper / simpler / narrower path"
   findings in scope mode — those are the scope-guardian's lane pre-Plan — and no longer
   asserts "there is no option space before a Plan exists."

2. [ ] The brief carries **one worked passing scope-mode finding** (the tune-vs-build
   example above or equivalent) and **one worked non-finding** ("Scope states a goal with
   no embedded solution → emit `[]`"), so the firing bar is demonstrated, not just
   described. A scope-mode finding is *valid* iff it (i) refs a Scope acceptance criterion,
   (ii) names an axis (*cheaper / lower-risk / better-fit*), (iii) points at the Scope's
   implicit solution-choice, and (iv) invents no implementation detail beyond naming the
   alternative's class.

3. [ ] The persona's existing **discipline is preserved verbatim** in scope mode:
   empty-by-default (a silent run is a successful run), no manufactured alternatives, and
   the cap of **2 findings**. The brief **acknowledges the convergence overlap** with the
   scope-guardian on case (a) and states the lane rule (analyst names the *alternative
   path*; guardian polices the *stated scope's* proportionality) — overlap is surfaced by
   the convergence merge, not suppressed.

4. [ ] The Panel Roster table (single source of truth in `SKILL.md`) lists
   `alternatives-analyst` on **all three** modes with a count of **5** each. The
   mode-dependency is **not deleted** but **relocated**: the roster is uniform; the
   persona reads `{mode}` and applies the scope-mode or plan-mode remit from its brief.
   The "Panel history" prose is updated to record this so the M-994→M-1248→this rationale
   stays coherent (answers the precedent-loss concern: context-conditionality is preserved
   in the brief, a cleaner pattern than roster-level exclusion).

5. [ ] **Full edit-surface inventory.** Every surface that currently encodes "4-in-Scope"
   or "Plan/Full-only" is updated, enumerated here so "everywhere" is checkable:
   `SKILL.md` — frontmatter description (L3), roster note (~L125), Panel-history prose
   (~L131), spawn instruction (~L150), the "Scope Review mode — suppress Plan-only
   findings" block (~L183), dispatch-mode table (~L217), report templates (~L521, ~L566),
   envelope `personas_spawned` prose (~L397/L418); `docs/FRAMEWORK.md` §Multi-persona
   Review + the roster-change-bar rationale (~L637, ~L782, ~L734 schema_version wording);
   `ARCHITECTURE.md` L49 ("four-persona review panel"); the persona file frontmatter
   `description` + body. A grep for `four-persona`, `4`-in-Scope, and `Plan, Full` over
   these files returns no stale survivors.

6. [ ] The "Scope Review mode — suppress Plan-only findings" block in `SKILL.md` is
   rewritten: it no longer *excludes* the analyst; it instructs the analyst to apply its
   **scope-mode remit** and still suppress any *implementation-approach* finding that
   presupposes a chosen Plan.

7. [ ] **Mirror obligation.** Both in-repo payload trees are edited in lockstep — the
   consumer/global path (`.claude/skills/`, `.claude/agents/`) **and** the bare plugin
   payload (`skills/`, `agents/`). The `docs/FRAMEWORK.md` schema_version 2.1.0 wording
   ("a fifth persona **and** a mode-dependent `personas_spawned`") is corrected in place to
   reflect the now-uniform panel size; no envelope version bump is required (the field
   range only narrows). Re-syncing the machine-global mirrors (`~/.claude`, `~/.spade`) is
   a post-merge delivery step, not a repo acceptance criterion. [[global-agent-mirror-in-place]]

8. [ ] `plugin.json` minor version bump (1.9.0 → 1.10.0) + a `CHANGELOG.md` entry framing
   the change as **additive**: the Scope panel gains a silent-by-default persona; Plan/Full
   behaviour is unchanged.

**Architectural Constraints:**

- **Prose + agent-brief edits only.** No new runtime, no script, no new dependency — the
  persona is a Markdown agent definition. Consistent with ARCHITECTURE.md ("the system is
  a set of files"), PATTERNS.md ("prose over code"), ANTI-PATTERNS.md.
- The **Panel Roster table stays the single source of truth** — every count references it.
- **Backward-compatible / additive**, as M-1248 was. Plan/Full behaviour unchanged.
- Do **not** reintroduce a merge script or `concern_tag` — convergence stays prose-only
  (M-968). [[spade-review-convergence-dead]]

**Dependencies:**

- **M-1248 (alternatives-analyst persona) — DELIVERED (v1.9.0).** This Scope retunes it.
- Files: `.claude/skills/spade-review/SKILL.md` + `skills/spade-review/SKILL.md`,
  `.claude/agents/spade-review-alternatives-analyst.md` + `agents/spade-review-alternatives-analyst.md`,
  `docs/FRAMEWORK.md`, `ARCHITECTURE.md`, `.claude-plugin/plugin.json`, `CHANGELOG.md`.

**Context:**

- **Upstream:** M-1248 added the analyst as Plan/Full-only with a mode-dependent roster.
- **Originating friction:** a real Scope review (another repo, 2026-06-06) landed the
  verdict *"experiment mis-filed as a feature — probe it cheaply first."* That is precisely
  a case-(a) implicit-solution reframe, and it had to come from adversarial + scope-guardian
  because the analyst was absent. The lens was wanted; the other two absorbed it.
- **Downstream:** the uniform roster + brief-level mode-conditionality is a cleaner
  precedent for future context-conditional personas than roster-level exclusion.

**Out of Scope:**

- Changing the remits of the other four personas.
- The **open-ended "cheaper / simpler / narrower path" scope-mode lens** — explicitly
  rejected by the panel as duplication of the scope-guardian's proportionality remit at
  scope stage. Only the two narrow cases (implicit-solution reframe, implicit buy-vs-build)
  are in scope.
- Any change to Plan / Full review behaviour beyond consistency edits flowing from the
  uniform roster.
- The machine-global re-mirror mechanism itself (a manual local step; tracked separately).
- Reworking the merge / convergence logic (M-968).

**Risk / Unknowns:**

- **Residual overlap with the scope-guardian on case (a)** is real and acknowledged, not
  eliminated — the convergence merge surfaces it as signal. Open question for delivery: is
  the lane rule in AC3 sharp enough that the analyst's finding reads as "the alternative
  path," not "the stated scope is heavy"?
- **Noise** is bounded by the silent-by-default + cap-2 discipline (preserved) and by the
  narrowed two-case firing bar — the analyst should be empty on most Scopes. If it fires
  on Scopes with no embedded solution, the remit is still too wide.
- Rewriting the load-bearing "no option space before a Plan" line must not weaken the
  **Plan-mode** discipline that stops the analyst manufacturing implementation alternatives.

**Delivery Preference:** Mostly AI-delivered — brief rewrite, skill-prose edits across
both payload trees, docs corrections, version bump, changelog. Global mirror re-synced
post-merge. **Human verification:** run a Scope with an embedded solution and a Scope
without one through the 5-persona panel; confirm the analyst fires on the first (refs an
AC, names an axis) and is empty on the second.

**Priority:** This cycle.

## Panel Review (2026-06-06)

A 4-persona `/spade-review` Scope panel (`subagent-dispatch`, 7 merged findings, 0
filtered) ran on the first draft — which proposed an *open-ended* scope-mode remit.
Disposition:

- **Core premise too strong / silent-or-manufacture (major — adversarial-reviewer):**
  accepted in part. An AC2 litmus (write one passing scope-mode finding) showed the
  open-ended remit collapses into the guardian, but the **two narrow cases** pass cleanly.
  Rescoped to those two cases only; open-ended path-finding moved to Out of Scope.
- **No checkable definition of a valid scope-mode finding (major — adversarial-reviewer,
  also scope-guardian):** fixed. AC2 now carries a worked passing finding + a worked
  non-finding and a four-part validity test.
- **AC1 under-enumerates the edit surface (major — architecture-strategist, also
  scope-guardian):** fixed. AC5 is now a full, checkable inventory incl. ARCHITECTURE.md:49
  and docs/FRAMEWORK.md.
- **Mirror propagation incomplete (major — architecture-strategist, also security-lens):**
  fixed. AC7 makes both in-repo payload trees a lockstep obligation; global mirror is an
  explicit post-merge delivery step.
- **Duplication of M-994's consolidated lanes (major, low conf — adversarial-reviewer):**
  acknowledged as residual risk; narrowed remit minimises it; convergence surfaces what
  remains.
- **Mode-dependency precedent loss (major — adversarial-reviewer):** answered. AC4
  relocates context-conditionality into the brief rather than deleting it — a cleaner
  precedent.
- **schema_version 2.1.0 wording goes stale (minor — architecture-strategist):** fixed in
  AC7 (corrected in place, no version bump).

Full report: `.spade/reviews/alternatives-analyst-scope-mode-2026-06-06.md`
