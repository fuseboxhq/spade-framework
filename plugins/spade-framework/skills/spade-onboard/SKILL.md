---
name: spade-onboard
description: Onboard a project into the SPADE framework. Creates AGENTS.md, CLAUDE.md, architecture templates, and example files if they don't exist, then analyses the codebase to fill in architecture docs. Use when someone says "onboard this project", "set up SPADE", "spade init", or when starting SPADE in a new repo. Also use when architecture docs are still templates with placeholder comments.
---

## Update Check

Before doing anything else, run `~/.spade/bin/spade-update-check` using exec_command.
Show the output to the user if it is non-empty.
If the script does not exist or fails, skip silently and continue with the skill.

# SPADE Onboard

You are onboarding a project into the SPADE framework. Your job is twofold:

1. **Initialise** — create the SPADE project files if they don't exist
2. **Analyse** — explore the codebase and help fill in architecture docs

## Self-onboard guard (stop here)

**Before anything else**, check whether the current working directory is the
SPADE framework repository itself:

```bash
if { [ -f "src/skills/spade-onboard/SKILL.md" ] || [ -f ".claude/skills/spade-onboard/SKILL.md" ] || [ -f ".codex/skills/spade-onboard/SKILL.md" ] || [ -f "skills/spade-onboard/SKILL.md" ]; } && [ -f "fragments/AGENTS-section.md" ]; then
  echo "This looks like the SPADE framework repository."
  echo "Refusing to self-onboard — the framework's own AGENTS.md / CLAUDE.md"
  echo "are the canonical source, not fragment-wrapped copies."
  exit 0
fi
```

If the guard triggers, stop and tell the human:

> This is the SPADE framework repo itself — no onboarding needed. Its
> `AGENTS.md`, `CLAUDE.md`, and architecture docs are already the source
> of truth. If you wanted to onboard a different project, `cd` into it
> and run `/spade-onboard` there.

Do not proceed to the steps below when in the framework repo.


## Step 0: Initialise SPADE Project Files

Before provisioning begins, read `references/project-files.md` completely and follow it through its observable report. Do not load it during the self-onboard guard.

## Step 1: Analyse the Codebase

Before asking the human anything, explore the project:

1. Read the directory structure (top two levels)
2. Read any existing README, docs, or configuration files
3. Look at package.json, requirements.txt, go.mod, Cargo.toml, or equivalent
   to understand the dependency landscape
4. Look at Dockerfiles, docker-compose files, or infrastructure configs
5. Look at CI/CD configuration (.github/workflows, .gitlab-ci.yml, etc.)
6. Read a sample of source files to understand coding patterns
7. Check for existing test files and testing patterns
8. Look for authentication/authorisation patterns
9. Check for database migrations or schema files

## Step 2: Present Your Understanding

Summarise what you have found and present it to the human for validation:

- "Here is what I understand about your project. Please correct anything
  that is wrong or incomplete."

Cover:
- What the project does (purpose, users)
- Infrastructure and hosting
- Tech stack (languages, frameworks, databases, queues, etc.)
- Code organisation and patterns
- Testing approach
- Deployment pipeline
- Security considerations
- External integrations

## Step 3: Fill In ARCHITECTURE.md

Based on the validated understanding, generate the content for ARCHITECTURE.md.
Follow the template structure already in the file, but replace all placeholder
comments with real content.

Present each section to the human for approval before moving to the next.
They know things about the system that code analysis cannot reveal (planned
migrations, deprecated components, infrastructure not visible in the repo).

## Step 4: Fill In PATTERNS.md

Document the coding patterns, conventions, and approved libraries visible in
the codebase. Focus on:

- Patterns that are consistently used (these are the established conventions)
- Libraries that appear across multiple files (these are the approved choices)
- Naming conventions, error handling approaches, logging patterns
- How tests are structured and what testing libraries are used
- How services communicate (REST, gRPC, events, etc.)

Ask the human: "Are there patterns you want to enforce that are not yet
consistently applied? These are also worth documenting."

## Step 5: Fill In ANTI-PATTERNS.md

This requires the most human input because anti-patterns often come from
painful experience rather than code analysis. Ask the human directly:

- "What mistakes have been made in this project that you want to prevent?"
- "Are there technologies or approaches that have been tried and rejected?"
- "What would you warn a new team member (or AI agent) not to do?"
- "Are there dependencies or patterns that should never be introduced?"

Document each anti-pattern with a clear rationale. The rationale matters
because it helps AI agents understand why the constraint exists, not just
that it exists.

## Step 6: Verify and Commit

After all three documents are filled in:

1. Show a summary of what was documented
2. Ask the human to review and confirm
3. Suggest they commit the changes:

```bash
git add AGENTS.md CLAUDE.md ARCHITECTURE.md PATTERNS.md ANTI-PATTERNS.md .claude/ .spade/
git commit -m "Onboard project with SPADE framework"
```

Remind them: "These documents are living. Update them as your architecture
evolves. The better the context, the better the AI-generated Plans."

Also remind them: "Once these files are committed, teammates who clone
this repo will have SPADE working automatically — they just need the
global skills install (`~/.spade/setup`)."

## Why This Matters

The quality of AI-generated Plans is directly proportional to the quality of
the architecture context. A blank ARCHITECTURE.md means the AI will guess.
A detailed one means the AI will propose solutions that fit your world. This
onboarding step is the single highest-leverage thing you can do to make SPADE
work well.

## Quality Checks

Before finishing, verify:

- [ ] All SPADE project files exist (AGENTS.md, CLAUDE.md, architecture docs)
- [ ] INTENT.md scaffolded as a template (onboard does not fill it — that is
      `/spade-intent`'s job; the human composes project intent)
- [ ] ARCHITECTURE.md has no placeholder comments remaining
- [ ] Tech stack table is complete with actual technologies and versions
- [ ] PATTERNS.md reflects what the code actually does, not aspirations
- [ ] ANTI-PATTERNS.md has rationale for every entry
- [ ] All three documents are specific enough that an AI agent reading them
      could propose a solution that fits this project
- [ ] The human has reviewed and approved all content

## If Linear MCP is Available

Also help the human set up the Linear integration:

1. Confirm the team and project from `.spade/config` are correct, and make
   sure the file carries the autonomy and guard defaults:

   ```yaml
   autonomy:
     default: deliver      # deliver | plan | scope | stub
     deliver:
       merge: human        # human | on-green (agent merges on green checks; Claude host guard enforces)
   guards:
     deny_stage_all: false # true denies git add -A / --all / .
   ```

   Explain that `on-green` is the human's call and that the guard blocks
   agent edits to this file once a Deliver run is active
   (`docs/FRAMEWORK.md` § Mechanical guards).
2. Check if the SPADE statuses exist in their Linear workflow
   (Scoped, Planning, Approval, Delivering, Evaluating, Done)
3. Check if the SPADE labels exist
   (ai-planned, ai-delivered, human-delivery, plan-rejected, needs-arch-review)
4. If not, advise the human on how to create them

## Output

The onboarding is complete when:
- All SPADE project files are created
- ARCHITECTURE.md is filled in and validated
- PATTERNS.md is filled in and validated
- ANTI-PATTERNS.md is filled in and validated
- The human understands how to use the SPADE skills
- Linear integration is configured (if applicable)
