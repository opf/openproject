---
name: api-endpoint-generator
description: Generates FastAPI endpoint/router files from existing SQLAlchemy models and service classes. Creates complete REST endpoints with proper RBAC decorators, error handling, and HTTP status codes. Use when you have a model and service but need to create API endpoints, or when adding additional endpoint variants (admin, read-only, bulk operations).
---

# API Endpoint Generator

This skill generates FastAPI endpoint files following the ESG Sustainify patterns, assuming you already have:
- SQLAlchemy ORM model
- Pydantic schemas (Create, Update, Response)
- Service layer class with business logic

## When to use this skill

- **Model exists, need endpoints**: You've created a model and service, now need the REST API
- **Multiple endpoint variants**: Need different endpoint files for same model (admin vs regular, read-only vs full CRUD)
- **Add endpoints to existing model**: Retrofit REST API to older vertical slices
- **Ensure pattern consistency**: Guarantees all endpoints follow ESG conventions (deps.py, permissions, error handling)
- **Scale endpoints faster**: Generate base endpoints, then customize

## How to use this skill

### Step 1: Verify prerequisites

Ensure these files already exist:
- `backend/app/models/<model_name>.py` - SQLAlchemy model
- `backend/app/schemas/<schema_name>.py` - Pydantic schemas with Create, Update, response models
- `backend/app/services/<service_name>_service.py` - Service class with business logic methods

### Step 2: Run the generator

```bash
python .agent/skills/api-endpoint-generator/scripts/generate_endpoint.py
```

The script will prompt for:

**Model Information:**
- Model name (PascalCase): e.g., "ClientCompany", "ToolAccess"
- Service name (snake_case): e.g., "client_company", "tool_access"

**Endpoint Configuration:**
- Permission resource (for RBAC): e.g., "clients", "tools"
- Base path prefix: e.g., "/clients", "/company", "/tools"
- Endpoint type: "full-crud", "list-only", "admin", "read-only"

### Step 3: Review generated endpoint file

The script creates:
```
backend/app/api/v1/endpoints/<service_name>.py
```

Or for variants:
```
backend/app/api/v1/endpoints/<service_name>_admin.py
backend/app/api/v1/endpoints/<service_name>_readonly.py
backend/app/api/v1/endpoints/<service_name>_bulk.py
```

### Step 4: Integrate endpoint into main router

Add the new endpoint to `backend/app/main.py`:

```python
from app.api.v1.endpoints import client_company
from app.api.v1.endpoints import client_company_admin  # if creating admin variant

app.include_router(client_company.router, prefix="/api/v1")
app.include_router(client_company_admin.router, prefix="/api/v1")
```

### Step 5: Customize and test

- [ ] Review permission scopes - adjust with `require_permission()`
- [ ] Add validation logic in service layer
- [ ] Verify error messages are helpful
- [ ] Test each endpoint manually
- [ ] Write integration tests

## Endpoint Types

### Full CRUD
Complete REST API for the model:
- `POST /` - Create (requires `{resource}.create` permission)
- `GET /` - List all (requires `{resource}.read` permission)
- `GET /{id}` - Get single (requires `{resource}.read` permission)
- `PUT /{id}` - Update (requires `{resource}.update` permission)
- `DELETE /{id}` - Delete (requires `{resource}.delete` permission)

### List Only
Read-only endpoints:
- `GET /` - List all (requires `{resource}.read` permission)
- `GET /{id}` - Get single (requires `{resource}.read` permission)

### Admin
Admin-only operations (applies `require_staff()` to all):
- Full CRUD endpoints
- All require staff/admin role
- `POST /{id}/approve` - Custom admin operations
- `POST /{id}/reject` - Custom admin operations

### Read Only
Simple read endpoint (no modifications):
- `GET /` - List all
- `GET /{id}` - Get single

## Generated File Pattern

### Full CRUD Endpoint

```python
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db, get_current_active_user, require_permission
from app.middleware.auth import User
from app.models import <Model>
from app.schemas import <Schema>Create, <Schema>Update, <Schema>
from app.services import <service>_service

router = APIRouter(
    prefix="/<path>",
    tags=["<resource>"],
)

@router.post(
    "/",
    response_model=<Schema>,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_permission("<resource>.create"))],
)
async def create_<service>(
    data: <Schema>Create,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Create a new <resource>."""
    return await <service>_service.create_<service>(db, data, current_user)

# ... GET, PUT, DELETE endpoints
```

### Permission Pattern

Every endpoint uses the Conventional Commit RBAC pattern:
```
{resource}.{action}

Examples:
- clients.create
- clients.read
- clients.update
- clients.delete
- tools.execute.all
- users.manage.own_company
```

