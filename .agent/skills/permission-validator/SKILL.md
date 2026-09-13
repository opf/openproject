---
name: permission-validator
description: Audits FastAPI endpoints for RBAC coverage, validates permission decorators, checks for missing permission checks, and suggests fixes for security gaps. Identifies client isolation violations and permission misconfigurations in ESG Sustainify endpoints. Use when reviewing endpoints for security or adding new features.
---

# Permission Validator

This skill audits endpoints to ensure complete RBAC coverage and client isolation enforcement.

## When to use this skill

- Security review: "Check for missing permission decorators"
- New endpoints: "Validate RBAC on these endpoints"
- Audit: "Find all endpoints without client isolation"
- Regression: "Verify no permission checks were removed"
- Planning: "What permissions does this feature need?"

## How to use this skill

### Step 1: Run validator

```bash
python .agent/skills/permission-validator/scripts/validate_permissions.py
```

Options:
- **Audit all** - Check all endpoints
- **Specific file** - Check one endpoint file
- **Find missing** - Find endpoints without permission checks
- **Client isolation** - Audit client filtering

### Step 2: Review findings

Output shows:
- Endpoints with permission checks ✅
- Endpoints missing checks ⚠️
- Potential security gaps ❌
- Client isolation status
- Recommendations ℹ️

### Step 3: Fix issues

For each finding:
1. Review the endpoint code
2. Add missing `require_permission()` decorators
3. Add client isolation filtering in service
4. Re-run validator to confirm

## RBAC Pattern

Every mutating endpoint should have permission check:

```python
@router.post(
    "/",
    dependencies=[Depends(require_permission("clients.create"))],  # ← REQUIRED
)
async def create_client(...):
    ...
```

Read endpoints can be less restrictive:

```python
@router.get(
    "/",
    dependencies=[Depends(require_permission("clients.read"))],  # ← STILL needed
)
async def list_clients(...):
    ...
```

## Permission Naming

Pattern: `{resource}.{action}.{scope}`

| Pattern | Example | Meaning |
|---------|---------|---------|
| `resource.action` | `clients.create` | Create clients |
| `resource.action.scope` | `users.manage.own_company` | Manage own company users |
| `resource.action.all` | `tools.execute.all` | Execute all tools |

## Validator Output Example

```
========================================
RBAC AUDIT - ESG Sustainify Endpoints
========================================

OVERALL SECURITY SCORE: ⚠️ 78%

✅ PROTECTED ENDPOINTS (23/30)

backend/app/api/v1/endpoints/clients.py:
  ✅ POST   / → require_permission("clients.create")
  ✅ GET    / → require_permission("clients.read")
  ✅ GET    /{id} → require_permission("clients.read")
  ✅ PUT    /{id} → require_permission("clients.update")
  ✅ DELETE /{id} → require_permission("clients.delete")

⚠️ UNPROTECTED ENDPOINTS (4/30)

backend/app/api/v1/endpoints/tools.py:
  ❌ GET    /public → NO PERMISSION CHECK
     Recommendation: Add require_permission("tools.read.public")
     
  ❌ POST   /batch → NO PERMISSION CHECK
     Recommendation: Add require_permission("tools.execute.batch")

backend/app/api/v1/endpoints/audit.py:
  ⚠️ POST   / → Uses require_staff() instead of fine-grained permission
     Recommendation: Change to require_permission("audit.log.create")

🔒 CLIENT ISOLATION AUDIT

✅ ISOLATED (15/20)

backend/app/api/v1/endpoints/clients.py:
  ✅ list_clients() → Filters by user.client_company_id ✓

❌ NOT ISOLATED (5/20)

backend/app/api/v1/endpoints/tools.py:
  ❌ get_tool() → Missing client_company_id filter
     Issue: Client users could access other companies' tools
     Fix: Add to service: 
       if user.user_type == "client_user":
           query = query.where(Tool.client_company_id == user.client_company_id)

backend/app/api/v1/endpoints/contacts.py:
  ❌ list_contacts() → Missing WHERE clause
     Issue: Client users see all company contacts
     Fix: Service should filter by company

📋 DETAILED FINDINGS

1. CRITICAL - Unprotected audit endpoint
   File: backend/app/api/v1/endpoints/audit.py:15
   Endpoint: POST /audit/
   Issue: No permission check - anyone can create audit logs
   Risk: High - audit trail compromise
   Fix: Add @require_permission("audit.log.create")
   Priority: P0 (fix immediately)

2. HIGH - Missing client isolation in tools
   File: backend/app/api/v1/endpoints/tools.py:42
   Endpoint: GET /tools/{id}
   Issue: Client queries not filtered by company
   Risk: Information disclosure across companies
   Fix: Add service-layer filtering (3 lines)
   Priority: P1 (fix before next release)

3. MEDIUM - Inconsistent permission naming
   File: backend/app/api/v1/endpoints/users.py:8-15
   Issue: Uses "user_admin" instead of "users.manage"
   Risk: Permission names not following convention
   Fix: Rename for consistency (refactor 2 endpoints)
   Priority: P2 (fix in tech debt sprint)

📊 PERMISSION COVERAGE

Permissions Defined: 27  
Permissions Used: 23  
Usage Coverage: 85%  

Missing permissions in code:
- clients.archive
- tools.deactivate
- contacts.merge

Unused permissions:
- users.impersonate

🆘 REMEDIATION PLAN

Priority P0 (Critical):
  [ ] Add permission to audit endpoint
  [ ] Test audit endpoint requires permission
  [ ] Commit: fix(security): add permission check to audit

Priority P1 (High):
  [ ] Add client isolation to tools service
  [ ] Add client isolation to contacts service
  [ ] Add integration tests for isolation
  [ ] Commit: fix(security): enforce client isolation

Priority P2 (Medium):
  [ ] Rename inconsistent permissions
  [ ] Update all references
  [ ] Commit: refactor(rbac): standardize permission names

AUTOMATED FIX SUGGESTIONS

1. backend/app/api/v1/endpoints/audit.py
   ADD THIS:
   from app.api.deps import require_permission
   
   Change line 15:
   - async def create_audit(...)
   + @router.post("/", dependencies=[Depends(require_permission("audit.log.create"))])
   + async def create_audit(...)

2. backend/app/api/v1/endpoints/tools.py
   Change line 42:
   - query = select(Tool).where(Tool.id == tool_id)
   + query = select(Tool).where(Tool.id == tool_id)
   + if user.user_type == "client_user":
   +     query = query.where(Tool.client_company_id == user.client_company_id)
```

