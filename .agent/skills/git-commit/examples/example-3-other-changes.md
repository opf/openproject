# Example 4: Component/Service Refactoring

**Scenario**: Extracting shared error handling logic

**Commit Message:**
```
refactor(api): extract common error handling into shared middleware
```

**Or with details:**
```
refactor(api): extract common error handling into shared middleware

Move duplicate error handling logic from individual endpoints
into a reusable error handler middleware. This reduces code
duplication and ensures consistent error responses.
```

**Files Changed:**
- `backend/app/middleware/error_handler.py` (new)
- `backend/app/main.py` (modified)
- `backend/app/api/v1/endpoints/clients.py` (modified)
- `backend/app/api/v1/endpoints/users.py` (modified)

**Git Command:**
```bash
git add backend/app/middleware/ backend/app/main.py backend/app/api/v1/endpoints/
git commit -m "refactor(api): extract common error handling into shared middleware"
```

---

# Example 5: Documentation Update

**Scenario**: Updating architecture documentation

**Commit Message:**
```
docs(architecture): update vertical slice architecture guide
```

**Or with details:**
```
docs(architecture): update vertical slice architecture guide with new examples

- Add Session 9D ClientToolAccess slice as reference example
- Update database schema diagram
- Clarify RBAC permission patterns
```

**Files Changed:**
- `infra/planning/project-overview.md` (modified)
- `infra/docs/architecture/vertical-slices.md` (modified)

**Git Command:**
```bash
git add infra/planning/ infra/docs/
git commit -m "docs(architecture): update vertical slice architecture guide with new examples"
```

---

# Example 6: Progress Update

**Scenario**: Marking completed work in BUILD-PROGRESS.md

**Commit Message:**
```
chore(progress): session 9D - clienttoolaccess implementation complete
```

**Or with details:**
```
chore(progress): session 9D - clienttoolaccess implementation complete

Mark the following as complete:
- [x] ClientToolAccess model
- [x] Database migration
- [x] Service layer
- [x] API endpoints with RBAC
- [x] Frontend components
- [x] Integration tests

Next: Session 9E - Audit logging enhancements
```

**Files Changed:**
- `infra/project-state/BUILD-PROGRESS.md` (modified)

**Git Command:**
```bash
git add infra/project-state/BUILD-PROGRESS.md
git commit -m "chore(progress): session 9D - clienttoolaccess implementation complete"
```
