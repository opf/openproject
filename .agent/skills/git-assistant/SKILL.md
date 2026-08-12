---
name: git-assistant
description: Automated conventional commits and pushing changes based on work completed.
---

# Git Assistant

This skill automates the Git workflow for the Class Management project. It ensures that every session or significant feature is committed with a clear, conventional message.

## When to use this skill
- Completing a vertical slice
- Implementing a new DocType or API method
- Fixing a bug or performing cleanup
- Ready to push changes to the remote repository

## How to use this skill

### Step 1: Create a Conventional Commit
The commit message should follow the pattern:
`<type>(<scope>): <short description>`

**Types**:
- `feat`: New feature (e.g., `feat(session): add attendance tracking`)
- `fix`: Bug fix (e.g., `fix(lesson): incorrect date filter`)
- `docs`: Documentation changes (e.g., `docs(agents): update skill list`)
- `style`: Formatting/Refactoring (e.g., `style(cleanup): lint controller`)
- `refactor`: Code change that neither fixes a bug nor adds a feature

### Step 2: Push Changes
Ensure all work is staged before pushing.

### Step 3: Branching (Optional)
Create feature branches for large slices if requested.

## Success Criteria
- Commit messages follow conventional standards.
- Commits are pushed regularly to ensure backup and visibility.
- History is clean and easy to read.
