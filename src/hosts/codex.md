# Codex Host Adapter

This adapter maps the fixed host-operation tokens used by canonical skills.
It contains no workflow behavior.

| Token | Projection text |
|---|---|
| `SPADE_ASK_USER` | request_user_input when available, otherwise a concise direct question |
| `SPADE_SHELL` | exec_command |
| `SPADE_ISOLATED_AGENT` | spawn_agent with a self-contained prompt and no inherited conversation |
| `SPADE_READ_ONLY_RESEARCH` | codex exec --sandbox read-only --ignore-user-config --ephemeral with the canonical researcher prompt |

Codex projections publish canonical persona and researcher definitions as references inside the owning skills.
The orchestrating skill loads the selected reference completely and sends it in the isolated prompt.

The read-only researcher path must pass three checks before release:

1. A filesystem write attempt is denied and creates no file.
2. User-configured MCP servers and connectors are unavailable.
3. Built-in web search remains available.

## Agent metadata

| Token | Projection text |
|---|---|
| `SPADE_AGENT_MODEL` | host-default |
| `SPADE_REVIEW_TOOLS` | read-only sandbox and repository read tools |
| `SPADE_RESEARCH_TOOLS` | read-only sandbox, built-in web search, and repository read tools |
