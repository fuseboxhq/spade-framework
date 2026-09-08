# Changelog

All notable changes to the SPADE Framework are documented here.
Versions follow [semver](https://semver.org/) at the framework level
(consumer fragments carry their own version stamp via
`<!-- SPADE-FRAMEWORK-START vX.Y.Z -->` markers).

## [5.1.0] - 2026-09-08

### Changed

- An agent that delivered a Scope, recorded a passing Evaluate, and merged it now closes the issue too. The rule reserving Done for a human is gone from the guard and from every document that stated it.
- Done is still the audit-trail closure point, and it now rests on the Evaluate record rather than on a person clicking it: a Scope reaches Done only behind a recorded PASS on the reviewed head. A PARTIAL, a FAIL, or an open evidence row leaves the issue in Evaluating.
- Ship is unchanged and stays human, expressed through `autonomy.deliver.merge`.

### Removed

- The completed-state guard, its dispatch, and the `guards.completed_states` config key. `hooks.json` no longer matches `mcp__linear__save_issue`, so the guard set is now three: protected path, merge policy, and the opt-in stage-all deny.
- Every clause that said an agent must never mark a parent issue Done. That covers the phase rules and never-do lists in AGENTS.md and both consumer fragments, the key rules in CLAUDE.md, `/spade-evaluate`'s If-PASS branch, Linear steps, local-mode step, and its acceptance-evidence reference, plus INTENT.md, README.md, and the run-continuity reference. `tests/spade-autonomy/approval-model-contract.sh` now scans the whole canonical tree for the old rule rather than checking a list of files, so a survivor fails CI.

### Compatibility

- A consumer who wants Done to stay human keeps it as a team convention; the framework no longer enforces it. The 5.0.1 to 5.1.0 lifecycle unit refreshes the consumer fragments (`refresh_fragments`).

## [5.0.1] - 2026-09-08

### Fixed

- The mechanical guard matched category words as substrings, so ordinary filenames were treated as protected: `tokenizer` and `tokenize` read as credentials, `processor` as authentication, `oracle` as IAM, `hashmap` as cryptography. It now splits a path into words and matches whole words, with a prefix allowance for families such as migration and deployment.
- Worse, the framework's own layout was treated as governance everywhere. In any consumer repository `src/**` matched, so `/spade-quick` and `/spade-unhinged` refused to write ordinary application code. Those paths now count as governance only inside the framework repository, detected by `src/CAPABILITIES.md` and `src/skills/` both existing. In a consumer repository the category covers `AGENTS.md`, `CLAUDE.md`, `PATTERNS.md`, `ANTI-PATTERNS.md`, `INTENT.md`, `docs/FRAMEWORK.md`, and the `.spade/` control files.
- Both faults reached Deliver as well, where a tokenizer or processor file read as secrets and credentials.

Whole-word matching also has to see the words. A name is split at each camelCase boundary and where an acronym runs into a word, so `accessToken.ts` and `SSHKeyLoader.ts` both still classify, and well-known credential files that carry no category word at all (`id_rsa`, `authorized_keys`, `.npmrc`, `.netrc`, `.pgpass`, `kubeconfig`) are named directly. `key` on its own stays an ordinary database and storage word, so `primaryKey.ts`, `rootKeys.ts`, and a `service` layer holding `translationKeys.ts` are left alone while `apiKey.ts` is not; service-account files are named directly instead.

`tests/hooks/guards.sh` gained a consumer fixture and a framework fixture and classifies the same paths against both, so the split cannot regress.

### Compatibility

- No contract change. The 5.0.0 to 5.0.1 lifecycle unit refreshes the consumer fragments (`refresh_fragments`).

## [5.0.0] - 2026-09-07

### Added

- Mechanical guards on the Claude host.
  `bin/spade-guard` runs as a command hook (`hooks/hooks.json` in the plugin payload, `.claude/settings.json` in this repository) and denies four things the harness can check without judgement: an agent moving a parent issue to a completed state, a protected-path edit while `/spade-quick`, `/spade-unhinged`, or a Deliver run is active, a merge outside the configured policy, and (opt-in) `git add -A`.
  Guards are inert outside a repository with `.spade/config`, need only `jq`, and write `.spade/guard/<session_id>/live` so skills know they are wired.
  `docs/FRAMEWORK.md` § Mechanical guards is the single definition; `tests/hooks/guards.sh` pins the behaviour.
- `autonomy.deliver.merge` in `.spade/config`: `human` (default) or `on-green`.
- `guards.deny_stage_all` and `guards.completed_states` in `.spade/config`.
- `tests/spade-autonomy/approval-model-contract.sh`, which pins the prose side of the new model.

### Changed

- The trust model is lighter where guards are live.
  Deliver is the default autonomy level (`/spade-onboard` writes `autonomy.default: deliver`).
  Scoping is draft-first with one lock-or-edit confirm.
  The second-opinion and file-versus-draft prompts, the quick-path type and eligibility prompts, the per-handoff autonomy confirm, and the orchestrated review action question are gone; the agent decides and records.
  Tripwire #6 halts before code only for secrets and credentials, production data, and permission widening; every other protected category is listed under **Protected paths** in the PR body.
  The agent records the Evaluate verdict when every criterion is diff- or runtime-verifiable with fresh evidence on the reviewed head; human-only and external-state rows still go to the human.
  Under `on-green` the agent merges once Evaluate recorded PASS on the current head, checks are green, and the merge command is pinned to that head; the guard checks the same facts. Under `human` with guards live the agent's merge command is denied and the human merges.
  Done and Ship stay human.
- Without the live marker (Codex, or a Claude install without hooks registered) the previous model applies unchanged.
- PATTERNS.md and ANTI-PATTERNS.md name `bin/spade-guard` as the one sanctioned enforcement script and forbid disarming it.

### Removed

- The clauses that said no `autonomy.*` setting may pre-authorize a merge, that a security-path change is never auto-delivered, that the Deliver tripwire offers no override, that the human owns the final Evaluate verdict, and the orchestrator's "merge without explicit human authorization" never-do.
  The unhinged gate keeps its no-override wording.

### Compatibility

- Breaking: the approval model and the meaning of Deliver change for every consumer on the Claude plugin path.
  The 4.0.0 to 5.0.0 lifecycle unit refreshes the consumer fragments (`refresh_fragments`).
  Consumers who want the previous behaviour set `autonomy.default: plan` and leave `autonomy.deliver.merge` unset.
- Codex parity is capability-level for skills, personas, and the researcher; enforcement is Claude-only and recorded as such in `src/CAPABILITIES.md`.

## [4.0.0] - 2026-08-20

### Changed

- Every new Lead now selects exactly one classification from `security`, `documentation`, `testing`, `bug`, `feature`, `enhancement`, and `maintenance`. The fixed precedence makes overlaps predictable, and the structured `Type` field records the same choice.
- GitHub and Linear flows inspect and create the required `lead` and classification labels, verify the resulting issue, and repair missing labels once. Ambiguous responses trigger an authoritative read before retry, so recovery does not duplicate the Lead.
- Label failures no longer discard a discovery. The issue or tracked-file Lead survives with its intended classification in the body, and the agent reports exactly which label could not be created or applied.

### Compatibility

- This replaces the previous free-form `Type` values and optional repository labels, so it is a breaking skill-contract change. Existing Leads are not reclassified.
- The 3.7.0 to 4.0.0 lifecycle unit refreshes the consumer fragments (`refresh_fragments`).

## [3.7.0] - 2026-08-19

### Added

- `unslop`, the nineteenth canonical skill: an edit pass that cuts AI tells from prose (puffery, AI vocabulary, em dashes, inline-header lists, filler, abstract metaphor jargon) and adds human voice. It ships in both host payloads, so every install has it.
- `docs/FRAMEWORK.md` § The unslop pass: the single-sourced rule naming which outputs get the pass - Scope and Plan prose, PR titles and bodies, TL;DRs, review and evaluate report prose, learnings, research findings, and tracker comments. Code, config, JSON envelopes, and other machine-read artefacts are exempt.
- One-line pointers at each present-or-persist moment in `/spade` (the Deliver PR step), `/spade-scope`, `/spade-plan`, `/spade-quick`, `/spade-review`, `/spade-evaluate`, `/spade-learn`, and `/spade-research`, plus the consumer AGENTS/CLAUDE fragments, so the pass applies in consumer repos too.

### Compatibility

- The 3.6.0 to 3.7.0 lifecycle unit refreshes the consumer fragments (`refresh_fragments`). Existing artefacts are not rewritten; the pass applies to prose written from now on.

## [3.6.0] - 2026-08-19

### Changed

- Every Plan task now renders as one strict card - **What / Done when / How / Verify / Needs / Blocks / Who** - fixed field set, fixed order, every field present on every task, each field one to two sentences. Scopes are written for humans; Plans are written for the agent that delivers them.
- The plan-field jargon is gone from generated output: "execution posture" is now the delivery approach opening the **How** field, the "tracer-bullet outcome" split into **Done when** (the observable result) and **Verify** (where it is checked), "blocking relationships" became **Needs / Blocks**, and the "slice rationale" became a groundwork note inside **What**. The semantics survive unchanged; `docs/FRAMEWORK.md` renames its canonical sections accordingly (§ Delivery approaches, § Observable outcomes and vertical slices).
- Named techniques, skills, patterns, and languages in a card are pointers to where they are defined, never inline explanations.
- Scope output gains explicit plain-language rules: per-field sentence caps, a no-jargon rule, and outcome-first phrasing, written into `/spade-scope` and its output-format reference.
- Every consumer of the old field names reads the card instead: the `/spade-approve` checklist (now "Task Cards and Delivery Shape"), `/spade-review` plan-review inputs and Delivery Review references, the consumer AGENTS/CLAUDE fragments, the delivery-assurance corpus and blind procedure, and the examples lint, which now validates the card shape and the delivery-approach vocabulary.
- The worked example plan and the healthz fixture plans are rewritten as card-format plans and serve as the canonical reference for the new shape.

### Compatibility

- Already-filed Plans in trackers keep their old shape; nothing migrates retroactively. The 3.5.0 to 3.6.0 lifecycle unit refreshes the consumer fragments (`refresh_fragments`).

## [3.5.0] - 2026-08-18

### Added

- Scope stable identifiers now read as what the work is: `sp-<stem>-<suffix>`, where the stem is derived from the Scope title (at most 40 characters, truncated at a word boundary) and the suffix is five random characters, e.g. `sp-readable-stable-ids-k3f9q` instead of `sp-7k2m9q`.
- A fixed, documented stem derivation with a fail-closed abort: a title that derives an empty stem stops the skill with a clear error rather than writing a path.
- The schema lint's first shape check on Scope `id`. A malformed identifier is now a hard failure, closing a gap where `id: banana` passed because only the field's presence was ever checked.
- Eight lint fixtures pinning the identifier rules: both accepted forms, an unparseable value, a present-but-blank value, a doubled hyphen, an over-length stem, a wrong-length suffix, and a traversal-shaped value.

### Changed

- `/spade-scope` states enough of the identifier grammar to mint one correctly, and names `docs/FRAMEWORK.md` as the full contract and the authority on any disagreement. The repetition is deliberate: `docs/FRAMEWORK.md` ships in no host payload, so a consumer install cannot resolve a pointer to it.
- `docs/FRAMEWORK.md` records that a stem is meaningful at creation and may read stale after a title reword, that `name` remains the current truth, and that Scope titles should avoid sensitive detail because an `id` cannot be renamed later.
- `docs/FRAMEWORK.md` replaces the old "~10⁹-value space" collision note, which described the retired random form and called `[a-z0-9]` base32.
- `docs/FRAMEWORK.md` states that a consumer's `.spade/docs/` copy is a point-in-time snapshot and the installed skill contracts are operative.
- Correcting a malformed identifier is documented as a permitted repair rather than a prohibited re-mint.
- The 3.4.0 to 3.5.0 lifecycle unit is a version pin: no consumer file needs rewriting.

### Compatibility

- The legacy `sp-` plus six characters form stays valid indefinitely. No existing identifier is rewritten, migrated, or back-filled, and a missing `id` keeps its grandfathered warning.
- Frontier `fr-` identifiers are deliberately unchanged.

## [3.4.0] - 2026-07-17

### Added

- `/leads` for capturing out-of-scope bugs, tech debt, improvements, security smells, flaky tests, and ideas without derailing the active task.
- Lead management commands for listing, showing, promoting, and closing tracked discoveries, with deduplication and structured reporting.

### Changed

- Repository tracker guidance can route Leads to Linear through `.spade/config`; GitHub Issues remains the default and tracked `LEADS.md` remains the unavailable-Issues fallback.
- Framework guidance now distinguishes actionable Leads from reusable `/spade-learn` knowledge.
- Claude, Codex, plugin, marketplace, and global-install projections now expose 18 governed skills while `leads` remains advisory and outside `critical_skills`.
- The 3.3.0 to 3.4.0 lifecycle unit refreshes consumer `AGENTS.md` and `CLAUDE.md` fragments before writing the version pin last.

## [3.3.0] - 2026-07-17

### Added

- `/spade-unhinged` for one explicitly confirmed, disposable, non-shipping experiment with no Scope, Plan, approval, tracker, run-state, or learning artefact.
- A 61-case blind behavioral corpus covering intent routing, read-only preflight, continuous path gating, bounded exits, Draft PR audit, and unchanged destructive confirmations.

### Changed

- Deliver tripwire #6 and Unhinged now share one canonical 14-category fail-closed security-sensitive path surface, with every v3.2.1 Deliver halt preserved before extension.
- Retained or shared experiments use an `[unhinged]` Draft PR that states `not approved for merge`, never merges, and must close before unchanged work re-enters a normal shipping-capable SPADE path.
- Consumer audit rules now recognise full-loop, quick-path, and non-shipping Unhinged audit shapes while preserving human ownership of Evaluate, Done, and Ship.
- Claude, Codex, plugin, marketplace, and global-install projections now expose 17 governed skills.
- The 3.2.1 to 3.3.0 lifecycle unit refreshes consumer `AGENTS.md` and `CLAUDE.md` fragments before writing the version pin last.

## [3.2.1] - 2026-07-14

### Fixed

- Review mode resolution now requires both a Scope and Plan for Full Review, preserving Plan-only review reachability.
- Tracer-bullet example lint and Codex plugin option parsing now reject empty template values and support flag-only validation correctly.
- Evaluate, Deliver, status, continuity, and hybrid-mode guidance now state their fail-closed evidence, timeout, idempotency, and recovery boundaries explicitly.
- Frontier discovery now records out-of-scope decisions consistently, detects orphaned Linear resolutions, fails named-question conflicts without mutation, and prevents duplicate handoff invocation.
- Historical v3.1.0 and v3.2.0 fixtures carry corrected Linear-canonical and reversible wording through explicit normalized fixture rules.

## [3.2.0] - 2026-07-14

### Added

- `/spade-frontier`, a governed discovery workflow for meaningful destinations that are not yet ready for normal Scope authoring.
- A versioned `spade-frontier/v1` decision index with canonical resolution records, bounded loading, and equivalent Linear, local, and hybrid behavior.
- Behavioral fixtures for initial mapping, no-fog routing, blocked questions, one-question frontier progression, and graduation into plan-ready Scopes.

### Changed

- `/spade-scope` can return uncertain major work to frontier discovery without adding a sixth SPADE phase.
- `/spade` ends a provisional pre-Scope run at a frontier handoff and starts normal run-state only from each graduated Scope's stable identity.
- Consumer fragments and host projections now register the sixteenth governed skill.

## [3.1.0] - 2026-07-14

### Added

- A versioned `spade-run-state/v1` summary covering Scope revision, autonomy, phase, checkpoints, active work, Git and PR references, verification freshness, halt reason, and next action.
- Safe `/spade` resume after live tracker, Plan, approval, repository, branch, worktree, PR, check, and capability validation.
- Bounded stale-state repair, restart, cancel, and dirty-worktree ownership paths that preserve human gates and local changes.
- Evidence-backed learning candidates from Deliver and Evaluate, deduplicated and routed through the existing public, private, or skip `/spade-learn` flow.
- A 51-case continuity corpus, independent blind procedure, and deterministic contract validation.

### Changed

- `/spade-status` now reports recorded continuity as unvalidated until `/spade` reconstructs live state.
- Linear uses immutable complete state snapshots, local mode uses one idempotently replaceable summary plus event history, and hybrid mode mirrors tracker-first state best-effort.
- Active learning matches can be updated or archived and replaced only through the existing human-gated refresh behavior.
- Host projections and clean-install manifests now carry the same continuity and candidate contracts for Claude and Codex.

## [3.0.0] - 2026-07-13

### Added

- Required tracer-bullet outcomes for every Plan task, covering usable end-to-end behavior, the highest practical test seam, and explicit blocking relationships.
- A fixed-base Delivery Review with independent Scope-conformance and repository engineering-standard axes.
- A criterion-by-criterion acceptance-evidence matrix with diff-verifiable, runtime-verifiable, external-state, and human-only classifications.
- Behavioral fixtures for missing Scope coverage, stale test output, unverified external state, standards-only defects, and changed review heads.

### Changed

- Plans now default to vertical slices and require a rationale for intentionally horizontal or preparatory tasks.
- Runtime-verifiable criteria require fresh commands and results, with proportionate browser, screenshot, console, or network evidence for UI criteria.
- External-state and human-only criteria remain explicitly open until the appropriate owner verifies them.
- Delivery Review findings and acceptance evidence feed an agent recommendation of PASS, PARTIAL, or FAIL.
- Human ownership remains explicit: the human decides the final Evaluate verdict, Done, and Ship.
- Consumer fragments now refresh during migration from 2.1.0 to 3.0.0 so the new contracts are present in repository guidance.

## [2.1.0] - 2026-07-12

### Added

- One host-neutral editable source under `src/` with deterministic Claude and Codex projections.
- A capability manifest covering 15 skills, eight reviewer personas, one researcher, and four helpers.
- Exact-manifest global installs for Claude and Codex, including stale-file cleanup and path-confinement tests.
- Skill-authoring, semantic-drift, context-budget, and cross-host behavioral fixtures.
- Progressive-disclosure references for the five largest skills.

### Changed

- Claude and Codex are both full supported hosts.
- Release packaging uses the same projection command as CI instead of a second mirroring implementation.
- Contributor guidance and architecture rules now make generated host paths read-only projections.

## [2.0.1] — 2026-07-12

### Changed

- After completing Evaluate, a human may explicitly ask an AI agent to merge the reviewed PR once required checks pass.
- Deliver still halts before merge by default, and machine-attributed Plan approval never counts as merge authorization.
- Consumer agent rules and installed `/spade` skills now carry the same explicit-authorization contract.

## [2.0.0] — 2026-07-01

**The Deliver autonomy level is live.** `/spade` can now run the full sweep —
scope → review → plan → code → open PR → one CodeRabbit cycle → **halt before
merge** — autonomously (PS-1862). The human gate is not removed: it **relocates
from the pre-code Plan tap to the PR**, where a human reviews a required
*approach summary* (the forks considered-and-rejected) plus the diff, and performs the merge themselves.
The 2.0.0 contract halted Deliver before merge; v2.0.1 supersedes that operational restriction while retaining human evaluation and explicit authorization.

Major because the documented **"Approval is a STOP gate"** invariant now carries
a sanctioned, machine-attributed exception. Scope, Plan, and Stub are unchanged
and backward-compatible; only the opt-in Deliver level auto-approves.

Safety controls, all prose the orchestrator reasons over (no enforcement
scripts): a **security-sensitive-path tripwire** (enumerable, fail-closed —
auth/secrets/crypto/permissions, `.claude/settings.local.json`, fragment
markers, `setup`/`bin/**`, and the `handoff` `--dangerously-*` flags); a
**bounded, fail-closed CodeRabbit auto-apply** (mechanical allowlist only); a
**per-project open-PR cap** (`autonomy.deliver.max_open_prs`, default 3); a
**kill-switch** (`.spade/abort`); **CodeRabbit optional**, degrading on
absent-or-hung; and a **live-halt recall test** that scores whether an
unprompted Deliver run actually halts.

- `docs/FRAMEWORK.md` — § Autonomy Pipeline gains § "The Deliver level",
  tripwire #6, and the auto-decision-log blind-spot note; the Deliver status is
  flipped to live.
- `skills/spade/SKILL.md` (+ `.claude` mirror) — the Deliver dispatch, the
  security-path tripwire, and the original halt-before-merge rule.
- `AGENTS.md`, `fragments/AGENTS-section.md`, `ANTI-PATTERNS.md`,
  `skills/spade-approve/SKILL.md` (+ mirror) — the sanctioned auto-approval
  carve-out, retaining the original halt-before-merge and never-mark-Done invariants.
- `.spade/config`, `examples/fixture-linear-mode/.spade/config`,
  `skills/spade-onboard/SKILL.md` (+ mirror) — the
  `autonomy.deliver.max_open_prs` cap, idempotent.
- `tests/spade-autonomy/corpus.md`, `blind-procedure.md` — the live-halt recall
  section and the live-run procedure.

## [1.14.1] — 2026-06-21

**Terminal TL;DR is easier to read when values wrap.** The v1.14.0 block
used inline `Label: value` rows with a hanging indent, which blurred
together once `Ships` and `Watch` ran to three or four lines each — no
visual boundary between the values. The block is now a framed four-row
layout with a **hairline rule between each value**, a fixed label column
so every value starts at the same column, and continuation lines aligned
under that column. The fourth label `Your call` is renamed **`Next`** so
the action label fits the narrow aligned column; the decision framing
("Approve, or push back …") lives in the value, not the label.

Format-only — the contract (always-on, all modes, what-it-does /
what-ships / what-could-bite, single-sourced in FRAMEWORK.md) is
unchanged.

- `docs/FRAMEWORK.md` — `## Terminal TL;DR` § Shape rewritten to the
  framed hairline-rule layout with explicit rendering rules (top title
  rule, 7-char label column, inset hairline separators, flush bottom
  rule); the labels table renames `Your call` → `Next`.
- `.claude/skills/spade-scope/SKILL.md`,
  `.claude/skills/spade-plan/SKILL.md` — the closing-step references now
  name the `Next` line instead of `Your call`. Both payload trees
  (`.claude/…` and the bare `skills/` plugin payload) updated in
  lockstep.

## [1.14.0] — 2026-06-21

**`/spade-scope` and `/spade-plan` close every run with a plain-English
Terminal TL;DR.** A human who never reads the full Scope or Plan brief
now always gets a five-second summary at the end of the run: what this
does, what will ship, what could bite, and the one decision to make
next. The block is a fixed `What / Ships / Watch / Your call` shape so
the eye lands on the same row every time, written in plain terms with no
SPADE jargon or internal IDs.

**Always-on, in every mode.** The TL;DR is stdout, not a stored file, so
it is **never gated on a local write** — it fires in `linear`,
`local`, and `hybrid` alike. This closes a gap in `linear` mode, where a
run previously ended with no human-facing closer at all (nothing renders
when there is no local file). Runtime order is now: structured artefact
→ Terminal TL;DR → render-and-link footer. The `file://…` render line,
where a file was written, still trails the TL;DR and remains the last
line, so each skill's "render-and-link is the last step" invariant
holds. `Ships` is tailored by artefact: for a Scope it is the
acceptance-criteria contract (no PR exists yet); for a Plan it is the
delivery bundles — the actual PR(s)/branch(es) that will land.

- `docs/FRAMEWORK.md` — new `## Terminal TL;DR` section (single source of
  truth) defining the block's shape, labels, voice, per-artefact `Ships`
  rule, all-modes/stdout contract, and the artefact → TL;DR → footer
  ordering. Placed after `## HTML Rendering`, before `## Handoff`.
- `.claude/skills/spade-scope/SKILL.md` — added "Closing Step — Terminal
  TL;DR (ALWAYS)" before the render-and-link step; amended the top-of-file
  mandatory-closing-step invariant and the render-and-link section so the
  TL;DR is the unconditional final step (all modes) and render-and-link
  is the conditional-final (only when a file was written).
- `.claude/skills/spade-plan/SKILL.md` — added "Closing Step — Terminal
  TL;DR (ALWAYS)" before the v1.6 rendering section; clarified that in the
  pure tracker-path the TL;DR still fires so the run is never left without
  a closer. Both payload trees (`.claude/…` and the bare `skills/` plugin
  payload) updated in lockstep.

## [1.13.0] — 2026-06-19

**`/spade-review` casts its persona roster dynamically.** The review was a
fixed five-persona panel run against every change. It is now a **dynamic
cast**: a triage step reads the change, enumerates the risk dimensions it
actually carries, and casts the personas those dimensions need — the way a
Claude Code workflow author fans out sub-agents to the parts that matter.
The five canonical personas (scope-guardian, architecture-strategist,
security-lens, adversarial-reviewer, alternatives-analyst) are now a
**default library**, not a fixed panel, and the coordinator can **invent
ad-hoc personas** for a dimension no canonical lane covers (e.g. an
`idempotency-auditor` for a queue consumer, a `migration-reversibility`
lens for a schema change).

**Drop-with-cause keeps it honest.** Dynamic casting re-opens the exact
blind spot a panel exists to prevent — the coordinator pre-judging what
matters before any persona has looked. So canonical personas are defaults
the coordinator may drop, but **every drop is recorded** in the envelope's
`dropped[]` with a reason, the **cast never falls below three**, and
`security-lens` is dropped only when a change touches no auth, secrets,
untrusted input, network boundary, IAM, or data sensitivity at all. The
casting decision is an audited artefact, not a private judgement.

- `.claude/skills/spade-review/SKILL.md` — replaced the fixed "Panel
  Roster — single source of truth" with "The Cast": a canonical-persona
  library, a triage/casting procedure, the drop-with-cause discipline, and
  an **ad-hoc persona brief template** that instantiates invented personas
  with the same severity rubric and `spade-findings` JSON contract so their
  findings merge identically. Spawning, the dispatch-mode machinery, the
  merge, the tiered report (now led by a **cast line** showing who was cast
  and who was dropped), and the *Must Never Do* rules ("silently collapse
  the cast", "spawn an ad-hoc persona without the standard contract")
  updated to match.
- **Report envelope → v3.0.0 (breaking).** The fixed `personas_spawned: 5`
  integer is replaced by `cast[]` (each entry `name` / `origin`
  `canonical|ad-hoc` / `concern`), `dropped[]` (`name` / `reason`), and a
  one-line `casting_rationale`. The **finding shape is unchanged** from
  2.x, so a 2.x consumer still parses every finding object; only the roster
  metadata changed. Consumers that read `personas_spawned` migrate to
  `cast.length`.
- `docs/FRAMEWORK.md` §Multi-persona Review — rewritten for dynamic
  casting: the canonical library vs per-review casting distinction, the
  v3.0.0 envelope, and "Why a cast and not a generalist" (drop-with-cause
  as the guard against the casting pre-judgment). Changing the **canonical
  library** still needs a Scope; per-review casting and inventing an ad-hoc
  persona do not.
- Consumer-facing descriptions updated: `CLAUDE.md`, `AGENTS.md`,
  `README.md`, `fragments/CLAUDE-section.md`, `fragments/AGENTS-section.md`
  (the last also dropped the long-removed `yagni-simplicity` from its stale
  roster). The five canonical persona agent files and their briefs are
  **unchanged** — only roster selection became dynamic. Both payload trees
  (`.claude/…` and the bare `skills/` plugin payload) updated in lockstep.

## [1.12.0] — 2026-06-19

**Priority is no longer asked at scope time.** Filing a Scope no longer
prompts for a priority/urgency. The team files all work at one priority, so
the question carried no signal and was pure friction. Removed end to end:
the `AskUserQuestion` decision prompt, the section that defined the field,
the `**Priority:**` output-template line, the `/spade-list` column and its
place in the required-fields quality check, and the sub-issue "priority set
by delivery sequence" step in `/spade-plan`.

- `.claude/skills/spade-scope/SKILL.md` — dropped the "Priority / Urgency"
  field, its output-template line, and the "Priority selection" entry in the
  Decision Prompts list.
- `.claude/skills/spade-list/SKILL.md` — dropped the `Priority` column from
  the Scoped table and removed `Priority` from the Scope quality-check
  required-fields list (so existing Scopes are no longer flagged for missing
  it).
- `.claude/skills/spade-plan/SKILL.md` — sub-issue creation no longer sets a
  Linear priority by delivery sequence.
- `docs/FRAMEWORK.md` — removed the stale `/spade-scope` priority
  `AskUserQuestion` reference. The optional `priority:` frontmatter key and
  its lint enum are left intact so the eight historical Scope files under
  `.spade/scopes/` remain schema-valid; the key is simply no longer prompted
  or emitted. Both payload trees (`.claude/…` and the bare `skills/` plugin
  payload) updated in lockstep.

## [1.11.0] — 2026-06-18

**Horizon roadmap binding.** A repo whose Linear project is fronted by a
**Horizon** roadmap board can now declare that binding, and SPADE enforces
the roadmap contract on every Scope. A Horizon board Item maps **1:1 to a
Linear Milestone**, so every Scope (parent issue) maps to one Milestone,
while Plan task sub-issues are left **unmilestoned** — the milestone rollup
counts roadmap Scopes, not implementation tasks. Opt-in and additive: a repo
without a `horizon:` block is completely unaffected.

- `docs/FRAMEWORK.md` — new § *Horizon Roadmap Binding* under "Linear as the
  System of Record" is the single source of truth: the 1:1 Item↔Milestone
  anchor, the parent-Scopes-only membership rule, the "AI never creates a
  Milestone" rule (human-owned, like the Done transition), warn-not-block
  enforcement, and the `horizon:` config shape (`linear`/`hybrid` only).
- `.claude/skills/spade-scope/SKILL.md` — new § *Horizon Milestone Mapping*:
  in a Horizon-bound repo, list Milestones, recommend the best fit, and
  prompt via `AskUserQuestion` (candidates + *File without a Milestone (not
  recommended)*). Warn-and-proceed on override; never auto-create. Wired
  into Create/Edit Mode Linear steps and the Decision Prompts list.
- `.claude/skills/spade-plan/SKILL.md` — sub-issue creation now leaves
  sub-issues unmilestoned in a Horizon-bound repo (does not inherit the
  parent's Milestone).
- `.claude/skills/spade-onboard/SKILL.md` — new opt-in *Horizon Binding*
  step writes the `horizon:` block to `.spade/config` (idempotent, same
  rule as the `handoff:` block).
- `AGENTS.md` — mandatory Scope-phase rule for Horizon-bound repos.
- `.spade/config` — documents the `horizon:` block (commented; this repo is
  not Horizon-bound). Both payload trees (`.claude/…` and the bare `skills/`
  plugin payload) updated in lockstep.

Pattern verified against the live Argus project, whose Milestone
descriptions already encode "Horizon item ↔ this milestone, 1:1; parent
scopes only".

## [1.10.0] — 2026-06-06

**`alternatives-analyst` gains a narrow Scope-mode remit.** The
counterfactual / road-not-taken persona now sits on the Scope Review
panel too, making the roster a **uniform five across all three modes**.
This is **additive** — Plan and Full review behaviour is unchanged; a
Scope panel simply gains a silent-by-default persona.

- `.claude/agents/spade-review-alternatives-analyst.md` — the brief is
  restructured into a shared discipline plus a `{mode}`-conditional
  remit. In Scope Review the analyst fires on exactly two cases: a Scope
  that has pre-committed to a solution (an implicit-solution reframe) or
  an implicit buy-vs-build — silent otherwise. Carries a worked passing
  finding, a worked non-finding, a four-part validity test, and an
  explicit lane rule + convergence-overlap acknowledgement vs the
  scope-guardian. Open-ended "cheaper/simpler/narrower path" findings are
  excluded in Scope mode (that is the guardian's proportionality remit).
- `.claude/skills/spade-review/SKILL.md` — Panel Roster is now 5/5/5
  (single source of truth); the "Scope Review mode" block applies the
  analyst's Scope-mode remit instead of excluding it; the mode-dependency
  is relocated from the roster into the persona brief. `personas_spawned`
  is a uniform `5`; `schema_version` stays `2.1.0` (the field range only
  narrowed). Dispatch-mode table, report templates, and Panel-history
  prose updated to match.
- `docs/FRAMEWORK.md`, `ARCHITECTURE.md` — §Multi-persona Review, the
  roster-change-bar rationale, the envelope-contract wording, and the
  data-flow panel reference updated to the uniform-five model.
- Both in-repo payload trees (`.claude/…` and the bare `skills/` /
  `agents/` plugin payload) updated in lockstep.

Scope: M-1293. Dogfooded through its own `/spade-review` Scope panel (7
findings, all dispositioned — the premise was narrowed from an open-ended
lens to the two-case remit as a direct result).

## [1.8.0] — 2026-05-18

**Local-mode artefact hardening — schema enforcement + stable IDs.**
The local-mode frontmatter schema is now machine-enforced in CI, and
every local Scope carries a stable identifier independent of its slug.

- `docs/FRAMEWORK.md` § Local Layout — adds the `id` field: a stable
  short identifier (`sp-` + six base32 characters) generated once at
  Scope creation, distinct from the title-derived slug, collision-
  resistant without a central allocator, and correctness-only — not an
  authorisation or trust primitive. The `status` / `type` / `priority`
  value sets are marked the canonical enum lists the schema lint
  enforces.
- New `scripts/lint/lint-local-frontmatter.sh` + a `local-frontmatter`
  CI job. `frontmatter.py` gains a `--schema` mode: Scope files
  hard-fail on an invalid `status` / `type` / `priority` enum value or
  a missing core field, and warn (not fail) on an unknown field or a
  missing `id` (grandfathered on pre-v1.8 files). Plan files get a
  light warn-only check; learnings stay with `lint-learnings.sh`. A
  legacy fixture and a bad-enum fixture self-test the check.
- `/spade-scope` now generates the `id` for new Scopes and aborts on a
  slug collision rather than silently overwriting an existing Scope.

Scope: M-1023. v1.8.0 also carries the `/spade-handoff` launcher,
merged unreleased since v1.7.0.

## [1.7.0] — 2026-05-18

**Local mode — read/write parity without Linear.** SPADE skills now
work end-to-end with no Linear MCP, reading and writing canonical state
from `.spade/`. A repo declares `mode: local | linear | hybrid` in
`.spade/config`; the canonical store becomes a per-repo choice rather
than a framework default. Consumer repos running under a hand-written
CLAUDE.md override to force local behaviour can drop that override.

Operating modes:

- `docs/FRAMEWORK.md` § Operating Modes — new single-source contract.
  § Mode Resolver: an explicit `mode:` wins; otherwise a `list_teams`
  probe with a 5-second timeout, resolving `linear` only when the
  configured `team_id` is in the returned set. Failure policy is
  asymmetric — fail-loud when an explicitly-configured tracker is
  unreachable, degrade-quiet to `local` when the repo was never
  configured. § Local Layout: canonical `.spade/` paths, slug grammar
  `[a-z0-9-]{1,64}`, the Scope frontmatter schema, and the
  `.spade/version` tie with pre-v1.7 grandfathering. § Hybrid Mode:
  tracker-canonical with a **non-authoritative** local mirror.

Skills:

- All nine skills (`/spade-scope`, `/spade-plan`, `/spade-approve`,
  `/spade-evaluate`, `/spade-list`, `/spade-status`, `/spade-learn`,
  `/spade-quick`, `/spade-onboard`) carry a "Mode Resolution" section
  and key tracker-vs-local behaviour off the resolved mode.
- `/spade-list` and `/spade-status` gain genuine `local`-mode code
  paths — they scan `.spade/scopes/` and parse frontmatter instead of
  hard-requiring Linear MCP. This was the M-879 origin bug.
- `/spade-onboard` scaffolds `.spade/scopes|plans|learnings` and writes
  a starter `.spade/config` with an explicit `mode:` chosen once at
  onboard time.
- `/spade-update` adds the v1.6.1 → v1.7.0 migration: it writes an
  explicit `mode:` line into `.spade/config` if absent, leaving every
  `.spade/plans/*` file grandfathered.

Lint:

- New `scripts/lint/lint-mcp-guard.sh` + `mcp-guard` CI job — fails
  when a skill names a Linear MCP tool without a "## Mode Resolution"
  section. A planted-violation fixture self-tests the check on every
  run, closing the manual-verification gap.

Fixtures:

- `examples/fixture-local-mode/` and `examples/fixture-linear-mode/` —
  minimal consumer repos for the manual happy-path verification.

Scope: M-879 (planned and delivered under the SPADE loop; the Scope's
stale "v1.4.0" version target was re-pointed to 1.7.0 at planning, the
framework already being at 1.6.1). v1.7.0 also carries the INTENT.md
project-intent loop (M-951).

## [1.6.1] — 2026-05-16

**Patch release — renderer fix and polish.** v1.6.0's HTML renderer
did not work on Pandoc 3.x. This release fixes it, gives the rendered
output a real visual design, and realigns the render lint with what
the feature is — a local-only convenience renderer, not a web app.

Renderer:

- `render/template.html`: fixed the `$for(css)$` block. It called
  non-existent Pandoc partials (`$styles.css()$`, `$css-content()$`)
  and made `spade-render` fail with exit 3 (`Could not find data file
  templates/styles.css`) on Pandoc 3.x. The stylesheet is now linked
  and inlined via `--embed-resources`, with `$highlighting-css$` for
  syntax highlighting. The `<html>` element carries `data-spade-status`
  so the stylesheet can theme to the document's phase.
- `bin/spade-render`: switched the deprecated `--highlight-style` flag
  to `--syntax-highlighting` (Pandoc 3.9+).
- `render/spade.css`: editorial redesign — status-coloured top accent
  bar, restructured document header (kicker pills, prominent title,
  quiet meta line), refined table of contents with nested indent
  guides, zebra-striped tables, softer code chips, tightened type
  scale. Light and dark both verified. 8.9KB, within the 12KB budget.

Lint:

- `scripts/lint/lint-render-security.sh` → `lint-render-smoke.sh`. The
  XSS / CSP / path-leak scan is replaced by a render smoke test: every
  fixture must render (exit 0) to a non-empty, standalone HTML document
  with the stylesheet inlined. `spade-render` turns the user's own
  Markdown into a local file they open themselves, so there is no
  web-security threat model to enforce; a functional regression guard
  (it would have caught the Pandoc 3.x breakage) is the right check.
  CI job renamed `render-security` → `render-smoke`.

Skills:

- `/spade-scope`: the render-and-link step is now a mandatory closing
  step, promoted from a trailing section so it is not treated as an
  optional appendix.

No fragment changes. Consumers on v1.6.0 only need to bump their
`.spade/version` pin to `1.6.1`.

## [1.6.0] — 2026-05-13

**HTML rendering for scopes and plans (Pandoc).** Every locally-stored
SPADE Scope and Plan now gets a sibling `.html` rendering produced by
the new `bin/spade-render` POSIX-shell wrapper around `pandoc`.
`/spade-scope` and `/spade-plan` append a clickable
`View in browser: file://...` link on every local write — modern
terminals (iTerm2, Warp, VS Code, Terminal.app) auto-linkify the URL
for cmd-click. Markdown remains canonical; HTML is a read-only
rendered view.

Released artefacts:

- `bin/spade-render` — POSIX-shell wrapper around `pandoc`, ≤100 lines.
- `render/template.html` — Pandoc HTML5 template (status header from
  frontmatter, TOC, restrictive CSP meta).
- `render/spade.css` — ≤12KB inlined stylesheet (system-font
  typography, six status pill colours, syntax highlighting via
  Pandoc's Skylighting, `prefers-color-scheme: dark`, `@media print`).
- `scripts/lint/lint-render-security.sh` + new `render-css-budget` and
  `render-security` CI jobs — fixture-driven XSS / path-leak / CSP
  assertions enforced on every PR.
- `tests/fixtures/render/{xss-attempts,minimal-scope}.md` — security
  and smoke fixtures.
- `docs/FRAMEWORK.md` §HTML Rendering — single source of truth for the
  Pandoc install matrix, renderer interface, status pill palette
  (hex values), security stance, recommended `.gitignore` line,
  `file://` linkification rule, and determinism contract.
- `ARCHITECTURE.md` §External Toolchain Policy — Pandoc named as a
  recommended consumer binary (same category as `git`/`jq`).

Skill changes:

- `/spade-scope` and `/spade-plan` gained a "Rendering and terminal
  link (v1.6+)" closing section. The render + link step is purely
  additive; existing skill behaviour is unchanged. Render failure
  never aborts the skill — the `.md` is always written.
- `/spade-update` documents the v1.3.x → v1.6.0 upgrade recipe with
  an informational pandoc presence check. No bulk render of historical
  `.md` files (lazy on next write only).

Architectural posture preserved:

- No vendored third-party code. No Node, no npm, no compiled
  artefacts. Pandoc is a recommended consumer dep, not a library.
- `PATTERNS.md` unchanged — "Markdown + YAML frontmatter is the only
  data format" still holds; HTML is a rendered view, not data.
- Graceful degradation: when pandoc is absent, `spade-render` exits 2
  and the calling skill surfaces an install hint on every write
  (not one-time-per-session) until pandoc is installed.

Deferred to v1.7+ (out of scope here):

- Mermaid pre-rendering (would pull in headless Chromium via `mmdc`).
- Terminal links on read skills (`/spade-status`, `/spade-list`,
  `/spade-approve`, `/spade-evaluate`, `/spade-review`).
- Bulk render on `/spade-update`.
- Auto-injection into the consumer's `.gitignore` (documented for
  opt-in only).
- AC checkbox state persistence, sticky TOC, dark-mode toggle button.
- Panel-report and learnings HTML rendering.

Scope: M-901. Two `/spade-review` panel rounds on the pre-shipped
drafts (33 + 41 findings, 4 blocking on the original Node-bundle
architecture) drove the switch to Pandoc and the minimum-viable
shape.

## [1.3.0] — 2026-04-28

- New skill `/spade-research` — landscape research via an isolated
  Opus 4.7 read-only subagent.
- New framework convention "Asking the Human" (`AskUserQuestion` for
  fixed-option decisions).
- Several skills retrofitted to the new convention.

## [1.2.0] — earlier

- M-420: Linear-canonical Plan storage. `.spade/plans/` becomes a
  fallback for Linear-less environments rather than a default
  dual-write.

## [1.1.x] — earlier

- Multi-persona `/spade-review` panel (5 subagents).
- `/spade-learn` skill.
- Execution posture field in Plan templates.
- CI lint suite.

## [1.0.0] — earlier

- Initial release: `/spade-scope`, `/spade-plan`, `/spade-approve`,
  `/spade-evaluate`, `/spade-quick`, `/spade-onboard`,
  `/spade-status`, `/spade-list`, `/spade-update`.
- Fragment-marker-based onboarding via `bin/spade-marker-replace`.
