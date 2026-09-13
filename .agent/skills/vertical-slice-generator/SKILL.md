---
name: vertical-slice-generator
description: Orchestrates the creation of a full FastAPI slice (Model -> Schema -> Service -> Endpoint -> UI).
---

# Vertical Slice Generator

This skill coordinates the creation of a complete vertical slice in the `backend/` and `frontend/` directories. It is the most powerful generator for building entire features (e.g., Tool 1-5, CRM).

## When to use this skill
- Implementing a new functional area or major feature expansion.
- Scaffolding a feature with database, business logic, and API endpoints.
- Building a complete UI module in Next.js connected to the backend.

## How to use this skill

### Step 1: Research & Planning
Review the architecture in `infra/planning/smart_mvp_spec_v4.md` and the build order in `infra/planning/build-order.md`. Determine the resource name and required permissions.

### Step 2: Database Migration
Use `database-migration-creator` to create the SQLAlchemy model and Alembic migration.
- Path: `backend/app/models/<resource>.py`

### Step 3: Pydantic Schemas & Service Layer
Define request/response schemas and implement business logic, validation, and client isolation in the service layer.
- Schemas: `backend/app/schemas/<resource>.py`
- Service: `backend/app/services/<resource>_service.py`

### Step 4: API Endpoints
Use `api-endpoint-generator` to create the FastAPI router with proper RBAC decorators.
- Path: `backend/app/api/v1/endpoints/<resource>.py`

### Step 5: Frontend Components
Use `frontend-component-generator` to build the corresponding UI in Next.js.
- Path: `frontend/app/(client)/<resource>/page.tsx` or `frontend/components/`

### Step 6: Hybrid QA Verification
Execute the `hybrid-qa-operations` skill. This involves running automated integration tests for the new slice and a Subagent UX audit. Verification is not complete until both passes are documented in a walkthrough.

## Success Criteria
- The functional slice is complete and fully operational from DB to UI.
- All code follows the principles defined in `AGENTS.md` and `infra/verticalslice.md`.
- Documentation in the project state is updated via the `progress-tracker` skill.
- Hybrid QA pass is documented.
