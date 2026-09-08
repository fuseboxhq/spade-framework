---
name: spade-frontier
description: Govern major-work discovery before Scope authoring. Use when a destination is meaningful but consequential decisions, dependencies, or boundaries are too uncertain for a normal plan-ready Scope in one session, or when someone invokes /spade-frontier. Creates or advances a bounded decision index one question at a time and graduates only through human-owned /spade-scope authoring. Never produces implementation code and is not a sixth SPADE phase.
---

## Update Check

Before doing anything else, run `~/.spade/bin/spade-update-check` using exec_command.
Show the output to the user if it is non-empty.
If the script does not exist or fails, skip silently and continue with the skill.

## Project Config

Read `.spade/config` in the current project directory.
This file specifies the operating mode and, when configured, the Linear team and project used for the frontier index.
If the file does not exist, ask the human which local or tracker-backed project should own the discovery map, or suggest running `/spade-onboard` first.

## Mode Resolution

Resolve the operating mode once, immediately after reading `.spade/config`, and before any other tracker call or local-file access, per `docs/FRAMEWORK.md` section "Mode Resolver".
Do not embed or alter the resolver algorithm.
The resolved `linear`, `local`, or `hybrid` mode governs every frontier index and resolution write.

# SPADE Frontier

`/spade-frontier` is governed discovery before normal Scope authoring.
It is not a sixth SPADE phase, a delivery exception, a strategy generator, or a replacement for `/spade-scope`, `/spade-research`, or `/spade`.

The human supplies the meaningful destination and why it matters.
This skill structures the unknowns, records evidence and decisions at one canonical location, and stops discovery from becoming unapproved implementation.

Do not produce implementation code.
Do not create a Plan, Plan task, branch, commit, PR, deployment, schema, migration, reusable prototype, or durable destination artefact.
Do not add frontier to `spade-run-state/v1` or to the five-phase SPADE model.

## Canonical contract

Read `references/map-contract.md` completely before creating, reading, advancing, blocking, or graduating a frontier map.
That reference owns the schemas, stable identifiers, question states, resolution paths, one-question invariant, bounded loading, mode-specific persistence, prototype and prerequisite boundary, graduation gate, and run-state boundary.
Do not re-specify or weaken those rules here.

## Invocation routing

First determine whether the invocation names an existing frontier index by tracker identifier, canonical URL, local index path, stable frontier id, or unambiguous current-session context.

- When an existing map is named, load its canonical index and continue with one eligible question under the reference contract.
- When no map is named, run the initial fog gate below before any persistent write.
- When more than one existing map could match, stop and ask the human to select one.
- Never infer one map from a similar title or destination alone.

## Initial fog gate

Ask the human for the destination and why it matters when either is missing.
Treat that composition as human-owned input.
Do not turn an open-ended request for business or portfolio strategy into a destination.

Compare the supplied destination with the existing `/spade-scope` required fields, verifiability checks, architectural boundaries, dependencies, and single-session sizing gate.
Classify only consequential unknowns as meaningful fog.
Choices an ordinary Plan can safely make are not discovery questions.

If no meaningful fog exists:

1. State why the destination is already Scope-ready.
2. Create no frontier issue, file, directory, comment, mirror, label, or run-state record.
3. Route directly to `/spade-scope` with the human-authored destination and the known Scope inputs.
4. Stop this skill after reporting the no-write route.

If meaningful fog exists, proceed to initial mapping.

Before drafting, refine every candidate open question until it names one precise missing decision or fact.
Do not persist a vague candidate question or move it into Unresolved fog as a substitute for refinement.
Use Unresolved fog only for consequential uncertainty that cannot yet be expressed as a candidate question at all.

## Initial mapping

Draft one `spade-frontier/v1` index before writing it.
The draft must include:

- the human-authored destination;
- decisions already made, with owner and canonical source;
- precise open questions that each name one missing decision or fact;
- dependencies between question ids;
- one resolution path and one `ai` or `human` owner per question;
- unresolved fog that cannot yet be made precise;
- explicit out-of-scope boundaries;
- an initial frontier containing only dependency-free, unblocked questions; and
- an empty graduated-Scopes section.

Creating the initial map may record decisions already made before this invocation.
It must resolve no open frontier question.

Show the complete draft and the proposed canonical location.
Ask through request_user_input when available, otherwise a concise direct question with exactly:

- `Create frontier map`;
- `Route to /spade-scope instead`;
- `Cancel`.

Do not preselect an option.
On Scope routing or Cancel, write nothing.

