# OpenProject CDE Vertical Slices

**Source:** `OpenProject_CDE_Domain_Architecture_Specification_v1.txt`
**Generated:** 2026-08-05
**Status:** MVP Implementation in Progress

---

## Architectural Basis

The Information Container is the primary business object and aggregate root. Everything relates back to it: revisions, metadata, approvals, relationships, audit events, exchange packages, and transmittals.

A slice is only done when ALL of the following are implemented:
- UI
- API
- Persistence
- Authorization
- Audit Events
- Tests
- Documentation

---

## Delivery Principles

1. Build around the Information Container as the aggregate root
2. Deliver end-to-end business capabilities rather than horizontal technical subsystems
3. Keep OpenProject responsible for platform services (users, groups, roles, permissions, projects, notifications, IFC viewer, BCF workflows)
4. Keep the CDE plugin responsible for governed information behavior (revisions, states, suitability, metadata, approvals, audit, exchange, compliance)
5. Enforce governance rules at the moment of business action, especially before publication

---

## Cross-Cutting Capabilities

### Container Permissions

| Permission | Description |
|-----------|-------------|
| `view_wip_container` | View containers in WIP state |
| `edit_container` | Create/edit containers |
| `share_container` | Share containers with others |
| `approve_container` | Approve containers for publication |
| `publish_container` | Publish containers |
| `archive_container` | Archive published containers |
| `manage_exchange_packages` | Manage exchange packages |

### Audit Infrastructure

Every slice that changes governed information must emit audit records with:
- User
- Object (container/revision)
- Action
- Old value
- New value
- Timestamp
- Reason (where applicable)

### Identifier Governance

Container identifiers must be:
- Unique within a project
- Valid format (field-per-attribute convention)
- Checked before publication

---

## Vertical Slices

### Slice 0: Platform Foundation ✅ COMPLETE

**Status:** COMPLETE

**Included capabilities:**
- Plugin shell inside OpenProject (`modules/cde/`)
- Navigation entry points for container features
- Container database foundation (`cde_containers`, `cde_revisions`, `cde_metadata`, `cde_suitabilities`, `cde_audit_events`)
- Initial persistence model for containers and revisions
- Basic authorization integration with OpenProject roles and permissions
- Audit event infrastructure
- Identifier validation service
- Publication gate service

**Outcome:** Later business slices can be implemented consistently without repeatedly rebuilding the same infrastructure.

---

### Slice 1: Create Information Container in WIP 🔄 IN PROGRESS

**Status:** Backend scaffolded, UI pending

**Included capabilities:**
- Create a container such as a drawing, model, report, or specification
- Enforce unique identifier within a project
- Assign ownership
- Create the initial working revision
- Store minimum required attributes
- Apply project and role-based access control
- Generate audit events for container creation and revision creation
- Expose capability through UI and `/containers` API

**Implementation plan:**
- [x] Model: `Cde::Container` with validations
- [x] Migration: `cde_containers` table
- [x] Service: `Cde::IdentifierValidator`
- [x] API: `API::V3::Cde::ContainersController#create`
- [ ] UI: Angular component for container creation form
- [ ] Permission: `view_wip_container`, `edit_container`
- [ ] Audit: Event emission on create
- [ ] Tests: Request spec, model spec

**Outcome:** Users can create governed project information in WIP with traceability from the beginning.

---

### Slice 2: Manage Working Revision 🔄 PENDING

**Status:** Backend scaffolded, UI pending

**Included capabilities:**
- Edit title, files, and version-aware metadata on the working revision
- Ensure only the active working revision is editable
- Prevent direct editing of published revisions
- Maintain ownership and authorization checks
- Record revision-level audit events for updates

**Implementation plan:**
- [x] Model: `Cde::Revision` with `is_working` flag
- [x] Migration: `cde_revisions` table
- [x] Invariant: Single active working revision enforced
- [ ] API: Update endpoint for revisions
- [ ] UI: Revision editing interface
- [ ] Permission: `edit_container`
- [ ] Audit: Event emission on revision update
- [ ] Tests: Invariant spec, request spec

**Outcome:** Users can safely work on draft information without compromising future publication controls.

---

### Slice 3: Metadata Governance and Search 🔄 PENDING

**Status:** Backend scaffolded, UI pending

**Included capabilities:**
- Metadata entry and editing UI
- Validation for mandatory fields: Discipline, Originator, Classification, Container Type
- Controlled vocabulary for discipline values
- Search by identifier
- Search by title
- Filter by metadata
- Filter by state
- Filter by suitability
- Persist metadata in relation to the container and revision context
- Audit metadata changes

**Implementation plan:**
- [x] Model: `Cde::Metadata` with enums
- [x] Migration: `cde_metadata` table
- [x] Controlled vocabularies in `cde_conventions.yml`
- [ ] API: Metadata CRUD endpoints
- [ ] UI: Metadata editing form
- [ ] Search: Elasticsearch or DB-level search
- [ ] Permission: `edit_container`
- [ ] Audit: Event emission on metadata changes
- [ ] Tests: Validation spec, search spec

