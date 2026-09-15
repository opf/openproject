---
description: Seed permissions matrix for CDE capabilities (view/edit/share/approve/publish/archive/manage-exchange). Basis for cde_slice_with_audit guarantees.
---

# Permissions Matrix (Seed)

Canonical capability set lives in `config/cde_conventions.yml#permissions.roles`.
This file is the seed consumed by `modules/cde/db/seeds.rb` and by
`cde_slice_with_audit` when scaffolding slice authorization.

## Why

- Single source of truth: YAML → seeds → OpenProject permission records.
- Auditability: every approval/publish/archive event carries a capability name
  that must exist here.
- Testability: `cde-invariant-verifier` diffs runtime role_capability rows
  against this matrix.

## Capabilities (columns)

- `create_container` — create a new governed container in WIP
- `edit_wip_container` — modify a container while WIP
- `share_for_review` — WIP → Shared (request review)
- `approve` — record an approval decision on a Shared container
- `publish` — Shared → Published (only via the precondition gate)
- `archive` — Published → Archived
- `create_exchange_package` — create an exchange package (transmittal)
- `assign_suitability` — set suitability code on a Shared container
- `view` — read (status-gated; see state_matrix in conventions)

## Roles (rows)

Default ISO 19650-flavored set; edit per appointment/EIR:

- `information_manager` — full governance (all capabilities)
- `bim_manager` — approve, publish, archive, assign_suitability, exchange pkg, share_for_review
- `task_information_manager` — create/edit/share containers in own scope
- `interface_manager` — share_for_review, create_exchange_package
- `originator` — create/edit containers (narrowed by project/conventions)

## [TBC] — open governance questions

1. Who may *request* a publication decision (Shared → gate)? BIM manager only, or
   also information_manager?
2. Does `originator` get `edit_wip_container` on others' containers, or only own?
3. Client reviewer visibility: Shared only, or also WIP with redaction?
4. Archive trigger: manual by information_manager, or scheduled after N years?

Resolve these in appointments/EIR, then un-[TBC] the rows.

## Loader contract

`Cde::Permissions.seed!` (in `modules/cde/db/seeds.rb`) reads this file and
upserts `role_capabilities`. Idempotent; safe to re-run after edits.

## See also

- `config/cde_conventions.yml#permissions` — role list referenced by the gate
- `rules/cde-domain-boundary` — capability names must match boundary rule
- `skills/cde-slice-with-audit` — consumes this to generate authorization
