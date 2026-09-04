---
name: auth-rbac-scaffold
description: Automates the creation of RBAC infrastructure (Roles, Permissions, Junction tables) and corresponding seed data scripts.
---

# Auth & RBAC Scaffold

This skill automates the setup of the RBAC system, including database models, permission checking services, and seed data.

## When to use this skill
- Initial project setup (Authentication Backend).
- Adding a new module that requires new permissions or roles.
- Refactoring the permission checking logic.

## How to use this skill

### Step 1: Define Roles & Permissions
Identify the roles (Super Admin, Consultant, Client Admin, Client User) and the 27+ permissions required by the spec.

### Step 2: Infrastructure Models
Ensure the following models exist:
- `backend/app/models/user.py` (with `user_type`, `role_id`, `client_company_id`)
- `backend/app/models/role.py`
- `backend/app/models/permission.py`
- `backend/app/models/role_permission.py` (Junction)

### Step 3: Permission Service
Implement or update `backend/app/services/permission_service.py` to handle:
- `get_user_permissions(db, user)`
- `user_has_permission(db, user, permission)`
- Permission caching (if applicable).

### Step 4: Seed Data
Create a seed script `backend/scripts/seed_rbac.py` to populate the roles and permissions tables with the latest definitions.

### Step 5: FastApi Dependencies
Update `backend/app/api/deps.py` with:
- `require_permission(*permissions)`
- `require_staff()`
- `require_super_admin()`

## Success Criteria
- RBAC tables are properly indexed and migrated.
- Seed data is successfully injected.
- `require_permission` correctly blocks unauthorized access with 403 errors.