## Common Issues Found

### Missing Permission Check

```python
# ❌ BAD - No permission decorator
@router.post("/")
async def create_client(...):
    ...

# ✅ GOOD - Has permission check
@router.post(
    "/",
    dependencies=[Depends(require_permission("clients.create"))],
)
async def create_client(...):
    ...
```

### Missing Client Isolation

```python
# ❌ BAD - Doesn't filter by company
async def get_contact(db, contact_id, user):
    query = select(Contact).where(Contact.id == contact_id)
    result = await db.execute(query)
    return result.scalar_one_or_none()

# ✅ GOOD - Filters by company
async def get_contact(db, contact_id, user):
    query = select(Contact).where(Contact.id == contact_id)
    if user.user_type == "client_user":
        query = query.where(Contact.company_id == user.client_company_id)
    result = await db.execute(query)
    return result.scalar_one_or_none()
```

### Inconsistent Permission Style

```python
# ❌ BAD - Inconsistent styles
require_permission("clients.create")     # lowercase
require_permission("TOOLS_READ")         # screaming
require_staff()                          # coarse-grained
require_super_admin()                    # too broad

# ✅ GOOD - Consistent style
require_permission("clients.create")
require_permission("tools.read")
require_permission("users.manage.own_company")
```

## Permission Design

### Granular Permissions

Avoid coarse-grained checks:

```python
# ❌ BAD - Too broad
@router.post("/", dependencies=[Depends(require_staff())])
async def create_client(...):
    ...

# ✅ GOOD - Specific permission
@router.post(
    "/",
    dependencies=[Depends(require_permission("clients.create"))],
)
async def create_client(...):
    ...
```

### Combining Checks

For complex scenarios:

```python
# Multiple permissions
dependencies=[
    Depends(require_permission("clients.update")),
    Depends(require_staff()),
],

# Or custom logic in service
async def update_client(db, client_id, data, user):
    if user.user_type == "client_user":
        # Limited permissions for client users
        if data.status == "archived":
            raise PermissionError("Clients can't archive")
```

## Testing Permissions

Every endpoint should have permission tests:

```python
def test_create_client_requires_permission(client):
    # Test without token
    response = client.post("/api/v1/clients/")
    assert response.status_code == 401
    
    # Test with insufficient permission
    response = client.post(
        "/api/v1/clients/",
        headers=consultant_headers,  # read-only role
    )
    assert response.status_code == 403
    
    # Test with correct permission
    response = client.post(
        "/api/v1/clients/",
        json={"name": "Test"},
        headers=admin_headers,
    )
    assert response.status_code == 201
```

## Audit Checklist

- [ ] All POST endpoints have `require_permission()` for create
- [ ] All PUT/PATCH endpoints have `require_permission()` for update
- [ ] All DELETE endpoints have `require_permission()` for delete
- [ ] GET endpoints have read permission (or public)
- [ ] Client users can only access own company data
- [ ] Permission names follow `resource.action` pattern
- [ ] Sensitive operations have audit logging
- [ ] Tests verify permission checks work
- [ ] No hardcoded role_id checks (use permissions)
- [ ] No missing client isolation anywhere

## See Also

- `vertical-slice-generator` - Generates endpoints with permissions
- `api-endpoint-generator` - Adds permission decorators
- `test-runner` - Tests permission enforcement
