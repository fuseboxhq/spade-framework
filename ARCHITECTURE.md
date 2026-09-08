# Architecture

This document defines the system architecture, infrastructure, and technical
constraints for this project. AI agents must read this file before generating
any Plan. Proposed solutions that conflict with this document must be flagged
and require explicit human approval before proceeding.

## System Overview

SPADE is a **convention + skills framework** for human–AI collaboration on
software engineering work. It is not a runtime, a service, or a package.

- **Users** are engineers working in Claude Code, Codex, or another compatible
  agent environment who want a documented, auditable loop for AI-assisted delivery.
- **Canonical surface area** is the host-neutral skill and agent tree under
  `src/`, plus bounded shell setup and projection tooling, Markdown architecture
  templates, and fragment files injected into consumer repos during onboarding.
- **Generated surface area** is the Claude and Codex plugin/global payloads under
  `.claude/`, `.codex/`, top-level `skills/`, and top-level `agents/`.
- **Core loop** is five phases with explicit ownership: Scope (human) → Plan
  (AI) → Approve (human) → Deliver (AI or human) → Evaluate (human, agent-recorded
  on the Deliver level when every criterion is machine-verifiable).

The "system" is a set of files. There is no server, no database, no compiled
artefact, no runtime agent of our own. Behaviour emerges from skill prose that
the agent reads and follows. On the Claude host a small set of command hooks
(`bin/spade-guard`) enforces the invariants that need checking rather than
reasoning; see `docs/FRAMEWORK.md` § Mechanical guards.

## Infrastructure

- **Distribution:** git repository with Claude and Codex plugin manifests, or an
  exact global install from `./setup` / `./setup.ps1` into host skill roots and
  `~/.spade/bin`.
  Global setup writes machine-local SHA-256 projection receipts under `~/.config/spade/`.
  Host-managed plugin payloads embed generated SHA-256 claims so diagnostics can distinguish intact payload content from modified installed content.
  Those self-contained claims are integrity evidence only; immutable publisher provenance must come from a separately trusted host-manager revision or fail unsupported.
- **Storage:** per-project state in `.spade/` (version pin, config, examples,
  docs copy, resumable run state, learnings, panel-review reports, and fallback Plan artefacts).
  Intended to be committed alongside project code, except `.spade/reviews/`
  (the `/spade-review` full-report artefacts) which is gitignored. Plans
  themselves are tracker-canonical from v1.2.0 — see Data Flow § "Local state".
