# Consumer Migration Contract

Read this reference completely before invoking `spade-lifecycle migrate`.

## Authority

`migrations/manifest.tsv` is the ordered migration-unit registry.
Each non-comment row contains exactly four pipe-separated fields:

```text
from_version|to_version|action|affected_paths
```

The capability manifest supplies the supported version floor, current version, and complete published-version set.
Every published transition from the floor to current must have one unique row.
Unknown, malformed, below-floor, future, duplicate, cyclic, or unreachable versions fail closed.

## Unit semantics

Each row is one discrete unit.
The action is an allowlisted operation implemented by the bounded lifecycle helper, not executable content from the manifest.

- `pin` changes only the consumer version pin.
- `refresh_fragments` refreshes the two bounded marker blocks and then changes the version pin.
- `intent_mode_fragments` refreshes marker blocks, scaffolds `INTENT.md` only when absent, records a validated tracker mode only when absent, and then changes the version pin.

The affected-path list is exact.
No unit may read or write outside those consumer-relative paths.
Every existing path component and target must be a regular non-symlink file.

## Transaction and resume behavior

The helper performs each unit in this order:

1. Re-read the real consumer version and require the row's `from_version`.
2. Copy only affected paths into an isolated stage.
3. Apply the allowlisted action to the stage.
4. Verify the complete staged postcondition.
5. Back up the affected consumer paths.
6. Replace non-version files, then replace `.spade/version` last.
7. Roll back the whole unit if any replacement fails.
8. Re-read the real version and verify the committed postcondition.

A completed unit is the resume checkpoint.
Before the first replacement, the helper atomically persists a bounded journal below the worktree's resolved Git directory, outside the tracked consumer tree.
Every journal field and path must match the applicable prevalidated manifest unit before recovery can read, copy, or remove a file.
The consumer pin, Git index or prior external checkpoint, live unit postcondition, and freshly recomputed staged output must corroborate the journal.
The journal can never override real tracker, worktree, version, or file state.
An interrupted run begins again by diagnosing the actual tracker, worktree, installed commit, capability manifest, and consumer version.

## Historical state rules

The registry explicitly covers every published starting state from v1.0.0.
Version-only releases remain explicit `pin` units so the chain is reviewable and testable.
Fragment-changing releases use `refresh_fragments`.
The v1.7.0 transition also scaffolds human-owned intent and requires a tracker mode validated by the calling skill.

`INTENT.md` is create-if-absent and is never AI-filled or overwritten.
Malformed or duplicate framework markers stop before commit for human repair.

## Postconditions

After the final unit:

- `.spade/version` equals the installed capability version.
- Each consumer fragment has exactly one matching marker pair.
- `mode:` is one of `linear`, `local`, or `hybrid` when the historical transition requires it.
- Diagnostics report the installed revision, helper inventory, tracker mode, consumer pin, fragment state, and renderer status from live state.

Show changed files to the human.
Do not create a consumer commit unless explicitly asked.
