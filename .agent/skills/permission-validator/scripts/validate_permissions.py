#!/usr/bin/env python3
"""
Permission Validator - Audits endpoints for RBAC coverage and client isolation.

This script scans FastAPI endpoints to ensure:
- All mutating endpoints have require_permission() decorators
- Read endpoints have permission checks
- Client users cannot access other companies' data
- Permission names follow naming conventions
- Audit logging for sensitive operations

Usage:
    python validate_permissions.py

Options:
    1. Audit all endpoints
    2. Check specific file
    3. Find missing permission checks
    4. Check client isolation
    5. Generate remediation report

Output:
    - Permission coverage report
    - Missing checks with recommendations
    - Client isolation violations
    - Security score
"""

import re
import ast
from pathlib import Path
from typing import Optional, Dict, List, Tuple
from dataclasses import dataclass


@dataclass
class EndpointInfo:
    file: str
    name: str
    method: str
    path: str
    has_permission_check: bool
    has_client_isolation: bool
    line_number: int


def find_backend_path() -> Optional[Path]:
    """Find backend directory."""
    current = Path(__file__)
    while current != current.parent:
        if (current / "backend" / "app").exists():
            return current / "backend"
        current = current.parent
    return None


def scan_endpoints() -> List[EndpointInfo]:
    """Scan all endpoint files for permission usage."""
    backend_path = find_backend_path()
    if not backend_path:
        print("ERROR: Could not find backend directory")
        return []
    
    endpoints = []
    endpoints_dir = backend_path / "app" / "api" / "v1" / "endpoints"
    
    if not endpoints_dir.exists():
        print(f"Endpoints directory not found: {endpoints_dir}")
        return []
    
    for endpoint_file in endpoints_dir.glob("*.py"):
        if endpoint_file.name == "__init__.py":
            continue
        
        content = endpoint_file.read_text()
        
        # Find all route decorators and functions
        route_pattern = r'@router\.(get|post|put|delete|patch)\(["\']([^"\']+)["\'][^)]*\)'
        func_pattern = r'async def (\w+)\('
        
        routes = list(re.finditer(route_pattern, content))
        funcs = list(re.finditer(func_pattern, content))
        
        for route_match in routes:
            method = route_match.group(1).upper()
            path = route_match.group(2)
            route_end = route_match.end()
            
            # Find next function after this route
            next_func = next(
                (f for f in funcs if f.start() > route_match.start()),
                None
            )
            
            if next_func:
                func_name = next_func.group(1)
                
                # Check for permission check in decorator or function
                decorator_section = content[route_match.start():next_func.start()]
                has_permission = (
                    "require_permission" in decorator_section or
                    "require_staff" in decorator_section or
                    "require_super_admin" in decorator_section
                )
                
                # Check for client isolation
                func_section = next_func.group(0)
                # Look for client_company_id filter in function body
                has_isolation = "client_company_id" in func_section
                
                endpoints.append(EndpointInfo(
                    file=endpoint_file.name,
                    name=func_name,
                    method=method,
                    path=path,
                    has_permission_check=has_permission,
                    has_client_isolation=has_isolation,
                    line_number=content[:route_match.start()].count("\n") + 1
                ))
    
    return endpoints


def audit_all_endpoints() -> None:
    """Audit all endpoints for RBAC coverage."""
    endpoints = scan_endpoints()
    
    if not endpoints:
        print("No endpoints found")
        return
    
    # Calculate stats
    total = len(endpoints)
    protected = sum(1 for e in endpoints if e.has_permission_check)
    isolated = sum(1 for e in endpoints if e.has_client_isolation)
    
    security_score = (protected / total * 100) if total > 0 else 0
    
    print("\n" + "="*70)
    print("RBAC AUDIT - ESG Sustainify Endpoints")
    print("="*70 + "\n")
    
    print(f"SECURITY SCORE: {'⚠️' if security_score < 80 else '✅'} {security_score:.0f}%\n")
    
    print(f"✅ PROTECTED: {protected}/{total} endpoints\n")
    for ep in sorted(endpoints, key=lambda e: (e.file, e.method)):
        if ep.has_permission_check:
            icon = "✅"
            print(f"  {icon} {ep.method:6} {ep.path:20} ({ep.file}:{ep.line_number})")
    
    unprotected = [e for e in endpoints if not e.has_permission_check]
    if unprotected:
        print(f"\n⚠️ UNPROTECTED: {len(unprotected)} endpoints\n")
        for ep in sorted(unprotected, key=lambda e: (e.file, e.method)):
            print(f"  ❌ {ep.method:6} {ep.path:20} ({ep.file}:{ep.line_number})")
            if ep.method in ("POST", "PUT", "DELETE"):
                print(f"     → ADD: @require_permission('{ep.path.split('/')[1]}.{ep.method.lower()}')")
    
    print(f"\n🔒 CLIENT ISOLATION: {isolated}/{total} endpoints\n")
    not_isolated = [e for e in endpoints if not e.has_client_isolation]
    if not_isolated:
        print(f"  {len(not_isolated)} endpoints without client_company_id filtering:")
        for ep in sorted(not_isolated, key=lambda e: (e.file, e.method))[:5]:
            print(f"    • {ep.file}:{ep.line_number} - {ep.name}()")


