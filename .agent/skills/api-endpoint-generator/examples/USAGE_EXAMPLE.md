# Example: API Endpoint Generation

This example demonstrates generating FastAPI endpoints for an existing model/service.

## Scenario

You've already created:
- ✓ `backend/app/models/client_company.py` (SQLAlchemy model)
- ✓ `backend/app/schemas/client_company.py` (Pydantic schemas)
- ✓ `backend/app/services/client_company_service.py` (business logic)

Now you need the REST API endpoints.

## User Interaction

```bash
$ python .agent/skills/api-endpoint-generator/scripts/generate_endpoint.py

======================================================================
  API ENDPOINT GENERATOR - ESG Sustainify
======================================================================

This tool generates FastAPI endpoint files from existing models/services.

Prerequisites:
  ✓ backend/app/models/<model>.py exists
  ✓ backend/app/schemas/<schema>.py exists
  ✓ backend/app/services/<service>_service.py exists

STEP 1: Model & Service Information
----------------------------------------------------------------------
Model name (PascalCase, e.g., 'ClientCompany'): ClientCompany
Service name (snake_case, e.g., 'client_company'): client_company
Schema name (PascalCase, or leave blank for ClientCompany) [ClientCompany]: (press Enter)

STEP 2: Endpoint Configuration
----------------------------------------------------------------------
Permission resource (for RBAC, e.g., 'clients', 'tools'): clients
Base path prefix (e.g., '/clients', '/company') [/client_company]: /clients
Endpoint type:
  1. full-crud
  2. read-only
  3. list-only
  4. admin
Select (number): 1

======================================================================
  GENERATING ENDPOINT
======================================================================

📁 full-crud endpoint...
   ✓ client_company.py

======================================================================
  SUMMARY
======================================================================

Model: ClientCompany
Service: client_company
Resource: clients
Path: /clients
Type: full-crud
File: backend/app/api/v1/endpoints/client_company.py

Proceed with generation? (yes/no): yes

======================================================================
  FILE GENERATED
======================================================================

✓ backend/app/api/v1/endpoints/client_company.py

======================================================================
  NEXT STEPS
======================================================================

1. Verify the endpoint file was created:
   → backend/app/api/v1/endpoints/client_company.py

2. Verify prerequisites exist:
   → Model: backend/app/models/client_company.py
   → Schema: backend/app/schemas/client_company.py
   → Service: backend/app/services/client_company_service.py

3. Register endpoint in main router:
   → Edit: backend/app/main.py
   → Add:
      from app.api.v1.endpoints import client_company
      app.include_router(
          client_company.router,
          prefix="/api/v1",
      )

4. Test the endpoint...
```

## Generated File

**File**: `backend/app/api/v1/endpoints/client_company.py`

```python
"""API endpoints for ClientCompany."""

from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import APIRouter, Depends, HTTPException, status

from app.api.deps import get_db, get_current_active_user, require_permission
from app.middleware.auth import User
from app.models import ClientCompany
from app.schemas import ClientCompanyCreate, ClientCompanyUpdate, ClientCompany
from app.services import client_company_service

router = APIRouter(
    prefix="/clients",
    tags=["clients"],
)


@router.post(
    "/",
    response_model=ClientCompany,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_permission("clients.create"))],
)
async def create_client_company(
    data: ClientCompanyCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> ClientCompany:
    """
    Create a new ClientCompany.
    
    Requires: clients.create permission
    """
    return await client_company_service.create_client_company(db, data, current_user)


@router.get(
    "/{client_company_id}",
    response_model=ClientCompany,
    dependencies=[Depends(require_permission("clients.read"))],
)
async def get_client_company(
    client_company_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> ClientCompany:
    """
    Retrieve a specific ClientCompany.
    
    Requires: clients.read permission
    Returns: 404 if not found
    """
    instance = await client_company_service.get_client_company(
        db, client_company_id, current_user
    )
    if not instance:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="ClientCompany not found",
        )
    return instance


@router.get(
    "/",
    response_model=list[ClientCompany],
    dependencies=[Depends(require_permission("clients.read"))],
)
async def list_client_company(
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> list[ClientCompany]:
    """
    List ClientCompany instances.
    
    Requires: clients.read permission
    Query Parameters:
        skip: Number of records to skip (default: 0)
        limit: Maximum records to return (default: 100)
    """
    return await client_company_service.list_client_company(
        db, current_user, skip, limit
    )


@router.put(
    "/{client_company_id}",
    response_model=ClientCompany,
    dependencies=[Depends(require_permission("clients.update"))],
)
async def update_client_company(
    client_company_id: int,
    data: ClientCompanyUpdate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> ClientCompany:
    """
    Update a ClientCompany.
    
    Requires: clients.update permission
    Returns: 404 if not found
    """
    instance = await client_company_service.update_client_company(
        db, client_company_id, data, current_user
    )
    if not instance:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="ClientCompany not found",
        )
    return instance


@router.delete(
    "/{client_company_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    dependencies=[Depends(require_permission("clients.delete"))],
)
async def delete_client_company(
    client_company_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> None:
    """
    Delete a ClientCompany.
    
    Requires: clients.delete permission
    Returns: 404 if not found
    """
    success = await client_company_service.delete_client_company(
        db, client_company_id, current_user
    )
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="ClientCompany not found",
        )
```

