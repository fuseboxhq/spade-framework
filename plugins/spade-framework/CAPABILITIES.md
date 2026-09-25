---
version: 6.0.1
canonical_remote: https://github.com/fuseboxhq/spade-framework.git
release_ref_policy: commit
minimum_supported_version: 1.0.0
published_versions: 1.0.0,1.1.0,1.1.1,1.2.0,1.3.0,1.6.0,1.6.1,1.7.0,1.8.0,1.9.0,1.10.0,1.11.0,1.12.0,1.13.0,1.14.0,1.14.1,2.0.0,2.0.1,2.1.0,3.0.0,3.1.0,3.2.0,3.2.1,3.3.0,3.4.0,3.5.0,3.6.0,3.7.0,4.0.0,5.0.0,5.0.1,5.1.0,6.0.0,6.0.1
skills: leads,spade,spade-evaluate,spade-learn,spade-onboard,spade-plan,spade-quick,spade-research,spade-review,spade-scope,spade-status,spade-update,unslop
review_personas: spade-reviewer
researcher: spade-researcher
helpers: spade-guard,spade-lifecycle,spade-marker-replace,spade-render,spade-update-check
skill_budget_bytes: 12288
fragment_budget_bytes: 3072
---

# SPADE Capability Manifest

This file is the canonical inventory for generated payloads, install manifests, documentation claims, and CI counts.
The frontmatter is deliberately flat so the existing standard-library parser and bounded shell tooling can read it without a YAML dependency.

## Supported host matrix

| Host | Plugin payload | Global install | Persona delivery | Researcher delivery |
|---|---|---|---|---|
| Claude | `.claude-plugin/` plus top-level `skills/`, `agents/`, `hooks/`, and `scripts/` | `~/.claude/skills`, `~/.claude/agents`, and `~/.spade/bin` | Registered agent definitions with tool allowlists | Registered read-only researcher agent |
| Codex | `.codex-plugin/plugin.json` plus `.codex/skills/` | `~/.codex/skills` and `~/.spade/bin` | Isolated subagents loaded from generated persona references | Ephemeral `codex exec` with enforced read-only sandbox and user MCP/config disabled |

All four paths expose the same thirteen skills, one reviewer agent, one researcher, and five helpers.
Parity is capability-level for skills, personas, and the researcher: host registration metadata may differ, but the behavior source, gates, and expected outcomes do not.
Mechanical guards are the one asymmetry.
The Claude plugin payload ships `hooks/hooks.json` and the `spade-guard` helper as command hooks; the global Claude install ships the helper without registering hooks; Codex has no hook surface and keeps prose-only enforcement with the previous approval model (`references/FRAMEWORK.md` § Mechanical guards).

## Context budgets

Every canonical `SKILL.md` stays at or under `skill_budget_bytes`, and each consumer fragment under `fragments/` stays at or under `fragment_budget_bytes`.
`scripts/lint/lint-skill-authoring.sh` enforces both.
There are no exceptions; a skill that needs more splits detail into a routed `references/` file.
