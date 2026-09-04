---
name: fastapi-vertical-slice-generator
description: Orchestrates the creation of a full FastAPI slice (Model -> Schema -> Service -> Endpoint) in one workflow.
---

# FastAPI Vertical Slice Generator

This skill coordinates the creation of a complete vertical slice in the `backend/` and `frontend/` directories. It follows the principles defined in `infra/verticalslice.md`.

## When to use this skill
- Implementing a new functional area (e.g., Client Portal, Tool 1-5).
- Scaffolding a feature with database, business logic, and API endpoints.
- Ensuring consistency across the Service Layer Pattern.

## How to use this skill

### Step 1: Research & Planning
Review the architecture in `infra/planning/smart_mvp_spec_v4.md` and the build order in `infra/planning/build-order.md`. Determine the resource name and required permissions.

### Step 2: Database Migration
Use `database-migration-creator` to create the SQLAlchemy model and Alembic migration.
- Path: `backend/app/models/<resource>.py`

### Step 3: Pydantic Schemas
Define request/response schemas.
- Path: `backend/app/schemas/<resource>.py`

### Step 4: Service Layer
Implement business logic, validation, and client isolation in the service layer.
- Path: `backend/app/services/<resource>_service.py`

### Step 5: API Endpoints
Use `api-endpoint-generator` to create the FastAPI router.
- Path: `backend/app/api/v1/endpoints/<resource>.py`

### Step 6: Frontend Components
Use `frontend-component-generator` to build the corresponding UI in Next.js.
- Path: `frontend/app/(staff)/<resource>/page.tsx` or `frontend/components/`

## Success Criteria
- The feature is fully functional from DB to UI.
- Client isolation is enforced in all queries.
- RBAC decorators are applied to all endpoints.
- Verification tests are passing.
