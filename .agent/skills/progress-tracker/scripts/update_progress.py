#!/usr/bin/env python3
"""
Progress Tracker - Updates BUILD-PROGRESS.md with session status and feature completion.

This script provides an interactive interface for tracking project progress,
logging session status, marking features complete, and planning next work.

Usage:
    python update_progress.py

Prompts:
    1. Action: View progress, Mark complete, Log blocker, Plan next, Session summary
    2. Details: Session/feature info, status, notes

Output:
    - Updated BUILD-PROGRESS.md
    - Session status and metrics
    - Next session recommendations
"""

import re
from pathlib import Path
from datetime import datetime
from typing import Optional


def find_progress_file() -> Optional[Path]:
    """Find BUILD-PROGRESS.md in project structure."""
    current = Path(__file__)
    while current != current.parent:
        progress_file = current / "infra" / "project-state" / "BUILD-PROGRESS.md"
        if progress_file.exists():
            return progress_file
        current = current.parent
    return None


def load_progress() -> str:
    """Load current progress file."""
    progress_file = find_progress_file()
    if not progress_file:
        print("ERROR: Could not find BUILD-PROGRESS.md")
        return ""
    
    return progress_file.read_text()


def save_progress(content: str) -> bool:
    """Save progress file."""
    progress_file = find_progress_file()
    if not progress_file:
        print("ERROR: Could not find BUILD-PROGRESS.md")
        return False
    
    progress_file.write_text(content)
    print(f"✅ Saved: {progress_file}")
    return True


def view_progress() -> None:
    """View current progress."""
    content = load_progress()
    if not content:
        return
    
    # Extract summary sections
    print("\n" + "="*70)
    print("BUILD PROGRESS - CURRENT STATUS")
    print("="*70 + "\n")
    
    # Show first 50 lines (summary)
    lines = content.split("\n")
    for i, line in enumerate(lines[:50]):
        print(line)
        if i > 40 and "Not Started" in line:
            print("\n... (see full file for details)")
            break


def mark_complete() -> None:
    """Mark a feature as complete."""
    content = load_progress()
    if not content:
        return
    
    session = input("Session identifier (e.g., 9D, 10): ").strip().upper()
    feature = input("Feature name: ").strip()
    notes = input("Notes (optional): ").strip()
    
    # Find session section
    session_pattern = rf"### Session {re.escape(session)}.*?(?=##|$)"
    
    if not re.search(session_pattern, content, re.DOTALL):
        print(f"⚠️ Session {session} not found. Creating new section...")
        
        # Add new session
        new_session = f"\n### Session {session} - [Feature Name] (✅ COMPLETE)\n"
        new_session += f"- [x] {feature}\n"
        if notes:
            new_session += f"  Notes: {notes}\n"
        
        # Insert before "Not Started" section
        content = content.replace("## Not Started", new_session + "\n## Not Started")
    else:
        # Update existing session
        def update_session(match):
            session_content = match.group(0)
            # Check if feature already exists
            if f"- [x] {feature}" in session_content:
                print(f"Feature '{feature}' already marked complete")
                return session_content
            
            # Mark as complete if not already done
            if "- [ ]" in session_content or "IN PROGRESS" in session_content:
                session_content = session_content.replace("IN PROGRESS", "COMPLETE")
                session_content = session_content.replace("🔄", "✅")
                
                # Add feature if not present
                if feature not in session_content:
                    lines = session_content.split("\n")
                    insert_pos = next(
                        (i for i, l in enumerate(lines) if l.startswith("- [")), 0
                    )
                    if insert_pos == 0:
                        insert_pos = 1
                    
                    new_item = f"- [x] {feature}"
                    if notes:
                        new_item += f"\n  Notes: {notes}"
                    
                    lines.insert(insert_pos, new_item)
                    session_content = "\n".join(lines)
            
            return session_content
        
        content = re.sub(
            session_pattern,
            update_session,
            content,
            flags=re.DOTALL
        )
    
    if save_progress(content):
        print(f"✅ Marked '{feature}' complete in Session {session}")


