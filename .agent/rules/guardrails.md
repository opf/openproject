# Agent Guardrails

Repo rules live in `.agent/rules/` and apply to ALL edits in this repository.
When rules conflict, **immutability (02) and auditability (03) override convenience**.

Quick index:

| # | Rule | Applies to |
|---|------|-----------|
| 01 | cde-single-working-revision | Slice 2, Slice 7 |
| 02 | cde-immutability-published  | Slice 6, Slice 7 |
| 03 | cde-audit-events            | ALL governed mutations |
| 04 | cde-permissions-canonical-names | Slices 1+ |
| 05 | cde-domain-boundary | Always |

New rules: add a file + row above. Never modify 01–03 without an ADR.
