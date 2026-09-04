# Permission Validator - Usage Examples

This guide shows how to use the permission-validator skill to audit RBAC coverage.

## Example 1: Audit All Endpoints

```bash
python .agent/skills/permission-validator/scripts/validate_permissions.py
```

**Select option: 1 (Audit all endpoints)**

**Output:**

```
======================================================================
RBAC AUDIT - ESG Sustainify Endpoints
======================================================================

SECURITY SCORE: ✅ 95%

✅ PROTECTED: 28/30 endpoints

  ✅ GET    /                    (clients.py:15)
  ✅ POST   /                    (clients.py:24)
  ✅ GET    /{id}                (clients.py:35)
  ✅ PUT    /{id}                (clients.py:48)
  ✅ DELETE /{id}                (clients.py:62)
  ✅ GET    /tools/list          (tools.py:18)
  ✅ POST   /tools/assign        (tools.py:32)

⚠️ UNPROTECTED: 2 endpoints

  ❌ GET    /public              (tools.py:45)
     → ADD: @require_permission('tools.read.public')
     
  ❌ POST   /batch               (audit.py:78)
     → ADD: @require_permission('audit.log.create')

🔒 CLIENT ISOLATION: 25/30 endpoints

  5 endpoints without client_company_id filtering:
    • tools.py:45 - get_public_tools()
    • contacts.py:62 - list_all_contacts()
    • users.py:18 - get_users()
```

## Example 2: Check Specific File

```bash
python .agent/skills/permission-validator/scripts/validate_permissions.py
```

**Select option: 2 (Check specific file)**

**Prompt:**

```
Filename (e.g., clients.py): tools.py
```

**Output:**

```
tools.py:
--------------------------------------------------
  ✅ GET    /                    (permission check present)
  ✅ POST   /                    (permission check present)
  ✅ GET    /{id}                (permission check present)
  ⚠️  GET    /public             (no permission check - public endpoint?)
  ❌ POST   /batch               (missing permission check)
     Add: @require_permission('tools.execute.batch')
```

## Example 3: Find Security Issues

```bash
python .tool/skills/permission-validator/scripts/validate_permissions.py
```

**Select option: 3 (Find security issues)**

**Output:**

```
📋 SECURITY ISSUES:

🔴 CRITICAL (1):
  • tools.py:45 - POST /batch (no permission check)

🟠 HIGH (3):
  • contacts.py:62 - list_all_contacts() (no client isolation)
  • users.py:18 - get_users() (no client isolation)
  • audit.py:78 - create_audit() (fine-grained permission expected)
```

## Real-World Scenarios

### Scenario 1: Adding New Endpoint

Before adding a new endpoint, validate it will have proper permissions:

```bash
# After creating new endpoint file: POST /api/v1/clients/{id}/contacts

# Run validator
python .agent/skills/permission-validator/scripts/validate_permissions.py

# If it shows:
# ❌ POST   /contacts     (missing permission check)
#    Add: @require_permission('contacts.create')

# Fix endpoint file:
@router.post(
    "/{client_id}/contacts",
    dependencies=[Depends(require_permission("contacts.create"))],
)
async def create_contact(...):
    ...
```

### Scenario 2: Code Review

During code review, validate RBAC before merge:

```bash
# Run full audit
python .agent/skills/permission-validator/scripts/validate_permissions.py

# Check results:
# SECURITY SCORE: 85% - Below target 95%
# UNPROTECTED: 2 endpoints - Need fixes before merge

# Find which ones:
# ❌ audit.py:78
# ❌ tools.py:45

# Ask developer to fix those endpoints
```

### Scenario 3: Refactoring Permissions

When renaming permissions or roles:

```bash
# Before refactoring:
# @router.get("/", dependencies=[Depends(require_permission("clients.read"))])
# @router.post("/", dependencies=[Depends(require_permission("clients.write"))])

# Validate current state
python .agent/skills/permission-validator/scripts/validate_permissions.py
# Result: ✅ 100% protected

# After refactoring to align naming:
# @router.get("/", dependencies=[Depends(require_permission("clients.read"))])
# @router.post("/", dependencies=[Depends(require_permission("clients.create"))])

# Validate again
python .agent/skills/permission-validator/scripts/validate_permissions.py
# Result: ✅ Still 100% protected, naming unified
```

## Client Isolation Audit

Ensuring client users can't access other companies' data:

### Before Isolation Fix

```python
# ❌ BAD - No client filtering
async def get_contact(db, contact_id, user):
    return await db.get(Contact, contact_id)
```

**Validator detects:**

```
❌ contacts.py:15 - get_contact() (no client isolation)
   Issue: Client users could access other companies' contacts
```

### After Isolation Fix

```python
# ✅ GOOD - Client isolation enforced
async def get_contact(db, contact_id, user):
    query = select(Contact).where(Contact.id == contact_id)
    if user.user_type == "client_user":
        query = query.where(Contact.company_id == user.client_company_id)
    return await db.execute(query)
```

**Validator confirms:**

```
✅ contacts.py:15 - get_contact() (client isolation verified)
```

## Permission Design Patterns

### Pattern 1: Read-Only Role

Consultant role should only read data:

```bash
# Run validator, check consultants
# Should see:
# ✅ GET    /clients        (consultants can read)
# ❌ POST   /clients        (consultants BLOCKED - no permission)
# ❌ PUT    /clients/{id}   (consultants BLOCKED - no permission)
```

### Pattern 2: Client User Restrictions

Client users should only access own company:

```bash
# Run validator, check client isolation
# Should see:
# ✅ clients.py - list_clients() filtered by company_id
# ✅ tools.py - list_tools() filtered by company_id
# ❌ contacts.py - list_contacts() needs filtering
```

## Automated Fixes

The validator shows suggested fixes:

**Example output:**

```
⚠️ UNPROTECTED: audit.py:78

    Change line 78:
    - async def create_audit(...)
    + @router.post(
    +     "/",
    +     dependencies=[Depends(require_permission("audit.log.create"))],
    + )
    + async def create_audit(...)
```

### Applying the Fix

1. Open `backend/app/api/v1/endpoints/audit.py`
2. Add the decorator before the function
3. Validate with the tool again
4. Commit changes

## Compliance Checklist

Before releasing features:

- [ ] Run full audit: `python validate_permissions.py`
- [ ] Security score ≥ 95%
- [ ] Zero CRITICAL issues
- [ ] All client isolation verified
- [ ] All new endpoints have permission checks
- [ ] Permission names follow `resource.action` pattern
- [ ] Tests verify permission enforcement
- [ ] Code review passes RBAC audit

## See Also

- `vertical-slice-generator` - Generates endpoints with permissions
- `api-endpoint-generator` - Adds permission decorators
- `test-runner` - Test permission enforcement
- `progress-tracker` - Track security audit sessions
