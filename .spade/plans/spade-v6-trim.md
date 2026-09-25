# Plan: SPADE v6 - cut the framework down to what current models need

Scope: `.spade/scopes/spade-v6-trim.md`
Approved by Kevin Robertson (direct instruction to implement), 2026-09-25.

## Approach

Rewrite from the spine outward: first the single definition (`docs/FRAMEWORK.md`) and the always-loaded fragments, then each skill against them, then the inventory, tests, and release plumbing.
FRAMEWORK.md becomes a short reference that keeps the precise parts (security path surface, guards, Deliver level, lifecycle) and drops history, rationale essays, and restated procedure.
Skills state the goal, the hard lines, and what done looks like, and trust the model with the steps.

Rejected forks:
- Keep the eight persona files and only make the panel optional. Lost because the files mostly restate what a reviewer already knows; a one-line lens does the same job.
- Keep frontier and unhinged behind usage telemetry first. Lost because local session history already shows zero invocations, and relaxing the "no code without a Scope" rule removes the reason unhinged exists.
- Replace prose-pinning tests with model-graded evals in CI. Lost because CI would need model access and spend; the eval harness runs manually instead.
- Split into several PRs. Lost because the fragments, skills, FRAMEWORK.md, and inventory must change together to stay consistent.

## Risks

- Removing literal-prose tests means CI no longer catches accidental deletion of a hard rule; mitigated by the eval harness and by keeping hard rules in guards.
- Consumers on 5.x see a large fragment change on update; mitigated by the ordinary refresh_fragments migration and a clear CHANGELOG.
- `bin/spade-guard` is a permission-widening path; the edit only narrows it, and the PR is left for a human merge.

## Tasks

- [x] 1. Core definition - done when `docs/FRAMEWORK.md`, `AGENTS.md`, `CLAUDE.md`, and both fragments are rewritten to the v6 model; verify with byte counts against AC 1 and 3.
- [x] 2. Loop skills - done when `spade`, `spade-scope`, `spade-plan`, `spade-quick`, and `spade-evaluate` are rewritten, `spade-approve` is folded into `spade-plan`, and `continuity.md` is deleted; verify each SKILL.md is at most 12 KiB.
- [x] 3. Review and research - done when `spade-review` uses one `spade-reviewer` agent with lenses, the eight persona files are gone, and `spade-research` plus the researcher carry no model pins or think-hard lines; verify with grep.
- [x] 4. Supporting skills - done when `spade-onboard` (absorbing INTENT.md, gotchas-first docs, and a verification-skill draft), `spade-status` (absorbing listing), `spade-learn`, `spade-update`, `leads`, and `unslop` are trimmed and frontier, unhinged, handoff, intent, and list are deleted; verify with the skill inventory.
- [x] 5. Inventory, tests, and release - done when CAPABILITIES, projections, installers, guard, lints, tests, eval harness, migration, CHANGELOG, README, ARCHITECTURE, PATTERNS, ANTI-PATTERNS, INTENT, and examples match v6; verify with `scripts/lint/run-all.sh` (only the environmental pwsh and release-history failures may remain).

## Halts

None. The guard edits (bin/spade-guard, .spade/config) only narrow protection and were made under Kevin's direct instruction; the merge is left to him.

## Evaluation

Reviewed head: e29c161 (Delivery Review by an independent Codex Sol reviewer in three passes: 8, then 3, then 1 blocking findings, all fixed; none open).

| # | Criterion | Evidence | Status |
|---|---|---|---|
| 1 | Fragments at most 3 KiB and 1 KiB, rules once, stop rule, no Scope demand for small work | `wc -c fragments/*.md`: 1,851 and 174 bytes; `lint-skill-authoring.sh` budget check; evals `quick-direct-request` and `question-needs-nothing` PASS | met |
| 2 | Six skills removed, duties folded, one reviewer agent, inventory agrees | `ls src/skills` lists 13; `ls src/agents` lists spade-reviewer and spade-researcher; `project-hosts.sh --check`, `lint-codex-plugin.sh`, and `lint-install-projections.sh` pass | met |
| 3 | Every SKILL.md at most 12 KiB; Deliver procedure at most 60 KiB | largest SKILL.md is leads at 7,917 bytes; spade, scope, plan, review, evaluate, unslop, reviewer, FRAMEWORK.md, and fragments total 57,117 bytes | met |
| 4 | Short Plan format at `.spade/plans/<scope-key>.md` as the resume point; run-state, sub-issues, cards, and approach vocabulary gone | `docs/FRAMEWORK.md` § Plan; `lint-examples.sh` passes on the new format; grep for `spade-run-state`, `Needs:`, `characterization-first` in src, fragments, and FRAMEWORK.md finds nothing; eval `plan-level` PASS | met |
| 5 | One reviewer by default, blocking-only contract, lenses on risk, no think-hard or model pins | `src/skills/spade-review/SKILL.md`, `src/agents/spade-reviewer.md`; lint check for think-hard and model names passes; eval `review-blocking-only` PASS | met |
| 6 | Prose-pinning tests replaced by structural lint and a manual eval harness; guard, lifecycle, install, onboarding tests pass | `tests/hooks/guards.sh` 0 failures; `tests/lifecycle.sh` 99 passed; `lint-install-projections.sh` passes (PowerShell fixture skipped, no pwsh here); `lint-onboard-idempotency.sh` 15 passed; `tests/evals/run.sh` 5 of 5 PASS | met |
| 7 | Guard and FRAMEWORK consistent, unhinged and handoff removed | `bin/spade-guard` accepts only quick and deliver modes and no longer names `.spade/handoff.local`; `tests/hooks/guards.sh` passes | met |
| 8 | v6.0.0 release plumbing and docs | `src/CAPABILITIES.md` version 6.0.0; `migrations/manifest.tsv` row 5.1.0 to 6.0.0; 6.0.0 lifecycle fixture; CHANGELOG, README, ARCHITECTURE, PATTERNS, ANTI-PATTERNS, INTENT updated; version-claim lint passes | met |

Known and pre-existing: `lint-lifecycle.sh` fails its release-history check in this snapshot repository (Lead #2), and GitHub Actions is disabled (Lead #3), so the lints were run locally.

**Verdict:** PASS - every criterion is met with evidence.
**Recorded by:** Kevin Robertson, 2026-09-25, by instructing the merge. The change edits the guard and `.spade/config`, so the verdict stayed with a human.
