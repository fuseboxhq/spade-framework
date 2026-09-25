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

- [ ] 1. Core definition - done when `docs/FRAMEWORK.md`, `AGENTS.md`, `CLAUDE.md`, and both fragments are rewritten to the v6 model; verify with byte counts against AC 1 and 3.
- [ ] 2. Loop skills - done when `spade`, `spade-scope`, `spade-plan`, `spade-quick`, and `spade-evaluate` are rewritten, `spade-approve` is folded into `spade-plan`, and `continuity.md` is deleted; verify each SKILL.md is at most 12 KiB.
- [ ] 3. Review and research - done when `spade-review` uses one `spade-reviewer` agent with lenses, the eight persona files are gone, and `spade-research` plus the researcher carry no model pins or think-hard lines; verify with grep.
- [ ] 4. Supporting skills - done when `spade-onboard` (absorbing INTENT.md, gotchas-first docs, and a verification-skill draft), `spade-status` (absorbing listing), `spade-learn`, `spade-update`, `leads`, and `unslop` are trimmed and frontier, unhinged, handoff, intent, and list are deleted; verify with the skill inventory.
- [ ] 5. Inventory, tests, and release - done when CAPABILITIES, projections, installers, guard, lints, tests, eval harness, migration, CHANGELOG, README, ARCHITECTURE, PATTERNS, ANTI-PATTERNS, INTENT, and examples match v6; verify with `scripts/lint/run-all.sh` (only the environmental pwsh and release-history failures may remain).

## Halts

None yet.
