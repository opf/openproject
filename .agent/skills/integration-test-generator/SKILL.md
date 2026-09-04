---
name: integration-test-generator
description: Generates integration tests that verify complete workflows across multiple components (backend services, endpoints, frontend). Creates test scenarios for complex multi-step flows like client creation → tool assignment → report generation. Use when testing features that span multiple layers or need realistic data flow validation.
---

# Integration Test Generator

This skill generates integration tests for multi-component workflows.

## When to use this skill

- Test workflows: "Create integration test for client creation flow"
- Complex features: "Test tool assignment with all dependencies"
- Regression: "Generate tests for known bugs"
- Acceptance tests: "Verify complete user journeys"
- Stakeholder validation: "Demonstrate feature works end-to-end"

## How to use this skill

### Step 1: Run generator

```bash
python .agent/skills/integration-test-generator/scripts/generate_integration_tests.py
```

Options:
- **Generate test** - Create integration test for workflow
- **Test scenario** - Specific user journey
- **API flow** - Multi-endpoint sequence
- **Data validation** - Verify data across components

### Step 2: Define workflow

Specify:
- Starting state (who, permissions)
- Step sequence (endpoints called)
- Expected outcomes (data created, side effects)
- Error cases (what should fail?)

### Step 3: Review generated test

Generated test covers:
- Setup (auth, initial data)
- Execute (call endpoints in sequence)
- Verify (assert results at each step)
- Cleanup (teardown test data)

### Step 4: Run test

```bash
pytest backend/tests/integration/test_client_flow.py -v
```

## Test Patterns

### Complete Feature Flow

```python
@pytest.mark.asyncio
async def test_client_creation_workflow(client_app):
    """
    Integration test: Create client → Assign tools → Generate report
    
    Workflow:
    1. Admin creates new client company
    2. Client admin creates user account
    3. Assign ESG tools to company
    4. Client user logs in and selects tool
    5. Tool execution and report generation
    """
    
    # SETUP: Authenticate as super admin
    admin_response = client_app.post("/api/v1/auth/login", json={
        "email": "admin@esg.com",
        "password": "secure_password"
    })
    admin_token = admin_response.json()["access_token"]
    admin_headers = {"Authorization": f"Bearer {admin_token}"}
    
    # STEP 1: Create client company
    client_response = client_app.post(
        "/api/v1/clients/",
        json={
            "name": "Acme Corp",
            "industry": "Manufacturing"
        },
        headers=admin_headers,
    )
    assert client_response.status_code == 201
    client_data = client_response.json()
    client_id = client_data["id"]
    
    # VERIFY: Client created with correct data
    assert client_data["name"] == "Acme Corp"
    assert client_data["industry"] == "Manufacturing"
    
    # STEP 2: Assign ESG tools to company
    tools = [1, 2, 3]  # EMS, Carbon, Water
    for tool_id in tools:
        assign_response = client_app.post(
            f"/api/v1/clients/{client_id}/tools/",
            json={"tool_id": tool_id},
            headers=admin_headers,
        )
        assert assign_response.status_code == 201
    
    # VERIFY: Tools assigned
    tools_response = client_app.get(
        f"/api/v1/clients/{client_id}/tools/",
        headers=admin_headers,
    )
    assigned_tools = tools_response.json()
    assert len(assigned_tools) == 3
    
    # STEP 3: Create client user
    user_response = client_app.post(
        f"/api/v1/clients/{client_id}/users/",
        json={
            "email": "user@acme.com",
            "first_name": "John",
            "last_name": "Doe"
        },
        headers=admin_headers,
    )
    assert user_response.status_code == 201
    user_id = user_response.json()["id"]
    
    # STEP 4: Client user logs in
    user_login = client_app.post("/api/v1/auth/login", json={
        "email": "user@acme.com",
        "password": "temp_password"
    })
    # May require password change flow
    
    # STEP 5: Execute tool and verify report
    user_token = user_login.json()["access_token"]
    user_headers = {"Authorization": f"Bearer {user_token}"}
    
    tool_response = client_app.post(
        "/api/v1/tools/1/execute/",
        json={"data": "facility_emissions"},
        headers=user_headers,
    )
    assert tool_response.status_code == 200
    report = tool_response.json()
    assert "esg_score" in report
    assert report["evaluation_date"] is not None
    
    # VERIFY: Final state
    assert report["status"] == "completed"
    assert report["tool_id"] == 1
    assert report["company_id"] == client_id
```

## Test Scenarios

### Scenario 1: Client Workflow

User actions:
1. Login as super admin
2. Create client (POST)
3. Create client contact (POST)
4. Assign tools (POST)
5. Logout

```python
@pytest.mark.asyncio
async def test_client_administration_workflow(client_app):
    """Test full client administration workflow."""
    # ... test implementation
```

### Scenario 2: Permission Escalation Test

Verify permission boundaries:

```python
@pytest.mark.asyncio
async def test_client_user_cannot_see_other_clients(client_app):
    """Verify client users only access own company."""
    
    # Create two clients
    admin_tokens = await create_admin_auth(client_app)
    
    client1 = await create_client(client_app, admin_tokens, "Client 1")
    client2 = await create_client(client_app, admin_tokens, "Client 2")
    
    # Create users in each client
    user1 = await create_user(client_app, admin_tokens, client1["id"])
    user2 = await create_user(client_app, admin_tokens, client2["id"])
    
    # Login as user1 (in client1)
    user1_token = await login(client_app, user1["email"])
    
    # Verify user1 CANNOT access client2
    response = client_app.get(
        f"/api/v1/clients/{client2['id']}/",
        headers={"Authorization": f"Bearer {user1_token}"}
    )
    assert response.status_code == 403  # Forbidden
```

