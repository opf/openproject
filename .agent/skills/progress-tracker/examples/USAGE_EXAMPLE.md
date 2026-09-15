# Progress Tracker - Usage Examples

This guide shows how to use the progress-tracker skill to maintain BUILD-PROGRESS.md.

## Example 1: View Current Progress

```bash
python .agent/skills/progress-tracker/scripts/update_progress.py
```

**Select option: 1 (View progress)**

**Output:**

```
======================================================================
BUILD PROGRESS - CURRENT STATUS
======================================================================

# ESG Sustainify - Build Progress

**Current Session**: 9D  
**Status**: In Progress  
**Last Updated**: 2026-02-27  

## Completed Milestones

### Session 9A - Auth & RBAC (✅ COMPLETE)
- [x] User model and schema
- [x] JWT authentication
- [x] RBAC system (roles, permissions)

### Session 9B - Clients (✅ COMPLETE)
- [x] ClientCompany model
- [x] Client endpoints (full CRUD)
- [x] Frontend list and detail views

## In Progress

### Session 9C - Tools & Access (🔄 IN PROGRESS)
- [x] Tool model (5 services)
- [x] ToolAccess model
- [ ] Tool execution endpoint
- [ ] Frontend tool selector
```

## Example 2: Mark Feature Complete

```bash
python .agent/skills/progress-tracker/scripts/update_progress.py
```

**Select option: 2 (Mark feature complete)**

**Prompts:**

```
Session identifier (e.g., 9D, 10): 9D

Feature name: ClientToolAccess model

Notes (optional): Created migration, model, and relationships
```

**Result:**

Updated BUILD-PROGRESS.md with new entry:

```markdown
### Session 9D - ClientToolAccess (✅ COMPLETE)
- [x] ClientToolAccess model
- [x] Migration and relationships
- Notes: Created migration, model, and relationships
```

## Example 3: Log a Blocker

```bash
python .agent/skills/progress-tracker/scripts/update_progress.py
```

**Select option: 3 (Log blocker)**

**Prompts:**

```
Session (e.g., 9C): 9C

Blocker description: Tool API contract not finalized

Impact (High/Medium/Low): High

Resolution path/ETA: Waiting on product team, expected 2026-03-01
```

**Result:**

Added to BUILD-PROGRESS.md:

```markdown
## Blockers

1. **Tool API contract not finalized (Session 9C)**
   - **Impact**: High
   - **Blocking**: Tool execution endpoint
   - **Resolution**: Waiting on product team, expected 2026-03-01
```

## Example 4: Plan Next Session

```bash
python .agent/skills/progress-tracker/scripts/update_progress.py
```

**Select option: 4 (Plan next session)**

**Prompts:**

```
Next session (e.g., 10): 10

Estimated duration (minutes): 90

Session title (feature name): CRM Integration

Enter goals (one per line, empty to finish):
  Goal 1: Create Contact model with client company FK
  Goal 2: Implement CRUD endpoints
  Goal 3: Build frontend contact list view
  Goal 4: Create contact form
  Goal 5: Add integration tests
```

**Result:**

Added to BUILD-PROGRESS.md:

```markdown
## Next Session Plan - Session 10 (CRM Integration)

**Estimated Duration**: 90 minutes

**Goals** (in order):
1. Create Contact model with client company FK
2. Implement CRUD endpoints
3. Build frontend contact list view
4. Create contact form
5. Add integration tests

**Success Criteria**: All goals complete, tests passing
```

## Example 5: Log Session Summary

```bash
python .agent/skills/progress-tracker/scripts/update_progress.py
```

**Select option: 5 (Session summary)**

**Prompts:**

```
Session to summarize (e.g., 9D): 9D

Items completed: 7

Lines of code added: 412

Test coverage %: 94

Key accomplishments: Completed ClientToolAccess model, all CRUD endpoints, 
integration tests, client isolation working correctly
```

**Result:**

```markdown
**Final Status**: ✅ COMPLETE  
**Items Completed**: 7  
**Code Added**: 412 LOC  
**Coverage**: 94%  
**Summary**: Completed ClientToolAccess model, all CRUD endpoints,
integration tests, client isolation working correctly
```

