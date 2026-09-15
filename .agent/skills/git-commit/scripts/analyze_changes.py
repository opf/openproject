#!/usr/bin/env python3
"""
Analyze Git changes and suggest commit type and scope for Conventional Commits.

This is an executable component of the git-commit Skill for Google Antigravity.
It analyzes staged (or recent) Git changes and outputs commit metadata.

Exit Codes:
    0: Successfully analyzed changes (commits metadata to stdout)
    1: Error occurred (error message written to stderr)

Output Format (key=value pairs on stdout):
    type=<commit_type>
    scope=<scope>
    files_changed=<count>
    changed_files=<file1>|<file2>|...
    
Category counts written to stderr for debugging.

Example:
    $ python analyze_changes.py
    type=feat
    scope=slice
    files_changed=3
    changed_files=backend/app/models/user.py|frontend/components/UserForm.tsx|...
"""

import subprocess
import sys
from typing import Tuple, List, Dict, Union

# ============================================================================
# Configuration: File categorization patterns for ESG project structure
# ============================================================================

FILE_PATTERNS = [
    ("backend_migration", "alembic/versions"),
    ("backend_endpoint", "backend/app/api/v1/endpoints"),
    ("backend_service", "backend/app/services"),
    ("backend_model", "backend/app/models"),
    ("backend_schema", "backend/app/schemas"),
    ("backend_core", "backend/app/core"),
    ("backend_script", "backend/scripts"),
    ("frontend_component", "frontend/components"),
    ("frontend_service", "frontend/lib/services"),
    ("frontend_type", "frontend/lib/types"),
    ("frontend_page", "frontend/app"),
    ("infra_progress", "build-progress.md"),
    ("infra_doc", ["infra/planning", "infra/docs"]),
    ("agent_config", ".agent/"),
    ("frontend_style", ["frontend/styles", "frontend/app/globals.css"]),
    ("test", "test"),
]

# Categories that indicate a new feature
FEATURE_CATEGORIES = {
    "backend_model",
    "backend_schema",
    "backend_service",
    "backend_endpoint",
    "frontend_page",
    "frontend_component",
}


# ============================================================================
# Git Integration: Retrieve changed files
# ============================================================================

def get_changed_files() -> List[str]:
    """
    Retrieve the list of staged (cached) files from git.
    
    Uses `git diff --name-status --cached` to identify files ready to commit.
    
    Returns:
        List of file paths that are staged for commit.
        
    Raises:
        SystemExit(1): If not in a git repository or git command fails.
    """
    try:
        result = subprocess.run(
            ["git", "diff", "--name-status", "--cached"],
            capture_output=True,
            text=True,
            check=True,
            timeout=5
        )
        files = [
            line.split('\t')[-1]
            for line in result.stdout.strip().split('\n')
            if line.strip()
        ]
        return files
    except subprocess.TimeoutExpired:
        print(
            "Error: git command timed out. Repository may be very large or unresponsive.",
            file=sys.stderr
        )
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print(
            "Error: Failed to run git command. Is this a git repository?",
            file=sys.stderr
        )
        if e.stderr:
            print(f"Git error: {e.stderr}", file=sys.stderr)
        sys.exit(1)
    except FileNotFoundError:
        print(
            "Error: git executable not found. Is git installed and in your PATH?",
            file=sys.stderr
        )
        sys.exit(1)


# ============================================================================
# Analysis: Categorize files by type
# ============================================================================

def categorize_changes(files: List[str]) -> Dict[str, int]:
    """
    Categorize files by type of change using pattern matching.
    
    Analyzes each file path against predefined patterns to classify changes.
    This allows the system to make intelligent suggestions about commit type
    and scope based on what parts of the codebase were modified.
    
    Args:
        files: List of changed file paths (e.g. from git diff --name-status)
        
    Returns:
        Dictionary mapping category names to count of files in that category.
        Always includes an "other" category for files not matching any pattern.
        
    Example:
        >>> categorize_changes(["backend/app/models/user.py", "frontend/components/Form.tsx"])
        {
            "backend_model": 1,
            "frontend_component": 1,
            "backend_migration": 0,
            # ... other categories
            "other": 0
        }
    """
    # Initialize all categories with zero count
    categories: Dict[str, int] = {cat: 0 for cat, _ in FILE_PATTERNS}
    categories["other"] = 0
    
    # Classify each file
    for file in files:
        file_lower = file.lower()
        categorized = False
        
        # Check against each pattern in order
        for category, pattern in FILE_PATTERNS:
            # Pattern can be a string or list of strings
            patterns_list = pattern if isinstance(pattern, list) else [pattern]
            
            # If any pattern matches, categorize and move to next file
            if any(p in file_lower for p in patterns_list):
                categories[category] += 1
                categorized = True
                break
        
        # Uncategorized files go to "other"
        if not categorized:
            categories["other"] += 1
    
    return categories


