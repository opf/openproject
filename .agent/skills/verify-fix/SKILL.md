---
name: verify-fix
description: Ensure the implemented fix works and introduces no regressions.
---

# Verify Fix

The final validation stage in the bug fixing pipeline.

## Instructions
1. **Run Suites**: Ensure `bench run-tests` and frontend test suites pass flawlessly.
2. **E2E Check**: Perform manual verification in the browser or via automated UI workflows to confirm resolution.
3. **Regression Safety**: Guarantee that horizontally adjacent components remain completely unaffected.
