# Consumer migration contract

`migrations/manifest.tsv` is the ordered migration registry.
Each non-comment row has `from_version|to_version|action|affected_paths`.
The capability manifest supplies the supported floor, current version, and published versions.
Unknown, malformed, duplicate, cyclic, future, below-floor, or unreachable states fail closed.

Actions are names implemented by `spade-lifecycle`, never shell from the manifest.
`pin` changes only `.spade/version`.
`refresh_fragments` refreshes the two marker blocks and then the version pin.
`intent_mode_fragments` is a historical action that refreshes the blocks, creates `INTENT.md` only when absent, records a validated tracker mode only when absent, and then changes the pin.

The affected-path list is exact.
The helper rejects paths outside the consumer root and unsafe symlinks.

For each unit, the helper:

1. re-reads the consumer version and requires the declared starting version;
2. copies only affected paths to an isolated stage;
3. applies the allowlisted action and verifies the complete staged result;
4. backs up affected consumer paths;
5. replaces non-version files and `.spade/version` last;
6. rolls the whole unit back if replacement fails;
7. re-reads and verifies committed state.

A verified unit is the resume checkpoint.
The bounded journal lives below the resolved Git directory and cannot override live worktree, tracker, version, index, or file state.
Malformed or duplicate framework markers stop before mutation for human repair.

After the final unit, the consumer pin matches the installed capability version and diagnostics report live fragment, inventory, tracker, version, and renderer state.
Show changed files to the human.
Do not commit consumer changes unless explicitly asked.