## Full BUILD-PROGRESS.md Example

```markdown
# ESG Sustainify - Build Progress

**Current Session**: 10  
**Status**: In Progress  
**Last Updated**: 2026-02-28  

## Completed Milestones

### Session 9A - Auth & RBAC (✅ COMPLETE)
- [x] User model and authentication
- [x] JWT tokens and sessions
- [x] RBAC system with 4 roles, 27 permissions
- Notes: Foundation solid, no regressions

### Session 9B - Clients (✅ COMPLETE)
- [x] ClientCompany model and migration
- [x] Full CRUD endpoints with permissions
- [x] Frontend list and detail views
- [x] Integration tests (92% coverage)
- Time: ~120 minutes

### Session 9C - Tools & Access (✅ COMPLETE)
- [x] Tool model (5 services: EMS, Carbon, Water, Waste, Strategy)
- [x] ClientToolAccess model
- [x] Tool assignment endpoints
- [x] Frontend tool selector
- Time: ~100 minutes
- Coverage: 95%

### Session 9D - ClientToolAccess (✅ COMPLETE)
- [x] Refined ClientToolAccess relationships
- [x] Permission scopes for tool execution
- [x] Audit logging for tool access changes
- [x] Integration tests
- Time: ~85 minutes
- Final Coverage: 94%

## In Progress

### Session 10 - CRM Integration (🔄 IN PROGRESS)
- [x] Contact model with company FK
- [x] Contact CRUD endpoints
- [ ] Frontend contact list
- [ ] Contact detail form
- [ ] Integration tests

**Notes**: Model created, endpoints in progress, blocked on API design

## Not Started

### Session 11 - Dashboards (⏳ PLANNED)
- [ ] Dashboard data aggregation
- [ ] Client dashboard UI
- [ ] Staff dashboard UI
- [ ] Chart components

### Session 12 - Reports (⏳ PLANNED)
- [ ] Report generation engine
- [ ] ESG report templates
- [ ] PDF export

## Blockers

1. **Contact API Design (Session 10)**
   - **Severity**: Medium
   - **Impact**: Can't finalize endpoints
   - **ETAssociated**: 2026-03-01
   - **Workaround**: Using provisional schema

## Technical Debt

- Refactor client isolation checks (appears in 3 endpoints)
- Add request logging middleware
- Create integration test suite for multi-tenant scenarios

## Metrics

- **Features Completed**: 4 sessions × 5 features = 20 features
- **Code Added**: ~1,800 LOC total
- **Test Coverage**: 94% (target 85%+)
- **Average Session Time**: 100 minutes
- **Session Velocity**: 5 features/session

## Next Session Plan - Session 11 (Dashboards)

**Estimated Duration**: 120 minutes  
**Dependencies**: Sessions 9-10 complete  

**Goals**:
1. Create dashboard data aggregation service
2. Build client dashboard with metrics
3. Build staff dashboard with analytics
4. Add chart components (client count, tool usage)
5. Integration tests

**Success Criteria**: All dashboards functional, no performance issues
```

## Integration with Git

After updating progress, commit the changes:

```bash
# Mark feature complete
git add infra/project-state/BUILD-PROGRESS.md
git commit -m "chore(progress): mark ClientToolAccess complete - session 9D"

# After session
git commit -m "chore(progress): session 9D summary - 7 items, 412 LOC, 94% coverage"

# After current session
git commit -m "chore(progress): plan session 11 - dashboards"
```

## Best Practices

1. **Update daily** - Don't wait until end of session
2. **Be specific** - List actual features, not "work on X"
3. **Track metrics** - LOC, coverage, time
4. **Note blockers** - Document impediments immediately
5. **Link commits** - Reference git commits that implement features
6. **Estimate future** - Plan next session while fresh

## See Also

- `vertical-slice-generator` - Plan features in slices
- `test-runner` - Track coverage in progress
- Session planning in `infra/planning/build-order.md`
