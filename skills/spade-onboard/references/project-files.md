# Project File Provisioning

Read this reference completely when Step 0 begins. It owns project-file creation, config prompts, local layout, examples, docs, and the provisioning report.
## Step 0: Initialise SPADE Project Files

Once the self-onboard guard has passed, initialise or update framework files
using the **marker-replace contract** implemented by
`~/.spade/bin/spade-marker-replace`:

Read the installed version from `~/.spade/CAPABILITIES.md`, falling back to
`~/.spade/src/CAPABILITIES.md` in a source clone.
Use that exact value for every marker and version pin below.

```bash
spade-marker-replace TARGET_FILE FRAGMENT_FILE VERSION
```

The contract is deterministic and idempotent:

| Target state                                      | Outcome                                                                 |
|---------------------------------------------------|-------------------------------------------------------------------------|
| Target file absent                                | Create with START (vVERSION) + fragment + END                           |
| Target exists, no markers                         | Append blank line, then START + fragment + END; preserve existing text  |
| Target has one matching `vX.Y.Z` marker pair      | Replace block in place, re-stamping START to `vVERSION`                 |
| Target has mismatched markers (START != END)      | Exit 2, no modification                                                 |
| Target has multiple START/END pairs               | Exit 3, no modification (human must resolve)                            |

Running twice with the same inputs produces an **unchanged file** on the
second run. This is the property onboarding relies on — re-running
`/spade-onboard` must not drift the consumer repo.

### AGENTS.md

Call the helper to insert or refresh the SPADE section:

```bash
~/.spade/bin/spade-marker-replace \
  "$PWD/AGENTS.md" \
  ~/.spade/fragments/AGENTS-section.md \
  "$SPADE_VERSION"
```

If the helper exits with code 2 (mismatched markers), stop and show the
human the error message. Do NOT try to "fix" the target file automatically
— malformed markers usually signal hand-editing the human should review.

If it exits with code 3 (duplicate markers), same behaviour — refuse, report,
ask the human to collapse the blocks by hand before re-running.

### CLAUDE.md

Same pattern, using the CLAUDE fragment:

```bash
~/.spade/bin/spade-marker-replace \
  "$PWD/CLAUDE.md" \
  ~/.spade/fragments/CLAUDE-section.md \
  "$SPADE_VERSION"
```

### Architecture Templates

For each of these files, create them **only if they don't exist**. Read the
template from `~/.spade/` and copy it:

- `ARCHITECTURE.md` (from `~/.spade/ARCHITECTURE.md`)
- `PATTERNS.md` (from `~/.spade/PATTERNS.md`)
- `ANTI-PATTERNS.md` (from `~/.spade/ANTI-PATTERNS.md`)

If any of these already exist, decide whether to prompt the human
deterministically by **detecting unfilled template markers**. The
framework templates use HTML comments of the shape
`<!-- Describe ... -->`, `<!-- List ... -->`, `<!-- Example: ... -->`,
or `<!-- Add ... -->` to mark sections the consumer is meant to
fill in. A real filled-in document has zero such markers (the comment
prompt has been replaced with project-specific prose).

**Detection mechanism:**

```bash
# Case-insensitive match for the four canonical template marker
# openings. Two or more matches in a single file = still a template.
grep -ciE '<!--[[:space:]]*(Describe|List|Example:|Add)[[:space:]]' "$f"
```

If the count is **≥ 2**, treat the file as still a template and
prompt the human via **`AskUserQuestion`** (per `docs/FRAMEWORK.md`
§ "Asking the Human") with options:

- *Overwrite with fresh template*
- *Merge — keep existing content, add missing sections*
- *Skip — leave as-is*

If the count is **0 or 1**, leave the file untouched — the consumer
already has real project-specific content and the prompt would be
noise. (The "1 match" tolerance covers a stray HTML comment in
otherwise-filled-in prose.)

Open-ended steps later in this skill (architecture-conflict
resolution, free-form pattern descriptions) stay free-form per the
convention's exception clause — only the overwrite/merge/skip
decision is structured.

### Intent Document

Create `INTENT.md` at the repository root **only if it does not already
exist**, by copying the distributable template:

```bash
[ -f "$PWD/INTENT.md" ] || cp ~/.spade/templates/INTENT.md "$PWD/INTENT.md"
```

`INTENT.md` is the project's durable statement of intent — the problem it
solves, who it serves, what it does, what success looks like, and its
non-goals. It is a root reference document, peer to `ARCHITECTURE.md`.

