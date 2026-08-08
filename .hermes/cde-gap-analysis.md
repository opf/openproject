# CDE Vertical Slices vs. nexuscde (OpenProject) Gap Analysis

**Date:** 2026-08-04
**Repo:** bimpro-edu/nexuscde (fork of opf/openproject)
**Branch:** dev (synced with upstream, commit 31d0bc5d1)
**Path:** D:\nexuscde

---

## Executive Summary

**The nexuscde repo is vanilla OpenProject with NO CDE plugin implemented.**

The CDE vertical slices from the specification document need to be built as a **new plugin** on top of OpenProject's existing infrastructure. The only partial overlaps are in the existing `modules/bim` module (BCF traceability and IFC models).

---

## Gap Analysis by Slice

| Slice | Capability | Status | Notes |
|-------|-----------|--------|-------|
| 0 | Platform Foundation | ✅ EXISTS | Ruby/Rails app, modules structure, Git, Docker, test infrastructure all present |
| 1 | Create Information Container in WIP | ❌ MISSING | No `InformationContainer` model. WorkPackages are used as primary work objects, but not as CDE containers |
| 2 | Manage Working Revision | ❌ MISSING | Revisions exist for Attachments/Documents, but not as CDE-specific concept |
| 3 | Metadata Governance & Search | ⚠️ PARTIAL | WorkPackages have custom attributes; Documents module has metadata. No CDE-specific metadata (Discipline, Originator, Classification, Container Type) |
| 4 | Lifecycle State Management | ❌ MISSING | WorkPackages have status states, but not CDE states (WIP → Shared → Published → Archived) |
| 4.5 | BIM Context Linking | ⚠️ PARTIAL | `modules/bim` has IFC model linking and BCF integration |
| 5 | Suitability Assignment | ❌ MISSING | No suitability codes (S0, S1, S2, A1, A2, D1) exist |
| 6 | Review, Approval & Publication | ❌ MISSING | No formal approval workflow or publication gate for CDE |
| 7 | Revision After Publication | ❌ MISSING | No immutability rules or supersession tracking |
| 8 | BCF Traceability | ⚠️ PARTIAL | `modules/bim` has BCF issues with viewpoint support |
| 9 | Published Information Consumption | ❌ MISSING | No published information register or read-only published views |
| 10 | Archive Lifecycle | ❌ MISSING | No archive state or read-only archived views |
| 11 | Exchange Packages | ❌ MISSING | No exchange package concept exists |
| 12 | Transmittals | ❌ MISSING | No transmittal module |
| 13 | Compliance Rules | ❌ MISSING | No automated governance checks |
| 14 | Governance Dashboards | ❌ MISSING | No CDE-specific dashboards or KPI reporting |

---

## Existing Relevant Modules

### `modules/bim` — Closest to CDE (Slices 4.5 & 8)
- IFC model management (`modules/bim/app/models/bim/ifc_models/ifc_model.rb`)
- BCF issues with viewpoints (`modules/bim/app/models/bim/bcf/viewpoint.rb`)
- BCF comments and topic management
- **Limitation:** BIM module is standalone, not integrated as a CDE plugin with containers/revisions

### `modules/documents` — Partial Metadata (Slice 3)
- Document types and categories
- Collaboration settings
- BlockNote editor integration
- **Limitation:** No CDE-specific metadata fields or governance rules

### `modules/wikis` — Content Management
- Wiki pages and navigation
- **Limitation:** Not designed for governed information containers

---

## Platform Infrastructure Available

The following OpenProject platform services can be reused for the CDE plugin:

