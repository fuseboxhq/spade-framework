---
title: In spade-framework, main is a strict ancestor of plugin-packaging — branch off plugin-packaging, and re-mirror the payload on every change
area: delivery
tags: git, branching, plugin-packaging, payload-mirror, distribution, spade-framework
created: 2026-05-30
status: archived
public_safe: true
scope_ref: M-1248
---

## Archive note

Archived on 2026-07-14 because current verified repository history contradicts this branch guidance.
Main absorbed the plugin-packaging work in v1.9.0, and current deliveries branch from main while generated payloads come from `scripts/project-hosts.sh`.

## What we learned

In the `spade-framework` repo, `main` and the
`kevinr-security/plugin-packaging` branch are **not forked** — `main` is
a **strict ancestor** of plugin-packaging (verified during M-1248: 0
commits ahead, 22 behind; `git merge-base main plugin-packaging` ==
`main` tip). `main` tracks 68 files (framework source only);
plugin-packaging tracks 119 — the same source **plus** the generated
plugin payload (`.claude-plugin/`, and the mirrored `skills/`, `agents/`,
`scripts/`). So plugin-packaging is the live, complete branch and `main`
is simply a stale subset, not a different lineage.

The plugin payload is a **mirror of canonical source**:
`scripts/release-plugin.sh` runs `rsync -a --delete .claude/skills/
skills/` and `rsync -a --delete --include='spade-*' .claude/agents/
agents/`. Any change to a skill or agent under `.claude/` must be
re-mirrored into `skills/`/`agents/` or the payload silently drifts from
source.

(Process note, not a repo fact: during M-1248 I briefly believed
plugin-packaging used an "ignore-all, re-include payload" `.gitignore`
and that `docs/` was git-ignored there. That was wrong — it stemmed from
misreading `git check-ignore -v` exit code 1 as "ignored" when **exit 1
means NOT ignored** (0 = ignored). The `.gitignore` on both branches is
ordinary.)

## Why it matters for future work

Branch off **`kevinr-security/plugin-packaging`**, not `main`, for active
SPADE-framework work — `main` is behind and a PR off it would mis-base.
Treat catching `main` up (a fast-forward, since it is a strict ancestor)
as its own separate exercise, decoupled from feature delivery. On any
change that touches a skill or agent, re-run `scripts/release-plugin.sh
<version>` (or the rsync it wraps) in the same change so source and
payload never diverge — and `diff -q .claude/skills/.../SKILL.md
skills/.../SKILL.md` to confirm. When reasoning about ignore status,
remember `git check-ignore -v <path>` exits **0 when ignored, 1 when
not** — do not infer from the exit code alone without reading the
printed rule.
