---
version: 5.1.0
canonical_remote: https://github.com/fuseboxhq/spade-framework.git
release_ref_policy: commit
minimum_supported_version: 1.0.0
published_versions: 1.0.0,1.1.0,1.1.1,1.2.0,1.3.0,1.6.0,1.6.1,1.7.0,1.8.0,1.9.0,1.10.0,1.11.0,1.12.0,1.13.0,1.14.0,1.14.1,2.0.0,2.0.1,2.1.0,3.0.0,3.1.0,3.2.0,3.2.1,3.3.0,3.4.0,3.5.0,3.6.0,3.7.0,4.0.0,5.0.0,5.0.1,5.1.0
skills: leads,spade,spade-approve,spade-evaluate,spade-frontier,spade-handoff,spade-intent,spade-learn,spade-list,spade-onboard,spade-plan,spade-quick,spade-research,spade-review,spade-scope,spade-status,spade-unhinged,spade-update,unslop
review_personas: spade-review-adversarial-reviewer,spade-review-alternatives-analyst,spade-review-architecture-strategist,spade-review-delivery-semantics,spade-review-migration-reversibility,spade-review-operability,spade-review-scope-guardian,spade-review-security-lens
researcher: spade-researcher
helpers: spade-guard,spade-handoff-launch,spade-lifecycle,spade-marker-replace,spade-render,spade-update-check
critical_skills: spade,spade-frontier,spade-scope,spade-plan,spade-approve,spade-review,spade-quick,spade-onboard,spade-update,spade-evaluate,spade-unhinged
large_skills: spade-review,spade-onboard,spade-plan,spade-update,spade-scope
always_loaded_budget_bytes: 32768
---

# SPADE Capability Manifest

This file is the canonical inventory for generated payloads, install manifests, documentation claims, and CI counts.
The frontmatter is deliberately flat so the existing standard-library parser and bounded shell tooling can read it without a YAML dependency.

## Supported host matrix

| Host | Plugin payload | Global install | Persona delivery | Researcher delivery |
|---|---|---|---|---|
| Claude | `.claude-plugin/` plus top-level `skills/`, `agents/`, `hooks/`, and `scripts/` | `~/.claude/skills`, `~/.claude/agents`, and `~/.spade/bin` | Registered agent definitions with tool allowlists | Registered read-only researcher agent |
| Codex | `.codex-plugin/plugin.json` plus `.codex/skills/` | `~/.codex/skills` and `~/.spade/bin` | Isolated subagents loaded from generated persona references | Ephemeral `codex exec` with enforced read-only sandbox and user MCP/config disabled |

All four paths expose the same nineteen skills, eight reviewer personas, one researcher, and six helpers.
Parity is capability-level for skills, personas, and the researcher: host registration metadata may differ, but the behavior source, gates, and expected outcomes do not.
Mechanical guards are the one asymmetry.
The Claude plugin payload ships `hooks/hooks.json` and the `spade-guard` helper as command hooks; the global Claude install ships the helper without registering hooks; Codex has no hook surface and keeps prose-only enforcement with the previous approval model (`docs/FRAMEWORK.md` § Mechanical guards).

## Immutable large-skill baselines

The baseline revision is `9c74a7500eb434cec23a3842a33558b256769f31`.

| Skill | Bytes |
|---|---:|
| `spade-review` | 52,427 |
| `spade-onboard` | 21,545 |
| `spade-plan` | 22,675 |
| `spade-update` | 20,170 |
| `spade-scope` | 21,959 |

No context-budget exceptions are approved.
