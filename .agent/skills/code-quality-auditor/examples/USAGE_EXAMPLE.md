# Code Quality Auditor - Usage Examples

## Quick Start

### Audit All Code

```bash
cd .agent/skills/code-quality-auditor
python scripts/audit_quality.py

# Select: 1 (Audit all code)
```

**Output:**
```
╔════════════════════════════════════════════════════════════════╗
║        Code Quality Auditor - ESG Sustainify                   ║
│                                                                ║
║  Run linters and generate comprehensive quality reports       ║
╚════════════════════════════════════════════════════════════════╝

📊 PYTHON CODE QUALITY
============================================================

🔍 Running pylint...
  Found 23 issues
    convention: 8
    warning: 12
    error: 3

🔍 Running mypy...
  Found 6 type errors

🔍 Checking with black (formatter)...
  ⚠️  Code formatting issues detected (use --fix to auto-format)

📊 JAVASCRIPT/TYPESCRIPT CODE QUALITY
============================================================

🔍 Running eslint...
  Found 15 issues

============================================================
📋 QUALITY REPORT SUMMARY
============================================================

📊 Overall Score: 72/100 ⚠️

Total Issues:
  Violations: 38
  Errors: 6

Breakdown:
  Backend: 23 violations, 6 errors
  Frontend: 15 violations, 0 errors

⚠️  Code quality needs improvement

📈 Recommendations:
  1. Fix 6 type/syntax errors immediately
  2. Address 38 linting violations
```

### Auto-Fix Formatting

```bash
python scripts/audit_quality.py

# Select: 4 (Fix issues)

# Results:
# ✅ Formatted with black
# ✅ Formatted with prettier
```

### Backend Only

```bash
python scripts/audit_quality.py

# Select: 2 (Backend only)
```

## Common Issues & Fixes

### Python: Unused Imports

**pylint error:**
```
frontend/lib/utils.ts:4: W0611 (unused-import)
Unused import json
```

**Fix:**
```python
# BEFORE
import json
import os
import sys

# AFTER
import os
import sys
```

### Python: Type Mismatches

**mypy error:**
```
backend/app/services/client_service.py:45: error: Argument 1 to "get_client"
has incompatible type "str"; expected "int"
```

**Fix:**
```python
# BEFORE
client = get_client(user_id)  # user_id is string

# AFTER
client = get_client(int(user_id))
```

### JavaScript: Missing Error Handling

**eslint error:**
```
frontend/components/ClientList.tsx:20: no-floating-promises
Promise returned in function but not caught
```

**Fix:**
```typescript
// BEFORE
const response = apiClient.get('/clients');

// AFTER
const response = await apiClient.get('/clients');
```

## Best Practices

### 1. Run Before Committing

```bash
# Pre-commit hook
python .agent/skills/code-quality-auditor/scripts/audit_quality.py
```

### 2. Set Quality Baseline

First run establishes baseline:
```
Score: 72/100
Violations: 38
Errors: 6
```

Then track improvement over time.

### 3. Fix Types First

Always fix mypy errors before violations:
```
Priority: Errors (6) → Violations (38) → Warnings (50)
```

### 4. Format Automatically

Never fix formatting manually—use black/prettier:
```bash
python audit_quality.py  # Select: 4 (Fix issues)
```

## Integration with CI/CD

Example GitHub Actions:

```yaml
# .github/workflows/quality.yml
name: Code Quality

on: [push, pull_request]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Run Quality Audit
        run: |
          cd backend
          pip install -r requirements.txt
          python ../.agent/skills/code-quality-auditor/scripts/audit_quality.py
```

## Configuration

### Pylint Configuration

File: `backend/.pylintrc` (or `setup.cfg`)

```ini
[MASTER]
load-plugins=pylint_django

[MESSAGES CONTROL]
disable=
    missing-docstring,
    too-many-arguments,
    too-few-public-methods
```

### MyPy Configuration

File: `backend/mypy.ini`

```ini
[mypy]
python_version = 3.10
ignore_missing_imports = True
strict_optional = True
```

### ESLint Configuration

File: `frontend/.eslintrc.json`

```json
{
  "extends": "next/core-web-vitals",
  "rules": {
    "react-hooks/rules-of-hooks": "error",
    "no-floating-promises": "error"
  }
}
```

## Troubleshooting

### Issue: "pylint not installed"

Solution:
```bash
cd backend
pip install pylint mypy black isort
```

### Issue: "eslin not found"

Solution:
```bash
cd frontend
npm install eslint prettier
```

### Issue: "Still failing after fix"

Some issues can't auto-fix. Read the error message and fix manually:
```bash
python audit_quality.py  # Read error details
# Edit files manually
python audit_quality.py  # Re-run to verify
```

## Performance Tips

### Only Audit Changed Files

```bash
# Fast (check specific directory)
python audit_quality.py
# Select backend folder only
```

### Skip Heavy Checks

To skip mypy (slowest):
```python
# Edit audit_quality.py
# Comment out mypy check
```

## Success Criteria

✅ Score ≥ 85 = Production ready
🟠 Score 70-85 = Needs improvement
🔴 Score < 70 = Critical issues

Aim for **zero errors** and **< 20 violations** per session.