**Outcome:** Containers become searchable, structured, and suitable for governance workflows.

---

### Slice 4: Lifecycle State Management 🔄 PENDING

**Status:** Backend scaffolded, UI pending

**Included capabilities:**
- Transition from `WIP → Shared`
- Transition from `Shared → WIP`
- Enforcement of allowed and forbidden transitions
- State-specific permission behavior
- Shared-state review and comment behavior
- Audit trail for state changes

**Implementation plan:**
- [x] State machine: AASM in `Cde::Container`
- [x] States: `wip`, `shared`, `published`, `archived`
- [ ] API: State transition endpoints
- [ ] UI: State transition buttons (Share, Return to WIP)
- [ ] Permission: `share_container`, `view_wip_container`
- [ ] Audit: Event emission on state changes
- [ ] Tests: State transition spec, invariant spec

**Outcome:** Teams can formally move information into review and return it for revision under controlled rules.

---

### Slice 4.5: BIM Context Linking ⏳ PENDING

**Status:** Not started

**Included capabilities:**
- Link container to IFC model
- Link container to model revision
- Display model context from the container view
- Maintain permissions for relationship management
- Audit events for model linked and model unlinked actions

**Implementation plan:**
- [ ] Model: Association with `Bim::IfcModel`
- [ ] API: Link/unlink endpoints
- [ ] UI: Model context display
- [ ] Permission: Integration with Bim module permissions
- [ ] Audit: Event emission on link/unlink
- [ ] Tests: Association spec

**Outcome:** Governed information becomes connected to model context early enough to support review and coordination workflows.

---

### Slice 5: Suitability Assignment 🔄 PENDING

**Status:** Backend scaffolded, UI pending

**Included capabilities:**
- Assign and modify suitability codes
- Support values: `S0`, `S1`, `S2`, `A1`, `A2`, `D1`
- Restrict suitability changes to authorized users
- Display suitability separately from lifecycle state
- Audit every suitability change

**Implementation plan:**
- [x] Model: `Cde::Suitability` with enum
- [x] Migration: `cde_suitabilities` table
- [x] Codes: S0, S1, S2, A1, A2, D1
- [ ] API: Suitability assignment endpoint
- [ ] UI: Suitability selector
- [ ] Permission: `approve_container`
- [ ] Audit: Event emission on suitability assignment
- [ ] Tests: Validation spec, authorization spec

**Outcome:** The system captures intended information use, not just process stage.

---

### Slice 6: Review, Approval and Publication 🔄 PENDING

**Status:** Backend scaffolded, UI pending

**Included capabilities:**
- Review workflow from Shared into approval
- Approval records with approver, decision, date, and comment
- Publication action for approved information
- Publication locking that makes published revisions immutable
- Assignment of latest published revision reference
- Audit events for approval granted, approval rejected, and revision published

**Publication preconditions:**
- Mandatory metadata complete
- Identifier valid
- Suitability assigned and valid
- Required approvals completed

**Implementation plan:**
- [x] Service: `Cde::PublicationGate`
- [x] Preconditions: 4 validation checks
- [ ] Model: `Cde::Approval` (new)
- [ ] API: Approval endpoints, publish endpoint
- [ ] UI: Approval workflow, publish button
- [ ] Permission: `approve_container`, `publish_container`
- [ ] Audit: Event emission for all publication events
- [ ] Tests: Gate spec, approval spec, publication spec

**Outcome:** Information can be formally approved and published as controlled project information.

---

### Slice 7: Revision After Publication ⏳ PENDING

**Status:** Not started

**Included capabilities:**
- Create a new working revision from a published revision
- Preserve the published revision unchanged
- Establish supersession relationship
- Maintain exactly one active working revision
- Display revision lineage and publication history
- Carry forward version-aware metadata where appropriate

**Implementation plan:**
- [ ] API: New revision from published endpoint
- [ ] UI: Revision lineage display
- [ ] Invariant: Published revisions immutable
- [ ] Audit: Event emission on revision creation
- [ ] Tests: Immutability spec, lineage spec

**Outcome:** The system supports iterative revision while preserving full traceability.

---

### Slice 8: BCF Traceability ⏳ PENDING

**Status:** Not started

**Included capabilities:**
- Link BCF issue to container
- Link BCF issue to revision
- Link BCF issue to model revision where appropriate
- Display issue relationships from governed information views
- Audit events for BCF linked and BCF unlinked actions

**Implementation plan:**
- [ ] Model: Association with `Bim::Bcf::Issue`
- [ ] API: Link/unlink endpoints
- [ ] UI: Issue relationship display
- [ ] Permission: Integration with Bim module permissions
- [ ] Audit: Event emission on link/unlink
- [ ] Tests: Association spec

**Outcome:** Issue management becomes traceable against governed information and revision history.

---

### Slice 9: Published Information Consumption 🔄 PENDING

**Status:** Backend scaffolded, UI pending

