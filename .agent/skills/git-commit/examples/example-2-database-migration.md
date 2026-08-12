# Example 2: Database Migration

**Scenario**: Adding a new column to an existing table

**Commit Message:**
```
chore(db): migration - add is_verified column to client_contacts table
```

**Or with more details:**
```
chore(db): migration - add verification tracking for client contacts

This migration adds is_verified and verified_at columns to track
whether contact information has been verified by the client.
```

**Files Changed:**
- `backend/alembic/versions/20251114_0009_add_verification_to_contacts.py` (new)

**Git Command:**
```bash
git add backend/alembic/versions/
git commit -m "chore(db): migration - add is_verified column to client_contacts"
```

---

# Example 3: Bug Fix with Specific Scope

**Scenario**: Fixing a permission check issue in the user management service

**Commit Message:**
```
fix(rbac): correct permission check for client user role escalation

- Fix bug where client users could assign consultant role to themselves
- Add stricter validation in require_staff() dependency
- Prevent non-admins from modifying user roles
```

**Files Changed:**  
- `backend/app/api/deps.py` (modified)
- `backend/app/services/user_service.py` (modified)
- `backend/tests/test_rbac_permissions.py` (modified)

**Git Command:**
```bash
git add backend/app/api/deps.py backend/app/services/user_service.py backend/tests/
git commit -m "fix(rbac): correct permission check for client user role escalation" -m "- Add stricter validation in require_staff() dependency
- Prevent non-admins from modifying user roles  
- Add regression tests"
```
