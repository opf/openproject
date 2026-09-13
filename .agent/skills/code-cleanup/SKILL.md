---
name: code-cleanup
description: A skill for linting, formatting, and general code cleanup.
---

# Code Cleanup

This skill ensures that the codebase follows the standard conventions for this repository (FastAPI backend + Next.js frontend).

## When to use this skill
- Before finalizing a slice
- Before pushing to the repository
- Correcting code after a linting error

## How to use this skill

### Step 1: Format Code
Run formatting on the backend:
```bash
cd backend
black .
isort .
```

### Step 2: Lint Code & Type-Check
Run linting and type checking on the backend:
```bash
cd backend
mypy .
pylint app
```

Run linting and type checking on the frontend:
```bash
cd frontend
npm run lint
npm run type-check
```

### Step 3: Refactor
- Reduce complexity in large functions or components.
- Standardize on `apiClient` for the frontend.
- Standardize on service layer delegation for the backend.

## Success Criteria
- Code is clean, formatted, and readable.
- No linting errors or warnings.
- Adherence to project architectural patterns (Vertical Slices, etc).
