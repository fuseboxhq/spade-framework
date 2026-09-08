---
name: bad-id-doubled-hyphen-scope
id: sp-readable-stable--ids-k3f9q
title: A Scope whose stable id contains a doubled hyphen
status: scoped
type: feature
phase: scope
created: 2026-08-18
updated: 2026-08-18
origin: ad-hoc
priority: this-cycle
delivery: mostly-ai-delivered
---

# Scope: bad-id-doubled-hyphen-scope fixture

`sp-readable-stable--ids-k3f9q` **matches the id regex on its own** — a
character class cannot say "no two hyphens in a row" — so the doubled-hyphen
rule is enforced by a separate check in `_scope_id_is_valid`. That makes this
the one identifier rule with no regex behind it, and therefore the one that
would rot silently: delete the check and every other fixture still passes.

A doubled hyphen is what a truncation bug produces (`sp-stem--abcde`), which is
exactly the defect the derivation's trailing-hyphen strip exists to prevent.
The schema lint MUST hard-fail this file.
