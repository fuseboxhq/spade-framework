# SPADE Skill Authoring Standard

This document is the contributor contract for every SPADE skill and agent.
The only human-editable behavior sources live under `src/`.
All `.claude/`, `.codex/`, top-level `skills/`, top-level `agents/`, and plugin payload files are generated projections.

## Invocation contract

Every `SKILL.md` frontmatter description states what the workflow does and the user language that should invoke it.
Descriptions identify the outcome and routing boundary, not implementation history.
Host-specific invocation mechanics use only the tokens declared under `src/hosts/`.

## Ordered steps and completion

Every workflow is an ordered sequence with observable completion criteria.
A terminating step is complete only when it names at least one of:

- an artefact that exists at a specified location;
- a tracker or repository state transition that can be read back;
- a command and its expected successful result;
- evidence whose required fields are enumerated;
- an explicit halt or refusal record that has been persisted.

An instruction such as "finish the update" or "make sure it worked" is a no-op because it provides no observable predicate.
Every shell function added by SPADE carries a contract comment naming its arguments, outputs, side effects, exit codes, and path-safety assumptions.

## Progressive disclosure

The always-loaded `SKILL.md` contains routing, invariants, safety gates, and completion rules.
Branch-specific procedures, worked examples, migration narratives, and historical explanation live in `references/`.
Every reference has a single explicit trigger in `SKILL.md` and is read completely when that trigger fires.
References never redefine a normative rule that remains in the always-loaded body.

The initial always-loaded budget is 32 KiB.
The five PS-2321 baseline skills must also be at least 25 percent smaller than their immutable `9c74a75` byte baseline:

| Skill | Baseline bytes | Maximum after 25 percent reduction |
|---|---:|---:|
| `spade-review` | 52,427 | 39,320 |
| `spade-onboard` | 21,545 | 16,158 |
| `spade-plan` | 22,675 | 17,006 |
| `spade-update` | 20,170 | 15,127 |
| `spade-scope` | 21,959 | 16,469 |

The 32 KiB ceiling wins when it is lower.
An exception must be declared in `src/CAPABILITIES.md`, justified in a reviewed Scope, and tested.

## Objective failure definitions

- Duplication: a normative behavior is authored in more than one canonical location instead of referenced.
- No-op: an action step lacks an observable artefact, state transition, command result, evidence predicate, or durable halt.
- Sediment: superseded history, worked examples, migration narratives, or branch-specific material remains always loaded without a live routing need.
- Sprawl: an always-loaded body exceeds its declared budget or a reference has no explicit trigger.
- Semantic drift: a host adapter adds behavior, changes a gate, widens tools or permissions, or produces a projection that differs from deterministic regeneration.

## Host adapters

Adapters translate only fixed host operations: user decisions, shell execution, isolated persona dispatch, and read-only researcher dispatch.
They may not add workflow commands, change approval or evaluation ownership, widen MCP permissions, or carry full skill bodies.
An unknown or unresolved token is a hard generation failure.

Claude uses registered agent definitions with declared tool allowlists.
Codex uses isolated subagents and the host-native read-only researcher invocation documented in `src/hosts/codex.md`.

## Behavioral fixtures

The critical set is:

- `spade`
- `spade-scope`
- `spade-plan`
- `spade-approve`
- `spade-review`
- `spade-quick`
- `spade-onboard`
- `spade-update`
- `spade-evaluate`

The applicability matrix in `tests/skill-authoring-corpus.md` maps each critical skill to premature completion, skipped human gate, silent no-op, missing halt persistence, and weakened refusal behavior.
Every applicable cell has a rejected negative case and a passing positive control.
Every non-applicable cell carries a reason.

## Contributor workflow

1. Edit only `src/`, canonical documentation, fixtures, or projection tooling.
2. Run `./scripts/project-hosts.sh` to regenerate every host payload.
3. Run `./scripts/project-hosts.sh --check` to prove the committed projections are current.
4. Run `./scripts/lint/run-all.sh` before opening a pull request.
5. Review canonical and adapter diffs first; generated diffs are evidence of the projection, not a second review surface.

Completion means regeneration is idempotent, check mode is clean, the full lint suite passes, and a second regeneration leaves `git status` unchanged.
