---
name: debug-domain-flow
description: Trace logic across services (DDD, APIs, DB).
---

# Debug Domain Flow

An optional, advanced diagnostic skill within the bug-fixing pipeline.

## Instructions
1. **Frontend Call**: Intercept and evaluate Next.js `frappeCall` request payloads and states.
2. **Backend Execution**: Step mentally or literally through Frappe `api.py` into DocType controllers and lifecycle `hooks.py`.
3. **State Verification**: Directly traverse or query the system layers (Redis, SQL) to confirm state mutations.
