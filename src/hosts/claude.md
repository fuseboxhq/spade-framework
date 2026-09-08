# Claude Host Adapter

This adapter maps the fixed host-operation tokens used by canonical skills.
It contains no workflow behavior.

| Token | Projection text |
|---|---|
| `SPADE_ASK_USER` | AskUserQuestion |
| `SPADE_SHELL` | Bash |
| `SPADE_ISOLATED_AGENT` | Task |
| `SPADE_READ_ONLY_RESEARCH` | registered spade-researcher agent with the declared read-only tool allowlist |

Claude plugin and global projections also publish every canonical agent under `agents/` or `~/.claude/agents/`.

## Agent metadata

| Token | Projection text |
|---|---|
| `SPADE_AGENT_MODEL` | opus |
| `SPADE_REVIEW_TOOLS` | Read, Grep, Glob |
| `SPADE_RESEARCH_TOOLS` | Read, Grep, Glob, WebSearch, WebFetch |
