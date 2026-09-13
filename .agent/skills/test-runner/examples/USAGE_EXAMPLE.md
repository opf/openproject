# Test Runner - Usage Examples

This guide shows how to use the test-runner skill with real scenarios.

## Example 1: Run All Tests with Coverage

```bash
python .agent/skills/test-runner/scripts/run_tests.py
```

**Interactive prompts:**

```
Test scope:
  1. All tests
  2. Backend only
  3. Frontend only
  4. Specific module
Select (1-4): 1

Generate coverage report? (yes/no): yes

Verbose output? (yes/no): yes

Stop on first failure? (yes/no): no
```

**Output:**

```
Running: python -m pytest . --cov=app --cov-report=html --cov-report=term-missing -vv

================================= test session starts ==================================
platform linux -- Python 3.11.0, pytest-8.0.0, py-1.13.0, pluggy-1.1.0
rootdir: /path/to/backend
collected 42 items

test_auth.py::test_user_registration PASSED                                    [11%]
test_auth.py::test_login_success PASSED                                        [22%]
test_rbac.py::test_permission_check FAILED                                     [33%]
test_services/test_client_service.py::test_create_client PASSED               [44%]

================================== FAILURES ==========================================
_________________________ test_rbac.py::test_permission_check __________________________

    def test_permission_check():
        user = User(id=1, role_id=2)
        expected = True
>       assert user_has_permission(user, "clients.create") == expected
E       AssertionError: assert False == True

test_rbac.py:6: AssertionError

=========================== 39 passed, 1 failed, 2 skipped, in 0.42s ===========================

========================== Coverage Summary ==========================
Name               Stmts   Miss  Cover   Missing
------------------------------------------------------
app/services       245      12    95%    45-47, 120
app/api            189      28    85%    56, 89, 123-130
app/models         156      15    90%    78-82, 234
------------------------------------------------------
TOTAL              590      55    91%

✅ Coverage report: /path/to/backend/htmlcov/index.html
   Open in browser to see detailed coverage
```

## Example 2: Test Backend Only (Fast Mode)

Strategy: Test just backend with failfast to catch issues quickly.

```bash
python .agent/skills/test-runner/scripts/run_tests.py

# Prompts:
Test scope: Backend only
Coverage: no
Verbose: yes
Failfast: yes
```

**Output:**

```
Running: python -m pytest backend/tests -v -x

test_auth.py::test_user_registration PASSED
test_auth.py::test_login_success PASSED
test_auth.py::test_logout PASSED
test_rbac.py::test_permission_check FAILED [FAILFAST]

FAILED test_rbac.py::test_permission_check - AssertionError
```

## Example 3: Test Specific Module

```bash
python .agent/skills/test-runner/scripts/run_tests.py

# Prompts:
Test scope: Specific module
```

Then enter:
```
  Enter module path: tests/test_auth.py
  Verbose: yes
  Coverage: yes
```

**Output:**

```
Running: python -m pytest backend/tests/test_auth.py --cov=app.api --cov-report=html -v

test_auth.py::test_user_registration PASSED
test_auth.py::test_login_success PASSED
test_auth.py::test_login_invalid_credentials PASSED
test_auth.py::test_password_reset_flow PASSED

========================= 4 passed in 0.25s =========================

Coverage Summary:
app/api/endpoints/auth.py   95%
app/services/auth_service   98%
app/core/security.py        92%

TOTAL  95%
```

## Example 4: Check Coverage Targets

```bash
python .agent/skills/test-runner/scripts/run_tests.py

# Select: Check coverage targets
```

**Output:**

```
📊 Coverage Targets:

  app/services: 90%+
  app/api: 85%+
  app/models: 80%+
  app/schemas: 70%+
```

## Common Test Patterns

### Testing a Service

```python
# backend/tests/test_services/test_client_service.py

import pytest
from sqlalchemy.ext.asyncio import AsyncMock
from app.services.client_service import ClientService
from app.schemas.client import ClientCreate
from app.models.client import ClientCompany

@pytest.mark.asyncio
async def test_create_client():
    """Test creating a client company."""
    db = AsyncMock()
    user = User(id=1, role_id=1, client_company_id=None)
    
    data = ClientCreate(name="Acme Corp", industry="Tech")
    
    result = await ClientService.create_client(db, data, user)
    
    assert result.name == "Acme Corp"
    assert result.created_by == 1
    db.add.assert_called_once()
    db.commit.assert_called_once()
```

### Testing an Endpoint

```python
# backend/tests/test_endpoints/test_clients.py

def test_create_client_endpoint(client, admin_headers):
    """Test POST /api/v1/clients/"""
    response = client.post(
        "/api/v1/clients/",
        json={"name": "Acme Corp", "industry": "Tech"},
        headers=admin_headers,
    )
    
    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "Acme Corp"
```

### Testing Permissions

```python
def test_client_user_cannot_create_client(client, client_user_headers):
    """Test that client users can't create clients."""
    response = client.post(
        "/api/v1/clients/",
        json={"name": "Test"},
        headers=client_user_headers,
    )
    
    assert response.status_code == 403
```

## Troubleshooting

### Test Fails with "ModuleNotFoundError"

```bash
# Activate virtual environment first
source backend/venv/bin/activate  # Linux/Mac
# or
backend\venv\Scripts\activate.bat  # Windows

# Then run tests
python .agent/skills/test-runner/scripts/run_tests.py
```

### Coverage Report Not Generated

```bash
# Ensure coverage is installed
pip install coverage

# Run with coverage
python .agent/skills/test-runner/scripts/run_tests.py
# Select: yes for coverage
```

### Tests Hang/Timeout

```bash
# Use failfast mode to stop on first failure
python .agent/skills/test-runner/scripts/run_tests.py
# Select: yes for failfast
```

## See Also

- Run backend tests only for faster iteration
- Use the `test-runner` before committing code
- Check coverage reports to identify untested code
- Write tests alongside new features (TDD approach)
