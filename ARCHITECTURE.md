# Architecture

## System boundaries

SPADE is a set of files, not a runtime: Markdown skills and agents, a framework reference, consumer fragments, and bounded shell helpers.
There is no server, database, daemon, or compiled artefact; behaviour comes from skill prose the host agent follows, plus Claude Code command hooks (`bin/spade-guard`) for the few rules that need checking rather than judgement.

- **Canonical source:** `src/` (skills, agents, host adapters, hooks, `CAPABILITIES.md`), `docs/FRAMEWORK.md`, `fragments/`, `bin/`, `migrations/`, `templates/`, `render/`.
- **Generated:** `.claude/`, `.codex/`, `skills/`, `agents/`, `hooks/`, `scripts/spade-*`, `.claude-plugin/payload.manifest`, `.codex-plugin/`, `.agents/plugins/`, `plugins/spade-framework/`, `generated/install/`, all written by `scripts/project-hosts.sh`.
- **Consumer state:** `.spade/` in each consumer repository (config, version pin, Scopes, Plans, learnings, review reports, guard markers). SPADE keeps no state anywhere else.
- **Integration:** Linear through its MCP server. Nothing else.

## Data and control flow

1. A Scope is a Linear parent issue, or `.spade/scopes/<slug>.md` in local mode.
2. `/spade-plan` writes `.spade/plans/<scope-key>.md` and, in Linear mode, posts it on the Scope issue. The Plan file is committed on the delivery branch and ticked as work lands, which makes it the resume point.
3. Approval is a line in the Plan: a human at the Plan level, a machine-recorded one at the Deliver level.
4. Delivery opens one PR per bundle; `/spade-review` reviews the fixed base..head range; `/spade-evaluate` records the verdict and writes `.spade/guard/reviewed-head-<pr>` for the merge guard.
5. The merge follows `autonomy.deliver.merge`; whoever records PASS moves the Scope to Done.

Every projected skill carries a copy of `docs/FRAMEWORK.md` at `references/FRAMEWORK.md`, because consumer repositories have no copy of their own.

## Deployment and operations

- **Distribution:** the git repository with Claude and Codex plugin manifests, or `./setup` / `./setup.ps1` installing exact projections into host skill roots and `~/.spade/bin`, with SHA-256 receipts under `~/.config/spade/`.
- **Versioning:** `src/CAPABILITIES.md` is the version authority. A fragment change is a release with a `refresh_fragments` row in `migrations/manifest.tsv`; `bin/spade-lifecycle` applies migrations transactionally and writes the consumer pin last.
- **CI:** `.github/workflows/lint.yml` runs the lints in `scripts/lint/`. Python there is stdlib-only and CI-only.

## Decisions and gotchas

- **Prose for judgement, guards for invariants.** A rule that needs no judgement goes in `bin/spade-guard` with a case in `tests/hooks/guards.sh`; everything else is prose. The guard is a path-shaped approximation of the security-sensitive surface in FRAMEWORK.md, so change both together.
- **Say it once.** Skills link to FRAMEWORK.md sections instead of restating them; the authoring lint fails on a `§` reference that does not resolve.
- **Tests check structure, not wording.** v6 deleted the literal-prose contract tests because they locked sediment in place. Behaviour is checked with the manual evals in `tests/evals/`.
- **Codex has no hooks.** On Codex, and anywhere `.spade/guard/<session>/live` is missing, the stricter model applies: any security category halts before code and the human merges.
- **Windows migrations need Git Bash or WSL.** `spade-marker-replace` and `spade-lifecycle` are bash-only; only `setup` has a PowerShell twin.
- **Pandoc is optional.** `bin/spade-render` needs pandoc 3.0+ and exits 2 without it; Markdown stays canonical.
- **Codex research isolation** uses `codex exec --sandbox read-only --ignore-user-config --ephemeral`; if that contract is unavailable the researcher fails closed.
- **Lifecycle fixtures need release history.** `tests/fixtures/lifecycle/historical.tsv` pins release commits that must exist in the local clone, so `lint-lifecycle.sh` only passes in a clone that has them.

## Security requirements

- No secrets in the repository; skills, fragments, and examples are public.
- Setup and lifecycle operations run only bounded local helpers, fetch only the canonical remote, and advance only to a human-approved commit SHA.
- Migration manifests are data mapped to allowlisted actions, never shell.
- Rendered Markdown is untrusted: raw HTML, unsafe links, and fetchable images are neutralised.
- Onboarding and updates are idempotent and edit only between fragment markers.
- Linear MCP permissions are granted per consumer project, never by the framework.
