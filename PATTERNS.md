# Patterns

Approved patterns, conventions, and libraries for this project. AI agents must
follow these patterns when generating Plans and delivering code. If a better
approach exists, flag it in the Plan and get human approval before deviating.

## Code Patterns

- **Prose over code.** Skills are Markdown. Behaviour is described in natural
  language so the agent can reason about it. Resist the temptation to write
  scripts that "enforce" skill logic — that belongs in the prose.
  The one exception is `bin/spade-guard`: deterministic checks over tool input
  and named local state, for invariants that need no judgement
  (`docs/FRAMEWORK.md` § Mechanical guards). A guard never decides a workflow
  question; it stops a tool call the prose already forbids.
- **Shell portability.** `setup` uses `/bin/bash`, POSIX-safe wherever
  practical. Avoid GNU-only flags. `bin/spade-update-check` must always
  `exit 0` so a failed update check never breaks a skill invocation.
- **Idempotent writes.** Any script that modifies a consumer repo (onboarding,
  update) must be safe to run twice. Use fragment markers, not append.
- **Transactional migration units.** Store historical transitions as flat data
  with one explicit source and target.
  Stage and verify one unit before mutation, roll it back as a unit on failure,
  and write the consumer version pin last so real state is the resume checkpoint.
  Persist transaction and checkpoint evidence below the resolved Git directory, never inside the tracked consumer tree.
- **Immutable release provenance.** Resolve releases from the exact canonical
  remote to a commit SHA, show that SHA for human approval, and re-resolve it
  immediately before advancing.
  Global setup persists machine-local SHA-256 receipts for the installed projection.
  Host-managed plugins carry embedded SHA-256 payload integrity claims.
  Never treat a payload's self-claim as publisher provenance; require separately trusted host-manager revision evidence or fail unsupported.
- **Stable diagnostics.** Read-only lifecycle checks emit one redacted,
  machine-parseable finding per check with expected state, observed state, and
  remediation plus distinct healthy, drift, and unsupported exit codes.
- **Dual-shell parity.** Every behaviour in `setup` must have a matching
  behaviour in `setup.ps1`. When one changes, the other changes in the same PR.
- **One editable behavior source.** Skills and agents are edited only under
  `src/`. Run `scripts/project-hosts.sh` to update Claude, Codex, plugin, and
  global-install projections; never edit generated host payloads directly.
- **Fixed host adapters.** Host adapters may translate only user-decision,
  shell, isolated-agent, and read-only-research primitives. They never carry
  workflow rules or change gates. Mechanical guards are not adapters; they
  live in `src/hooks/` and `bin/` and are Claude-host only.
- **Progressive disclosure.** Always-loaded skills retain routing, invariants,
  safety gates, and completion rules. Triggered histories, examples, migration
  procedures, and branch-specific detail live under `references/`.

## Project Structure

```text
spade-framework/
├── src/skills/, src/agents/          # the only editable skill and agent source
├── src/hosts/                         # thin host adapters (token translation only)
├── src/hooks/hooks.json               # canonical Claude hook source (mechanical guards)
├── src/CAPABILITIES.md                # inventory, budgets, version authority
├── docs/FRAMEWORK.md                  # the framework reference, copied into every projected skill
├── fragments/                         # AGENTS.md and CLAUDE.md sections for consumer repos
├── bin/                               # guard, lifecycle, marker, render, update-check helpers
├── migrations/manifest.tsv            # ordered consumer migration units
├── templates/, render/, examples/     # INTENT template, HTML renderer, worked Scope and Plan
├── tests/                             # guard, lifecycle, install, onboarding tests and manual evals
├── scripts/                           # projection generator and lints
├── .claude/, .codex/, skills/, agents/, hooks/, plugins/, generated/   # generated projections
├── .spade/                            # this repo's own config, Scopes, Plans, learnings
└── setup, setup.ps1                   # POSIX and Windows installers
```

## Data Patterns

