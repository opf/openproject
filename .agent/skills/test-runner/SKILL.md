---
name: test-runner
description: Runs pytest on backend tests with coverage reporting, identifies failing tests, suggests fixes, and validates test structure. Provides detailed failure analysis and recommendations for ESG Sustainify tests. Use when running unit tests, integration tests, or checking test coverage.
---

# Test Runner

This skill executes pytest with comprehensive output, coverage analysis, and failure diagnostics.

## When to use this skill

- Running all tests: "Run all tests and show coverage"
- Running specific tests: "Test the auth module"
- Check coverage: "What's our test coverage?"
- Fix failures: "Fix failing tests"
- New tests: "Run tests after adding new code"

## How to use this skill

### Step 1: Run tests

```bash
python .agent/skills/test-runner/scripts/run_tests.py
```

Interactive prompts:
- **Test scope**: all, backend, frontend, specific file/module
- **Coverage**: yes/no (generate coverage report)
- **Verbose**: yes/no (detailed output)
- **Failfast**: yes/no (stop on first failure)

### Step 2: Review output

The script generates:
- Test results (passed/failed/skipped)
- Failure details with line numbers
- Coverage statistics per module
- Recommendations for fixes

### Step 3: Fix failures

Based on the output, identify:
- Why test failed (assertion error, exception, timeout)
- Which function/module affected
- Suggested fix or investigation area

## Test Organization

Backend tests follow ESG structure:

```
backend/tests/
├── test_auth.py              - Authentication/JWT tests
├── test_rbac.py              - RBAC and permissions tests
├── test_services/            - Service layer tests
│   ├── test_client_service.py
│   ├── test_tool_service.py
│   └── ...
├── test_endpoints/           - API endpoint tests
│   ├── test_clients_endpoint.py
│   └── ...
├── conftest.py               - Pytest fixtures
└── __init__.py
```

## Coverage Goals

Target coverage by component:

| Component | Target |
|-----------|--------|
| Services | 90%+ |
| Endpoints | 85%+ |
| Models | 80%+ |
| Schemas | 70%+ |
| Overall | 80%+ |

## Running Tests

### All Tests
```bash
# Run all tests with coverage
python run_tests.py
→ Select: all
→ Coverage: yes
→ Verbose: yes
```

### By Module
```bash
# Test authentication only
→ Test scope: backend/test_auth.py
```

### By Pattern
```bash
# Test all services
→ Test scope: backend/tests/test_services/
```

### Fast Mode
```bash
# Stop on first failure (debugging)
→ Failfast: yes
```

## Test Output Example

```
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
>   assert user_has_permission(user, "clients.create")
E   AssertionError: assert False == True
E   
E   + where False = <function user_has_permission at 0x...>

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
```

## Common Test Patterns

### Service Test

```python
@pytest.mark.asyncio
async def test_create_client():
    db = AsyncMock()
    user = User(id=1, client_company_id=1)
    data = ClientCompanyCreate(name="Test Co")
    
    result = await client_service.create_client(db, data, user)
    
    assert result.name == "Test Co"
    assert result.created_by == 1
    db.add.assert_called_once()
    db.commit.assert_called_once()
```

### Endpoint Test

```python
def test_create_client_endpoint(client, auth_headers):
    response = client.post(
        "/api/v1/clients/",
        json={"name": "Test Co"},
        headers=auth_headers,
    )
    
    assert response.status_code == 201
    assert response.json()["name"] == "Test Co"
```

### Permission Test

```python
def test_permission_denied():
    user = User(id=1, role_id=4)  # Client user
    
    with pytest.raises(PermissionError):
        require_permission("clients.create")(user)
```

## Fixtures (conftest.py)

Reusable test fixtures:

```python
@pytest.fixture
async def db():
    """Mock async database session"""
    return AsyncMock(spec=AsyncSession)

@pytest.fixture
def admin_user():
    """Super admin user"""
    return User(id=1, role_id=1, email="admin@test.com")

@pytest.fixture
def auth_headers(admin_user):
    """Authorization header with valid JWT"""
    token = create_access_token(data={"sub": admin_user.email})
    return {"Authorization": f"Bearer {token}"}
```

## Coverage Reports

After running tests with coverage:

```
Coverage HTML Report: htmlcov/index.html
Open in browser to see:
- Per-file coverage with uncovered lines highlighted
- Trend over time (if using coverage history)
- Branch coverage analysis
```

## Failing Test Diagnosis

When a test fails, look at:

1. **Assertion Error** - What was expected vs actual?
2. **Exception** - Was an error raised?
3. **Missing Line** - Coverage shows uncovered code path
4. **Setup** - Are fixtures initialized correctly?
5. **Async** - Did async test properly await?

## Best Practices

✅ **Test Isolation** - Each test is independent  
✅ **Meaningful Names** - `test_create_client_without_permission` not `test_1`  
✅ **Arrange-Act-Assert** - Setup → Execute → Verify  
✅ **Mock External** - Don't hit real DB in tests  
✅ **Test Edge Cases** - Not just happy path  
✅ **One Assert** - Test one thing per test (usually)  

❌ **Don't:**
- Use sleep() in tests
- Share state between tests
- Test implementation details
- Write non-deterministic tests
- Skip tests without reason

## See Also

- `vertical-slice-generator` - Generates test stubs
- `permission-validator` - Audits RBAC coverage
- Frontend tests can use Vitest, Jest, or Playwright

