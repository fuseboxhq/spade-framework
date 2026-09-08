# Scope Tracker and Local Storage

Read this reference completely before milestone selection, tracker persistence, or local Scope creation.
## Horizon Milestone Mapping

This section applies **only when the repo is Horizon-bound** — a `horizon:`
block is present in `.spade/config` — and only in `linear` or `hybrid`
mode (in `local` mode there are no Linear Milestones, so this section is
inert). The full contract lives in `docs/FRAMEWORK.md` § Horizon Roadmap
Binding; do not re-specify it here. The rule it imposes on this skill:

**Every Scope filed in a Horizon-bound repo should map to exactly one
Linear Milestone** — the Milestone is the 1:1 anchor for a Horizon
roadmap Item, and a Scope without one is invisible to the roadmap.

When Horizon-bound, before filing the parent issue (Create Mode step 1,
or when an Edit-Mode Scope is still unmilestoned):

1. List the project's Milestones (`list_milestones`). Read each
   Milestone's name/description and **recommend the best fit** for this
   Scope's intent and theme — say which one and why.
2. Prompt for the Milestone via **`AskUserQuestion`**: the candidate
   Milestones (best fit first, labelled *Recommended*) plus a final
   *File without a Milestone (not recommended)* option.
3. If the human picks a Milestone, set it on the parent issue.
4. If the human picks *File without a Milestone*, **proceed anyway** —
   enforcement is warn, not block (unless `enforce_scope_milestone: off`,
   in which case skip this prompt entirely) — but emit a one-line warning
   that the Scope is unmilestoned and the Horizon rollup will under-count
   it until it is attached.
5. **Never create a Milestone.** A Milestone is a Horizon roadmap line and
   is human-owned (the same reason AI never marks a parent issue Done). If
   no Milestone fits, tell the human the roadmap Item is likely missing
   from Horizon and that they should add it (which creates the Milestone)
   before — or after — filing; do not invent one.

The corollary — Plan task sub-issues are left **unmilestoned** so the
rollup counts roadmap Scopes, not tasks — is enforced in `/spade-plan`,
not here.

## Linear Integration

### Create Mode
In `linear` or `hybrid` mode:
1. Create a parent issue with the Scope content in the description
2. Set status to "Scoped"
3. Assign to the appropriate team member (ask the human)
4. **Milestone.** In a Horizon-bound repo, attach the Milestone resolved
   via "Horizon Milestone Mapping" above (warn-and-proceed if the human
   files without one). Otherwise, link the relevant Milestone if applicable.
5. Confirm the issue was created and share the identifier

### Edit Mode
In `linear` or `hybrid` mode:
1. Fetch the existing issue
2. Show the current content and highlight missing required fields
3. Walk through each missing or weak field with the human
4. Update the issue description with the complete Scope
5. Set status to "Scoped" if not already
6. **Milestone.** In a Horizon-bound repo, if the issue has no Milestone,
   run "Horizon Milestone Mapping" above and attach the chosen one
   (warn-and-proceed if the human declines).
7. Confirm the update

In `local` mode, the skill writes the canonical Scope file itself to
`.spade/scopes/<slug>.md` (no Linear issue is created) — applying the
ID and collision rules in § Stable ID and Slug Collision Check below —
then runs the mandatory render-and-link closing step. The human does
not create the file by hand.

## Stable ID and Slug Collision Check

These two rules apply whenever the skill **creates** a Scope file under
`.spade/scopes/` (Create Mode, in `local` and `hybrid` modes). They do
not apply in Edit Mode — editing an existing Scope keeps its file and
its `id` unchanged.

**Stable ID.** Every new Scope carries a stable `id` in its frontmatter,
of the form `sp-<stem>-<suffix>` — for example
`sp-readable-stable-ids-k3f9q`.

Enough of the rule to mint one correctly is repeated here **on purpose**:
`docs/FRAMEWORK.md` does not ship inside a host payload, so a consumer
install cannot resolve a pointer to it. `docs/FRAMEWORK.md` § Local
Layout → "Stable identifier" remains the **full contract and the
authority** — read it when it is available, and prefer it over this
summary if the two ever disagree.

- `<stem>`: lowercase the title and fold it to ASCII by normalising to
  **NFKD**, dropping combining marks, and discarding any remaining
  non-ASCII character — never transliterating. Replace each run of
  characters outside `[a-z0-9]` with a single hyphen, strip leading and
  trailing hyphens, then truncate to at most 40 characters at a hyphen
  boundary (hard-truncate at 40 if the first word alone is longer) and
  strip any hyphen left at the cut.
- `<suffix>`: exactly five characters drawn at random from `[a-z0-9]`.
- The whole `id` must match `^sp-[a-z0-9][a-z0-9-]{0,39}-[a-z0-9]{5}$`
  and contain no doubled hyphen.

Mint the `id` once, when the Scope is created, and write it into the
frontmatter next to `name`. The `id` is the Scope's permanent identity —
it never changes even if the title (and therefore the slug) is later
reworded, which is why its stem describes the work as it was named at
creation rather than as it is named now. Never regenerate or reuse an
`id`, and never back-fill one into a pre-existing Scope file that lacks
it (those are grandfathered — see § Local Layout).

If the title derives an empty stem, **abort with a clear error** rather
than inventing a fallback identifier.

**Slug collision check.** The filename slug is derived from the title
per the § Local Layout slug grammar. **Before writing**
`.spade/scopes/<slug>.md`, check whether a file with that slug already
exists. If it does, **abort with a clear error** — never overwrite it:

> A Scope already exists at `.spade/scopes/<slug>.md`. Choose a
> distinct title, or edit the existing Scope instead.

Silently overwriting would destroy an existing Scope and its audit
trail. This check is mandatory on every Create-Mode local write.