# ============================================================================
# Suggestion: Recommend commit type and scope
# ============================================================================

def suggest_commit_type(categories: Dict[str, int]) -> Tuple[str, str]:
    """
    Suggest commit type and scope based on categorized changes.
    
    Uses heuristics to determine the most appropriate Conventional Commit
    type (feat, fix, docs, refactor, etc.) and scope based on which parts
    of the codebase were modified.
    
    Decision Logic:
        1. No changes detected → default to "chore:unknown"
        2. Any feature-related categories → "feat:slice"
        3. Single-category matches with specific rules (db, progress, etc.)
        4. Test-only changes → "test:unit"
        5. Documentation-only changes → "docs:infra"
        6. Default fallback → "chore:misc"
    
    Args:
        categories: Dictionary of file categories and their counts
        
    Returns:
        Tuple of (commit_type, scope) strings following Conventional Commits
        format (e.g., "feat", "slice", which becomes "feat(slice): ...")
        
    Example:
        >>> suggest_commit_type({"backend_model": 1, "backend_service": 1, ...})
        ("feat", "slice")
    """
    total_changes = sum(categories.values())
    
    # No changes detected
    if total_changes == 0:
        return "chore", "unknown"
    
    # Feature changes (new functionality) - multiple system areas touched
    if any(categories.get(c, 0) > 0 for c in FEATURE_CATEGORIES):
        return "feat", "slice"
    
    # Specific single-category commits with defined mappings
    specific_mappings = [
        ("backend_migration", ("chore", "db")),
        ("infra_progress", ("chore", "progress")),
        ("agent_config", ("chore", "agent")),
        ("frontend_style", ("style", "ui")),
    ]
    
    for category, (commit_type, scope) in specific_mappings:
        if categories.get(category, 0) > 0 and total_changes == categories[category]:
            return commit_type, scope
    
    # Special case: test-only changes
    test_count = categories.get("test", 0)
    if test_count > 0 and total_changes == test_count:
        return "test", "unit"
    
    # Special case: documentation-only changes
    doc_count = categories.get("infra_doc", 0)
    if doc_count > 0 and total_changes == doc_count:
        return "docs", "infra"
    
    # Default: miscellaneous changes
    return "chore", "misc"


# ============================================================================
# Entrypoint: Orchestrate analysis and output results
# ============================================================================

def main() -> None:
    """
    Analyze staged changes and output commit suggestion.
    
    This is the main entry point for the script. It orchestrates the analysis
    workflow and outputs results in a format suitable for shell/agent consumption.
    
    Output (stdout):
        Key=value pairs, one per line:
        - type: Conventional Commit type (feat, fix, docs, etc.)
        - scope: Commit scope (slice, db, ui, etc.)
        - files_changed: Number of changed files
        - changed_files: Pipe-separated list of file paths
        
    Debugging (stderr):
        Category breakdown with file counts (only if count > 0)
        
    Exit Codes:
        0: Success - commit metadata output to stdout
        1: Failure - no changes or git error, error message to stderr
    """
    try:
        # Step 1: Get changed files from git
        files = get_changed_files()
        
        # Step 2: Check if there are any staged changes
        if not files:
            print(
                "Error: No staged changes found. Use `git add` to stage files.",
                file=sys.stderr
            )
            sys.exit(1)
        
        # Step 3: Analyze the changes
        categories = categorize_changes(files)
        
        # Step 4: Suggest commit metadata
        commit_type, scope = suggest_commit_type(categories)
        
        # Step 5: Output results to stdout (agent/shell consumable format)
        print(f"type={commit_type}")
        print(f"scope={scope}")
        print(f"files_changed={len(files)}")
        print(f"changed_files={'|'.join(files)}")
        
        # Step 6: Debug output to stderr (category breakdown)
        print("", file=sys.stderr)
        print("# Category breakdown:", file=sys.stderr)
        for category, count in sorted(categories.items()):
            if count > 0:
                print(f"  {category}: {count}", file=sys.stderr)
        
        sys.exit(0)
        
    except KeyboardInterrupt:
        print("Error: Interrupted by user (Ctrl+C)", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        # Catch unexpected errors
        print(f"Error: Unexpected error during analysis: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    """Script entry point - used when executed directly from command line or shell."""
    main()
