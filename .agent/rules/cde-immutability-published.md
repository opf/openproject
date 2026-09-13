---
name: cde-immutability-published
description: Published and Archived CDE revisions are frozen. Applies when editing CDE models.
when_to_use: When writing or reviewing any code path that mutates a CDE revision in Published or Archived state.
---

# Rule: Published Revisions Are Immutable

Once a revision is `Published` (or `Archived`), **no field may change** — not metadata, not files, not suitability, not approval records attached to it. This is the property that turns the publication gate's decision into permanent audit evidence (see `cde-publication-precondition-gate`).

## Enforcement layers

1. **Model guard** — `Cde::Revision#setattr`-level contract rejects all writes when `status == Published/Archived`.
2. **State machine** — there is exactly ONE transition INTO `Archived`: `Published → Archived`. There are NO transitions out of `Archived`.
3. **DB backstop** — Postgres: `CREATE RULE` (or trigger) revoking UPDATE on rows where status is terminal. Belt-and-suspenders against raw SQL and consoles.

## Continued delivery = new revision

Post-publication change requests (Slice 7) must:
1. Create a NEW working revision from the published revision.
2. Copy forward version-aware metadata where appropriate.
3. Link via `supersedes_id` (supersession relationship).
4. Leave the published revision untouched.

## Architecture test (must exist)

A test that greps for direct-state-mutation bypasses of the Publication gate and asserts: `bin/rails runner` (or console) cannot UPDATE a published revision's row. If Rails `update_column`/`update_all` on a published row succeeds, this rule is violated.