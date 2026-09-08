---
name: bad-id-traversal-scope
id: sp-..-abcde
title: A Scope whose stable id is shaped like a path traversal
status: scoped
type: feature
phase: scope
created: 2026-08-18
updated: 2026-08-18
origin: ad-hoc
priority: this-cycle
delivery: mostly-ai-delivered
---

# Scope: bad-id-traversal-scope fixture

The `id` becomes a filesystem path component (the run key in
`.spade/runs/<scope-key>.md`), so a `..` stem would escape `.spade/`. The
character class already excludes `.`, so no extra logic defends this — the
fixture exists to prove the path-safety boundary actually holds.