## Integration into Main Router

**File**: `backend/app/main.py`

```python
from fastapi import FastAPI

# ... other imports
from app.api.v1.endpoints import client_company  # NEW

app = FastAPI()

# ... middleware setup

# Register routers
app.include_router(
    client_company.router,
    prefix="/api/v1",
)

# ... other route registrations
```

## Testing the Endpoint

Using curl or API client:

### Create
```bash
curl -X POST http://localhost:8000/api/v1/clients/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"company_name": "Acme Corp", "industry": "Technology"}'
```

Response (201 Created):
```json
{
  "id": 1,
  "company_name": "Acme Corp",
  "industry": "Technology",
  "created_at": "2026-02-27T15:30:00",
  "updated_at": "2026-02-27T15:30:00",
  "created_by": 5
}
```

### List
```bash
curl http://localhost:8000/api/v1/clients/ \
  -H "Authorization: Bearer $TOKEN"
```

Response (200 OK):
```json
[
  {
    "id": 1,
    "company_name": "Acme Corp",
    "industry": "Technology",
    "created_at": "2026-02-27T15:30:00",
    "updated_at": "2026-02-27T15:30:00",
    "created_by": 5
  }
]
```

### Get Single
```bash
curl http://localhost:8000/api/v1/clients/1 \
  -H "Authorization: Bearer $TOKEN"
```

### Update
```bash
curl -X PUT http://localhost:8000/api/v1/clients/1 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"industry": "Consulting"}'
```

### Delete
```bash
curl -X DELETE http://localhost:8000/api/v1/clients/1 \
  -H "Authorization: Bearer $TOKEN"
```

Response (204 No Content): Empty

## Permission Reference

Permissions used in the endpoint:
- `clients.create` - POST /clients/
- `clients.read` - GET /clients/, GET /clients/{id}
- `clients.update` - PUT /clients/{id}
- `clients.delete` - DELETE /clients/{id}

These must exist in your `permissions` table. Update as needed for your specific RBAC setup.

## Endpoint Variants

### Read-Only Variant
If you wanted read-only endpoints only:
- Generate with type: "read-only"
- Filename: `client_company_readonly.py`
- Only GET endpoints included

### Admin Variant
For admin-only operations:
- Generate with type: "admin"
- Filename: `client_company_admin.py`
- Path: /clients/admin
- All endpoints require `require_staff()`

### List-Only Variant
For endpoints with no detail view:
- Generate with type: "list-only"
- Filename: `client_company_list.py`
- Only GET / endpoint (no GET /{id})

## Customization Examples

### Add Filtering

```python
@router.get("/", response_model=list[ClientCompany])
async def list_client_company(
    skip: int = 0,
    limit: int = 100,
    industry: Optional[str] = None,  # NEW FILTER
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> list[ClientCompany]:
    """List ClientCompany instances with optional industry filter."""
    return await client_company_service.list_client_company_filtered(
        db, current_user, skip, limit, industry
    )
```

### Add Bulk Operations

```python
@router.post(
    "/bulk",
    response_model=list[ClientCompany],
    dependencies=[Depends(require_permission("clients.create"))],
)
async def bulk_create_clients(
    data: list[ClientCompanyCreate],
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> list[ClientCompany]:
    """Create multiple ClientCompany instances."""
    return await client_company_service.bulk_create_client_company(db, data, current_user)
```

### Add Search

```python
@router.get("/search/{query}")
async def search_clients(
    query: str,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> list[ClientCompany]:
    """Search ClientCompany by name or industry."""
    return await client_company_service.search_client_company(db, current_user, query)
```

## Checklist

Before committing:

- [ ] Endpoint file created in correct location
- [ ] Model, schema, service imports resolve
- [ ] Registered in backend/app/main.py
- [ ] Test all HTTP methods manually
- [ ] Verify permissions are correct
- [ ] Check error messages are helpful
- [ ] Add integration tests in backend/tests/
- [ ] Commit: `git add backend/app/api/v1/endpoints/client_company.py`
