# SPADES Framework

**A human-AI operating model for engineering teams.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-5.1.0-green.svg)](setup)
[![Claude Code](https://img.shields.io/badge/Claude_Code-compatible-blueviolet.svg)](https://claude.ai/code)

SPADES defines clear boundaries between what humans own and what AI handles,
creating a loop that is fast, auditable, and safe.

```
SCOPE ──► PLAN ──► APPROVE ──► DELIVER ──► EVALUATE ──► SHIP
 (H)       (AI)      (H*)       (AI/H)       (H*)       (H)
```

**Humans own the edges** (deciding what to build, and shipping it).
**AI owns the middle** (planning the approach and executing the work).

`*` Approve and Evaluate are human gates on the Plan and Scope autonomy levels.
On the Deliver level Approve is machine-attributed and Evaluate is agent-recorded
when every criterion is machine-verifiable; anything external or human-only hands
the verdict back. Whoever records a PASS closes the issue.

---

## Quick Start

Two steps to get SPADES working:

```bash
# 1. Install SPADES globally (one-time)
git clone https://github.com/fuseboxhq/spade-framework.git ~/.spade
~/.spade/setup

# 2. In any project, open Claude Code or Codex and run:
/spade-onboard
```

That's it. The onboard skill creates all the framework files in your project,
analyses your codebase, and helps you fill in architecture docs. Commit the
generated files and your team has SPADES automatically.

---

## The Problem

Without a framework, teams fall into one of two failure modes:

1. **Too manual.** AI is used as fancy autocomplete. Humans do all the planning,
   structuring, and project management. Slow, no leverage.

2. **Too unsupervised.** AI is given open-ended goals with no review gates.
   Output may be technically functional but architecturally wrong, insecure,
   or solving the wrong problem. Confidently wrong slop.

SPADES prevents both by enforcing human gates at the right points in the loop.

---

## Prerequisites

- **Claude Code or Codex** - both hosts expose the full SPADE skill, persona,
  researcher, and helper capability manifest.
- **A project tracker** (recommended: [Linear](https://linear.app)) — SPADES
  uses parent issues as Scopes and sub-issues as Plan tasks. Any tracker works,
  but Linear integration via MCP is fully automated.
- **Git** — SPADES files are designed to be committed to your repo so the whole
  team gets them automatically.

Optional:
- **Linear MCP** — enables Claude Code to read/write issues, create sub-tasks,
  and update statuses automatically. Without it, you manage issues manually.

---

## Installation

### Step 1: Install SPADES (one-time)

You can use a host plugin or the exact global projections produced by setup.

#### Option A — Claude Code plugin (recommended)

SPADES is published as a Claude Code plugin out of this repo. One-time setup:

```text
/plugin marketplace add fuseboxhq/spade-framework
/plugin install spade@spade-framework
```

Updates: `/plugin marketplace update && /plugin update spade@spade-framework`.

For HTML rendering (`spade-render`) and update-check banners to work, also
clone the repo to `~/.spade` (or symlink the plugin's `scripts/` directory
into `~/.spade/bin/` — see `.claude-plugin/README.md` if present, or below).

#### Option A2 - Codex plugin

The repository carries a generated Codex marketplace and plugin projection.
After cloning to `~/.spade`, install that explicit local marketplace and plugin:

```bash
codex plugin marketplace add ~/.spade
codex plugin add spade-framework@spade-framework
```

After `git pull`, rerun `codex plugin add spade-framework@spade-framework`
and start a new task so Codex picks up the refreshed skills.

#### Option B — Clone + setup script

Clone the framework and run setup.
The default installs exact Claude and Codex global projections.
Use `--host claude`, `--host codex`, or `--host all` to select a target.

**macOS / Linux / WSL:**

```bash
git clone https://github.com/fuseboxhq/spade-framework.git ~/.spade
~/.spade/setup
# Or: ~/.spade/setup --host codex
```

**Windows (PowerShell):**

```powershell
git clone https://github.com/fuseboxhq/spade-framework.git $HOME\.spade
& $HOME\.spade\setup.ps1 -HostTarget all
```

That's the only setup step. Skills are now available globally.

### Step 2: Onboard a project

Open Claude Code or Codex in any project and run:

```
/spade-onboard
```

This does two things:

1. **Creates framework files** — `AGENTS.md`, `CLAUDE.md`, architecture
   templates (`ARCHITECTURE.md`, `PATTERNS.md`, `ANTI-PATTERNS.md`), example
   files, and `.spade/` metadata. If any of these already exist, they are
   left untouched or augmented (not overwritten).

2. **Analyses your codebase** — explores your project structure, dependencies,
   patterns, and infrastructure, then helps you fill in the architecture docs
   with real content specific to your project.

Once onboarding is done, commit the generated files:

```bash
git add AGENTS.md CLAUDE.md ARCHITECTURE.md PATTERNS.md ANTI-PATTERNS.md .claude/ .spade/
git commit -m "Onboard project with SPADES framework"
```

Teammates who clone the repo will have SPADES working immediately — they just
need the global skills install (Step 1).

### Upgrading

```bash
# macOS / Linux / WSL
cd ~/.spade && git pull && ~/.spade/setup
```

```powershell
# Windows (PowerShell)
cd $HOME\.spade; git pull; & $HOME\.spade\setup.ps1
```

This updates the global skills. To update SPADES files in a specific project,
run `/spade-onboard` again — it will update framework sections while
preserving your project-specific content.

---

## Using SPADES

Once installed and onboarded:

1. Write a Scope in Linear (parent issue with acceptance criteria)
2. Run `/spade-plan` and point it at the issue
3. Review the Plan with `/spade-approve`
4. Let delivery run (AI handles code, you handle the rest)
5. Verify output with `/spade-evaluate`
6. Ship the verified work (merge, deploy, hand off)
7. Check progress any time with `/spade-status`

### Available Skills

| Skill | What it does |
|-------|-------------|
| `/spade` | Orchestrator entry point: Deliver, Plan, Scope, or Stub; safely resumes incomplete runs after live state validation |
| `/spade-frontier` | Govern major-work discovery one question at a time, then graduate through human-owned Scope authoring |
| `/spade-onboard` | Initialise SPADES in a project and fill in architecture docs |
| `/spade-intent` | Create or maintain the project's durable human-owned statement of intent |
| `/spade-scope` | Create or edit a well-formed Scope (enforces 10 required fields) |
| `/spade-list` | List active Scopes from Linear, filtered by SPADES phase |
| `/spade-plan` | Generate a structured Plan from a Scope; each task is one strict card (What / Done when / How / Verify / Needs / Blocks / Who); surfaces matching prior learnings |
| `/spade-approve` | Present a Plan for human review against the approval checklist |
| `/spade-handoff` | Hand an approved Plan to a fresh CLI agent (Claude Code or Amp) in a new macOS terminal window to deliver it; opt-in, macOS-only |
| `/spade-review` | Dynamic-cast Scope and Plan review, plus fixed-range Delivery Review on independent Scope and engineering-standard axes |
| `/spade-quick` | Fast-track path for trivial work (typos, tweaks, small config / docs changes) |
| `/spade-unhinged` | Run one explicitly confirmed throwaway experiment under a continuous protected-path gate; retained work gets a non-shipping Draft PR audit |
| `/spade-research` | Landscape research via an isolated Opus 4.7 subagent (read-only tools); returns a structured findings report; optional Linear comment with explicit consent (v1.3.0+) |
| `/spade-learn` | Capture human-authored or evidence-backed candidate learnings under `.spade/learnings/` or `private/`; `--refresh` updates or supersedes with approval |
| `/leads` | Capture out-of-scope discoveries with one fixed classification, even when tracker labels fail; list, show, promote, or close them later |
| `/unslop` | Cut AI tells from any writing and add human voice; SPADE applies it to every human-facing output |
| `/spade-evaluate` | Record criterion evidence, recommend a human-owned verdict, and surface high-signal learning candidates |
| `/spade-status` | Show current phase, progress, and unvalidated continuity state for active work |
| `/spade-update` | Check for and install SPADES framework updates; handles v1.0.0 → v1.1.0 consumer fragment migration |

`/spade-unhinged` is intentionally absent from the `/spade` autonomy picker.
It is only for one explicitly confirmed, non-shipping experiment whose complete
current and proposed path set remains outside the fail-closed protected surface.
It creates no Scope, Plan, approval, tracker, run-state, or learning artefact.
An `[unhinged]` Draft PR is experiment evidence only and must be closed before
unchanged work re-enters `/spade-quick` or the full loop for possible landing.

---

## How It Works

### Scope (Human)

The engineer defines what needs to be achieved and why. A good Scope includes
acceptance criteria, architectural constraints, and upstream/downstream context.
Scopes originate from OKRs, milestones, or reactive work (tickets, incidents).

### Plan (AI)

The AI agent produces a structured plan: 3-7 discrete tasks, each rendered as one strict card - What / Done when / How / Verify / Needs / Blocks / Who.
Every card names the observable result the task makes real, where it is verified, its dependencies in both directions, and the delivery approach it opens with.
Plans default to vertical slices; an intentionally preparatory task marks itself as groundwork and names the vertical task it enables.
The Plan is documented on the parent issue as a first-class artefact.

### Approve (Human)

The engineer reviews the Plan against reality: architecture alignment,
completeness, feasibility, risk, and scope. This is a gate, not a rubber stamp.
Rejected plans go back with specific feedback.

### Deliver (AI or Human)

Tasks get executed. AI handles code, pipelines, configuration, documentation.
Humans handle stakeholder conversations, hardware testing, vendor negotiations,
and anything requiring organisational context.
Delivery records one immutable base and final head for project-native checks and two independent review axes: Scope conformance and repository engineering standards.
Any later commit invalidates head-bound evidence and requires a fresh review.

### Evaluate (Agent-Recorded When Fully Verifiable)

The agent records every criterion as diff-verifiable, runtime-verifiable, external-state, or human-only, with fresh evidence where the class permits it.
UI evidence is conditional on UI criteria, while external and human-only criteria remain explicitly open until verified.
The agent records PASS, PARTIAL, or FAIL when every criterion is machine-verifiable and closes the issue on a PASS; anything external or human-only hands the verdict back, and the human owns Ship.

### Ship (Human-Owned)

The verified work is released — merged to main, deployed, or otherwise
handed off to its destination. Shipping is the moment value reaches users;
SPADES treats it as an explicit final step rather than an implicit
afterthought, so the loop closes on delivered value rather than on
acceptance alone.
Shipping remains human-owned, but after completing Evaluate, reviewing the PR, and confirming required repository checks pass, the human may explicitly ask an AI agent to merge it.
This merge permission does not authorize deployment or handoff actions that were not separately requested.

---

## Project Structure

After onboarding, your project will contain:

```
your-project/
├── AGENTS.md              # Mandatory agent behaviour (the enforcement layer)
├── CLAUDE.md              # Claude Code project configuration
├── ARCHITECTURE.md        # Your system architecture and constraints
├── PATTERNS.md            # Approved patterns and conventions
├── ANTI-PATTERNS.md       # Things not to do
├── .claude/
│   └── skills/            # (empty — skills are installed globally)
└── .spade/
    ├── version            # Install metadata
    ├── plans/             # Approved SPADES plans (generated by /spade-plan)
    │   └── M-68-plan.md
    ├── docs/              # Framework reference documentation
    │   └── FRAMEWORK.md
    └── examples/          # Example Scope and Plan
        ├── example-scope.md
        └── example-plan.md
```

---

## Compatibility

SPADES is a pattern, not a product integration. The framework works with any
project tracker and any AI agent that can read structured context.

### AI Agents

| Agent | Support Level | Notes |
|-------|--------------|-------|
| **Claude Code** | Full | Native skills, Linear MCP, automated workflow |
| **Cursor** | Partial | Reads AGENTS.md for rules, no skill support |
| **GitHub Copilot** | Partial | Reads AGENTS.md for rules, no skill support |
| **Codex** | Full | Native plugin and global skills, isolated persona dispatch, sandboxed researcher |
| **Any MCP-compatible agent** | Varies | Can slot into the Deliver phase |

The key insight: AGENTS.md works as a universal enforcement layer. Any AI agent
that reads project context files will follow SPADES rules. The skills add
convenience but are not required for the pattern to work.

### Project Trackers

| Tracker | Support Level | Notes |
|---------|--------------|-------|
| **Linear** | Full | Automated via MCP (issue creation, status updates, labels) |
| **GitHub Issues** | Manual | Use the SPADES loop manually; issues as Scopes |
| **Jira** | Manual | Use the SPADES loop manually; tickets as Scopes |
| **Any tracker** | Manual | The pattern holds regardless of tooling |

---

## FAQ

**How do I add SPADES to a new project?**
Run `/spade-onboard` in Claude Code. It creates all the files and walks you
through filling in the architecture docs.

**What if I already have an AGENTS.md?**
The onboard skill appends its section between marker comments. Your existing
content is untouched.

**What if I already have ARCHITECTURE.md?**
It will not be overwritten. The onboard skill skips files that already exist
and moves straight to helping you fill in content.

**Can I use SPADES without Linear?**
Yes. Linear integration is optional. Without it, you manage Scopes and Plans
manually (in any tracker or even in markdown files). The SPADES loop is the
same regardless of tooling.

**Can I use SPADES without Claude Code?**
Yes, partially. AGENTS.md works with any AI agent that reads project context.
You lose the `/spade-*` skills but keep the enforcement rules and the workflow
pattern.

**How do I scale ceremony for small tasks?**
The loop compresses. For a bug fix, the ticket is the Scope, planning is a
quick comment, approval is a fast check. The structure exists but the ceremony
is light. See `docs/FRAMEWORK.md` for details.

**Do teammates need to install SPADES too?**
They need the global skills install (Step 1). The project files created by
`/spade-onboard` should be committed to the repo so they're available
automatically.

---

## Principles

1. **Humans own the edges.** AI never decides what to build. AI output is never
   shipped without human verification.
2. **Plans are artefacts, not ephemeral.** Every plan is documented and attached
   to the work item.
3. **Approval is a gate, not a rubber stamp.** If you approve every plan in
   30 seconds, the gate is not working.
4. **Delivery mode is explicit.** Every task is labelled AI-delivered or
   human-delivered.
5. **Feedback loops are first-class.** Rejected plans and failed evaluations
   go back into the loop with specific feedback.
6. **Architecture constraints are codified, not memorised.** Maintain living
   documents that AI reads during planning.
7. **Scope determines approval depth.** Strategic decisions get deep review.
   Granular tasks get light review.

---

## Contributing

Contributions are welcome. If you have ideas for improving the framework:

1. Fork the repo
2. Create a branch for your change
3. Submit a pull request with a clear description of the improvement

For bugs in the setup script, please include your OS and shell version.

### Development

Run the framework's own lint suite before pushing a PR:

```bash
./scripts/lint/run-all.sh
```

See `scripts/lint/README.md` for what each check does. The same lints run in CI on every PR (`.github/workflows/lint.yml`).

---

## Licence

MIT. Use it, fork it, make it yours.

---

*The SPADES Framework - Fusebox HQ, April 2026*
