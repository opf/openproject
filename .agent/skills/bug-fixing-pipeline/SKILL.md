---
name: bug-fixing-pipeline
description: Orchestrates the strict, deterministic bug fixing process.
---

# Bug Fixing Pipeline

This skill orchestrates the end-to-end deterministic bug fixing process as defined in our robust AI workflow.

## Pipeline Architecture
To resolve a bug efficiently, invoke these actions/skills sequentially:

1. **`triage-bug`**: Understand and isolate the bug boundary.
2. **`Check Next.js Version`**: Verify the version in `frontend/package.json` to ensure architecture compatibility (App Router vs Pages).
3. **`root-cause-analysis`**: Deep investigation into why the bug happens at the code level.
4. **`fix-with-tdd`**: Implement the fix safely using tests.
5. **`verify-fix`**: Ensure the fix works and introduces no regressions.

*Optional advanced tooling:* Use **`debug-domain-flow`** to manually trace complex logic spanning across Next.js, FastAPI, and PostgreSQL.

### Core Guardrails
- **Complete State (#9):** Ensure all relevant file contents and current system logs are completely loaded *before* starting analysis.
- **Error Ritual (#10):** Proactively outline side-effects and expected error scenarios *prior* to implementation.
- **Parseable Output (#13):** Produce a JSON-formatted summary of the bug resolution at the end.