| Platform Service | Available | Usage for CDE |
|-----------------|-----------|---------------|
| Users & Authentication | ✅ | Container ownership, permissions |
| Groups & Roles | ✅ | Role-based access control (BIM Coordinator, BIM Manager, Client Reviewer) |
| Projects | ✅ | Container scope (containers belong to projects) |
| WorkPackages | ✅ | Can be used as base for containers OR plugin can use custom models |
| Notifications | ✅ | State change notifications, approval alerts |
| Audit/Journals | ✅ | Append-only audit events for all changes |
| Permissions | ✅ | Permission matrix mapping (view_wip_container, edit_container, etc.) |
| API (v3) | ✅ | REST API for containers, revisions, metadata |
| IFC Viewer | ✅ | BIM module has IFC model viewer |
| BCF Workflows | ✅ | BIM module has BCF issue tracking |

---

## Recommended Implementation Approach

### Phase 1: Foundation (Slice 0)
- Create plugin shell: `modules/cde/` (or reuse `modules/bim/` structure)
- Add database migrations for:
  - `cde_containers` table
  - `cde_revisions` table
  - `cde_metadata` table
  - `cde_audit_events` table
- Register plugin in OpenProject plugin system
- Add navigation entry points

### Phase 2: Core CDE (Slices 1-3, 9)
- **Slice 1:** `Cde::Container` model with identifier governance
- **Slice 2:** `Cde::Revision` model with working revision logic
- **Slice 3:** Metadata schema (Discipline, Originator, Classification, Container Type)
- **Slice 9:** Published information register/list view

### Phase 3: Governance (Slices 4-8, 10)
- **Slice 4:** State machine (WIP → Shared → Published → Archived)
- **Slice 4.5:** IFC model linking (reuse existing `modules/bim`)
- **Slice 5:** Suitability codes (S0, S1, S2, A1, A2, D1)
- **Slice 6:** Approval workflow with publication gate
- **Slice 7:** Revision lineage and supersession
- **Slice 8:** BCF issue linking (reuse existing `modules/bim`)
- **Slice 10:** Archive state

### Phase 4: Advanced (Slices 11-14)
- **Slice 11:** Exchange packages
- **Slice 12:** Transmittals
- **Slice 13:** Compliance rules engine
- **Slice 14:** Governance dashboards

---

## MVP Scope (per specification)

The recommended MVP should implement:
- Slice 1: Create Information Container in WIP
- Slice 2: Manage Working Revision
- Slice 3: Metadata Governance and Search
- Slice 4: Lifecycle State Management
- Slice 5: Suitability Assignment
- Slice 6: Review, Approval and Publication
- Slice 9: Published Information Consumption

This covers the core CDE flow: **Create → Review → Approve → Publish → Consume**

---

## Files to Create/Modify

### New Plugin Structure
```
modules/cde/
├── app/
│   ├── components/
│   ├── controllers/
│   ├── contracts/
│   ├── helpers/
│   ├── models/
│   │   ├── cde/
│   │   │   ├── container.rb
│   │   │   ├── revision.rb
│   │   │   ├── metadata.rb
│   │   │   └── audit_event.rb
│   ├── services/
│   ├── views/
│   └── workers/
├── config/
│   ├── routes.rb
│   └── locales/
├── db/
│   └── migrate/
│       ├── 20260804000001_create_cde_containers.rb
│       ├── 20260804000002_create_cde_revisions.rb
│       ├── 20260804000003_create_cde_metadata.rb
│       └── 20260804000004_create_cde_audit_events.rb
├── lib/
│   └── open_project/cde/
│       ├── engine.rb
│       ├── initializer.rb
│       └── patches.rb
├── spec/
└── README.md
```

---

## Next Steps

1. **Create the plugin shell** in `modules/cde/`
2. **Define the domain models** (Container, Revision, Metadata, AuditEvent)
3. **Implement Slice 0** (Platform Foundation)
4. **Proceed with MVP slices** (1, 2, 3, 4, 5, 6, 9)

---

*Analysis generated from: D:\nexuscde\.hermes\desktop-attachments\playground_exported_message.docx*
*Source: OpenProject_CDE_Domain_Architecture_Specification_v1.txt*
