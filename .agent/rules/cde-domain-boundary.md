---
name: cde-domain-boundary
description: OpenProject owns platform services; the CDE plugin owns governed information. Do not force CDE onto WorkPackages/Attachments.
---

# cde-domain-boundary

Per the source specification's "Notes on OpenProject Alignment", keep this separation explicit.

## OpenProject owns (platform layer — reuse, don't rebuild)

- users, groups, roles, permissions
- projects (container scope lives here)
- notifications
- IFC viewer, BCF workflows (modules/bim)
- journals/audit primitive, REST API v3

## CDE plugin owns (governed information behavior)

- Information Containers (own model — NOT a WorkPackage subtype)
- Revisions (working vs published, lineage, supersession)
- Lifecycle states (WIP → Shared → Published → Archived)
- Suitability codes
- Metadata governance (mandatory fields, controlled vocabularies)
- Approval workflows
- Audit trail (append-only, CDE-event typed)
- Exchange packages, transmittals
- Compliance reporting

## Rules

1. Do NOT model an Information Container as a WorkPackage. Reuse OP's permission/project/notification primitives; keep the aggregate root its own model.
2. Do NOT model a governed document as an Attachment metadata bag.
3. Shared services (auth, journals) — call OP APIs/services. Governed behavior (state transitions, publication gates) — own services in the CDE module.
4. When a requirement could live in either layer, ask: "Is this platform-generic or governance-specific?" Platform-generic → reuse; governance-specific → CDE module.

## Pointer

Full rationale: `.agent/rules/` siblings + the gap analysis at `.hermes/cde-gap-analysis.md`.