**Do not AI-fill `INTENT.md`.** This is a deliberate exception to the
fill-in pattern used for the architecture docs in Steps 3–5. Project intent
is the most human-owned artefact in SPADE — only a human can author it.
Onboarding's job is to scaffold the template and hand off; the human fills
it in with the `/spade-intent` skill.

After scaffolding — or if `INTENT.md` already exists but is still an
unfilled template — tell the human:

> `INTENT.md` has been scaffolded. Run `/spade-intent` to fill it in — it
> walks you through the project's problem, users, what it does, success,
> non-goals, and maturity. The SPADE loop reads `INTENT.md` to keep Scopes
> aligned with the project's purpose.

If `INTENT.md` already exists and is filled in, leave it untouched — the
same create-if-absent rule as the architecture templates.

### Project Config

Create `.spade/config` if it doesn't exist. This file tells all SPADE skills
which Linear team and project to target. If Linear MCP is available, help
the human fill it in interactively:

1. Use `list_teams` to show available teams. Ask which one.
2. Use `list_projects` to show projects for that team. Ask which one.
3. Ask for a default assignee (their name or "me").

Write the config file as YAML, using the same nested shape this repo's
own `.spade/config` uses:

```yaml
# SPADE per-repo configuration.
# Read by SPADE skills to avoid prompting for team/project on every invocation.

linear:
  team: Example Team
  team_id: 55069140-fef8-4f1a-8d04-726227e0292b
  project: Argus
  project_id: <uuid from list_projects>
  default_assignee: me

# Autonomy pipeline default for /spade. Omit `default` to always show the
# picker. See docs/FRAMEWORK.md § Autonomy Pipeline.
autonomy:
  # default: plan         # deliver | plan | scope | stub — uncomment to skip the picker
  size_ceiling:
    tasks: 7              # plan-size tripwire: halt for human review beyond this
    files: 12
  deliver:
    max_open_prs: 3        # per-project cap: Deliver halts before opening a 4th open auto-PR
```

`team_id` and `project_id` are optional but recommended — capturing them
during onboarding saves a `list_*` round-trip on every future skill
invocation. The `autonomy:` block is optional: with no `default`, `/spade`
shows the picker every time; `size_ceiling` supplies the plan-size tripwire
constant. Write the `autonomy:` block when `autonomy:` is absent; if the key
already exists, merge in any missing subkeys (especially `size_ceiling` and
`deliver.max_open_prs`) without overwriting existing values, so a rerun stays
idempotent and a pre-onboarded repo still picks up the new ceiling and the
Deliver PR cap (the same idempotency principle the marker-replace contract
enforces for `AGENTS.md` / `CLAUDE.md`).

If Linear MCP is not available, create the file with placeholder values
(omit the `*_id` fields) and tell the human to fill it in manually.

All SPADE skills that interact with Linear MUST read `.spade/config` first
to determine the team, project, and assignee. Do not prompt for these values
if the config file exists and is populated.

### Handoff Config (opt-in)

`/spade-handoff` spawns a fresh CLI agent in a new terminal window to
deliver an approved Plan. It is **opt-in** — dormant until a `handoff:`
block exists in `.spade/config`. Offer it; do not assume it.

Ask the human via **`AskUserQuestion`** whether to set up handoff now:

- *Yes — set up `/spade-handoff`*
- *No — skip (can be added later)*

If they skip, do nothing: `/spade-handoff` stays dormant and a consumer
who never opts in is unaffected.

If they opt in, ask two structured questions (`AskUserQuestion`):

1. **Agent** — *claude* / *amp* — which CLI agent the handoff spawns.
2. **Autonomy default** — *Interactive (recommended)* / *Autonomous* —
   whether the spawned agent runs interactively or with its permission
   checks bypassed.

Then add the `handoff:` block to `.spade/config` **only if no `handoff:`
key is already present** — re-running `/spade-onboard` must not duplicate
or overwrite an existing block (the same idempotency rule the
marker-replace contract enforces for `AGENTS.md` / `CLAUDE.md`). Use this
shape, setting `agent` and `autonomous` from the answers above:

```yaml
handoff:
  agent: claude            # which agent to spawn: claude | amp
  autonomous: false        # false = spawned agent runs interactively;
                           # true  = add the agent's skip-permission flag
                           #         and confirm on every run
```

The launcher owns the allowlisted command contract for each supported agent.
Never write executable names, argument arrays, prompt transport, or autonomy flags into committed project config.

Terminal choice is **machine-specific** and must never be committed. Ask
the human (`AskUserQuestion`: *iTerm2* / *Terminal.app*) and write it to
`.spade/handoff.local`:

```yaml
terminal: iterm   # iterm | terminal
```

Ensure `.spade/handoff.local` appears in `.gitignore` — add the line if
absent (idempotent; do not duplicate it).