def log_blocker() -> None:
    """Log a blocker/issue."""
    content = load_progress()
    if not content:
        return
    
    session = input("Session (e.g., 9C): ").strip().upper()
    issue = input("Blocker description: ").strip()
    impact = input("Impact (High/Medium/Low): ").strip()
    resolution = input("Resolution path/ETA: ").strip()
    
    # Find blockers section
    if "## Blockers" not in content:
        # Add blockers section before technical debt
        content = content.replace(
            "## Technical Debt",
            "## Blockers\n\n1. **[To be added]**\n\n## Technical Debt"
        )
    
    blocker_entry = f"\n1. **{issue} (Session {session})**\n"
    blocker_entry += f"   - **Impact**: {impact}\n"
    blocker_entry += f"   - **Blocking**: [Feature description]\n"
    blocker_entry += f"   - **Resolution**: {resolution}\n"
    
    # Insert blocker
    blockers_pattern = r"(## Blockers\n)"
    content = re.sub(
        blockers_pattern,
        r"\1" + blocker_entry,
        content
    )
    
    if save_progress(content):
        print(f"✅ Logged blocker for Session {session}")


def plan_next_session() -> None:
    """Plan the next session."""
    content = load_progress()
    if not content:
        return
    
    next_session = input("Next session (e.g., 10): ").strip().upper()
    duration = input("Estimated duration (minutes): ").strip()
    title = input("Session title (feature name): ").strip()
    
    goals = []
    print("Enter goals (one per line, empty to finish):")
    i = 1
    while True:
        goal = input(f"  Goal {i}: ").strip()
        if not goal:
            break
        goals.append(f"{i}. {goal}")
        i += 1
    
    # Create session plan
    plan = f"\n## Next Session Plan - Session {next_session} ({title})\n\n"
    plan += f"**Estimated Duration**: {duration} minutes\n\n"
    plan += "**Goals** (in order):\n"
    for goal in goals:
        plan += f"{goal}\n"
    plan += "\n**Success Criteria**: All goals complete, tests passing\n"
    
    # Insert before end of file
    content = content.rstrip() + plan + "\n"
    
    if save_progress(content):
        print(f"✅ Planned Session {next_session}")


def session_summary() -> None:
    """Create session summary report."""
    content = load_progress()
    if not content:
        return
    
    session = input("Session to summarize (e.g., 9D): ").strip().upper()
    
    completed = int(input("Items completed: ").strip() or "0")
    lines_added = int(input("Lines of code added: ").strip() or "0")
    coverage = input("Test coverage %: ").strip()
    notes = input("Key accomplishments: ").strip()
    
    summary = f"\n**Final Status**: ✅ COMPLETE\n"
    summary += f"**Items Completed**: {completed}\n"
    summary += f"**Code Added**: {lines_added} LOC\n"
    if coverage:
        summary += f"**Coverage**: {coverage}%\n"
    if notes:
        summary += f"**Summary**: {notes}\n"
    
    print("\nSession Summary:")
    print(summary)
    
    if input("Save summary? (yes/no): ").lower() in ("y", "yes"):
        if save_progress(content + summary):
            print("✅ Summary saved")


if __name__ == "__main__":
    print("""
╔════════════════════════════════════════════════════════════════╗
║          Progress Tracker - ESG Sustainify Project              ║
║                                                                ║
║  Manage BUILD-PROGRESS.md with session status and metrics      ║
╚════════════════════════════════════════════════════════════════╝
""")
    
    while True:
        print("\nOptions:")
        print("  1. View progress")
        print("  2. Mark feature complete")
        print("  3. Log blocker")
        print("  4. Plan next session")
        print("  5. Session summary")
        print("  6. Exit")
        
        choice = input("\nSelect (1-6): ").strip()
        
        if choice == "1":
            view_progress()
        elif choice == "2":
            mark_complete()
        elif choice == "3":
            log_blocker()
        elif choice == "4":
            plan_next_session()
        elif choice == "5":
            session_summary()
        elif choice == "6":
            print("Goodbye!")
            break
        else:
            print("Invalid choice")