### Status Codes

- `201 Created` - POST successful
- `200 OK` - GET, PUT successful
- `204 No Content` - DELETE successful
- `400 Bad Request` - Validation error
- `401 Unauthorized` - No auth token
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource doesn't exist
- `500 Internal Server Error` - Unexpected error

## Service Layer Requirements

Your service class must have these methods (generated endpoint calls them):

```python
class <Model>Service:
    @staticmethod
    async def create_<service>(db: AsyncSession, data: <Schema>Create, user: User):
        ...
    
    @staticmethod
    async def get_<service>(db: AsyncSession, id: int, user: User):
        ...
    
    @staticmethod  
    async def list_<service>(db: AsyncSession, user: User, skip: int, limit: int):
        ...
    
    @staticmethod
    async def update_<service>(db: AsyncSession, id: int, data: <Schema>Update, user: User):
        ...
    
    @staticmethod
    async def delete_<service>(db: AsyncSession, id: int, user: User):
        ...
```

The service methods handle:
- Business logic and validation
- Client isolation filtering
- Error handling
- Logging

## Constraints

- **File size** - Keep endpoint files < 200 LOC
- **Delegation** - All logic in service layer, not endpoints
- **Permissions** - Every mutating operation requires `require_permission()`
- **Errors** - Return HTTPException with status codes, not raw errors
- **Documentation** - Each endpoint has docstring explaining purpose
- **Async** - All dependencies use async/await

## Variants Explained

### When to Create Multiple Endpoint Files

**Example: Client Company Management**

1. **clients.py** (Full CRUD)
   - Regular staff access
   - Create, Read, Update, Delete
   - Permissions: clients.create, clients.read, clients.update, clients.delete

2. **clients_readonly.py** (Read Only)
   - For consultant role
   - Only GET endpoints
   - No permissions required (all consultants can read)

3. **clients_admin.py** (Admin Only)
   - For super admin
   - Needs `require_super_admin()` on all
   - Bulk operations, force delete, reset data

All three mounted on different prefixes or same router with different tags.

## Integration Example

After generating `clients.py`:

```python
# backend/app/main.py
from app.api.v1.endpoints import (
    clients,
    clients_readonly,
    clients_admin,
)

app.include_router(clients.router, prefix="/api/v1", tags=["Clients"])
app.include_router(clients_readonly.router, prefix="/api/v1", tags=["Clients - Read Only"])
app.include_router(clients_admin.router, prefix="/api/v1", tags=["Admin - Clients"])
```

This creates separate API sections:
- `/api/v1/clients/` - Full CRUD
- `/api/v1/clients/` - Read only (different endpoints)
- `/api/v1/clients/admin/` - Admin operations

## Common Customizations

### Add Filtering

```python
@router.get("/", response_model=list[ClientSchema])
async def list_clients(
    skip: int = 0,
    limit: int = 100,
    industry: Optional[str] = None,  # Add filter
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """List clients (with optional industry filter)."""
    return await client_service.list_clients_filtered(
        db, current_user, skip, limit, industry=industry
    )
```

### Add Bulk Operations

```python
@router.post("/bulk", response_model=list[ClientSchema])
async def bulk_create_clients(
    data: list[ClientCreate],
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Create multiple clients at once."""
    return await client_service.bulk_create_clients(db, data, current_user)
```

### Add Export

```python
@router.get("/export")
async def export_clients(
    format: str = "json",  # json, csv
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Export clients in specified format."""
    data = await client_service.list_clients(db, current_user)
    if format == "csv":
        return generate_csv(data)
    return data
```

## Important Notes

- Generator assumes service methods exist (it doesn't create them)
- Verify model/schema names before running
- Generated code follows ESG conventions but may need tweaks for your specific:
  - Permission scopes
  - Filter logic
  - Sorting options
  - Pagination defaults
- Always test endpoints before committing
- Use integration tests to verify end-to-end flow

## Next Steps

After generation:

1. Verify endpoint import works: `from app.api.v1.endpoints import <service>`
2. Add router to `app/main.py` with `app.include_router()`
3. Test with API client (curl, Postman, Insomnia):
   ```bash
   POST /api/v1/<path>/ -H "Authorization: Bearer $TOKEN" -d '{"field": "value"}'
   GET /api/v1/<path>/
   PUT /api/v1/<path>/1 -d '{"field": "updated"}'
   DELETE /api/v1/<path>/1
   ```
4. Write integration tests in `backend/tests/`
5. Verify permissions are correct for your RBAC setup

## See Also

- `vertical-slice-generator` - If you need model + service + endpoint all at once
- `test-runner` - For testing your endpoints
- `permission-validator` - To audit RBAC coverage
