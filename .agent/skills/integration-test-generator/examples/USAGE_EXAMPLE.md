# Integration Test Generator - Usage Examples

## Quick Start

### Generate Feature Flow Test

```bash
cd .agent/skills/integration-test-generator
python scripts/generate_integration_tests.py

# Select: 1 (Feature flow)
# Entity name: client
```

**Output:**
```
╔════════════════════════════════════════════════════════════════╗
║    Integration Test Generator - ESG Sustainify                ║
║                                                                ║
║  Generate multi-component workflow tests                      ║
╚════════════════════════════════════════════════════════════════╝

Test Types:
  1. Feature flow (complete workflow)
  2. Permission boundary tests
  3. Data consistency tests
  4. All of the above

Select (1-4): 1
Feature/entity name (e.g., client): client

✅ Created: backend/tests/integration/test_client.py

✅ Integration tests generated!

Run tests with: pytest backend/tests/integration/ -v
```

## Generated Test Examples

### Feature Flow Test

```python
import pytest
from sqlalchemy.ext.asyncio import AsyncMock

@pytest.mark.asyncio
async def test_client_feature_flow(client_app):
    """
    Integration test: Complete client workflow
    
    Workflow:
    # POST /api/v1/clients/
    # GET /api/v1/clients/{id}
    # PUT /api/v1/clients/{id}
    # DELETE /api/v1/clients/{id}
    """
    
    # SETUP: Authenticate
    admin_response = client_app.post("/api/v1/auth/login", json={
        "email": "admin@test.com",
        "password": "secure_password"
    })
    admin_token = admin_response.json()["access_token"]
    admin_headers = {"Authorization": f"Bearer {admin_token}"}
    
    # Step 1: Create client
    create_response = client_app.post(
        "/api/v1/clients/",
        json={"name": "Test Corp", "industry": "Tech"},
        headers=admin_headers
    )
    assert create_response.status_code == 201
    client_id = create_response.json()["id"]
    
    # Step 2: Read client
    get_response = client_app.get(
        f"/api/v1/clients/{client_id}/",
        headers=admin_headers
    )
    assert get_response.status_code == 200
    assert get_response.json()["name"] == "Test Corp"
    
    # VERIFY: Final state
    assert get_response.json()["status"] == "active"
```

### Running Feature Flow Test

```bash
# Run single test
pytest backend/tests/integration/test_client.py::test_client_feature_flow -v

# Output:
# test_client_feature_flow PASSED [100%]
# 
# ✅ Feature flow verified
```

## Permission Boundary Tests

```python
@pytest.mark.asyncio
async def test_client_permission_denied(client_app):
    """Verify client respects permission boundaries."""
    
    # Get consultant token (limited permissions)
    consultant_token = await get_consultant_token(client_app)
    consultant_headers = {"Authorization": f"Bearer {consultant_token}"}
    
    # Attempt restricted action (create client)
    response = client_app.post(
        "/api/v1/clients/",
        json={"name": "Test"},
        headers=consultant_headers
    )
    
    # Should be forbidden
    assert response.status_code == 403
    assert response.json()["detail"] == "Not enough permissions"

@pytest.mark.asyncio
async def test_client_isolation(client_app):
    """Verify feature enforces multi-tenant isolation."""
    
    # Create two clients
    client1 = await create_client(client_app, "Client 1")
    client2 = await create_client(client_app, "Client 2")
    
    # Create user in client1
    user1_token = await create_user_in_client(client_app, client1)
    
    # User1 tries to access client2
    response = client_app.get(
        f"/api/v1/clients/{client2['id']}/",
        headers={"Authorization": f"Bearer {user1_token}"}
    )
    
    # Should not have access
    assert response.status_code == 403
```

### Running Permission Tests

```bash
pytest backend/tests/integration/test_client.py::test_client_permission_denied -v
pytest backend/tests/integration/test_client.py::test_client_isolation -v

# Should all pass
```

## Data Consistency Tests

