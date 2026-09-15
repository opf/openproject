# Example: Multiple Endpoint Variants

This example shows how to generate multiple endpoint variants for the same model.

## Scenario: Client Company - Multiple Perspectives

You have one `ClientCompany` model but need endpoints for different roles:

1. **Regular Staff** - Full CRUD (create, read, update, delete)
2. **Consultants** - Read-only (analyze clients)
3. **Super Admin** - Admin-only (force operations, reset data)

## Generation Workflow

### Round 1: Full CRUD for Staff

```
Model name: ClientCompany
Service name: client_company
Schema name: ClientCompany
Resource: clients
Path: /clients
Type: full-crud
→ Generates: backend/app/api/v1/endpoints/client_company.py
```

### Round 2: Read-Only for Consultants

```
Model name: ClientCompany
Service name: client_company
Schema name: ClientCompany
Resource: clients
Path: /clients
Type: read-only
→ Generates: backend/app/api/v1/endpoints/client_company_readonly.py
```

### Round 3: Admin for Super Admin

```
Model name: ClientCompany
Service name: client_company
Schema name: ClientCompany
Resource: clients
Path: /clients
Type: admin
→ Generates: backend/app/api/v1/endpoints/client_company_admin.py
```

## File Structure After Generation

```
backend/app/api/v1/endpoints/
├── client_company.py          (full CRUD)
├── client_company_readonly.py (read-only)
└── client_company_admin.py    (admin-only)
```

## Integration in Main Router

**File**: `backend/app/main.py`

```python
from app.api.v1.endpoints import (
    client_company,
    client_company_readonly,
    client_company_admin,
)

# Register endpoints with different tags for clarity
app.include_router(
    client_company.router,
    prefix="/api/v1",
    tags=["Clients - Full CRUD"],
)

app.include_router(
    client_company_readonly.router,
    prefix="/api/v1",
    tags=["Clients - Read Only (Consultants)"],
)

app.include_router(
    client_company_admin.router,
    prefix="/api/v1",
    tags=["Admin - Clients"],
)
```

## API Documentation Structure

After registration, your API docs show:

```
Clients - Full CRUD
  POST   /api/v1/clients/
  GET    /api/v1/clients/
  GET    /api/v1/clients/{id}
  PUT    /api/v1/clients/{id}
  DELETE /api/v1/clients/{id}

Clients - Read Only (Consultants)
  GET    /api/v1/clients/
  GET    /api/v1/clients/{id}

Admin - Clients
  POST   /api/v1/clients/admin/
  GET    /api/v1/clients/admin/
  PUT    /api/v1/clients/admin/{id}
  DELETE /api/v1/clients/admin/{id}
```

## Full CRUD Endpoint

**File**: `client_company.py`

```python
@router.post("/", dependencies=[Depends(require_permission("clients.create"))])
async def create_client_company(data: ClientCompanyCreate, ...):
    """Create new client. Requires: clients.create permission"""

@router.get("/", dependencies=[Depends(require_permission("clients.read"))])
async def list_client_company(...):
    """List all clients. Requires: clients.read permission"""

@router.get("/{client_company_id}", dependencies=[Depends(require_permission("clients.read"))])
async def get_client_company(...):
    """Get specific client. Requires: clients.read permission"""

@router.put("/{client_company_id}", dependencies=[Depends(require_permission("clients.update"))])
async def update_client_company(...):
    """Update client. Requires: clients.update permission"""

@router.delete("/{client_company_id}", dependencies=[Depends(require_permission("clients.delete"))])
async def delete_client_company(...):
    """Delete client. Requires: clients.delete permission"""
```

## Read-Only Endpoint

**File**: `client_company_readonly.py`

```python
@router.get("/", dependencies=[Depends(require_permission("clients.read"))])
async def list_client_company(...):
    """List all clients (read-only). Requires: clients.read permission"""

@router.get("/{client_company_id}", dependencies=[Depends(require_permission("clients.read"))])
async def get_client_company(...):
    """Get specific client (read-only). Requires: clients.read permission"""
```

**Note**: Path is same `/clients/` but different endpoint functions to avoid conflicts.

