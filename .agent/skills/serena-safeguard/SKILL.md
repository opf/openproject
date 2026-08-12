# Skill: Serena Safeguard & Codebase Mapping

**Version:** 1.0  
**Last Updated:** April 15, 2026  
**Reliability Tier:** High-Confidence  
**Maintainer:** AI Agent

---

## Overview

This skill provides a **high-reliability workflow** for performing impact analysis, maintaining structural codebase maps, and preventing regressions during any code modification or feature development. It leverages **Serena MCP** (language server protocol) for symbol-level accuracy and maintains persistent knowledge in `.serena/memories/` and `CODEBASE_MAP.md`.

---

## When to Use This Skill

- **Before modifying existing code:** Understand all dependents and side effects.
- **During feature development:** Ensure new code integrates seamlessly without naming collisions or breaking changes.
- **After major refactors:** Verify structural integrity and update central maps.
- **During cross-module integration:** Validate that public API signatures remain stable.
- **When risk is high:** Critical path changes, shared utilities, public API modifications.
- **For knowledge synchronization:** Keep codebase documentation in sync with reality.

### Use in Parallel with Other Agents
This skill is **safe to combine** with feature development, bug-fixing, and refactoring tasks. Always invoke **before** implementation begins on risky changes.

---

## When NOT to Use This Skill

- **Trivial single-file edits:** Simple typo fixes, comment updates, or isolated utility changes don't warrant full impact analysis.
- **Greenfield projects:** New projects without existing critical paths—standard development practices suffice.
- **Documentation-only changes:** Non-code updates (README, guides, examples) don't require structural analysis.
- **Known, well-isolated changes:** If you can manually verify all affected files in <5 minutes, standard editing is sufficient.
- **Prototyping/scratch code:** Temporary experimental work outside the main codebase.

---

## Workflow

### Phase 1: Pre-Implementation (Stop Before Coding)

#### Step 1A: Consult Codebase Maps
1. Check if `CODEBASE_MAP.md` exists in the workspace root.
2. Check if `.serena/memories/` directory exists and review:
   - `critical_paths.md` — List of modules/functions that affect many dependents
   - `naming_conventions.md` — Established patterns to avoid collisions
   - `public_api_registry.md` — APIs exposed to external systems

**Action if missing:** Create stub files (see **Initialization** section below).

#### Step 1B: Impact Analysis for Existing Code Changes

**If modifying existing symbols (function, class, method, variable):**

1. Use **Serena `find_references`** to identify all call sites, imports, and usages.
   - Command signature: `serena.find_references(symbol: string, filePath: string, lineContent: string)`
   - Collect the complete dependency graph.

2. Categorize each reference:
   - **Local:** Same file or package—low risk
   - **Cross-module:** Different subsystem—medium risk, requires testing
   - **Public API:** Consumed by external code (frontend, third-party)—**CRITICAL, requires versioning**

3. **Alert Condition:** If the modified symbol appears in `.serena/memories/critical_paths.md`:
   - **STOP implementation**
   - Request explicit confirmation from user before proceeding
   - Log the decision in session memory

**Example Alert:**
```
⚠️  CRITICAL PATH ALERT ⚠️
Proposed change: Rename `frappe.get_all()` wrapper in lib/frappe/client.ts
Affected modules: 12 components (6 critical)
Dependents: frontend/* (5 files), hooks/* (3 files), components/* (4 files)

This symbol is in critical_paths.md. Proceed only with explicit approval.
User confirmation required: YES / NO
```

#### Step 1C: Impact Analysis for New Features

**If adding new code (files, functions, classes):**

1. Use **Serena `get_symbols_overview`** on related modules to understand:
   - Existing naming patterns (e.g., hooks use `use*`, components use `PascalCase`)
   - Established export conventions
   - Potential naming collisions

2. Cross-check new names against `.serena/memories/naming_conventions.md`

3. Verify architectural fit:
   - Does the new module belong in its proposed directory?
   - Are there existing utilities it should inherit/extend?
   - Does it follow the project's dependency hierarchy (no circular imports)?

---

### Phase 2: Implementation

#### Step 2A: Use Serena for Symbolic Operations

**Whenever modifying code references:**

1. **Prefer Serena's LSP-based tools** over raw text replacement:
   - Use `serena.refactor_rename()` for symbol renames (updates all references automatically)
   - Use `serena.refactor_extract()` for extracting code into new functions
   - Use `serena.refactor_inline()` for consolidating repeated patterns

2. **Fallback to text replacement** only when:
   - The symbol has no references
   - You need to modify string values (not code references)
   - Serena tools are unavailable or inappropriate

#### Step 2B: Implement Changes

- Follow the project's established patterns (architecture, naming, structure)
- Ensure new public APIs are backward-compatible if applicable
- Update existing function signatures **only if unavoidable**—and only after impact analysis confirms all call sites are updated

---

### Phase 3: Post-Implementation (Verification & Synchronization)

#### Step 3A: Structural Re-Scan

After writing files, immediately run:

1. **Serena `get_symbols_overview`** on each modified file to confirm:
   - All intended symbols are present
   - No unintended deletions occurred
   - Export statements are intact

