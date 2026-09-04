# Skill: CDE Invariant Verifier

## Description
Verify that CDE domain invariants hold for a given container, revision, or the entire dataset. This skill implements the mechanical checks from ISO 19650-1 and the project's CDE conventions.

## When to Use
- Before merging any CDE slice PR
- After running migrations
- During slice completion verification
- In CI/CD pipeline for governance checks

## Invariants to Check

### 1. Single Active Working Revision
```ruby
# Each container must have exactly one working revision
container.revisions.where(is_working: true).count == 1
```

### 2. Published Revisions Are Immutable
```ruby
# No updates allowed to published revisions
revision.published? ? revision.locked? : true
```

### 3. Identifier Uniqueness
```ruby
# Identifier must be unique within project
Cde::IdentifierValidator.valid?(container.identifier, container.project_id)
```

### 4. Status Code Validity
```ruby
# Status must be from controlled vocabulary
valid_statuses = Cde::Conventions.status_codes
container.status.in?(valid_statuses)
```

### 5. Suitability Code Validity
```ruby
# Suitability must be from controlled vocabulary
valid_suitabilities = Cde::Conventions.suitability_codes
container.suitability&.code.in?(valid_suitabilities)
```

### 6. Metadata Completeness
```ruby
# Mandatory metadata fields must be present
mandatory_fields = Cde::Conventions.mandatory_metadata_fields
container.metadata_entries.all? { |m| mandatory_fields.all? { |f| m.send(f).present? } }
```

### 7. Audit Trail Completeness
```ruby
# Every mutation must have an audit event
# Check for missing audit events on recent mutations
```

## Usage

### CLI Verification
```bash
# Check a specific container
ruby scripts/check.rb --container-id 123

# Check all containers in a project
ruby scripts/check.rb --project-id 456

# Check all invariants across all containers
ruby scripts/check.rb --all

# Fix reportable issues (where possible)
ruby scripts/check.rb --fix
```

### API Verification
```ruby
# Check a container
Cde::InvariantVerifier.check(container)

# Check with fix option
Cde::InvariantVerifier.check(container, fix: true)

# Get detailed report
report = Cde::InvariantVerifier.verify(container)
report.errors  # List of violations
report.warnings  # List of potential issues
report.passed?  # Boolean
```

## Output Format

### Pass
```
✅ All invariants passed for Container #123
  - Working revision: 1 (valid)
  - Published revisions: 2 (immutable)
  - Identifier: valid (unique within project)
  - Status: published (valid code)
  - Suitability: S1 (valid code)
  - Metadata: complete (all mandatory fields present)
  - Audit trail: complete (all mutations logged)
```

### Fail
```
❌ Invariant violations found for Container #123

Errors:
  [E001] Multiple working revisions: expected 1, found 2
    - Revision #456 is_working=true
    - Revision #789 is_working=true
    - Suggested fix: Set is_working=false on older revision

  [E002] Published revision has recent update
    - Revision #123 published at 2024-01-01
    - Updated at 2024-01-02 (after publication)
    - Suggested fix: Create new working revision instead of editing published one

Warnings:
  [W001] Metadata originator inconsistent
    - Current value: "BIM Team"
    - Expected: One of [BIM Manager, BIM Coordinator, Lead Designer]
```

## Error Code Reference

| Code | Severity | Description |
|------|----------|-------------|
| E001 | Error | Multiple working revisions |
| E002 | Error | Published revision modified after publication |
| E003 | Error | Invalid identifier format |
| E004 | Error | Duplicate identifier within project |
| E005 | Error | Invalid status code |
| E006 | Error | Invalid suitability code |
| E007 | Error | Missing mandatory metadata |
| E008 | Error | Missing audit event for mutation |

| Code | Severity | Description |
|------|----------|-------------|
| W001 | Warning | Inconsistent metadata values |
| W002 | Warning | Stale audit events |
| W003 | Warning | Orphaned revisions |

## Related Skills
- `cde-slice-contract-check` — Verify slice completion
- `cde-publication-precondition-gate` — Check publication preconditions
- `cde-permissions-matrix` — Verify permission matrix consistency

## ISO 19650 Compliance
This verifier implements the mechanical checks required by ISO 19650-1 for:
- Container identification and uniqueness (§12.5)
- Revision management (§12.6)
- Status codes (§12.7)
- Metadata requirements (§12.8)
- Audit trail requirements (§12.9)

Human-governed clauses (EIR, TIDP, capability assessments) are NOT checked by this tool.