**Included capabilities:**
- Published information register or list view
- Read access to published revisions
- Download published information
- Reference published information from related workflows
- Show state, suitability, metadata, and revision code
- Search and filtering across published information
- Permission behavior aligned with published-state access rules

**Implementation plan:**
- [x] API: Published containers endpoint
- [ ] UI: Published information register
- [ ] Search: Filter by state, suitability, metadata
- [ ] Permission: `view_wip_container` (read-only for published)
- [ ] Tests: Request spec, search spec

**Outcome:** Published information can be consumed reliably by project participants, including client reviewers.

---

### Slice 10: Archive Lifecycle ⏳ PENDING

**Status:** Not started

**Included capabilities:**
- Transition from `Published → Archived`
- Read-only archived view
- Prevention of invalid transitions out of Archived
- Audit events for archive actions

**Implementation plan:**
- [ ] API: Archive endpoint
- [ ] UI: Archive button, read-only view
- [ ] Permission: `archive_container`
- [ ] Audit: Event emission on archive
- [ ] Tests: State transition spec

**Outcome:** Controlled information can be retired safely while remaining accessible for record purposes.

---

### Slice 11: Exchange Packages ⏳ PENDING

**Status:** Not started

**Included capabilities:**
- Create exchange package
- Assign package identifier
- Select published deliverables
- Record sender and recipients
- Track package issue date and status
- Manage acceptance states: Pending, Accepted, Rejected
- Link exchange packages to source containers
- Audit package delivery actions

**Implementation plan:**
- [ ] Model: `Cde::ExchangePackage`
- [ ] Migration: `cde_exchange_packages` table
- [ ] API: Exchange package CRUD
- [ ] UI: Package creation and management
- [ ] Permission: `manage_exchange_packages`
- [ ] Audit: Event emission on package actions
- [ ] Tests: Full workflow spec

**Outcome:** The platform supports formal structured information exchange, not just internal publication.

---

### Slice 12: Transmittals ⏳ PENDING

**Status:** Not started

**Included capabilities:**
- Create transmittal with number, sender, recipients, issue date, and container list
- Link transmittal to exchange package where applicable
- Maintain auditable and searchable transmittal history
- Expose traceable delivery records in the UI and API

**Implementation plan:**
- [ ] Model: `Cde::Transmittal`
- [ ] Migration: `cde_transmittals` table
- [ ] API: Transmittal CRUD
- [ ] UI: Transmittal creation and display
- [ ] Permission: `manage_exchange_packages`
- [ ] Audit: Event emission on transmittal actions
- [ ] Tests: Full workflow spec

**Outcome:** Project deliveries are formally recorded with full traceability.

---

### Slice 13: Compliance Rules ⏳ PENDING

**Status:** Not started

**Included capabilities:**
- Check duplicate identifier
- Check missing metadata
- Check missing approval
- Check invalid state
- Check invalid suitability
- Check broken relationships
- Expose rule results for drill-down and correction workflows

**Implementation plan:**
- [ ] Service: `Cde::ComplianceChecker`
- [ ] API: Compliance check endpoint
- [ ] UI: Compliance dashboard widget
- [ ] Audit: Rule evaluation logging
- [ ] Tests: Rule spec, check spec

**Outcome:** Governance issues are automatically detected rather than discovered manually.

---

### Slice 14: Governance Dashboards ⏳ PENDING

**Status:** Not started

**Included capabilities:**
- Dashboard metrics for published containers
- Dashboard metrics for pending reviews
- Dashboard metrics for unauthorized access attempts
- Dashboard metrics for revision statistics
- Dashboard metrics for metadata completion rate
- Dashboard metrics for exchange status
- Exportable views and KPI reporting

**Implementation plan:**
- [ ] Service: `Cde::DashboardMetrics`
- [ ] API: Dashboard metrics endpoint
- [ ] UI: Dashboard views
- [ ] Export: CSV/PDF export
- [ ] Tests: Metrics spec, aggregation spec

**Outcome:** Governance quality becomes measurable and visible to project leadership.

---

## Recommended MVP Scope

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

## OpenProject Alignment

| Responsibility | Owner |
|---------------|-------|
| Users, Groups, Roles, Permissions | OpenProject |
| Projects | OpenProject |
| Notifications | OpenProject |
| IFC Viewer | OpenProject (`modules/bim`) |
| BCF Workflows | OpenProject (`modules/bim`) |
| Information Containers | CDE Plugin |
| Revisions | CDE Plugin |
| Lifecycle States | CDE Plugin |
| Suitability | CDE Plugin |
| Metadata Governance | CDE Plugin |
| Approval Workflows | CDE Plugin |
| Audit Trail | CDE Plugin |
| Exchange Packages | CDE Plugin |
| Transmittals | CDE Plugin |
| Compliance Reporting | CDE Plugin |

---

## Source

- `OpenProject_CDE_Domain_Architecture_Specification_v1.txt`
- `playground_exported_message.docx` (revised markdown export)