2. **Serena `find_references`** on newly created public exports to ensure:
   - No naming collisions with existing code
   - Correct import paths (if applicable)

#### Step 3B: Update Knowledge Maps

1. **Update `CODEBASE_MAP.md`:**
   - Add new modules/functions to the structure section
   - Update dependency tree if cross-module imports changed
   - Document any new public APIs

2. **Update `.serena/memories/`:**
   - If the change affects critical paths, update `critical_paths.md`
   - If new naming patterns were introduced, update `naming_conventions.md`
   - If new public APIs were created, update `public_api_registry.md`

3. **Format Requirement:** Markdown tables for easy scanning, 1-line descriptions

#### Step 3C: Record Implementation Details

Log in session memory (`/memories/session/`):
- Files modified/created
- Symbols affected (list)
- References updated (count)
- Verification results (pass/fail)
- Any deviations from plan

---

## Initialization (First Run)

If `.serena/memories/` doesn't exist, create these stub files:

### `.serena/memories/critical_paths.md`
```markdown
# Critical Paths — Symbols Affecting Multiple Dependents

## Core Libraries
| Symbol | Module | Dependents | Risk Level |
|---|---|---|---|
| `frappeCall` | `lib/frappe/client.ts` | 12+ components | CRITICAL |
| `frappe.whitelist()` | Backend API | All backend endpoints | CRITICAL |

## UI Components
| Symbol | Module | Dependents | Risk Level |
|---|---|---|---|
| `cn()` | `lib/utils.ts` | 40+ components | HIGH |

*Add entries as you discover highly-coupled code.*
```

### `.serena/memories/naming_conventions.md`
```markdown
# Naming Conventions — Prevent Collisions

## React Hooks
- **Pattern:** `use<Feature>`
- **Examples:** `useClasses()`, `useSessions()`, `useAttendance()`
- **Rule:** Always start with `use`, PascalCase for feature name

## Components
- **Pattern:** `PascalCase.tsx`
- **Examples:** `ClassTable.tsx`, `SessionForm.tsx`
- **Utilities:** `kebab-case.ts` (e.g., `form-helpers.ts`)

## Backend Functions
- **Pattern:** `snake_case()`
- **Frappe whitelist:** `app_name.module.function_name`
- **Example:** `class_mgmt.api.get_session_attendance`

*Document project-specific patterns here.*
```

### `.serena/memories/public_api_registry.md`
```markdown
# Public API Registry — External Consumers

## Backend Whitelist Methods
| Method | Module | Consumers | Stability |
|---|---|---|---|
| `class_mgmt.api.get_sessions` | `api.py` | Frontend ClassTable | STABLE |

## Frontend Exports (if shared libraries exist)
| Export | Module | Consumers | Stability |
|---|---|---|---|

*Track APIs exposed to external systems.*
```

### `CODEBASE_MAP.md` (if missing)
```markdown
# Codebase Map — Structural Overview

## Project Structure
```
class-manager/
├── .agent/                    # Agent skills & configurations
├── .serena/                   # Serena knowledge base
├── frontend/                  # Next.js app (frontend)
│   ├── app/                   # Pages & layouts
│   ├── components/            # UI components
│   ├── hooks/                 # React hooks
│   ├── lib/                   # Utilities & API client
│   └── types/                 # TypeScript definitions
├── class_mgmt/                # Frappe backend app
│   ├── api.py                 # Whitelisted endpoints
│   ├── hooks.py               # DocType hooks
│   └── doctype/               # DocType definitions
└── Slices/                    # Feature specifications
```

## Critical Dependencies
- `frontend/lib/frappe/client.ts` → All Frappe API calls
- `class_mgmt/api.py` → Backend business logic
- `class_mgmt/hooks.py` → DocType lifecycle events

*Document critical paths here.*
```

---

## Best Practices

### 1. Impact Analysis First, Code Second
- Never jump to implementation without understanding dependents.
- A 10-minute impact analysis saves 2 hours of debugging.

### 2. Symbolic Integrity Over Text Replacement
- Use Serena's refactoring tools to maintain reference integrity.
- Avoid manual find-and-replace for code references—it misses edge cases.

### 3. Document Critical Paths
- The more "hidden" a reference is (dynamic calls, string-based imports), the more critical it is to document in `.serena/memories/`.

### 4. Incremental Verification
- After each significant change, re-scan with Serena to confirm structural integrity.
- Don't batch multiple changes before verification.

### 5. Keep Maps Current
- A stale `CODEBASE_MAP.md` is worse than none—it provides false confidence.
- Update it **immediately** after major refactors.

---

## Constraints

### ❌ NEVER
- Delete or modify existing functions/variables without a complete impact report.
- Change public API signatures or return types without updating **all** detected references.
- Introduce naming collisions (always check `naming_conventions.md` first).
- Commit changes without verifying Serena's structural re-scan passes.
- Ignore CRITICAL PATH ALERTS—always request user confirmation.