### Scenario 3: Data Consistency

Verify data persists and relates correctly:

```python
@pytest.mark.asyncio
async def test_data_consistency_across_requests(client_app):
    """Verify data consistency: create → read → update → delete."""
    
    admin_token = await get_admin_token(client_app)
    headers = {"Authorization": f"Bearer {admin_token}"}
    
    # CREATE
    create_response = client_app.post(
        "/api/v1/clients/",
        json={"name": "Test Client"},
        headers=headers
    )
    client_id = create_response.json()["id"]
    
    # READ
    read_response = client_app.get(
        f"/api/v1/clients/{client_id}/",
        headers=headers
    )
    assert read_response.json()["name"] == "Test Client"
    
    # UPDATE
    update_response = client_app.put(
        f"/api/v1/clients/{client_id}/",
        json={"name": "Updated Client"},
        headers=headers
    )
    assert update_response.status_code == 200
    
    # VERIFY
    verify_response = client_app.get(
        f"/api/v1/clients/{client_id}/",
        headers=headers
    )
    assert verify_response.json()["name"] == "Updated Client"
    
    # DELETE
    delete_response = client_app.delete(
        f"/api/v1/clients/{client_id}/",
        headers=headers
    )
    assert delete_response.status_code == 204
    
    # VERIFY DELETED
    get_deleted = client_app.get(
        f"/api/v1/clients/{client_id}/",
        headers=headers
    )
    assert get_deleted.status_code == 404
```

## Test Fixtures

Reusable test helpers:

```python
@pytest.fixture
async def admin_auth(client_app):
    """Get admin authentication token."""
    response = client_app.post("/api/v1/auth/login", json={
        "email": "admin@test.com",
        "password": "admin_pass"
    })
    return response.json()["access_token"]

@pytest.fixture
async def client_company(client_app, admin_auth):
    """Create test client company."""
    response = client_app.post(
        "/api/v1/clients/",
        json={"name": "Test Client"},
        headers={"Authorization": f"Bearer {admin_auth}"}
    )
    return response.json()

@pytest.fixture
async def client_user(client_app, admin_auth, client_company):
    """Create test user in a client company."""
    response = client_app.post(
        f"/api/v1/clients/{client_company['id']}/users/",
        json={"email": "user@test.com"},
        headers={"Authorization": f"Bearer {admin_auth}"}
    )
    return response.json()
```

## Error Case Testing

Test failure scenarios:

```python
@pytest.mark.asyncio
async def test_missing_required_field():
    """Verify proper error on missing required field."""
    response = client_app.post("/api/v1/clients/", json={})
    assert response.status_code == 422
    errors = response.json()["detail"]
    assert any(e["loc"][0] == "name" for e in errors)

@pytest.mark.asyncio
async def test_unauthorized_access():
    """Verify 401 when missing credentials."""
    response = client_app.get("/api/v1/clients/")
    assert response.status_code == 401

@pytest.mark.asyncio
async def test_forbidden_by_permission():
    """Verify 403 when insufficient permissions."""
    user_token = get_consultant_token()
    response = client_app.post(
        "/api/v1/clients/",
        json={"name": "Test"},
        headers={"Authorization": f"Bearer {user_token}"}
    )
    assert response.status_code == 403
```

## Performance in Integration Tests

Test relevant performance characteristics:

```python
@pytest.mark.asyncio
async def test_list_clients_performance():
    """Verify list endpoint performs well at scale."""
    admin_token = await get_admin_token()
    
    # Create 100 clients
    for i in range(100):
        await create_client(admin_token, f"Client {i}")
    
    # Measure list performance
    import time
    start = time.time()
    response = client_app.get(
        "/api/v1/clients/?limit=50",
        headers={"Authorization": f"Bearer {admin_token}"}
    )
    elapsed = time.time() - start
    
    assert elapsed < 1.0  # Should complete in < 1 second
    assert len(response.json()) == 50
```

## Running Integration Tests

```bash
# Run all integration tests
pytest backend/tests/integration/ -v

# Run specific test file
pytest backend/tests/integration/test_client_flow.py -v

# Run specific test
pytest backend/tests/integration/test_client_flow.py::test_client_creation_workflow -v

# Run with coverage
pytest backend/tests/integration/ --cov=app --cov-report=html
```

## Best Practices

✅ **Test complete workflows** - Not just individual endpoints  
✅ **Use realistic data** - Mirror production scenarios  
✅ **Test permissions** - Verify access control  
✅ **Test error cases** - Invalid inputs, missing auth  
✅ **Clean up after tests** - Don't leave test data  
✅ **Use fixtures** - Reusable setup/teardown  

❌ **Don't:**
- Test implementation details
- Make tests interdependent
- Use production data
- Skip error cases
- Make tests slow (> 1 sec each)

## See Also

- `test-runner` - Execute integration tests
- `permission-validator` - Verify RBAC in tests
- `code-quality-auditor` - Test code quality
- `vertical-slice-generator` - Generates test stubs