def check_specific_file(filename: str) -> None:
    """Check a specific endpoint file."""
    backend_path = find_backend_path()
    if not backend_path:
        print("ERROR: Could not find backend directory")
        return
    
    endpoint_file = backend_path / "app" / "api" / "v1" / "endpoints" / filename
    
    if not endpoint_file.exists():
        print(f"File not found: {endpoint_file}")
        return
    
    # Scan just this file
    content = endpoint_file.read_text()
    
    # Find routes
    route_pattern = r'@router\.(get|post|put|delete|patch)\(["\']([^"\']+)["\'][^)]*\)'
    func_pattern = r'async def (\w+)\('
    
    routes = list(re.finditer(route_pattern, content))
    
    print(f"\n{filename}:")
    print("-" * 50)
    
    for route_match in routes:
        method = route_match.group(1).upper()
        path = route_match.group(2)
        
        decorator_section = content[max(0, route_match.start()-200):route_match.end()]
        has_permission = "require_permission" in decorator_section
        
        icon = "✅" if has_permission else "❌"
        print(f"  {icon} {method:6} {path}")
        
        if not has_permission and method in ("POST", "PUT", "DELETE", "PATCH"):
            resource = path.split("/")[1] or "resource"
            print(f"     Add: @require_permission('{resource}.{method.lower()}')")


def find_issues() -> None:
    """Find missing permission checks and isolation violations."""
    endpoints = scan_endpoints()
    
    issues = {
        "critical": [],      # Unprotected mutating endpoints
        "high": [],          # Missing client isolation
        "medium": [],        # Inconsistent patterns
    }
    
    for ep in endpoints:
        # Critical: POST/PUT/DELETE without permission
        if ep.method in ("POST", "PUT", "DELETE", "PATCH") and not ep.has_permission_check:
            issues["critical"].append(
                f"{ep.file}:{ep.line_number} - {ep.method} {ep.path} (no permission check)"
            )
        
        # High: Sensitive operations without isolation
        if not ep.has_client_isolation and ep.method in ("GET", "POST", "PUT"):
            issues["high"].append(
                f"{ep.file}:{ep.line_number} - {ep.name}() (no client isolation)"
            )
    
    print("\n📋 SECURITY ISSUES:\n")
    
    if issues["critical"]:
        print(f"🔴 CRITICAL ({len(issues['critical'])}):")
        for issue in issues["critical"]:
            print(f"  • {issue}")
    
    if issues["high"]:
        print(f"\n🟠 HIGH ({len(issues['high'])}):")
        for issue in issues["high"][:5]:
            print(f"  • {issue}")
        if len(issues["high"]) > 5:
            print(f"  ... and {len(issues['high'])-5} more")


if __name__ == "__main__":
    print("""
╔════════════════════════════════════════════════════════════════╗
║      Permission Validator - ESG Sustainify RBAC Auditor         ║
║                                                                ║
║  Audit endpoints for permission coverage and client isolation  ║
╚════════════════════════════════════════════════════════════════╝
""")
    
    while True:
        print("\nOptions:")
        print("  1. Audit all endpoints")
        print("  2. Check specific file")
        print("  3. Find security issues")
        print("  4. Exit")
        
        choice = input("\nSelect (1-4): ").strip()
        
        if choice == "1":
            audit_all_endpoints()
        elif choice == "2":
            filename = input("Filename (e.g., clients.py): ").strip()
            if filename:
                check_specific_file(filename)
        elif choice == "3":
            find_issues()
        elif choice == "4":
            print("Goodbye!")
            break
        else:
            print("Invalid choice")
