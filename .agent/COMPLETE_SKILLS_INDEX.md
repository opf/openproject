# All Skills - Complete Inventory (ESG Sustainify)

**Status**: 15+ skills fully implemented for FastAPI/Next.js stack  
**Standard**: Vertical Slice Architecture alignment  
**Auth**: `httpOnly` cookie strategy enforcement

---

## Foundational Skills (8)

### 1. session-orchestrator (New)
- **Purpose**: Meta-skill enforcing the Deliberation → Action → Verification pass.
- **Impact**: ⭐⭐⭐⭐⭐ Ensures governance, branding, and security are checked *before* code is written.
- **Usage**: At the start and end of every session.

### 2. fastapi-vertical-slice-generator (New)
- **Purpose**: Scaffolds complete features (Model → Migration → Service → Endpoint → Component).
- **Impact**: ⭐⭐⭐⭐⭐ Complete feature parity in minutes.
- **Alignment**: Async SQLAlchemy 2.0 + Pydantic v2 + React 19.

### 3. auth-rbac-scaffold (New)
- **Purpose**: Automates RBAC setup (Roles, Permissions, Junction tables) and Auth migrations.
- **Impact**: ⭐⭐⭐⭐ Security infrastructure consistency.

### 4. frontend-auth-logic-generator (New)
- **Purpose**: Generates specialized Next.js authentication layer (`AuthContext`, `ProtectedRoute`).
- **Impact**: ⭐⭐⭐⭐ Enforces secure `httpOnly` cookie handling.

### 5. api-endpoint-generator
- **Purpose**: Generates FastAPI endpoints with RBAC decorators and service delegation.
- **Impact**: ⭐⭐⭐⭐ Rapid backend development.

### 6. frontend-component-generator
- **Purpose**: Generates React components using `shadcn/ui`, `theme.ts`, and `TanStack Query`.
- **Impact**: ⭐⭐⭐⭐ UI consistency and standard form handling.

### 7. database-migration-creator
- **Purpose**: Safe Alembic migrations with async support.
- **Impact**: ⭐⭐⭐ Reliable schema evolution.

### 8. progress-tracker
- **Purpose**: Manages `BUILD-PROGRESS.md` and project metrics.
- **Impact**: ⭐⭐⭐ Real-time status reporting.

---

## Analysis & Quality Skills (7)

### 9. code-quality-auditor
- **Purpose**: Linting and type-checking (Pylint, Mypy, ESLint).
- **Impact**: ⭐⭐⭐⭐ Zero-defect deployment gate.

### 10. permission-validator
- **Purpose**: Audits RBAC coverage and client isolation logic.
- **Impact**: ⭐⭐⭐⭐⭐ Security guardrail for client-isolated multi-tenancy.

### 11. test-runner
- **Purpose**: Execute pytest with coverage analysis.
- **Impact**: ⭐⭐⭐ Reliable regression testing.

### 12. integration-test-generator
- **Purpose**: Generates multi-component workflow tests.
- **Impact**: ⭐⭐⭐⭐ End-to-end reliability verification.

### 13. performance-profiler
- **Purpose**: Detects N+1 queries and slow endpoints.
- **Impact**: ⭐⭐⭐⭐ Optimization before scale.

### 14. git-commit
- **Purpose**: Conventional commit analysis.
- **Impact**: ⭐⭐ Clean history.

### 15. api-documentation-generator
- **Purpose**: OpenAPI/Swagger documentation.
- **Impact**: ⭐⭐⭐⭐ Self-documenting API.

---

## Lifecycle Orchestration

All development follow the **Session Pipeline**:
1. **Deliberation** (`session-orchestrator`)
2. **Infrastructure** (`database-migration-creator`)
3. **Generation** (`fastapi-vertical-slice-generator`)
4. **Refinement** (`api-endpoint-generator`, `frontend-component-generator`)
5. **Validation** (`permission-validator`, `test-runner`)
6. **Reporting** (`session-orchestrator`, `progress-tracker`)

---

**Last Updated**: April 30, 2026  
**Architecture**: FastAPI 0.104+ | Next.js 16+ | PostgreSQL 15+