```python
@pytest.mark.asyncio
async def test_client_data_consistency(client_app):
    """Verify CREATE → READ → UPDATE → DELETE consistency."""
    
    admin_token = await get_admin_token(client_app)
    headers = {"Authorization": f"Bearer {admin_token}"}
    
    # CREATE
    create_resp = client_app.post(
        "/api/v1/clients/",
        json={"name": "Test Client"},
        headers=headers
    )
    assert create_resp.status_code == 201
    client_id = create_resp.json()["id"]
    
    # READ
    read_resp = client_app.get(
        f"/api/v1/clients/{client_id}/",
        headers=headers
    )
    assert read_resp.status_code == 200
    assert read_resp.json()["name"] == "Test Client"
    
    # UPDATE
    update_resp = client_app.put(
        f"/api/v1/clients/{client_id}/",
        json={"name": "Updated Client"},
        headers=headers
    )
    assert update_resp.status_code == 200
    
    # VERIFY UPDATE
    verify_resp = client_app.get(
        f"/api/v1/clients/{client_id}/",
        headers=headers
    )
    assert verify_resp.json()["name"] == "Updated Client"
    
    # DELETE
    delete_resp = client_app.delete(
        f"/api/v1/clients/{client_id}/",
        headers=headers
    )
    assert delete_resp.status_code == 204
    
    # VERIFY DELETED
    not_found_resp = client_app.get(
        f"/api/v1/clients/{client_id}/",
        headers=headers
    )
    assert not_found_resp.status_code == 404
```

### Running Data Consistency Tests

```bash
pytest backend/tests/integration/test_client.py::test_client_data_consistency -v

# Output shows:
# 1. CREATE successful
# 2. READ returns correct data
# 3. UPDATE applied
# 4. DELETE removed
# All in proper sequence
```

## Complete Test Suite

Generate all test types:

```bash
python scripts/generate_integration_tests.py

# Select: 4 (All of the above)
# Feature name: client
```

Creates three test files:
- `test_client.py` - Feature flow
- `test_client_permission.py` - Permission boundaries
- `test_client_data.py` - CRUD consistency

### Run All Integration Tests

```bash
pytest backend/tests/integration/ -v

# Output:
# test_client_feature_flow PASSED
# test_client_permission_denied PASSED
# test_client_isolation PASSED
# test_client_data_consistency PASSED
#
# ===== 4 passed in 2.34s =====
```

## Real-World Scenarios

### Tool Execution Workflow

Test complete tool execution flow:

```python
@pytest.mark.asyncio
async def test_tool_execution_workflow(client_app):
    """
    Integration: Client user executes ESG assessment tool
    
    Workflow:
    1. Client admin assigns tool to client
    2. Client user lists available tools
    3. Client user executes tool with data
    4. Results saved and accessible
    """
    
    # Authenticate client admin
    admin_token = await authenticate(client_app, "admin@client.com")
    admin_headers = {"Authorization": f"Bearer {admin_token}"}
    
    # Step 1: Assign tool (admin only)
    assign = client_app.post(
        "/api/v1/client-tool-access/",
        json={"tool_id": 1, "client_id": 1},
        headers=admin_headers
    )
    assert assign.status_code == 201
    
    # Authenticate client user
    user_token = await authenticate(client_app, "user@client.com")
    user_headers = {"Authorization": f"Bearer {user_token}"}
    
    # Step 2: List available tools
    tools = client_app.get(
        "/api/v1/tools/available",
        headers=user_headers
    )
    assert len(tools.json()) > 0
    
    # Step 3: Execute tool
    execution = client_app.post(
        "/api/v1/tools/execute",
        json={
            "tool_id": 1,
            "parameters": {"company_size": "1000"}
        },
        headers=user_headers
    )
    assert execution.status_code == 201
    execution_id = execution.json()["id"]
    
    # Step 4: Verify results saved
    results = client_app.get(
        f"/api/v1/tools/executions/{execution_id}/",
        headers=user_headers
    )
    assert results.status_code == 200
    assert results.json()["status"] == "completed"
```

### Multi-Client Isolation

Test isolation between clients:

