#!/usr/bin/env python3
"""
Integration Test Generator - Creates multi-component workflow tests.

This script generates integration tests that verify complete workflows,
testing interactions between multiple endpoints and ensuring data
flows correctly across the system.

Usage:
    python generate_integration_tests.py

Options:
    feature_flow    - Test complete feature workflow
    api_sequence    - Test endpoint call sequences
    error_cases     - Test failure scenarios
    data_validation - Verify data consistency
"""

import sys
from pathlib import Path
from typing import Optional


def find_backend_path() -> Optional[Path]:
    """Find backend directory."""
    current = Path(__file__)
    while current != current.parent:
        if (current / "backend" / "app").exists():
            return current / "backend"
        current = current.parent
    return None


def generate_feature_flow_test(feature: str, endpoints: list) -> str:
    """Generate integration test for feature flow."""
    test_name = f"test_{feature}_feature_flow"
    endpoints_str = "\n    ".join([f"# {ep}" for ep in endpoints])
    
    test_code = f'''import pytest
from sqlalchemy.ext.asyncio import AsyncMock

@pytest.mark.asyncio
async def {test_name}(client_app):
    """
    Integration test: Complete {feature} workflow
    
    Workflow:
    {endpoints_str}
    """
    
    # SETUP: Authenticate
    admin_response = client_app.post("/api/v1/auth/login", json={{
        "email": "admin@test.com",
        "password": "secure_password"
    }})
    admin_token = admin_response.json()["access_token"]
    admin_headers = {{"Authorization": f"Bearer {{admin_token}}"}}
    
    # Step 1: TODO - First endpoint
    # response = client_app.post(...)
    # assert response.status_code == 201
    
    # Step 2: TODO - Second endpoint
    # response = client_app.get(...)
    # assert response.status_code == 200
    
    # VERIFY: Final state
    # assert data["status"] == "completed"
'''
    
    return test_code


def generate_permission_test(feature: str) -> str:
    """Generate permission boundary tests."""
    test_code = f'''@pytest.mark.asyncio
async def test_{feature}_permission_denied(client_app):
    """Verify {feature} respects permission boundaries."""
    
    # Get consultant token (limited permissions)
    consultant_token = await get_consultant_token(client_app)
    consultant_headers = {{"Authorization": f"Bearer {{consultant_token}}"}}
    
    # Attempt restricted action
    response = client_app.post(
        "/api/v1/clients/",
        json={{"name": "Test"}},
        headers=consultant_headers
    )
    
    # Should be forbidden
    assert response.status_code == 403

@pytest.mark.asyncio
async def test_{feature}_client_isolation(client_app):
    """Verify {feature} enforces multi-tenant isolation."""
    
    # Create two clients
    client1 = await create_client(client_app, "Client 1")
    client2 = await create_client(client_app, "Client 2")
    
    # Create user in client1
    user1_token = await create_user_in_client(client_app, client1)
    
    # User1 tries to access client2
    response = client_app.get(
        f"/api/v1/clients/{{client2['id']}}/",
        headers={{"Authorization": f"Bearer {{user1_token}}"}}
    )
    
    # Should not have access
    assert response.status_code == 403
'''
    
    return test_code


def generate_data_consistency_test(entity: str) -> str:
    """Generate CRUD data consistency test."""
    test_code = f'''@pytest.mark.asyncio
async def test_{entity}_data_consistency(client_app):
    """Verify CREATE → READ → UPDATE → DELETE consistency."""
    
    admin_token = await get_admin_token(client_app)
    headers = {{"Authorization": f"Bearer {{admin_token}}"}}
    
    # CREATE
    create_resp = client_app.post(
        "/api/v1/{entity.lower()}s/",
        json={{"name": "Test {{entity}}"}},
        headers=headers
    )
    assert create_resp.status_code == 201
    entity_id = create_resp.json()["id"]
    
    # READ
    read_resp = client_app.get(
        f"/api/v1/{entity.lower()}s/{{entity_id}}/",
        headers=headers
    )
    assert read_resp.status_code == 200
    assert read_resp.json()["name"] == "Test {{entity}}"
    
    # UPDATE
    update_resp = client_app.put(
        f"/api/v1/{entity.lower()}s/{{entity_id}}/",
        json={{"name": "Updated {{entity}}"}},
        headers=headers
    )
    assert update_resp.status_code == 200
    
    # VERIFY UPDATE
    verify_resp = client_app.get(
        f"/api/v1/{entity.lower()}s/{{entity_id}}/",
        headers=headers
    )
    assert verify_resp.json()["name"] == "Updated {{entity}}"
    
    # DELETE
    delete_resp = client_app.delete(
        f"/api/v1/{entity.lower()}s/{{entity_id}}/",
        headers=headers
    )
    assert delete_resp.status_code == 204
    
    # VERIFY DELETED
    not_found_resp = client_app.get(
        f"/api/v1/{entity.lower()}s/{{entity_id}}/",
        headers=headers
    )
    assert not_found_resp.status_code == 404
'''
    
    return test_code


def create_test_file(backend_path: Path, test_type: str, name: str) -> None:
    """Create integration test file."""
    tests_dir = backend_path / "tests" / "integration"
    tests_dir.mkdir(parents=True, exist_ok=True)
    
    test_file = tests_dir / f"test_{name}.py"
    
    if test_type == "feature_flow":
        endpoints = [
            "POST /api/v1/clients/",
            "GET /api/v1/clients/{id}",
            "PUT /api/v1/clients/{id}",
            "DELETE /api/v1/clients/{id}"
        ]
        test_code = generate_feature_flow_test(name, endpoints)
    elif test_type == "permission":
        test_code = generate_permission_test(name)
    elif test_type == "data":
        test_code = generate_data_consistency_test(name)
    else:
        test_code = "# TODO: Add test"
    
    with open(test_file, "w") as f:
        f.write(test_code)
    
    print(f"✅ Created: {test_file}")


if __name__ == "__main__":
    print("""
╔════════════════════════════════════════════════════════════════╗
║    Integration Test Generator - ESG Sustainify                ║
║                                                                ║
║  Generate multi-component workflow tests                      ║
╚════════════════════════════════════════════════════════════════╝
""")
    
    backend_path = find_backend_path()
    if not backend_path:
        print("ERROR: Could not find backend directory")
        sys.exit(1)
    
    print("\nTest Types:")
    print("  1. Feature flow (complete workflow)")
    print("  2. Permission boundary tests")
    print("  3. Data consistency tests")
    print("  4. All of the above")
    
    choice = input("\nSelect (1-4): ").strip()
    
    feature_name = input("Feature/entity name (e.g., client): ").strip()
    
    if choice == "1":
        create_test_file(backend_path, "feature_flow", feature_name)
    elif choice == "2":
        create_test_file(backend_path, "permission", feature_name)
    elif choice == "3":
        create_test_file(backend_path, "data", feature_name)
    elif choice == "4":
        create_test_file(backend_path, "feature_flow", feature_name)
        create_test_file(backend_path, "permission", feature_name)
        create_test_file(backend_path, "data", feature_name)
    
    print("\n✅ Integration tests generated!")
    print(f"\nRun tests with: pytest backend/tests/integration/ -v")