### ✅ ALWAYS
- Run impact analysis before modifying existing code.
- Use Serena's symbolic tools instead of text replacement when possible.
- Update `.serena/memories/` and `CODEBASE_MAP.md` after implementation.
- Re-scan modified files using `serena.get_symbols_overview()` to confirm integrity.
- Document decisions in session memory for traceability.

---

## Example Workflows

### Scenario 1: Renaming a Widely-Used Utility Function

```
Step 1: Impact Analysis
   └─ serena.find_references("formatDate", "lib/utils.ts")
   └─ Result: 23 references across 8 files

Step 2: Alert Check
   └─ Is "formatDate" in critical_paths.md? YES
   └─ Notify user: "CRITICAL PATH ALERT — 23 dependents found"
   └─ Wait for explicit approval

Step 3: Implementation
   └─ Use serena.refactor_rename("formatDate", "formatSessionDate")
   └─ All 23 references updated automatically

Step 4: Verification
   └─ serena.get_symbols_overview("lib/utils.ts")
   └─ Confirm "formatSessionDate" exported correctly
   └─ serena.find_references("formatSessionDate") should show 23 matches

Step 5: Sync Knowledge
   └─ Update CODEBASE_MAP.md (export section)
   └─ Update .serena/memories/naming_conventions.md if pattern changed
   └─ Log in session memory: "Renamed formatDate → formatSessionDate (23 refs)"
```

### Scenario 2: Adding a New React Hook

```
Step 1: Fit Check
   └─ serena.get_symbols_overview("hooks/")
   └─ Review existing hook naming patterns

Step 2: Naming Collision Check
   └─ Check naming_conventions.md: pattern is "use<Feature>"
   └─ No collision with existing "useClasses", "useSessions"

Step 3: Implementation
   └─ Create "useNewFeature.ts" following established patterns
   └─ Export from hooks/index.ts

Step 4: Verification
   └─ serena.get_symbols_overview("hooks/useNewFeature.ts")
   └─ Confirm export is correct

Step 5: Sync Knowledge
   └─ Update CODEBASE_MAP.md with new hook location
   └─ Session memory: "Added useNewFeature hook to hooks/"
```

### Scenario 3: Adding a Backend Whitelist Method

```
Step 1: API Registry Check
   └─ Review public_api_registry.md for patterns
   └─ Check for naming collisions with existing endpoints

Step 2: Impact Check
   └─ New method, so no existing references to worry about
   └─ But verify it doesn't conflict with LMS API patterns

Step 3: Implementation
   └─ Add @frappe.whitelist() method to api.py
   └─ Follow naming pattern: class_mgmt.api.new_endpoint

Step 4: Verification
   └─ serena.get_symbols_overview("api.py")
   └─ Confirm method is exported in __all__

Step 5: Sync Knowledge
   └─ Update public_api_registry.md with new endpoint
   └─ Update CODEBASE_MAP.md (API section)
   └─ Log in session memory
```

---

## Integration with Other Agents

### Safe to Combine With:
- **Vertical-Slice-Generator:** Use this skill to validate slice architecture before implementation.
- **Bug-Fixing-Pipeline:** Use this skill in the "root-cause-analysis" phase to understand affected systems.
- **Feature-Evolution-Pipeline:** Use this skill before "implement-feature-slice" to plan architecture.
- **Code-Cleanup:** Use this skill to validate refactoring scope before cleanup.

### Invoke Pattern:
```
1. Main task begins (e.g., "implement feature X")
2. Call Serena-Safeguard skill (impact analysis phase)
3. Get confirmation if needed
4. Proceed with feature implementation
5. Call Serena-Safeguard again (post-implementation verification)
6. Continue with main task
```

---

## Troubleshooting

### Issue: Serena Tools Unavailable
- **Fallback:** Use `grep_search` and `vscode_listCodeUsages` for manual reference discovery.
- **Then:** Apply text replacements carefully, with extra verification.
- **Remember:** This is lower-reliability than Serena-based workflows.

### Issue: Codebase Maps Outdated
- **Action:** Run full re-scan using `Explore` agent:
  ```
  Explore: Scan entire codebase for all exported symbols and critical functions.
  Create a fresh CODEBASE_MAP.md and .serena/memories/ files.
  ```
- **Then:** Resume normal Serena-Safeguard workflows.

### Issue: Too Many Dependents (>50 References)
- **Strategy:** Break the change into smaller, incremental steps.
- **Batch approach:** Change 10-15 references at a time, verify each batch.
- **Document:** Log each batch completion in session memory.

---

## Related Files & Commands

| Resource | Location | Purpose |
|---|---|---|
| Codebase Map | `CODEBASE_MAP.md` | Structural reference |
| Critical Paths | `.serena/memories/critical_paths.md` | Risk identification |
| Naming Conventions | `.serena/memories/naming_conventions.md` | Collision prevention |
| Public API Registry | `.serena/memories/public_api_registry.md` | External consumer tracking |
| Session Notes | `/memories/session/` | Implementation log |

---

## Version History

| Version | Date | Changes |
|---|---|---|
| 1.0 | April 15, 2026 | Initial skill definition with full workflow |

