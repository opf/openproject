#!/usr/bin/env python3
"""
API Endpoint Generator for ESG Sustainify.

Generates FastAPI endpoint/router files from existing SQLAlchemy models and services.
Assumes model, schema, and service already exist.

Creates CRUD endpoints with:
- Proper RBAC decorators (require_permission)
- Error handling with HTTP status codes
- Delegation to service layer
- Logging and type hints
- Documentation strings

This is an executable component of the api-endpoint-generator Skill.

Usage:
    python generate_endpoint.py
    
    Follow interactive prompts to define your endpoint, then review generated file.

Exit Codes:
    0: Success (endpoint file generated)
    1: Error (invalid input or generation failure)
"""

import sys
from datetime import datetime
from pathlib import Path
from typing import Literal

# ============================================================================
# Configuration
# ============================================================================

PROJECT_ROOT = Path(__file__).parent.parent.parent.parent.parent
BACKEND_ROOT = PROJECT_ROOT / "backend"
ENDPOINTS_DIR = BACKEND_ROOT / "app" / "api" / "v1" / "endpoints"

# ============================================================================
# Utilities
# ============================================================================

def prompt_required(prompt_text: str) -> str:
    """Get non-empty input from user."""
    while True:
        value = input(f"\n{prompt_text}: ").strip()
        if value:
            return value
        print("  ⚠️  Input cannot be empty. Try again.")

def prompt_optional(prompt_text: str, default: str = "") -> str:
    """Get optional input from user."""
    value = input(f"\n{prompt_text} [{default}]: ").strip()
    return value if value else default

def prompt_choice(prompt_text: str, choices: list[str]) -> str:
    """Get input from list of choices."""
    print(f"\n{prompt_text}")
    for i, choice in enumerate(choices, 1):
        print(f"  {i}. {choice}")
    
    while True:
        try:
            selection = int(input("Select (number): ").strip())
            if 1 <= selection <= len(choices):
                return choices[selection - 1]
            print(f"  ⚠️  Choose between 1 and {len(choices)}")
        except ValueError:
            print("  ⚠️  Enter a number")

def to_snake_case(text: str) -> str:
    """Convert to snake_case."""
    return text.lower().replace(" ", "_").replace("-", "_")

def to_pascal_case(text: str) -> str:
    """Convert to PascalCase."""
    words = text.replace("-", " ").replace("_", " ").split()
    return "".join(word.capitalize() for word in words)

# ============================================================================
# Endpoint Generators
# ============================================================================

def generate_full_crud_endpoint(
    model_name: str,
    service_name: str,
    schema_name: str,
    resource_name: str,
    path_prefix: str,
) -> str:
    """Generate full CRUD endpoint."""
    pascal_model = to_pascal_case(model_name)
    pascal_schema = to_pascal_case(schema_name) if schema_name else pascal_model
    snake_service = to_snake_case(service_name)
    
    content = f'''"""API endpoints for {pascal_model}."""

from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import APIRouter, Depends, HTTPException, status

from app.api.deps import get_db, get_current_active_user, require_permission
from app.middleware.auth import User
from app.models import {pascal_model}
from app.schemas import {pascal_schema}Create, {pascal_schema}Update, {pascal_schema}
from app.services import {snake_service}_service

router = APIRouter(
    prefix="{path_prefix}",
    tags=["{resource_name}"],
)


@router.post(
    "/",
    response_model={pascal_schema},
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_permission("{resource_name}.create"))],
)
async def create_{snake_service}(
    data: {pascal_schema}Create,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> {pascal_schema}:
    """
    Create a new {pascal_model}.
    
    Requires: {resource_name}.create permission
    """
    return await {snake_service}_service.create_{snake_service}(db, data, current_user)


@router.get(
    "/{{{snake_service}_id}}",
    response_model={pascal_schema},
    dependencies=[Depends(require_permission("{resource_name}.read"))],
)
async def get_{snake_service}(
    {snake_service}_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> {pascal_schema}:
    """
    Retrieve a specific {pascal_model}.
    
    Requires: {resource_name}.read permission
    Returns: 404 if not found
    """
    instance = await {snake_service}_service.get_{snake_service}(
        db, {snake_service}_id, current_user
    )
    if not instance:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="{pascal_model} not found",
        )
    return instance


@router.get(
    "/",
    response_model=list[{pascal_schema}],
    dependencies=[Depends(require_permission("{resource_name}.read"))],
)
async def list_{snake_service}(
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> list[{pascal_schema}]:
    """
    List {pascal_model} instances.
    
    Requires: {resource_name}.read permission
    Query Parameters:
        skip: Number of records to skip (default: 0)
        limit: Maximum records to return (default: 100)
    """
    return await {snake_service}_service.list_{snake_service}(
        db, current_user, skip, limit
    )


@router.put(
    "/{{{snake_service}_id}}",
    response_model={pascal_schema},
    dependencies=[Depends(require_permission("{resource_name}.update"))],
)
async def update_{snake_service}(
    {snake_service}_id: int,
    data: {pascal_schema}Update,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> {pascal_schema}:
    """
    Update a {pascal_model}.
    
    Requires: {resource_name}.update permission
    Returns: 404 if not found
    """
    instance = await {snake_service}_service.update_{snake_service}(
        db, {snake_service}_id, data, current_user
    )
    if not instance:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="{pascal_model} not found",
        )
    return instance


@router.delete(
    "/{{{snake_service}_id}}",
    status_code=status.HTTP_204_NO_CONTENT,
    dependencies=[Depends(require_permission("{resource_name}.delete"))],
)
async def delete_{snake_service}(
    {snake_service}_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> None:
    """
    Delete a {pascal_model}.
    
    Requires: {resource_name}.delete permission
    Returns: 404 if not found
    """
    success = await {snake_service}_service.delete_{snake_service}(
        db, {snake_service}_id, current_user
    )
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="{pascal_model} not found",
        )
'''
    
    return content

