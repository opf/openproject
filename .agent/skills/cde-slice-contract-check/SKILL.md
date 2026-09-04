# Skill: CDE Slice Contract Checker

## Description
Verify that a CDE slice implementation satisfies the 7-part completion contract. This skill enforces the spec requirement that a slice is only "done" when all dimensions are present.

## When to Use
- After scaffolding a new CDE slice (Slice 1-14)
- Before marking a slice as complete
- During PR review for CDE changes
- When verifying MVP scope completion

## The 7-Part Completion Contract
A CDE slice is ONLY complete when ALL of the following are implemented:

1. **UI** — Angular component or Rails view with permission-aware rendering
2. **API** — Rails controller action + Grape/Grape-Entity representer in `/api/v3/cde/...`
3. **Persistence** — Database migration + model with validations
4. **Authorization** — Permission matrix entry in `cde_permissions.seed.yml` + controller authorization check
5. **Audit Events** — Audit event emission on every mutating path (create, update, delete, state transition)
6. **Tests** — Model spec + policy spec + request spec + system spec
7. **Documentation** — Slice README + update `docs/cde/compliance-map.md`

## Verification Steps

### Step 1: Check UI
```bash
# Look for Angular component or Rails view
find modules/cde/app/views -name "*slice_N*"
find frontend/src/app -name "*cde-slice*N*"
```

### Step 2: Check API
```bash
# Look for controller and routes
grep -r "slice_N" modules/cde/app/controllers/
grep -r "slice_N" modules/cde/config/routes.rb
```

### Step 3: Check Persistence
```bash
# Look for migration and model
ls db/migrate/*slice_N*
ls modules/cde/app/models/cde/*slice_N*
```

### Step 4: Check Authorization
```bash
# Look for permission in seed file
grep "slice_N" modules/cde/config/cde_permissions.seed.yml
```

### Step 5: Check Audit Events
```bash
# Look for audit event emission
grep -r "AuditEvent.create" modules/cde/app/services/
grep -r "Cde::AuditEvent" modules/cde/app/models/
```

### Step 6: Check Tests
```bash
# Look for test files
find modules/cde/spec -name "*slice_N*"
```

### Step 7: Check Documentation
```bash
# Look for slice README and compliance map
ls docs/cde/slices/slice_N.md
grep "slice_N" docs/cde/compliance-map.md
```

## Output Format
After verification, output:
```
Slice N: [COMPLETE | PARTIAL | INCOMPLETE]

Completed:
- [ ] UI: ✓/✗
- [ ] API: ✓/✗
- [ ] Persistence: ✓/✗
- [ ] Authorization: ✓/✗
- [ ] Audit Events: ✓/✗
- [ ] Tests: ✓/✗
- [ ] Documentation: ✓/✗

Missing:
- [List any missing components]
```

## ISO 19650 Compliance
This verification ensures that each slice implements the full ISO 19650 capability, not just a partial technical implementation. The 7-part contract prevents "technical completion" (code exists) without "business completion" (user can actually use the feature end-to-end).

## Related Skills
- `vertical-slice-generator` — Scaffolds new slices
- `cde-invariant-verifier` — Verifies domain invariants
- `cde-publication-precondition-gate` — Verifies publication gate
