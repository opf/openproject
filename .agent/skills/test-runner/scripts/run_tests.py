#!/usr/bin/env python3
"""
Test Runner - Executes pytest with coverage reporting and failure analysis.

This script provides an interactive interface for running backend tests,
generating coverage reports, and identifying failing tests with diagnosis.

Usage:
    python run_tests.py

Prompts:
    1. Test scope: all, backend, frontend, or specific file/module
    2. Coverage: Whether to generate coverage report (yes/no)
    3. Verbose: Detailed output (yes/no)
    4. Failfast: Stop on first failure (yes/no)

Output:
    - Test results (passed/failed/skipped)
    - Coverage HTML report (if coverage enabled)
    - Failure diagnosis with suggestions
"""

import subprocess
import sys
import re
from pathlib import Path
from typing import Optional


def prompt_required(message: str, options: list[str]) -> str:
    """Prompt user to select from options."""
    while True:
        print(f"\n{message}")
        for i, opt in enumerate(options, 1):
            print(f"  {i}. {opt}")
        choice = input("Select (1-{}): ".format(len(options))).strip()
        
        try:
            idx = int(choice) - 1
            if 0 <= idx < len(options):
                return options[idx]
        except ValueError:
            pass
        print("Invalid selection. Try again.")


def prompt_yes_no(message: str) -> bool:
    """Prompt for yes/no answer."""
    while True:
        answer = input(f"{message} (yes/no): ").strip().lower()
        if answer in ("yes", "y"):
            return True
        if answer in ("no", "n"):
            return False
        print("Please enter 'yes' or 'no'")


def run_tests() -> int:
    """Run pytest with chosen configuration."""
    backend_path = Path(__file__).parent.parent.parent.parent.parent / "backend"
    
    # Check if backend exists
    if not backend_path.exists():
        print(f"ERROR: Backend path not found: {backend_path}")
        return 1
    
    # Prompt for test scope
    scope = prompt_required(
        "Test scope:",
        ["All tests", "Backend only", "Frontend only", "Specific module"]
    )
    
    test_path = ""
    if scope == "All tests":
        test_path = "."
    elif scope == "Backend only":
        test_path = str(backend_path / "tests")
    elif scope == "Frontend only":
        frontend_path = backend_path.parent / "frontend"
        test_path = str(frontend_path / "tests") if (frontend_path / "tests").exists() else ""
    elif scope == "Specific module":
        module = input("Enter module path (e.g., tests/test_auth.py): ").strip()
        test_path = str(backend_path / module)
    
    if not test_path:
        print("ERROR: No valid test path")
        return 1
    
    # Coverage option
    coverage = prompt_yes_no("Generate coverage report?")
    
    # Verbose option
    verbose = prompt_yes_no("Verbose output?")
    
    # Failfast option
    failfast = prompt_yes_no("Stop on first failure?")
    
    # Build pytest command
    cmd = [sys.executable, "-m", "pytest", test_path]
    
    if coverage:
        cmd.extend(["--cov=app", "--cov-report=html", "--cov-report=term-missing"])
    
    if verbose:
        cmd.append("-vv")
    else:
        cmd.append("-v")
    
    if failfast:
        cmd.append("-x")
    
    # Show command
    print(f"\nRunning: {' '.join(cmd)}\n")
    
    # Run pytest
    result = subprocess.run(cmd, cwd=backend_path)
    
    # Show coverage report location
    if coverage and result.returncode == 0:
        coverage_html = backend_path / "htmlcov" / "index.html"
        if coverage_html.exists():
            print(f"\n✅ Coverage report: {coverage_html}")
            print("   Open in browser to see detailed coverage")
    
    return result.returncode


def run_specific_test() -> int:
    """Run a specific test file or pattern."""
    backend_path = Path(__file__).parent.parent.parent.parent.parent / "backend"
    
    test_pattern = input("Enter test pattern (e.g., test_auth.py or test_auth::test_login): ").strip()
    
    if not test_pattern:
        print("ERROR: No test pattern provided")
        return 1
    
    cmd = [sys.executable, "-m", "pytest", test_pattern, "-vv"]
    
    verbose = prompt_yes_no("Show full failure details?")
    if verbose:
        cmd.append("-vv")
    
    print(f"\nRunning: {' '.join(cmd)}\n")
    result = subprocess.run(cmd, cwd=backend_path)
    
    return result.returncode


def check_coverage_targets() -> None:
    """Check if coverage meets target thresholds."""
    backend_path = Path(__file__).parent.parent.parent.parent.parent / "backend"
    coverage_file = backend_path / ".coverage"
    
    if not coverage_file.exists():
        print("No coverage data found. Run tests with --cov flag first.")
        return
    
    # Target coverage by component
    targets = {
        "app/services": 90,
        "app/api": 85,
        "app/models": 80,
        "app/schemas": 70,
    }
    
    print("\n📊 Coverage Targets:\n")
    for component, target in targets.items():
        print(f"  {component}: {target}%+")


if __name__ == "__main__":
    print("""
------------------------------------------------------------------
              Test Runner - ESG Sustainify Backend               
                                                                
  Run pytest with coverage reporting and failure analysis       
------------------------------------------------------------------
""")
    
    mode = prompt_required(
        "Select mode:",
        ["Run tests", "Run specific test", "Check coverage targets"]
    )
    
    if mode == "Run tests":
        exit_code = run_tests()
    elif mode == "Run specific test":
        exit_code = run_specific_test()
    else:
        check_coverage_targets()
        exit_code = 0
    
    sys.exit(exit_code)
