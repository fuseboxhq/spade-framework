# SPADE Framework

**A human-AI operating model for engineering teams.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-6.0.1-green.svg)](setup)
[![Claude Code](https://img.shields.io/badge/Claude_Code-compatible-blueviolet.svg)](https://claude.ai/code)

```
SCOPE -> PLAN -> APPROVE -> DELIVER -> EVALUATE -> SHIP
 human    AI     human*      AI         AI*        human
```

Humans decide what to build and whether it ships.
Agents plan, build, review, and verify in between, against acceptance criteria the human wrote.

`*` At the Deliver level with guards live, approval is machine-recorded and the agent records the Evaluate verdict when every criterion has fresh evidence; otherwise both go to the human.

## Why

Current models do their best work when you tell them what done looks like, when to stop and ask, and then let them run.
They do their worst when nobody decided what to build, the finish line is vague, or they check their own work.
SPADE makes the finish line explicit (the Scope), keeps the stops few and meaningful (tripwires), keeps review independent of the agent that did the work, and leaves a trail from Scope to merged PR.

## Quick start

```bash
git clone https://github.com/fuseboxhq/spade-framework.git ~/.spade
~/.spade/setup                  # Claude and Codex; --host claude|codex to pick one
```

Then, in any project, run `/spade-onboard`, and start work with `/spade`.

### Other installs

- **Claude Code plugin:** `/plugin marketplace add fuseboxhq/spade-framework`, then `/plugin install spade@spade-framework`. Clone to `~/.spade` as well if you want update banners and HTML rendering.
- **Codex plugin:** after cloning to `~/.spade`, run `codex plugin marketplace add ~/.spade` and `codex plugin add spade-framework@spade-framework`.
- **Windows:** clone to `$HOME\.spade` and run `& $HOME\.spade\setup.ps1 -HostTarget all`.

To upgrade, run `/spade-update`, or pull `~/.spade` and rerun setup.

## Using it

- `/spade <what you want>` takes the work as far as the autonomy level allows: Deliver (to a reviewed, evaluated PR), Plan (to an approved Plan), Scope, or Stub. Small changes go to `/spade-quick` automatically.
- Ask for a small change directly and it goes through `/spade-quick`: one commit, tests, a PR.
- Questions, debugging, and spikes need no Scope.
- `/spade-status` shows what is in flight and what is waiting on you.

### Skills

| Skill | What it does |
|---|---|
| `/spade` | Entry point: runs the loop to the chosen level and resumes work in flight |
| `/spade-scope` | Draft a Scope from your brief and lock it with one confirm |
| `/spade-plan` | Write a short Plan (approach, rejected forks, risks, checkbox tasks) and take it to approval |
| `/spade-review` | Independent review that reports only merge-blocking problems, with lens reviewers when the change carries the risk |
| `/spade-evaluate` | One evidence row per acceptance criterion and a PASS, PARTIAL, or FAIL verdict |
| `/spade-quick` | Small, low-risk changes with the PR as the audit record |
| `/spade-status` | Active Scopes by phase, or one Scope's progress and blockers |
| `/spade-learn` | Record a repository gotcha future Plans should know |
| `/spade-research` | Read-only research with citations and a list of what could not be confirmed |
| `/spade-onboard` | Set up a repository: config, fragments, gotchas-first architecture docs, INTENT.md, and a verification skill |
| `/spade-update` | Update the install from an approved commit and migrate consumer repositories |
| `/leads` | Capture out-of-scope discoveries as tracked Leads without derailing the work |
| `/unslop` | Strip AI tells from prose; SPADE applies it to everything a person reads |

## What onboarding adds to a repository

```
your-project/
├── AGENTS.md          # a short SPADE section between markers, loaded every session
├── CLAUDE.md          # points Claude at AGENTS.md
├── ARCHITECTURE.md    # boundaries and decisions the code cannot show
├── PATTERNS.md        # conventions a contributor could miss
├── ANTI-PATTERNS.md   # rejected approaches and recurring mistakes
├── INTENT.md          # the human-owned statement of what the project is for
├── .claude/skills/verify/ and .agents/skills/verify/   # how to verify a change end to end
└── .spade/
    ├── config         # tracker mode, autonomy level, merge policy, guards
    ├── version
    ├── scopes/        # Scopes in local mode
    ├── plans/         # Plans, ticked off as delivery runs
    └── learnings/
```

## Trackers and agents

Linear is supported through its MCP server: Scopes are parent issues whose status follows the loop.
Without Linear, `mode: local` keeps everything under `.spade/`.
Claude Code and Codex both get every skill; Claude Code also gets the mechanical guards (command hooks that enforce protected paths and the merge policy).
Any agent that reads AGENTS.md gets the rules.

## Principles

1. Humans own intent and Ship. AI never decides what to build.
2. The acceptance criteria are the finish line, and every one is checkable.
3. Agents keep going until a real decision needs a human, and write every halt down.
4. Review and evaluation are independent of the agent that did the work.
5. Rules that need no judgement are enforced by guards, not prose.
6. Say it once: the framework reference is `docs/FRAMEWORK.md`, and every skill ships a copy.

## Contributing

Edit `src/`, run `./scripts/project-hosts.sh`, then `./scripts/lint/run-all.sh`, and run the affected evals in `tests/evals/`.
`docs/SKILL-AUTHORING.md` covers how skills are written, and AGENTS.md lists the repository's gotchas.

## Licence

MIT.
