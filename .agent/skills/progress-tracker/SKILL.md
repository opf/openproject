---
name: progress-tracker
description: Tracks development progress through vertical slices. Updates the status of slices and logs current session state to ensure continuity across agent handoffs.
---

# Progress Tracker

This skill manages the project's development state by tracking progress through the 6 predefined vertical slices in the `Slices/` directory.

## When to use this skill
- Starting a new development session (to resume from previous state)
- Completing a slice or a significant milestone within a slice
- Before handing off control to another agent or ending a session
- Language like "what's the progress?" or "mark slice 1 as complete"

## How to use this skill

### Step 1: Check Current Progress
The agent should read `Slices/` to see which slices are marked as complete.

### Step 2: Update Progress
When a slice is finished:
1. Update the slice file in `Slices/` if it has a status field (optional).
2. Log the progress in the session notes.

### Step 3: Session Handoff
Before ending, summarize:
- **Completed**: Features/DocTypes implemented.
- **In Progress**: Current tasks and partial work.
- **Next Steps**: What to do immediately in the next session.

## Success Criteria
- The project state is always clear.
- No redundant work is performed because progress was not tracked.
- Next sessions can start immediately from where the last one left off.