```python
@pytest.mark.asyncio
async def test_multi_client_isolation(client_app):
    """Verify data isolation between different clients."""
    
    # Create client1 with user1
    client1 = await create_client(client_app, "Company A")
    user1 = await create_user(client_app, client1, "user1@a.com")
    token1 = await authenticate(client_app, "user1@a.com")
    
    # Create client2 with user2
    client2 = await create_client(client_app, "Company B")
    user2 = await create_user(client_app, client2, "user2@b.com")
    token2 = await authenticate(client_app, "user2@b.com")
    
    # User1 creates a client note
    note1 = client_app.post(
        "/api/v1/clients/notes/",
        json={"text": "Secret for A"},
        headers={"Authorization": f"Bearer {token1}"}
    )
    assert note1.status_code == 201
    
    # User2 tries to access User1's note
    access = client_app.get(
        f"/api/v1/clients/notes/{note1.json()['id']}/",
        headers={"Authorization": f"Bearer {token2}"}
    )
    
    # Should be denied
    assert access.status_code == 403
```

## Fixtures & Helpers

Create `conftest.py` with common fixtures:

```python
# backend/tests/conftest.py
import pytest
from sqlalchemy.ext.asyncio import AsyncSession

@pytest.fixture
async def admin_token(client_app):
    """Get admin authentication token."""
    response = client_app.post("/api/v1/auth/login", json={
        "email": "admin@test.com",
        "password": "password"
    })
    return response.json()["access_token"]

@pytest.fixture
async def client_user_token(client_app):
    """Get client user authentication token."""
    response = client_app.post("/api/v1/auth/login", json={
        "email": "user@client.com",
        "password": "password"
    })
    return response.json()["access_token"]

@pytest.fixture
async def admin_headers(admin_token):
    """Get admin request headers."""
    return {"Authorization": f"Bearer {admin_token}"}

async def create_client(client_app, name):
    """Helper: Create a test client."""
    response = client_app.post(
        "/api/v1/clients/",
        json={"name": name},
        headers=admin_headers
    )
    return response.json()
```

## CI/CD Integration

Run integration tests on every PR:

```yaml
# .github/workflows/integration-tests.yml
name: Integration Tests

on: [pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: password
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
    
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-python@v2
        with:
          python-version: 3.10
      
      - name: Install dependencies
        run: |
          pip install -r backend/requirements.txt
          pip install pytest pytest-asyncio
      
      - name: Run integration tests
        run: pytest backend/tests/integration/ -v --tb=short
        env:
          DATABASE_URL: postgresql://user:password@localhost/test_db
```

## Best Practices

✅ **DO**:
- Test complete workflows, not single queries
- Include permission/isolation checks
- Use fixtures for auth headers
- Test error cases (404, 403, etc.)
- Verify data state after operations

❌ **DON'T**:
- Mock the database (test real interactions)
- Test unrelated features in one test
- Skip permission tests
- Hardcode user IDs (use fixtures)
- Ignore isolation requirements

## Troubleshooting

### Issue: Tests fail with "Database locked"

Solution: Ensure database migrations run first

```bash
alembic upgrade head
pytest backend/tests/integration/ -v
```

### Issue: "Auth token expired"

Solution: Extend token lifetime for tests

```python
# conftest.py
@pytest.fixture
async def admin_token(client_app, monkeypatch):
    # Extend token lifetime during tests
    monkeypatch.setenv("JWT_EXPIRATION_HOURS", "24")
    ...
```

### Issue: Permission tests always pass

Solution: Verify endpoint has `@require_permission` decorator

```python
# BEFORE (no security)
@router.post("/clients/")
async def create_client(...):
    ...

# AFTER (with security)
@router.post(
    "/clients/",
    dependencies=[Depends(require_permission("clients.create"))]
)
async def create_client(...):
    ...
```

## Success Criteria

✅ All feature workflows execute successfully
✅ Permission boundaries enforced correctly
✅ CRUD operations maintain data consistency
✅ Multi-client isolation verified
✅ Error cases handled appropriately
✅ Tests document expected behavior