`/spade-handoff` itself is documented in `docs/FRAMEWORK.md` § Handoff.

### Horizon Binding (opt-in)

If this repo's Linear project is fronted by a **Horizon** roadmap board,
bind it so SPADE maps every Scope to a Linear Milestone (a Horizon board
Item, 1:1) and leaves Plan task sub-issues unmilestoned. It is **opt-in**
and only meaningful in `linear`/`hybrid` mode — skip the offer entirely in
`local` mode, where there are no Linear Milestones. The full contract is in
`docs/FRAMEWORK.md` § Horizon Roadmap Binding.

Ask the human via **`AskUserQuestion`** whether this project is tracked on
Horizon:

- *Yes — this Linear project has a Horizon roadmap board*
- *No — skip (can be added later)*

If they skip, do nothing: SPADE stays Horizon-unaware and an un-bound repo
is unaffected.

If they opt in, add a `horizon:` block to `.spade/config` **only if no
`horizon:` key is already present** (the same idempotency rule as the
`handoff:` block — re-running `/spade-onboard` must not duplicate or
overwrite it). Optionally ask for the Horizon board URL for deep links; if
the human does not have it to hand, omit `board_url`. Use this shape:

```yaml
horizon:
  board_url: https://horizon.example.com/t/<team>/p/<project>  # optional, for deep links
  enforce_scope_milestone: warn   # warn (default) | off — omit to mean warn
```

Then confirm the binding is live: from now on `/spade-scope` will prompt
for a Milestone on every Scope in this repo, and `/spade-plan` will leave
sub-issues unmilestoned.

## Mode Resolution

Before any tracker call or local-file access, resolve the operating mode
**once** per `docs/FRAMEWORK.md` § Mode Resolver:

- Read `mode:` from `.spade/config`. An explicit value (`linear`,
  `local`, or `hybrid`) wins immediately.
- If `mode:` is absent, auto-detect: probe with a `list_teams` MCP call
  (try/skip, 5-second timeout). Resolve `linear` if it returns a team
  set containing `linear.team_id`; otherwise resolve `local`.
- Failure policy: an explicit `mode` with a configured `team_id` and a
  failing probe is a **fail-loud abort**; an absent `mode` with a
  failing probe **degrades quietly to `local`**.

Do not embed the resolver algorithm — it is single-sourced in
FRAMEWORK.md.

### Local layout provisioning

Onboarding MUST scaffold the local artefact layout so that `local` and
`hybrid` modes have somewhere to write. Create these directories if they
do not already exist — this is **idempotent**, never error when a
directory is already present:

- `.spade/scopes/`
- `.spade/plans/`
- `.spade/learnings/`

Then write a starter `.spade/config` that includes an explicit `mode:`
line. The mode value is chosen **once, at onboard time** — it is not
re-derived on every skill run:

1. Probe Linear MCP availability per § Mode Resolver (the `list_teams`
   try/skip with a 5-second timeout).
2. Ask the human to confirm the mode via **`AskUserQuestion`** (per
   `docs/FRAMEWORK.md` § "Asking the Human") with options `linear`,
   `local`, and `hybrid`. Use the probe result as the recommended
   default — `linear` when the probe succeeds, `local` when it does
   not.
3. Persist the chosen mode to `.spade/config` as the `mode:` line. In
   `linear` or `hybrid` mode, also write the `linear:` block (§ Project
   Config above); capturing `team_id`/`project_id` via `list_teams` /
   `list_projects` is the only tracker call onboarding makes, and it
   runs *after* the mode is known. In `local` mode, write only
   `mode: local` and make no tracker calls.

Because the choice is persisted, later skill runs read `mode:` directly
and never re-probe. The onboard summary output (see § Report What Was
Done) MUST state the chosen mode.

### Examples and Docs

- Create `.spade/examples/` if it doesn't exist and copy example files from
  `~/.spade/examples/`
- Create `.spade/docs/` and copy docs from `~/.spade/docs/`
- Create `.spade/version` with install metadata

### Report What Was Done

After initialisation, tell the human what was created and what was
skipped. The summary MUST state the operating mode chosen during
local-layout provisioning:

```
SPADE project files:
  ✓ AGENTS.md created
  ✓ CLAUDE.md created
  ✓ ARCHITECTURE.md created (template)
  ✓ INTENT.md created (template — fill with /spade-intent)
  ! PATTERNS.md already exists, skipped
  ✓ .spade/scopes/ .spade/plans/ .spade/learnings/ created
  ✓ .spade/examples/ created
  ✓ .spade/config written — mode: linear
```

If all files already existed, say so and move straight to the analysis step.
