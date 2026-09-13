# Rule: Single Active Working Revision

## Statement
At any given time, an Information Container MUST have exactly ONE active working revision. When a new working revision is created, the previous one MUST be deactivated (set `is_working = false`).

## Rationale
This invariant prevents concurrent editing conflicts and ensures a clear single source of truth for the working state. It is a fundamental rule of ISO 19650 revision management.

## Enforcement
- **Model level**: `before_save` callback in `Cde::Revision` deactivates other working revisions when a new one is activated.
- **Service level**: Services that create or activate revisions MUST enforce this invariant.
- **Audit level**: Every transition of working revision MUST emit an audit event.

## Violations
If this invariant is violated:
1. The system MUST reject the operation with a clear error.
2. An audit event MUST be logged with the attempted action and the violation reason.
3. The system state MUST be rolled back to the pre-violation state.

## Compliance Check
```ruby
# In tests or verification scripts
def verify_single_working_revision(container)
  working_count = container.revisions.where(is_working: true).count
  raise "Invariant violated: expected 1 working revision, found #{working_count}" unless working_count == 1
end
```

## Related Slices
- Slice 1: Create Information Container in WIP
- Slice 2: Manage Working Revision
- Slice 7: Revision After Publication
