---
name: code-quality-auditor
description: Runs Python linters (pylint, mypy, black), JavaScript linters (eslint), and generates quality reports with issues, violations, and recommendations. Identifies code style violations, type errors, and security issues across backend and frontend codebase. Use when auditing code quality, before releases, or improving code metrics.
---

# Code Quality Auditor

This skill runs multiple code quality tools (linting, type checking, formatting) and generates comprehensive reports with actionable fixes.

## When to use this skill

- Code review: "Check code quality on these files"
- Pre-release: "Run full quality audit before deployment"
- Quality metrics: "What's our code quality score?"
- Fix issues: "Show me linting violations"
- CI/CD: "Validate code before merge"

## How to use this skill

### Step 1: Run auditor

```bash
python .agent/skills/code-quality-auditor/scripts/audit_quality.py
```

Options:
- **Audit all** - Check entire codebase
- **Backend only** - Python code only
- **Frontend only** - JavaScript/TypeScript only
- **Specific file** - Check single file or folder
- **Fix issues** - Auto-fix common violations

### Step 2: Review report

Output shows:
- Total violations count
- Issues by severity (critical, error, warning, info)
- Specific violations with line numbers
- Actionable fixes for each issue
- Quality score trends
- Recommendations

### Step 3: Fix violations

Use tool to:
1. Auto-fix simple issues (format, import order)
2. Review complex issues for manual fixes
3. Suppress false positives with inline comments
4. Commit fixed code

## Quality Tools

### Python

#### pylint
- Detects errors, coding violations, refactoring suggestions
- Configurable via `.pylintrc`
- Example: Unused imports, undefined variables, missing docstrings

#### mypy
- Static type checking
- Finds type mismatches before runtime
- Example: Wrong function argument types, missing None checks

#### black
- Code formatter (enforces consistent style)
- Opinionated but deterministic
- Example: Line length, indentation, spacing

#### isort
- Organizes imports (split stdlib, third-party, local)
- Consistency across codebase
- Example: Import ordering, unused imports

### JavaScript/TypeScript

#### eslint
- Identifies and reports code quality issues
- Enforces coding standards
- Example: Unused variables, inconsistent naming, security issues

#### prettier
- Code formatter (enforces consistent style)
- Opinionated formatting rules
- Example: Line length, quotes, semicolons, indentation

#### typescript compiler (tsc)
- Type checking for TypeScript files
- Catch type errors at build time
- Example: Type mismatches, missing properties

## Report Structure

```
╔════════════════════════════════════════════════════════════════╗
║              Code Quality Audit Report                         ║
╚════════════════════════════════════════════════════════════════╝

📊 OVERALL SCORE: 82/100

Violations by Severity:
  🔴 CRITICAL: 2
  🟠 ERROR:    7
  🟡 WARNING: 34
  🔵 INFO:    12

────────────────────────────────────────────────────────────────

📁 PYTHON (Backend)

Files Checked: 45
Violations: 32

Top Issues:
  ❌ Unused imports (8)
  ❌ Type errors (4)
  ⚠️  Missing docstrings (12)
  ℹ️  Long functions (8)

Details:

  🔴 CRITICAL (2)
  ─────────────────────────────────────────────────────────────
  1. backend/app/models/user.py:45
     Issue: Undefined variable 'ClientCompany'
     Severity: CRITICAL
     Fix: Add import: from app.models import ClientCompany
     Line: password_hash: str = Field(ClientCompany)
                                       ^^^^^^^^^^^^^^

  2. backend/app/services/client_service.py:120
     Issue: Type mismatch - expected str, got int
     Severity: CRITICAL
     Fix: Change parameter type or convert value
     Line: return client.update(client_id=user.id)

  🟠 ERROR (7)
  ─────────────────────────────────────────────────────────────
  1. backend/app/api/v1/endpoints/clients.py:12
     Issue: Unused import 'List'
     Severity: ERROR
     Fix: Remove unused import or use it
     Line: from typing import List

────────────────────────────────────────────────────────────────

📁 JAVASCRIPT/TYPESCRIPT (Frontend)

Files Checked: 38
Violations: 16

Top Issues:
  ❌ Unused variables (4)
  ⚠️  Missing types (6)
  ⚠️  Inconsistent naming (3)
  ℹ️  Console.log calls (3)

Details:

  🔴 CRITICAL (0)
  
  🟠 ERROR (1)
  ─────────────────────────────────────────────────────────────
  1. frontend/components/clients/ClientList.tsx:45
     Issue: Implicitly any type 'client'
     Severity: ERROR
     Fix: Add TypeScript type annotation
     Line: const client = clients?.find(c => c.id === id)
                     ^^^^^^

────────────────────────────────────────────────────────────────

📈 TRENDS

Quality Score:
  Last Week:  75
  This Week:  82
  Improvement: ↑ 7 points (+9%)

Most Improved:
  backend/services/ - Type coverage up from 60% → 92%
  frontend/components/ - Violations down from 28 → 16

────────────────────────────────────────────────────────────────

✅ AUTO-FIXABLE ISSUES: 12

The following issues can be automatically fixed:

  1. Unused imports (8) - Run with --fix flag
  2. Import ordering (4) - Run isort --fix

Run: audit_quality.py --fix

────────────────────────────────────────────────────────────────

🎯 RECOMMENDATIONS

Priority 1 (Fix Immediately):
  [ ] Resolve 2 CRITICAL type errors
  [ ] Add missing type annotations in frontend
  [ ] Fix undefined imports

Priority 2 (Before Release):
  [ ] Add docstrings to public functions
  [ ] Reduce function complexity (5 functions > 20 lines)
  [ ] Remove console.log statements

Priority 3 (Technical Debt):
  [ ] Increase type coverage to 95%
  [ ] Standardize naming conventions
  [ ] Add more type hints

────────────────────────────────────────────────────────────────

💾 EXPORT FORMATS

HTML Report: htmlcov/quality-report.html
JSON Format: reports/quality-report.json
SARIF (CI/CD): reports/quality-report.sarif
```

