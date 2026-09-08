---
name: spade-update
description: Diagnose and update a SPADE installation from immutable canonical provenance, then run explicit resumable consumer migrations. Use when someone says "update spade", "upgrade spade", "check for updates", "is spade up to date", or asks why an installation has drifted.
---

# SPADE Update

## Update Check

Before doing anything else, run `~/.spade/bin/spade-update-check` using {{SPADE_SHELL}}.
Show the output to the user if it is non-empty.
If the script does not exist or fails, continue to diagnostics.

## Authority

Resolve the real installation root before reading authority:

1. For a loaded Claude or Codex plugin, walk up from this loaded skill file to the nearest regular `CAPABILITIES.md` in that plugin payload.
2. For a global projection, use `~/.spade/CAPABILITIES.md` and the matching `~/.claude/skills` or `~/.codex/skills` inventory.
3. For the canonical clone installation, use `~/.spade/src/CAPABILITIES.md` and require `~/.spade/.git`.

Set `SPADE_INSTALL_ROOT`, `SPADE_HOST`, and the regular non-symlink `SPADE_LIFECYCLE` path (`bin/spade-lifecycle` in a clone/global projection or `scripts/spade-lifecycle` in a plugin payload).
If the loaded skill and resolved payload do not share the same capability version, halt as drift.
The flat manifest is authoritative for the canonical remote, current version, minimum supported version, published versions, helpers, skills, and immutable release-ref policy.
Do not hard-code any of those values in an update decision.

The only approved clone remote is the exact `canonical_remote` value.
The approved release identity is an exact commit SHA fetched from that remote.
Tags, branch names, local refs, cached issue state, and plugin display versions are diagnostic hints, not release authority.

## Step 1: Diagnose without mutation

Run:

```bash
"$SPADE_LIFECYCLE" diagnose \
  --install-root "$SPADE_INSTALL_ROOT" \
  --consumer-root "$PWD" \
  --host "$SPADE_HOST"
```

Exit 0 is healthy.
Exit 1 means actionable drift and must be shown to the human before any update.
Exit 2 means the installation or consumer state is unsupported and must halt.

Every finding has the stable form:

```text
SEVERITY|check|expected=...|observed=...|remediation=...
```

Diagnostics are read-only.
Do not repair a failed check implicitly.

## Step 2: Resolve the installation mode

If the resolved root has a host plugin manifest, treat it as host-managed.
Require its embedded SHA-256 payload claims to match, report its capability version and diagnostics, then tell the human to update through that host's plugin manager.
Embedded hashes prove payload consistency, not publisher provenance.
Unless the host exposes a separately trusted immutable manager revision, report installed provenance as unsupported and never describe the embedded claim as approval evidence.
Do not run Git commands, replace plugin files, or imitate the host manager.

If the resolved root is the global projection at `~/.spade` without `.git`, report it as global, not plugin-managed.
Require the selected host projection to match the machine-local SHA-256 receipt written by setup.
The receipt is authoritative only when setup recorded the exact canonical commit previously approved by the human.
Tell the human to update the canonical source clone they installed from and rerun its `setup --host <host>`.
If that source clone cannot be identified from live state, halt and offer a fresh canonical clone instead of guessing.

If `~/.spade/.git` exists, require all of the following before fetching:

- `~/.spade` is a real non-symlink worktree.
- `origin` exactly equals `canonical_remote`.
- The worktree is clean, including untracked files.
- The checked-out branch is exactly `main` and the installed commit is reported to the human.

Any mismatch halts with remediation.

## Step 3: Resolve and approve one immutable candidate

Fetch only the canonical default branch:

```bash
test "$(git -C ~/.spade remote get-url origin)" = "$canonical_remote"
git -C ~/.spade fetch --prune origin main
candidate="$(git -C ~/.spade rev-parse 'refs/remotes/origin/main^{commit}')"
git -C ~/.spade log --oneline --decorate HEAD.."$candidate"
```

Show the exact candidate SHA and commit summary.
Ask the human via `{{SPADE_ASK_USER}}` to approve that exact SHA or skip.
Approval of `main`, `latest`, a version string, or an earlier candidate is not approval of a different commit.

Advance only through the bounded lifecycle operation.
It acquires an installation lock, revalidates the remote, branch, clean worktree, and installed commit, fetches again, requires the candidate to equal the approved SHA, performs one fast-forward, verifies the exact installed commit, and runs setup from that commit:

```bash
"$SPADE_LIFECYCLE" advance \
  --install-root "$SPADE_INSTALL_ROOT" \
  --approved-sha "$approved_sha"
```

If it differs from the approved SHA, halt and ask again with the new SHA.
Verify `git -C ~/.spade rev-parse HEAD` still equals the approved SHA and rerun diagnostics.
Clear only the update-check cache:

```bash
rm -f ~/.spade/.state/last-update-check
```

## Step 4: Apply consumer migrations

Read `references/migrations.md` completely before migration.
Resolve the consumer tracker mode from real `.spade/config` plus live tracker availability.
Do not infer mode from a stale run summary.

Run the bounded engine:

```bash
"$SPADE_LIFECYCLE" migrate \
  --install-root "$SPADE_INSTALL_ROOT" \
  --consumer-root "$PWD" \
  --tracker-mode <linear|local|hybrid>
```

The engine validates the real worktree and version, selects one explicit transition at a time, stages it, verifies it, commits its files atomically, and writes `.spade/version` last.
An interruption resumes from the last verified version pin.
Never skip a transition or edit the pin to simulate completion.

After migration, rerun diagnostics and show the changed files for human review.
Do not commit consumer changes unless the human asked for that operation.

## Already current

If the fetched candidate equals installed `HEAD` and the consumer pin equals the manifest version, report `SPADE is up to date (v<manifest version>, commit <SHA>).`
Still surface any diagnostic drift.

## Missing or damaged installation

If `~/.spade` is absent, show this exact canonical clone flow:

```bash
git clone https://github.com/fuseboxhq/spade-framework.git ~/.spade
bootstrap_sha="$(git -C ~/.spade rev-parse HEAD)"
```

Show `bootstrap_sha` and its commit summary, then ask the human to approve that exact SHA.
Only after approval run `SPADE_APPROVED_SHA="$bootstrap_sha" ~/.spade/setup`.

If it exists but is unsupported, offer a reinstall only after showing the failed diagnostics.
Removing `~/.spade` is destructive and requires explicit structured human confirmation.

## Never

- Never run an unbounded `git pull`.
- Never update from a non-canonical remote, moving branch name, or unverified tag.
- Never treat a plugin directory as a Git clone.
- Never continue after the approved candidate SHA changes.
- Never hand-edit a historical migration or version pin to get past a failed unit.
- Never claim success until post-update diagnostics match installed reality.