- **Integrations:** Linear (via Anthropic's Linear MCP server) for issue
  tracking. No other external services.
- **Runtime:** the host agent environment invokes generated Markdown skills.
  SPADE owns no runtime, daemon, or service.

There is no cloud provider, no orchestration, no container runtime owned by
this repo.

## Data Flow

1. Human writes a **Scope** in Linear (or any tracker) as a parent issue.
2. `/spade-plan` reads the Scope + architecture docs, produces a Plan document,
   and creates sub-issues grouped into delivery bundles.
3. `/spade-approve` gates the Plan on the Plan level; the Deliver level records
   a machine-attributed approval and relocates the gate to the PR.
4. `/spade-review` (optional) spawns a five-persona review panel for a
   second opinion on the Scope, the Plan, or both.
5. Delivery happens one bundle at a time: one branch → one PR → one or more
   sub-issues closed.
6. `/spade-evaluate` checks delivered output against acceptance criteria and
   records the verdict when every criterion is machine-verifiable.
7. The PR merges by policy (`autonomy.deliver.merge`); whoever recorded the
   PASS moves the parent issue to Done.

Local state: from v1.2.0 onward the tracker (Linear) is the **canonical**
Plan store when available. `.spade/plans/` is a **fallback** for
Linear-less environments and a **read-path for historical archives**
written under v1.0–v1.1, when the framework defaulted to a dual-write.
`/spade-plan` writes to `.spade/plans/` only when the tracker cannot
accept the Plan (MCP unreachable, no parent issue, or write failure).
Existing archives are non-destructive — they are never deleted, moved,
or rewritten by the framework. See `PATTERNS.md` and `/spade-plan` for
the precise gate.

Run continuity state follows the active operating mode.
Linear keeps immutable complete state snapshots on the Scope, local mode keeps one `.spade/runs/<scope-key>.md` summary and event history, and hybrid mode mirrors the tracker record best-effort.
Every recorded external reference is revalidated before resume and no continuity artefact is treated as authority for Git or PR state.

## Tech Stack

| Layer          | Technology                        | Notes                                                                 |
|----------------|-----------------------------------|-----------------------------------------------------------------------|
| Skill format   | Markdown with YAML frontmatter    | Canonical `src/skills/<name>/SKILL.md`; host projections are generated |
| Projection     | Bash 3.2 (`scripts/project-hosts.sh`) | Local-only fixed-token rendering with write and drift-check modes  |
| Setup          | Bash (`setup`) + PowerShell       | Exact-manifest Claude and Codex global installs; must stay feature-parity |
| Utilities      | Bash (`bin/spade-*`)             | Bash 3.2-safe bounded helpers for update checks, marker replacement, lifecycle diagnostics and migrations, handoff, and rendering. Setup stays dual-shell (`setup` + `setup.ps1`). |
| Guards         | Bash 3.2 + `jq` (`bin/spade-guard`) as Claude Code command hooks | Deterministic invariant checks on the Claude host only; Codex keeps prose-only enforcement. Source `src/hooks/hooks.json`, payload `hooks/`. |
| Issue tracking | Linear (via Linear MCP)           | Primary integration. Other trackers are supported but manual.         |
| Agents         | Claude Code and Codex             | Claude registers agent files; Codex uses generated persona references and isolated dispatch |
| Versioning     | Fragment markers (`<!-- SPADE-FRAMEWORK-START vX.Y.Z -->`) | Gates idempotent onboarding                                           |
| CI             | GitHub Actions (`.github/workflows/lint.yml`) | Runs 15 jobs including authoring/projection drift, lifecycle authority, and clean-install parity; Python 3.11 is stdlib-only lint support |

## External Toolchain Policy

Two toolchains live outside the "Markdown + shell" core and are permitted
**only** under the narrow conditions below. New toolchain additions
require a new Scope; this section should not be interpreted as a general
permit.

### Python is allowed for CI lint only — never at runtime

`scripts/lint/frontmatter.py` and any other `scripts/lint/*.py` use the
**Python 3.11 standard library only**. No `requirements.txt`, no `pip`,
no third-party packages. This is acceptable because:

- CI-only: Python never ships to a consumer repo or runs in an agent
  session — it executes inside GitHub Actions via
  `actions/setup-python@v5`.
- Stdlib-only: no supply-chain surface beyond Python itself and the
  pinned GitHub Action version.
- Bounded: confined to `scripts/lint/`. Any proposal to use Python
  outside this directory — including "just a small helper" in
  `bin/` or a skill — is a runtime dependency and forbidden by
  `ANTI-PATTERNS.md#dependency-anti-patterns`.

If a future lint genuinely needs a non-stdlib YAML parser or similar, the
correct response is to simplify the schema, not to add `requirements.txt`.

### Windows consumers need Git-Bash or WSL for `/spade-update` migration

`bin/spade-marker-replace` and `bin/spade-lifecycle` are bash.
There is no PowerShell twin.
Windows consumers who run `/spade-update` migrations must do so from **Git-Bash** or
**WSL**, not native PowerShell.

Rationale:

- Claude Code on Windows already assumes a POSIX-shell posture for most
  skills. Running `/spade-update` from Git-Bash or WSL is the same shell
  environment consumers already use.
- A PowerShell twin of `spade-marker-replace` would roughly double the
  helper's surface and require its own fixture tests to keep behaviour
  parity with the bash version — high maintenance cost, low incremental
  value for a tool that runs once per minor version bump.
- Dual-shell parity is still enforced for `setup` and `setup.ps1` —
  those run once per install and must remain cross-shell.
  `spade-marker-replace` is not a setup script; it is a migration helper
  called from a skill.

If Windows-native `/spade-update` becomes a real need, the fix is a
focused Scope that ships `bin/spade-marker-replace.ps1` with its own
fixture tests, not an ad-hoc PowerShell rewrite.

### Pandoc is a recommended consumer binary for HTML rendering (v1.6+)

`bin/spade-render` wraps a `pandoc` invocation to produce sibling
`<scope>.html` and `<plan>.html` files for cmd-click reading. Pandoc
sits in the same dependency category as `git` or `jq` — a system tool
the consumer has or installs (`brew install pandoc` /
`apt install pandoc` / `winget install pandoc`). When pandoc is
absent, `spade-render` exits 2 and the calling skill surfaces a
one-line install hint on every write until pandoc is installed; the
underlying `.md` is the canonical artefact and is always written.
This is a recommended optional dep, not a runtime — no npm, no Node,
no vendored bundle. See `docs/FRAMEWORK.md` §HTML Rendering for the
full contract.

### Codex uses host-native isolation for read-only research

The Codex projection invokes the already-running host's `codex exec` command
with `--sandbox read-only --ignore-user-config --ephemeral` when
`/spade-research` needs an isolated researcher.
This is not a SPADE runtime or bundled dependency.
It is the Codex equivalent of Claude registering a read-only agent definition.

Release fixtures must prove that a write is denied, user MCP/connectors are
not loaded, and built-in web research remains available.
If that host contract is unavailable, the Codex researcher capability fails
closed rather than falling back to a prompt-only restriction.

## Security Requirements

- **No secrets in the repo.** Skills, examples, and fragments are public.
- **No arbitrary code execution from remote sources** during `setup` or
  lifecycle operations beyond bounded helpers fetched from the exact canonical
  remote and approved by immutable commit SHA.
- **Migration manifests are data, not executable shell.** The lifecycle helper
  accepts only fixed actions and exact consumer-relative paths, stages and
  verifies each unit, and writes the consumer version pin last.
- **Rendered Markdown is untrusted input.** Raw HTML, unsafe URL schemes,
  fetchable images, and Markdown-supplied attributes must be neutralised before
  the standalone CSP-protected document is written.
- **Linear MCP permissions** must be declared in `.claude/settings.local.json`
  per consumer project; the framework does not auto-grant.
- **Setup scripts must be safe to re-run.** Idempotency is a security property
  here: non-idempotent onboarding can duplicate configuration and hide
  malicious insertions on re-run.

## API Conventions

- **Skill invocation:** slash-commands (`/spade-scope`, `/spade-plan`, etc.).
- **Skill frontmatter** (YAML) is the contract between the framework and the
  agent runtime. All skills carry at minimum `name` and `description`; richer
  fields (e.g. `phase`, `requires_mcp`, `min_spade_version`) may be added.
- **Linear labels** form a stable taxonomy. Full-loop: `ai-planned`,
  `ai-delivered`, `human-delivery`, `plan-rejected`, `needs-arch-review`.
  Fast-track: `spade:quick`, `type:bug|tweak|chore|docs|refactor`. Bundle
  grouping is **not** a label — it lives in the Plan's Delivery Bundles
  section and the parent→sub-issue hierarchy (see
  `.claude/skills/spade-plan/SKILL.md`).
- **Fragment markers** (`<!-- SPADE-FRAMEWORK-START vX.Y.Z -->` …
  `<!-- SPADE-FRAMEWORK-END -->`) delimit framework-owned regions inside
  consumer `AGENTS.md` / `CLAUDE.md`. Only content between these markers may
  be rewritten by `/spade-onboard` or `/spade-update`.

## Testing Requirements

- **No service unit tests** are expected because there is no service runtime.
- **Bounded helper tests** are required for lifecycle transactions, diagnostics,
  renderer safety, handoff command constraints, and other executable behavior.
- **Framework validation tests** cover: (a) canonical skill frontmatter parses
  and carries required fields; (b) example Scopes and Plans in `examples/`
  conform to the documented schema; (c) fragments insert idempotently into
  consumer `AGENTS.md` / `CLAUDE.md`; (d) setup scripts succeed on a clean
  `$HOME`; (e) bash and PowerShell setup produce the same installed file set.
- **CI** runs the above on every PR via `.github/workflows/lint.yml` with
  15 jobs: canonical skill frontmatter, agents, skill authoring/projections,
  clean installs, examples, fragments, learnings, onboard idempotency, handoff,
  trusted lifecycle, render CSS budget, render smoke, MCP guard, local frontmatter,
  and mechanical guards.
  Shipped in Bundle C (v1.1); extended by the agents lint in Bundle E;
  render-css-budget and render-security added in v1.6.
- **Consumer projects** are responsible for their own test suites — SPADE does
  not mandate a testing approach, only that Plans describe one.