## Configuration Files

### Python (.pylintrc)

Located at: `backend/.pylintrc`

```ini
[MASTER]
disable=C0111,  # missing-docstring
        R0903,  # too-few-public-methods
        W0212   # protected-access

max-line-length=100
```

### JavaScript (.eslintrc.json)

Located at: `frontend/.eslintrc.json`

```json
{
  "extends": ["next/core-web-vitals"],
  "rules": {
    "no-console": "warn",
    "no-unused-vars": "error",
    "@typescript-eslint/no-explicit-any": "error"
  }
}
```

## Common Issues & Fixes

### Python

**Unused Imports**
```python
# ❌ BAD
from typing import List, Optional  # List is unused
from app.models import ClientCompany

# ✅ GOOD
from typing import Optional
from app.models import ClientCompany
```

**Missing Type Hints**
```python
# ❌ BAD
def create_client(data):
    return client

# ✅ GOOD
def create_client(data: ClientCreate) -> ClientCompany:
    return client
```

**Missing Docstring**
```python
# ❌ BAD
def get_total_clients(db):
    return db.query(ClientCompany).count()

# ✅ GOOD
def get_total_clients(db: AsyncSession) -> int:
    """Get total number of client companies."""
    return db.query(ClientCompany).count()
```

### JavaScript/TypeScript

**Unused Variables**
```typescript
// ❌ BAD
const unused = "value";
const clients = await clientService.list();

// ✅ GOOD
const clients = await clientService.list();
```

**Missing Types**
```typescript
// ❌ BAD
const client = clients?.find(c => c.id === id);

// ✅ GOOD
const client = clients?.find((c: Client) => c.id === id);
```

**Implicit Any**
```typescript
// ❌ BAD
function processClient(data) {
    return data.name;
}

// ✅ GOOD
function processClient(data: ClientCreate): string {
    return data.name;
}
```

## Auto-Fix Usage

```bash
python audit_quality.py --fix
```

Automatically fixes:
- Import ordering (isort)
- Code formatting (black, prettier)
- Simple refactoring (remove unused imports)

❌ Cannot auto-fix:
- Type errors (need manual review)
- Missing docstrings (context-dependent)
- Complex refactoring
- Logic errors

## Integration with CI/CD

Fail the build if quality score drops:

```bash
# Set minimum score threshold
audit_quality.py --min-score 85

# Fail if violations exceed limit
audit_quality.py --max-violations 20
```

## Team Standards

Enforce consistency:

- **Line length**: 100 characters (Python), 88 (JavaScript)
- **Type coverage**: 90%+
- **Documentation**: Docstring for all public functions
- **Naming**: snake_case (Python), camelCase (JavaScript)
- **Imports**: Organized, no unused imports

## See Also

- `vertical-slice-generator` - Generates code meeting quality standards
- `test-runner` - Coverage metrics alongside quality
- `permission-validator` - Security-specific code review
- `progress-tracker` - Track quality improvements over time
