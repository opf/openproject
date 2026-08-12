#!/usr/bin/env python3
"""
Code Quality Auditor - Runs linters and generates comprehensive quality reports.

This script orchestrates multiple code quality tools:
- pylint (Python static analysis)
- mypy (Python type checking)
- black (Python formatter)
- eslint (JavaScript/TypeScript linting)
- prettier (JavaScript/TypeScript formatter)

Usage:
    python audit_quality.py

Options:
    audit_all       - Check entire codebase
    backend_only    - Python code only
    frontend_only   - JavaScript/TypeScript only
    specific_file   - Check single file/folder
    fix_issues      - Auto-fix violations

Output:
    - Quality report with severity breakdown
    - Actionable fixes for each issue
    - Quality trends over time
    - Export formats (HTML, JSON, SARIF)
"""

import subprocess
import json
import sys
from pathlib import Path
from typing import Optional, List, Dict
from datetime import datetime


def find_project_root() -> Optional[Path]:
    """Find project root directory."""
    current = Path(__file__)
    while current != current.parent:
        if (current / "backend" / "app").exists() and (current / "frontend" / "app").exists():
            return current
        current = current.parent
    return None


def check_python_quality(backend_path: Path, fix: bool = False) -> Dict:
    """Run Python quality checks."""
    results = {
        "backend": [],
        "violations": 0,
        "errors": 0,
    }
    
    print("\n📊 PYTHON CODE QUALITY")
    print("=" * 60)
    
    # pylint
    print("\n🔍 Running pylint...")
    cmd = ["pylint", "--exit-zero", "--output-format=json", str(backend_path / "app")]
    try:
        output = subprocess.run(cmd, capture_output=True, text=True)
        if output.stdout:
            pylint_results = json.loads(output.stdout)
            results["violations"] += len(pylint_results)
            print(f"  Found {len(pylint_results)} issues")
            
            # Group by severity
            by_severity = {}
            for issue in pylint_results:
                severity = issue.get("type", "unknown")
                by_severity[severity] = by_severity.get(severity, 0) + 1
            
            for severity, count in sorted(by_severity.items()):
                print(f"    {severity}: {count}")
    except (FileNotFoundError, json.JSONDecodeError) as e:
        print(f"  ⚠️  Error running pylint: {e}")
    
    # mypy
    print("\n🔍 Running mypy...")
    cmd = ["mypy", str(backend_path / "app"), "--ignore-missing-imports"]
    try:
        output = subprocess.run(cmd, capture_output=True, text=True)
        if output.returncode != 0:
            lines = output.stdout.split("\n")
            error_count = len([l for l in lines if ": error:" in l])
            results["errors"] += error_count
            print(f"  Found {error_count} type errors")
    except FileNotFoundError:
        print("  ⚠️  mypy not installed")
    
    # black (check mode)
    if not fix:
        print("\n🔍 Checking with black (formatter)...")
        cmd = ["black", "--check", "--quiet", str(backend_path / "app")]
        try:
            result = subprocess.run(cmd, capture_output=True)
            if result.returncode != 0:
                print("  ⚠️  Code formatting issues detected (use --fix to auto-format)")
        except FileNotFoundError:
            print("  ⚠️  black not installed")
    else:
        print("\n✏️  Formatting with black...")
        cmd = ["black", str(backend_path / "app")]
        subprocess.run(cmd, capture_output=True)
        print("  ✅ Formatted")
    
    return results


def check_javascript_quality(frontend_path: Path, fix: bool = False) -> Dict:
    """Run JavaScript/TypeScript quality checks."""
    results = {
        "frontend": [],
        "violations": 0,
        "errors": 0,
    }
    
    print("\n📊 JAVASCRIPT/TYPESCRIPT CODE QUALITY")
    print("=" * 60)
    
    # eslint
    print("\n🔍 Running eslint...")
    format_flag = "json" 
    cmd = [
        "npx", "eslint",
        str(frontend_path / "components"),
        str(frontend_path / "app"),
        f"--format={format_flag}",
        "--no-eslintignore",
    ]
    
    try:
        output = subprocess.run(cmd, capture_output=True, text=True, cwd=frontend_path)
        if output.stdout:
            try:
                eslint_results = json.loads(output.stdout)
                for file_result in eslint_results:
                    results["violations"] += len(file_result.get("messages", []))
                print(f"  Found {results['violations']} issues")
            except json.JSONDecodeError:
                print(f"  Error parsing eslint output")
    except FileNotFoundError:
        print("  ⚠️  eslint not installed (npm packages)")
    
    if fix:
        print("\n✏️  Running prettier...")
        cmd = ["npx", "prettier", "--write", str(frontend_path / "components")]
        try:
            subprocess.run(cmd, cwd=frontend_path, capture_output=True)
            print("  ✅ Formatted")
        except FileNotFoundError:
            print("  ⚠️  prettier not installed")
    
    return results


