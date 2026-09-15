# Serena Safeguard — Quick Reference

## When to Invoke

```
User asks to: Modify existing code → USE THIS SKILL
User asks to: Add new feature → USE THIS SKILL
User asks to: Refactor/rename → USE THIS SKILL
User asks to: Fix typo in one file → Skip this skill
```

---

## 3-Phase Workflow (30-Second Summary)

### Phase 1: Pre-Implementation
```
1. Check CODEBASE_MAP.md and .serena/memories/
2. Run serena.find_references(symbol) if modifying existing code
3. Check if symbol is in critical_paths.md
4. If CRITICAL: Request user approval
5. If NEW: Run serena.get_symbols_overview() for conflict check
```

### Phase 2: Implementation
```
6. Use serena.refactor_* tools for code changes (not manual text replacement)
7. Follow established naming conventions
8. Keep changes isolated where possible
```

### Phase 3: Post-Implementation
```
9. Run serena.get_symbols_overview() on modified files
10. Update CODEBASE_MAP.md with any new structures
11. Update .serena/memories/ with any pattern changes
12. Log completion in /memories/session/
```

---

## Critical Checklist

- [ ] Impact analysis done (find_references for existing code)
- [ ] Critical path check completed
- [ ] User approval obtained (if CRITICAL PATH alert)
- [ ] Implementation used Serena symbolic tools (not text replacement)
- [ ] Post-implementation verification passed
- [ ] Knowledge maps updated
- [ ] Session notes logged

---

## Alert Threshold

**STOP & REQUEST APPROVAL if:**
- Symbol is in `.serena/memories/critical_paths.md`
- 15+ references across 5+ files
- Change affects public API signatures
- Modifying shared utilities (lib/, utils/, hooks/)

**Proceed without approval if:**
- New code (isolated, no existing dependents)
- ≤5 references in same module
- Documentation/comment-only changes

---

## Serena Commands Reference

```typescript
// Existing code changes
serena.find_references(symbol, filePath, lineContent)
  → Find all usages of a symbol

// New code validation
serena.get_symbols_overview(filePath)
  → List all exported symbols in a file

// Refactoring (preferred over text replacement)
serena.refactor_rename(oldName, newName)
serena.refactor_extract(code, newFunctionName)
serena.refactor_inline(functionToInline)
```

---

## File Locations

```
.serena/memories/
  ├─ critical_paths.md (symbols with 10+ dependents)
  ├─ naming_conventions.md (project patterns)
  └─ public_api_registry.md (backend whitelist methods)

CODEBASE_MAP.md (project-level structure)

/memories/session/ (implementation log for this session)
```

---

## Output Template (After Implementation)

```markdown
## Implementation Summary

**Files Modified:** [list]
**Symbols Affected:** [count]
**References Updated:** [count]
**Critical Paths Touched:** [yes/no]
**Impact Analysis:** [link to full report in session memory]

✅ Structural Verification Passed
✅ Knowledge Maps Updated
✅ Ready for Integration

```

---

## Common Mistakes to Avoid

❌ Starting code without impact analysis  
❌ Using text replace for code references (use Serena refactor tools)  
❌ Ignoring critical_paths.md alerts  
❌ Forgetting to update CODEBASE_MAP.md  
❌ Not re-scanning after implementation  
❌ Over-engineering trivial changes (typo fixes don't need this workflow)