## Admin Endpoint

**File**: `client_company_admin.py`

```python
@router.post("/admin/", dependencies=[Depends(require_staff())])
async def admin_create_client_company(...):
    """Create client (admin only). Requires: Staff role"""

@router.get("/admin/", dependencies=[Depends(require_staff())])
async def admin_list_client_company(...):
    """List all clients (admin). Requires: Staff role"""

@router.get("/admin/{client_company_id}", dependencies=[Depends(require_staff())])
async def admin_get_client_company(...):
    """Get client (admin). Requires: Staff role"""

@router.put("/admin/{client_company_id}", dependencies=[Depends(require_staff())])
async def admin_update_client_company(...):
    """Update client (admin). Requires: Staff role"""

@router.delete("/admin/{client_company_id}", dependencies=[Depends(require_staff())])
async def admin_delete_client_company(...):
    """Delete client (admin). Requires: Staff role"""
```

**Note**: Path is `/clients/admin/` to separate from regular endpoints.

## API Access by Role

### Super Admin User
- Can access: Full CRUD + Admin endpoints
- Permissions: All clients.* permissions + staff role
- Endpoints available:
  - `/api/v1/clients/` (full CRUD)
  - `/api/v1/clients/admin/` (admin operations)

### Staff/Consultant User
- Can access: Read-only + optionally CRUD if consultant-with-edit role
- Permissions: clients.read (minimum)
- Endpoints available:
  - `/api/v1/clients/` (read-only via readonly endpoint)
  - OR `/api/v1/clients/` (full CRUD via regular endpoint if has permissions)

### Client User
- Can NOT access client management endpoints
- These are staff-only resources

## Testing Multiple Variants

```bash
# Test CRUD endpoint (requires clients.create)
curl -X POST http://localhost:8000/api/v1/clients/ \
  -H "Authorization: Bearer $STAFF_TOKEN" \
  -d '{...}'

# Test read-only (consultants can use this)
curl http://localhost:8000/api/v1/clients/ \
  -H "Authorization: Bearer $CONSULTANT_TOKEN"

# Test admin (super admin only)
curl -X PUT http://localhost:8000/api/v1/clients/admin/1 \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{...}'
```

## Use Cases for Variants

### 1. Audit Logging
```
Full CRUD: Users.create, users.update, users.delete log all changes
Admin: Force-delete, reset data operations have special logging
```

### 2. Read-Only for Analytics
```
customer_analytics_readonly.py for data analysts
Only GET endpoints, no /admin paths
Simpler responses (subset of fields)
```

### 3. Bulk Operations
```
clients_bulk.py variant
POST /clients/bulk/ - create multiple
DELETE /clients/bulk/ - delete multiple
PUT /clients/bulk/ - update multiple
```

### 4. Public API
```
clients_public.py endpoint
Limited fields (no internal_notes, no created_by, etc.)
No create/update/delete
Only public company information
```

### 5. Export/Reporting
```
clients_export.py variant
GET /clients/export?format=csv - CSV export
GET /clients/export?format=json - JSON export
POST /clients/export/scheduled - Schedule export
```

## Best Practices

✅ **Do:**
- Use separate endpoint files for different access patterns
- Include endpoint type in filename (readonly, admin, public, bulk)
- Document which role can access which endpoint
- Test each variant independently
- Use appropriate RBAC decorators (require_permission vs require_staff)

❌ **Don't:**
- Put multiple resource types in one endpoint file
- Mix CRUD and admin operations in same endpoint
- Use different service names for same model endpoints
- Create more than 4-5 variants for one model

## Naming Convention

```
{service_name}.py                  Full CRUD (default)
{service_name}_readonly.py         Read-only
{service_name}_admin.py            Admin-only
{service_name}_public.py           Public/unauthenticated
{service_name}_bulk.py             Bulk operations
{service_name}_export.py           Export/reporting
```

## Commit All Variants

```bash
git add backend/app/api/v1/endpoints/client_company*.py
git commit -m "feat(api): add client company endpoints - full CRUD, read-only, admin variants"
```