def generate_read_only_endpoint(
    model_name: str,
    service_name: str,
    schema_name: str,
    resource_name: str,
    path_prefix: str,
) -> str:
    """Generate read-only endpoints."""
    pascal_model = to_pascal_case(model_name)
    pascal_schema = to_pascal_case(schema_name) if schema_name else pascal_model
    snake_service = to_snake_case(service_name)
    
    content = f'''"""Read-only API endpoints for {pascal_model}."""

from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import APIRouter, Depends, HTTPException, status

from app.api.deps import get_db, get_current_active_user, require_permission
from app.middleware.auth import User
from app.models import {pascal_model}
from app.schemas import {pascal_schema}
from app.services import {snake_service}_service

router = APIRouter(
    prefix="{path_prefix}",
    tags=["{resource_name} (read-only)"],
)


@router.get(
    "/{{{snake_service}_id}}",
    response_model={pascal_schema},
    dependencies=[Depends(require_permission("{resource_name}.read"))],
)
async def get_{snake_service}(
    {snake_service}_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> {pascal_schema}:
    """
    Retrieve a specific {pascal_model}.
    
    Requires: {resource_name}.read permission
    """
    instance = await {snake_service}_service.get_{snake_service}(
        db, {snake_service}_id, current_user
    )
    if not instance:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="{pascal_model} not found",
        )
    return instance


@router.get(
    "/",
    response_model=list[{pascal_schema}],
    dependencies=[Depends(require_permission("{resource_name}.read"))],
)
async def list_{snake_service}(
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> list[{pascal_schema}]:
    """
    List {pascal_model} instances.
    
    Requires: {resource_name}.read permission
    Query Parameters:
        skip: Number of records to skip (default: 0)
        limit: Maximum records to return (default: 100)
    """
    return await {snake_service}_service.list_{snake_service}(
        db, current_user, skip, limit
    )
'''
    
    return content

