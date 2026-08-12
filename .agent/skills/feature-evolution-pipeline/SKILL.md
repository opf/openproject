---
name: feature-evolution-pipeline
description: Orchestrates the design-first feature enhancement process.
---

# Feature Evolution Pipeline

This skill orchestrates the architecture-first feature evolution process for robust enhancements.

## Pipeline Architecture
To implement a new feature enhancement, follow these sequential steps:

1. **`analyze-current-feature`**: Understand the current architectural and UX limitations.
2. **`redesign-feature`**: Propose a better structure or API surface.
3. **`evaluate-design-options`**: Compare multiple approaches for scalability and maintainability.
4. **`fastapi-vertical-slice-generator`**: Implement a clean vertical slice (Model -> Schema -> Service -> Endpoint -> Component).
5. **`hybrid-qa-operations`**: Execute the dual-path verification pass (Playwright + Subagent) to ensure technical and visual excellence.

*Optional operations:* Utilize **`optimize-domain-model`** or **`extend-existing-api`** when refining the core domain.

### Incremental Strategy Guardrails
When executing this pipeline across sessions, you must adhere strictly to the **13 Tips** outlined in the global `GEMINI.md`:
- **Deliberation Mode (#7) & Research Mode (#5):** `analyze-current-feature` and `redesign-feature` must be thoroughly documented without writing code. Research APIs and validate dependencies (*Tool Governance #6*).
- **Complexity Escalation (#3) & Vertical Slicing:** In `fastapi-vertical-slice-generator`, build simple static UI versions *before* introducing state management.
- **Update vs Rewrite (#2):** Default to incremental code updates for additions under 20 lines. Only perform complete file rewrites for major restructuring.
- **Artifacts (#1):** Any new component exceeding 20 lines must be split into a dedicated artifact/file.
- **Parseable Output (#13):** Generate JSON dependency reports and feature completion statuses at the end of the slice for systematic progress tracking.