On Create, follow the reference's mode-specific write order, collision checks, partial-failure reporting, and read-back verification.
Write tracker state first in `linear` and `hybrid` modes.
Write only the local index in `local` mode.
Never create local decision files in a pointer-only hybrid mirror.

The initial invocation completes only after the canonical index is read back with the expected identity, revision, required sections, decision pointers, question states, and current frontier.

## Existing-map entry

When continuing a map, load only the canonical index first.
Verify its schema, identity, revision, status, pointers, and current frontier before asking which single question to advance.
In `linear` and `hybrid` modes, also compare canonical resolution comments with index pointers and fail closed on any orphaned record before selection.
If the map is blocked, show the exact blockers and their owners.
If the map is graduated, show the canonical Scope links and do not reopen discovery by inference.

If the invocation names one question, require that it is currently `frontier`.
If no question is named and exactly one is visible, present that question for confirmation.
If more than one question is visible, ask through request_user_input when available, otherwise a concise direct question with the visible question ids and concise titles plus `Cancel`.
If the visible questions plus Cancel exceed five options, split selection into two sequential structured prompts without resolving or hiding a question.
Do not show blocked or dependency-incomplete questions as selectable options and do not preselect a question.

After selection, load only that question's direct canonical dependency records and evidence pointers.
State its exact question, path, owner, dependencies, evidence already available, and unblock condition before taking the path.

## Resolution paths

Follow exactly the selected question's recorded path.
Changing a path or owner changes the map's decision structure, so show the proposed change and require human confirmation before updating the index and continuing in a later invocation.
Never change the path merely because another route is easier for the agent.

### Research path

Invoke `/spade-research` for the selected question only and preserve its isolated read-only and one-question behavior.
Display its report under the research contract.
Draft a concise frontier answer containing only the supported conclusion, real source links, consequences, and Scope impact.

Ask through request_user_input when available, otherwise a concise direct question with exactly:

- `Record this research resolution`;
- `Revise the concise answer`;
- `Leave the question unresolved`;
- `Cancel`.

Do not persist the complete research report as a frontier resolution.
On Revise, let the human edit the concise answer and present it again before any write.
On Leave unresolved or Cancel, write no answer and do not change the frontier.

### Prototype path

Before running anything, show the bounded experiment method, synthetic or non-production inputs, temporary location, expected observation, cleanup boundary, and proof that the destination repository and shared external state remain unchanged.

Ask through request_user_input when available, otherwise a concise direct question with exactly:

- `Run the disposable prototype`;
- `Reclassify as a prerequisite`;
- `Cancel`.

Run an approved prototype only in a temporary location outside the destination repository.
Do not use production data or credentials.
Do not change repository files, dependency manifests, schemas, configuration, shared services, or external state.
Do not commit, deploy, import, or retain the prototype implementation.

After the experiment, retain only the method, bounded input, observation, conclusion, limitations, and Scope impact.
Verify the destination repository and named external state remain unchanged before proposing the resolution.
If any mutation occurred or useful code must be retained, stop, surface the exact state, and reclassify the work as a prerequisite instead of recording a successful prototype.

Ask whether to `Record this prototype resolution`, `Leave the question unresolved`, or `Cancel` before writing the evidence-only resolution.

### Human-decision path

Present the precise question, existing evidence, viable options, material trade-offs, and one recommended answer.
The recommendation must not be preselected.
Use request_user_input when available, otherwise a concise direct question with the viable options plus `Defer` and `Cancel`.
If those choices exceed five options, split them into two sequential structured prompts.

On a selected option, repeat the exact answer and consequences and ask the human to confirm the resolution record and attribution.
On Defer, update only the blocker owner and unblock condition, leave the question unresolved, and expose no dependent question.
On Cancel, write nothing.

### Prerequisite path

First look for the authoritative task or Scope link and its named completion condition.
If it does not exist and the prerequisite is sufficiently understood to Scope, route it through normal `/spade-scope` authoring.
Do not create a Plan sub-issue, write a Plan, or deliver the prerequisite inside frontier.

When completion evidence is absent, set or retain `blocked`, record the owner and exact unblock condition, and stop after reporting that evidence is required.
When evidence is supplied, verify it through the authoritative system rather than trusting the map or conversation summary.
Draft one concise answer explaining what the prerequisite established and how it changes the destination.
Require human confirmation before recording the resolution and recalculating the frontier.

## Canonical progression write

Immediately before writing, re-read the canonical index.
Require the same frontier id and revision, the selected question still in `frontier` or eligible blocked-prerequisite state, unchanged dependencies, no existing resolution pointer, and the same recorded path and owner.
If any value differs, write nothing and report that the map must be reloaded.