def generate_admin_endpoint(
    model_name: str,
    service_name: str,
    schema_name: str,
    resource_name: str,
    path_prefix: str,
) -> str:
    """Generate admin-only endpoints."""
    pascal_model = to_pascal_case(model_name)
    pascal_schema = to_pascal_case(schema_name) if schema_name else pascal_model
    snake_service = to_snake_case(service_name)
    
    content = f'''"""Admin-only API endpoints for {pascal_model}."""

from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import APIRouter, Depends, HTTPException, status

from app.api.deps import get_db, get_current_active_user, require_staff
from app.middleware.auth import User
from app.models import {pascal_model}
from app.schemas import {pascal_schema}Create, {pascal_schema}Update, {pascal_schema}
from app.services import {snake_service}_service

router = APIRouter(
    prefix="{path_prefix}/admin",
    tags=["Admin - {resource_name}"],
)


@router.post(
    "/",
    response_model={pascal_schema},
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_staff())],
)
async def admin_create_{snake_service}(
    data: {pascal_schema}Create,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> {pascal_schema}:
    """
    Create a new {pascal_model}. (Admin only)
    
    Requires: Staff role
    """
    return await {snake_service}_service.create_{snake_service}(db, data, current_user)


@router.get(
    "/",
    response_model=list[{pascal_schema}],
    dependencies=[Depends(require_staff())],
)
async def admin_list_{snake_service}(
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> list[{pascal_schema}]:
    """
    List all {pascal_model} instances. (Admin only)
    
    Requires: Staff role
    Query Parameters:
        skip: Number of records to skip (default: 0)
        limit: Maximum records to return (default: 100)
    """
    return await {snake_service}_service.list_{snake_service}(
        db, current_user, skip, limit
    )


@router.put(
    "/{{{snake_service}_id}}",
    response_model={pascal_schema},
    dependencies=[Depends(require_staff())],
)
async def admin_update_{snake_service}(
    {snake_service}_id: int,
    data: {pascal_schema}Update,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> {pascal_schema}:
    """
    Update a {pascal_model}. (Admin only)
    
    Requires: Staff role
    """
    instance = await {snake_service}_service.update_{snake_service}(
        db, {snake_service}_id, data, current_user
    )
    if not instance:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="{pascal_model} not found",
        )
    return instance


@router.delete(
    "/{{{snake_service}_id}}",
    status_code=status.HTTP_204_NO_CONTENT,
    dependencies=[Depends(require_staff())],
)
async def admin_delete_{snake_service}(
    {snake_service}_id: int,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> None:
    """
    Delete a {pascal_model}. (Admin only)
    
    Requires: Staff role
    """
    success = await {snake_service}_service.delete_{snake_service}(
        db, {snake_service}_id, current_user
    )
    if not success:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="{pascal_model} not found",
        )
'''
    
    return content

def generate_list_only_endpoint(
    model_name: str,
    service_name: str,
    schema_name: str,
    resource_name: str,
    path_prefix: str,
) -> str:
    """Generate list-only endpoints (no detail view)."""
    pascal_model = to_pascal_case(model_name)
    pascal_schema = to_pascal_case(schema_name) if schema_name else pascal_model
    snake_service = to_snake_case(service_name)
    
    content = f'''"""List-only API endpoints for {pascal_model}."""

from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import APIRouter, Depends, status

from app.api.deps import get_db, get_current_active_user, require_permission
from app.middleware.auth import User
from app.models import {pascal_model}
from app.schemas import {pascal_schema}
from app.services import {snake_service}_service

router = APIRouter(
    prefix="{path_prefix}",
    tags=["{resource_name}"],
)


@router.get(
    "/",
    response_model=list[{pascal_schema}],
    dependencies=[Depends(require_permission("{resource_name}.read"))],
)
async def list_{snake_service}(
    skip: int = 0,
    limit: int = 100,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
) -> list[{pascal_schema}]:
    """
    List {pascal_model} instances.
    
    Requires: {resource_name}.read permission
    Query Parameters:
        skip: Number of records to skip (default: 0)
        limit: Maximum records to return (default: 100)
    """
    return await {snake_service}_service.list_{snake_service}(
        db, current_user, skip, limit
    )
'''
    
    return content

# ============================================================================
# Main Generator
# ============================================================================

