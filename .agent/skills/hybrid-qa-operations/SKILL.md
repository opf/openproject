---
name: hybrid-qa-operations
description: Execute a dual-path verification of data integrity (automated) and UI aesthetics (agentic).
---

# Hybrid QA Operations

This skill balances the precision of automated testing with the contextual intelligence of an AI agent for exploratory and aesthetic verification.

## Instructions

### Phase 1: Automated Verification (Playwright)
1. **Regression Check**: Run existing Playwright test suites (`pnpm test:e2e`) to ensure no breaking changes in data flow or core business logic.
2. **Implementation Verification**: Write or update specific `.spec.ts` files for the new feature.
3. **Data Assertions**: Use strict assertions for database states, API response schemas, and critical UI elements (e.g., `expect(page.getByText('Student Enrolled')).toBeVisible()`).

### Phase 2: Agentic Exploratory Audit (Subagent)
1. **Visual Consistency**: Verify that components use `shadcn/ui` primitives and align with the "Premium UI" mandate (gradients, transitions, spacing).
2. **Responsive Check**: Test the UI at different viewport sizes (Mobile, Tablet, Desktop) and check for layout breakages.
3. **"Writability" & Flow**: Ensure the user journey feels intuitive and interaction feedback (loading states, toast notifications) is clear and smooth.

### Phase 3: Consolidation
1. **Evidence Collection**: Capture screenshots/recordings of both technical failures (from Playwright Trace) and aesthetic successes (from the subagent).
2. **Summary Report**: Mark the feature as "Verified" only after both Phases pass successfully.

## Recommended Tools
- **Playwright**: `npx playwright test`
- **Tracing**: `npx playwright show-trace trace.zip`
- **Subagent**: `browser_subagent` with a task focused on "Aesthetics and UX Audit".