- **Markdown + YAML frontmatter** is the only data format. Skills, fragments,
  examples, and architecture docs are all Markdown. Structured metadata lives
  in YAML frontmatter.
- **Fragment markers** delimit framework-owned regions in consumer docs:
  `<!-- SPADE-FRAMEWORK-START vX.Y.Z -->` / `<!-- SPADE-FRAMEWORK-END -->`.
- **`.spade/version`** is a `key=value` text file, not YAML or JSON. Keep it
  that way — it is read by bash.
- **`.spade/config`** is YAML. Records per-repo binding to Linear team +
  project + default assignee.
  Security-sensitive executable names and argument arrays do not belong here.
  It also carries the `autonomy:` defaults and the `guards:` block that
  `bin/spade-guard` reads. The merge policy lives here deliberately: the
  deliver-mode guard blocks agent edits to this file, so only a human can
  loosen it.
- **`migrations/manifest.tsv`** is a flat four-field registry.
  It is parsed as data and may select only actions compiled into the lifecycle helper.

## Integration Patterns

- **Linear MCP** is the primary tracker integration. Always check whether
  Linear MCP is available before attempting to create issues; fall back to
  asking the human if it is not.
- **Tracker-agnostic skills.** Skill prose must degrade gracefully when Linear
  is unavailable: e.g. `/spade-plan` must be able to produce a Plan document
  in-file without requiring an issue to exist.
- **No other external services.** The framework does not call out to GitHub,
  Slack, email, or any other integration. Consumer projects add their own.

## Deployment Patterns

- **Clone deployment uses an approved commit + `./setup`.** Resolve and approve
  one immutable commit from the exact canonical remote, then advance with a
  fast-forward to that commit.
  Host-managed plugins use their host manager and validate embedded payload claims.
  Global projections validate the exact receipts written by setup.
- **Version authority** is `src/CAPABILITIES.md`.
  The repository pin, plugin manifests, install payloads, fragments, and release
  checks derive from or are validated against it.
- **Breaking changes** to skill contracts must bump the major version and
  update the fragment marker version so `/spade-update` can rewrite safely.

## Approved Libraries

| Purpose            | Library / Tool          | Version   | Notes                                                     |
|--------------------|-------------------------|-----------|-----------------------------------------------------------|
| Shell              | bash                    | 3.2+      | macOS ships bash 3.2; avoid bash-4-only features          |
| Shell (Windows)    | PowerShell              | 5.1+      | Feature parity with bash setup                            |
| Issue tracker      | Linear (Anthropic MCP)  | n/a       | Only external integration                                 |
| Codex host         | Codex CLI                | host      | Existing host capability; read-only ephemeral research only |
| CI                 | GitHub Actions           | n/a       | Canonical schema, projections, installs, behavior corpora, and existing framework checks |

No npm / pip / cargo / go modules. No compiled code. If a future change
requires one, it is a major architectural shift and must be scoped explicitly.

## Documentation Patterns

- **Every skill has one canonical `SKILL.md`.** Its always-loaded body owns
  routing and invariants; branch-specific material may live in explicitly
  routed canonical `references/` files.
- **Generated paths are never edited.** CI regenerates in a temporary tree and
  fails when any Claude, Codex, plugin, install-manifest, count, or version
  projection differs from `src/` and `src/CAPABILITIES.md`.
- **The Plan lives in the repository.** `/spade-plan` writes `.spade/plans/<scope-key>.md` in every mode and, with Linear, also posts it on the Scope issue.
  Delivery ticks its tasks and commits it on the delivery branch, so it is both the audit record and the resume point.
  SPADE creates no per-task sub-issues.
- **Architecture docs (this file, ARCHITECTURE.md, ANTI-PATTERNS.md) apply to
  this repo itself.** Consumer repos get their own copies via `/spade-onboard`
  and fill them in with their own content.
- **Worked examples** (`examples/example-scope.md`, `examples/example-plan.md`)
  are the canonical shape for Scopes and Plans. Keep them in sync with skill
  prose.