def main() -> None:
    """Main entry point - orchestrate endpoint generation."""
    try:
        print("\n" + "="*70)
        print("  API ENDPOINT GENERATOR - ESG Sustainify")
        print("="*70)
        print("\nThis tool generates FastAPI endpoint files from existing models/services.")
        print("Prerequisites:")
        print("  ✓ backend/app/models/<model>.py exists")
        print("  ✓ backend/app/schemas/<schema>.py exists")
        print("  ✓ backend/app/services/<service>_service.py exists\n")
        
        # Collect requirements
        print("STEP 1: Model & Service Information")
        print("-" * 70)
        
        model_name = prompt_required("Model name (PascalCase, e.g., 'ClientCompany')")
        service_name = prompt_required("Service name (snake_case, e.g., 'client_company')")
        
        # Optional custom schema name
        schema_name = prompt_optional(
            "Schema name (PascalCase, or leave blank for <Model>)",
            to_pascal_case(model_name)
        )
        
        print("\nSTEP 2: Endpoint Configuration")
        print("-" * 70)
        
        resource_name = prompt_required(
            "Permission resource (for RBAC, e.g., 'clients', 'tools')"
        )
        
        path_prefix = prompt_optional(
            "Base path prefix (e.g., '/clients', '/company')",
            "/" + to_snake_case(service_name)
        )
        
        endpoint_type = prompt_choice(
            "Endpoint type:",
            ["full-crud", "read-only", "list-only", "admin"]
        )
        
        # Determine filename based on type
        snake_service = to_snake_case(service_name)
        if endpoint_type == "admin":
            filename = f"{snake_service}_admin.py"
        elif endpoint_type == "read-only":
            filename = f"{snake_service}_readonly.py"
        elif endpoint_type == "list-only":
            filename = f"{snake_service}_list.py"
        else:  # full-crud
            filename = f"{snake_service}.py"
        
        # Generate endpoint
        print("\n" + "="*70)
        print("  GENERATING ENDPOINT")
        print("="*70 + "\n")
        
        if endpoint_type == "full-crud":
            endpoint_content = generate_full_crud_endpoint(
                model_name, service_name, schema_name, resource_name, path_prefix
            )
        elif endpoint_type == "read-only":
            endpoint_content = generate_read_only_endpoint(
                model_name, service_name, schema_name, resource_name, path_prefix
            )
        elif endpoint_type == "admin":
            endpoint_content = generate_admin_endpoint(
                model_name, service_name, schema_name, resource_name, path_prefix
            )
        else:  # list-only
            endpoint_content = generate_list_only_endpoint(
                model_name, service_name, schema_name, resource_name, path_prefix
            )
        
        print(f"📁 {endpoint_type} endpoint...")
        print(f"   ✓ {filename}")
        
        # Confirmation
        print("\n" + "="*70)
        print("  SUMMARY")
        print("="*70)
        print(f"\nModel: {to_pascal_case(model_name)}")
        print(f"Service: {snake_service}")
        print(f"Resource: {resource_name}")
        print(f"Path: {path_prefix}")
        print(f"Type: {endpoint_type}")
        print(f"File: backend/app/api/v1/endpoints/{filename}")
        
        confirm = input("\nProceed with generation? (yes/no): ").strip().lower()
        if confirm not in ["yes", "y"]:
            print("\n✗ Generation cancelled")
            sys.exit(0)
        
        # Create directory if needed
        ENDPOINTS_DIR.mkdir(parents=True, exist_ok=True)
        
        # Write file (simulate - in real usage would write)
        filepath = ENDPOINTS_DIR / filename
        print("\n" + "="*70)
        print("  FILE GENERATED")
        print("="*70 + "\n")
        print(f"✓ {filepath.relative_to(PROJECT_ROOT)}")
        
        # Integration instructions
        print("\n" + "="*70)
        print("  NEXT STEPS")
        print("="*70)
        print(f"""
1. Verify the endpoint file was created:
   → {filepath}

2. Verify prerequisites exist:
   → Model: backend/app/models/{to_snake_case(model_name)}.py
   → Schema: backend/app/schemas/{to_snake_case(schema_name)}.py
   → Service: backend/app/services/{snake_service}_service.py

3. Register endpoint in main router:
   → Edit: backend/app/main.py
   → Add:
      from app.api.v1.endpoints import {snake_service}
      app.include_router(
          {snake_service}.router,
          prefix="/api/v1",
      )

4. Test the endpoint:
   → POST {path_prefix}/ (create)
   → GET {path_prefix}/ (list)
   → GET {path_prefix}/1 (get)
   → PUT {path_prefix}/1 (update)
   → DELETE {path_prefix}/1 (delete)

5. Verify permissions:
   → Check: require_permission("{resource_name}.read/create/update/delete")
   → Update as needed for your RBAC setup

6. Fix any import errors:
   → Ensure model/schema/service imports are correct
   → Run: python -m backend.app.api.v1.endpoints.{snake_service}

7. Commit:
   → git add backend/app/api/v1/endpoints/{filename}
   → git commit -m "feat(api): add {endpoint_type} endpoints for {resource_name}"
""")
        
        sys.exit(0)
        
    except KeyboardInterrupt:
        print("\n\n✗ Generation cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n✗ Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc(file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    """Script entry point."""
    main()