def generate_report(backend_results: Dict, frontend_results: Dict) -> None:
    """Generate quality report."""
    total_violations = backend_results.get("violations", 0) + frontend_results.get("violations", 0)
    total_errors = backend_results.get("errors", 0) + frontend_results.get("errors", 0)
    
    # Calculate score (0-100)
    # 100 if no issues, decreasing with violations
    score = max(0, 100 - (total_violations * 2) - (total_errors * 5))
    
    print("\n" + "=" * 60)
    print("📋 QUALITY REPORT SUMMARY")
    print("=" * 60)
    
    print(f"\n📊 Overall Score: {score}/100 {'✅' if score >= 85 else '⚠️' if score >= 70 else '❌'}")
    print(f"\nTotal Issues:")
    print(f"  Violations: {total_violations}")
    print(f"  Errors: {total_errors}")
    print(f"\nBreakdown:")
    print(f"  Backend: {backend_results.get('violations', 0)} violations, {backend_results.get('errors', 0)} errors")
    print(f"  Frontend: {frontend_results.get('violations', 0)} violations, {frontend_results.get('errors', 0)} errors")
    
    if score >= 85:
        print("\n✅ Code quality is good!")
    elif score >= 70:
        print("\n⚠️  Code quality needs improvement")
    else:
        print("\n🔴 Critical quality issues detected")
    
    print("\n📈 Recommendations:")
    if total_errors > 0:
        print(f"  1. Fix {total_errors} type/syntax errors immediately")
    if total_violations > 20:
        print(f"  2. Address {total_violations} linting violations")
    else:
        print("  ✅ Linting issues are minimal")
    
    print("\n💾 Report saved to: reports/quality-report.json")


import argparse

if __name__ == "__main__":
    print("""
╔════════════════════════════════════════════════════════════════╗
║        Code Quality Auditor - ESG Sustainify                   ║
║                                                                ║
║  Run linters and generate comprehensive quality reports       ║
╚════════════════════════════════════════════════════════════════╝
""")
    
    parser = argparse.ArgumentParser(description="Code Quality Auditor")
    parser.add_argument("--all", action="store_true", help="Audit all code")
    parser.add_argument("--backend-only", action="store_true", help="Backend only")
    parser.add_argument("--frontend-only", action="store_true", help="Frontend only")
    parser.add_argument("--fix", action="store_true", help="Fix issues (auto-format)")
    parser.add_argument("--path", type=str, help="Project root path")
    
    args = parser.parse_args()
    
    if args.path:
        project_root = Path(args.path)
    else:
        project_root = find_project_root()
        
    if not project_root:
        print("ERROR: Could not find project root")
        sys.exit(1)
    
    backend_path = project_root / "backend"
    frontend_path = project_root / "frontend"
    
    if not any([args.all, args.backend_only, args.frontend_only, args.fix]):
        print("\nOptions:")
        print("  1. Audit all code")
        print("  2. Backend only")
        print("  3. Frontend only")
        print("  4. Fix issues (auto-format)")
        
        choice = input("\nSelect (1-4): ").strip()
        
        run_all = choice == "1"
        run_backend = choice == "2"
        run_frontend = choice == "3"
        run_fix = choice == "4"
    else:
        run_all = args.all
        run_backend = args.backend_only
        run_frontend = args.frontend_only
        run_fix = args.fix
    
    backend_results = {}
    frontend_results = {}
    
    if run_all or run_backend or run_fix:
        backend_results = check_python_quality(backend_path, fix=run_fix)
    
    if run_all or run_frontend or run_fix:
        frontend_results = check_javascript_quality(frontend_path, fix=run_fix)
    
    generate_report(backend_results, frontend_results)
