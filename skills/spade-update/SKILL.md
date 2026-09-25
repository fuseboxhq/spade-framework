---
name: spade-update
description: Diagnose and update a SPADE installation from its canonical source, then apply bounded consumer migrations. Use for update requests, version checks, installation drift, or failed SPADE upgrades.
---

# SPADE update

## Update Check

Before doing anything else, run `~/.spade/bin/spade-update-check` using Bash.
Show the output to the user if it is non-empty.
If the script does not exist or fails, continue to diagnostics.

`bin/spade-lifecycle` performs diagnosis, clone advancement, and consumer migration.
Do not reproduce its mutations by hand.

## Resolve authority

Find the real installation root and regular, non-symlink lifecycle helper:

- A host-managed plugin uses the nearest payload `CAPABILITIES.md` and `scripts/spade-lifecycle`.
- A global projection uses `~/.spade/CAPABILITIES.md` and `~/.spade/bin/spade-lifecycle`.
- A canonical clone uses `~/.spade/src/CAPABILITIES.md`, `~/.spade/bin/spade-lifecycle`, and requires `~/.spade/.git`.

The capability manifest owns the canonical remote, current version, supported version floor, published versions, inventory, and release policy.
If the loaded skill and resolved payload disagree on capability version, halt as drift.

An exact commit SHA fetched from the manifest's canonical remote is the only update identity a human can approve.
Do not treat a tag, branch, version string, local ref, or plugin display version as approval evidence.

## Diagnose first

Run:

```bash
"$SPADE_LIFECYCLE" diagnose \
  --install-root "$SPADE_INSTALL_ROOT" \
  --consumer-root "$PWD" \
  --host "$SPADE_HOST"
```

Exit 0 is healthy.
Exit 1 is drift that must be shown before any update.
Exit 2 is unsupported state and halts the update.
Diagnostics are read-only, and no failed check may be repaired implicitly.

## Choose the supported update path

For a host-managed plugin, verify its embedded SHA-256 payload claims, report diagnostics, and update only through the host's plugin manager.
Never run Git in the payload, replace plugin files, or imitate the manager.
An embedded payload hash proves integrity, not publisher provenance.

For a global projection without `.git`, require the selected host projection to match its machine-local setup receipt.
Update the canonical source clone recorded by that approved receipt, then rerun its `setup --host <host>`.
If live state cannot identify that clone, halt and offer a fresh canonical clone.

For a clone, require a real non-symlink worktree, exact canonical `origin`, a clean tree including untracked files, branch `main`, and a reported installed SHA.
Any mismatch halts before fetch.

## Approve and advance one exact commit

Fetch only the canonical default branch and resolve the candidate commit:

```bash
test "$(git -C ~/.spade remote get-url origin)" = "$canonical_remote"
git -C ~/.spade fetch --prune origin main
candidate="$(git -C ~/.spade rev-parse 'refs/remotes/origin/main^{commit}')"
git -C ~/.spade log --oneline --decorate HEAD.."$candidate"
```

Show the exact candidate SHA and commit summary.
Ask through `AskUserQuestion` whether to approve that exact SHA or skip.

Immediately before advancing, re-resolve `refs/remotes/origin/main^{commit}` and require it to equal the approved SHA.
Then run only:

```bash
"$SPADE_LIFECYCLE" advance \
  --install-root "$SPADE_INSTALL_ROOT" \
  --approved-sha "$approved_sha"
```

The helper locks the installation, fetches again, revalidates the remote, branch, tree, and installed commit, requires the fetched candidate to equal the approved SHA, fast-forwards once, verifies HEAD, and runs setup from that commit.
If the candidate changes at either re-resolution, halt and ask for approval of the new exact SHA.

After advancement, verify HEAD equals the approved SHA, rerun `diagnose`, and clear only `~/.spade/.state/last-update-check`.

## Migrate the consumer

Read `references/migrations.md` completely.
Resolve the tracker mode from the live `.spade/config` under `references/FRAMEWORK.md` § Operating modes.
Normalize the legacy alias to `linear` rather than treating it as another mode.

Run:

```bash
"$SPADE_LIFECYCLE" migrate \
  --install-root "$SPADE_INSTALL_ROOT" \
  --consumer-root "$PWD" \
  --tracker-mode <linear|local>
```

The helper selects and commits each declared migration unit and writes `.spade/version` last.
An interrupted migration resumes from verified state.
Never skip a transition, edit the version pin, or hand-apply part of a unit.

Rerun `diagnose` after migration and show the changed consumer files.
Do not create a consumer Git commit unless the human asked for one.

## Current, missing, or damaged installs

When the fetched candidate equals installed HEAD and the consumer pin equals the capability version, report the exact version and SHA while still surfacing drift.

If `~/.spade` is absent, use this bootstrap:

```bash
git clone https://github.com/fuseboxhq/spade-framework.git ~/.spade
bootstrap_sha="$(git -C ~/.spade rev-parse HEAD)"
```

Show the exact SHA and summary, then ask through `AskUserQuestion` to approve it before running setup with `SPADE_APPROVED_SHA`.

If an installation is damaged, show the failed diagnostics first.
Never remove `~/.spade` without explicit structured confirmation through `AskUserQuestion` that names that exact path and says the removal is destructive.

## Hard lines

- Never run `git pull`.
- Never update from a non-canonical remote or a moving name.
- Never treat a plugin payload as a Git clone.
- Never continue after the approved SHA changes.
- Never edit migration history or a version pin to bypass failure.
- Never claim success until post-update diagnostics match live state.

End with:

- **Blocked on me**: an exact SHA approval, destructive reinstall confirmation, or unsupported-state repair, or `nothing`.
- **Changed**: the installed SHA, migrated files, and resulting version, or `nothing`.
- **Found**: diagnostic drift, provenance limits, or migration warnings, or `nothing`.
