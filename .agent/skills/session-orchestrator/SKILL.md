---
name: session-orchestrator
description: A meta-skill that enforces the Deliberation -> Action -> Verification cycle and generates the Feature Completion Report (JSON).
---

# Session Orchestrator

This is a meta-skill designed to maintain project momentum and documentation integrity. It enforces the "Session" pattern used in the `infra/prompts/prompts_template.txt`.

## When to use this skill
- At the start of every new feature slice.
- When finishing a development session to generate reports.
- To ensure governance continuity (e.g., brand color checks).

## How to use this skill

### Step 1: Deliberation Mode
Before writing code, create a plan that addresses:
- **Governance**: Are we using the correct `theme.json` colors?
- **Security**: Is client isolation handled?
- **Logic**: What is the root cause or design decision?

### Step 2: Action Mode
Execute the technical tasks using other specialized skills (`fastapi-vertical-slice-generator`, etc.).

### Step 3: Verification & Reporting
After implementation, run verification tests and generate a completion report.

#### Completion Report Structure
Create `project-state/feature-reports/<feature_name>.json`:
```json
{
  "featureName": "Name",
  "status": "complete",
  "sessions": [11],
  "backend": { "files": [], "loc": 0, "endpoints": 0 },
  "frontend": { "files": [], "loc": 0, "components": 0 },
  "lessons": ["What we learned about the stack or project."]
}
```

### Step 4: Progress Tracking
Update `project-state/BUILD-PROGRESS.md` and set the next session in `project-state/current-session.json`.

## Success Criteria
- Every feature has a corresponding JSON report.
- `BUILD-PROGRESS.md` is always up to date.
- The agent explicitly follows the "Deliberation" phase before code changes.
