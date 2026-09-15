# Example 1: New Vertical Slice (Complete Feature)

**Scenario**: Completed implementation of a new vertical slice (e.g., Session 9D - ClientToolAccess)

**Commit Message:**
```
feat(slice-09d): implement client tool access management

- Add ClientToolAccess model with relationships to ClientCompany and Tool
- Create client_tool_access migration (20251012_0007)  
- Implement get_client_tool_access, assign_tool_to_client, revoke_tool_access services
- Add /api/v1/clients/{client_id}/tools endpoints with RBAC
- Create frontend ClientToolAccess components (assignment form, access table)
- Add integration tests for tool access permissions
- Update BUILD-PROGRESS.md with completion status
```

**Files Changed:**
- `backend/alembic/versions/20251012_0007_create_client_tool_access.py` (new)
- `backend/app/models/client_tool_access.py` (new)
- `backend/app/schemas/client_tool_access.py` (new)
- `backend/app/services/client_tool_access_service.py` (new)
- `backend/app/api/v1/endpoints/client_tools.py` (new)
- `frontend/components/clients/ClientToolAssignment.tsx` (new)
- `frontend/lib/services/clientToolService.ts` (new)
- `infra/project-state/BUILD-PROGRESS.md` (modified)

**Git Command:**
```bash
git add .
git commit -m "feat(slice-09d): implement client tool access management" -m "- Add ClientToolAccess model and migration
- Implement service layer for tool assignment
- Create API endpoints with RBAC checks
- Add frontend components for tool management
- Update progress tracking"
```