Persist exactly one canonical resolution record using the mode order in `references/map-contract.md`.
In Linear and hybrid modes, write and verify one immutable resolution comment before updating the tracker index.
In local mode, create and verify the new immutable decision file before replacing the index through a same-directory temporary file.
Never create a local decision file in hybrid mode.

After the resolution succeeds, update only the selected question's state and canonical pointer, set a new unique index revision, recompute every derived question state, and replace the Current frontier section.
Do not rewrite other resolution records or copy the new answer into the index.

Read the resolution record and index back from the canonical store.
Require one active pointer, the expected new revision, the selected question resolved, dependency-incomplete questions still open, blockers still blocked, and newly eligible questions on the current frontier.
If read-back exposes a duplicate, concurrent update, or wrong frontier, halt and report the contradiction without deleting shared state.

Resolve no second question in the same invocation.
If the map is not graduation-ready, report the new frontier or blocker and stop.
If the final material question was resolved, continue only to the bounded graduation postcondition defined by the canonical contract.

## Graduation postcondition

Graduation runs only after the current invocation resolves the final material question or validates authoritative completion evidence for that one question's prerequisite.
It is not available as a separate batch invocation.

Re-read the canonical index and require every question to be `resolved` or human-confirmed `out-of-scope`, Unresolved fog to be empty, every prerequisite to have authoritative completion evidence, and every consequential human answer to have human attribution.
If any check fails, leave the map active or blocked, name the exact gap, create no Scope, and stop.

Use the current `/spade-scope` required fields and quality checks to draft the smallest set of vertical Scope candidates that preserves independently valuable outcomes and system or team boundaries.
Each candidate must have a human-authored intent, individually verifiable acceptance criteria, explicit architectural constraints, dependencies, context, out-of-scope boundaries, origin, risks, and delivery preference.
Each candidate must fit the single-session sizing gate.
When several Scopes are required, state their dependency order and do not hide shared prerequisites.

Present all candidate titles, intents, boundaries, and dependency order before creating any Scope.
Ask through request_user_input when available, otherwise a concise direct question with exactly:

- `Author these Scopes with /spade-scope`;
- `Revise the Scope split`;
- `Keep discovery active`;
- `Cancel`.

Do not preselect an option.
On Revise, accept human composition and rerun the readiness and sizing checks before presenting the candidates again.
On Keep active or Cancel, create no Scope and do not mark the map graduated.

On Author, invoke `/spade-scope` separately for each candidate in dependency order.
Preserve `/spade-scope`'s human ownership, mode resolution, required fields, optional second opinion, and canonical persistence rules.
Do not generate a Plan, create Plan tasks, approve delivery, or continue into `/spade-plan`.

After every intended Scope is canonical, read each one back and verify its stable identity, complete body, and dependency link.
If any Scope write or read-back fails, leave the frontier map ungraduated, report the exact successful and failed Scope operations, and do not delete successfully created Scopes.

Re-read the frontier index immediately before its final update and require the same ready revision and question set used to author the Scopes.
Add only canonical Scope links and dependency order, set a new revision, set status `graduated`, and write through the resolved mode's canonical path.
Read the graduated index back before reporting success.

Each Scope receives one backlink to the canonical frontier index and only the relevant decision pointers.
Do not copy the full index, resolution bodies, or research report into a Scope.

Frontier itself writes no `spade-run-state/v1` record.
After graduation, the human may invoke `/spade` independently for each Scope.
Each normal run starts only after its Scope has a stable identity and does not splice frontier history into run-state history.

## Failure handling

Fail without mutation when the mode cannot be resolved, the destination is missing, the map identity is ambiguous, the canonical store is unavailable, the index is malformed or stale, a path is unsafe, a duplicate map exists, or read-back fails.
Also fail without mutation when a named question is in any state other than `frontier` (`open`, `blocked`, `resolved`, or `out-of-scope`), or when its map is graduated.
Surface the exact failed check, expected value, observed value, and safe next action.
Never delete or overwrite a shared issue, comment, map, resolution record, user file, or external state to recover from a partial write.

## Completion

Every invocation ends with a concise report that names:

- `Map`: the canonical location, or `none` for a no-fog exit;
- `Resolved`: `none` or the one question id resolved in this invocation;
- `Frontier`: the currently visible question ids, or the exact blockers;
- `Scopes`: canonical graduated Scope links, or `none`; and
- `Next`: one bounded human action or skill invocation.

The skill is complete only when every canonical write was read back successfully, no more than one open question was resolved, and no implementation output was produced.
