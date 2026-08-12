---
name: cde-publication-precondition-gate
description: Verify a CDE container revision may transition to Published. Single non-bypassable gate. Emits audit events for pass AND fail.
when_to_use: Called from the state machine guard on any transition into `Published`. Also runnable manually to dry-run a publish attempt.
category: cde-domain
metadata:
  hermes:
    tags: [cde, openproject, governance, publication, state-gate]
---

# CDE Publication Precondition Gate

The single authorized path into `Published`. Enforces the publication preconditions from the CDE spec (Slice 6) and converts state changes into audit evidence.

## Precondition set (all must PASS)

| # | Check | Method | ISO 19650 anchor |
|---|-------|--------|------------------|
| 1 | Mandatory metadata complete | `Cde::IdentifierValidator.metadata_errors(container).empty?` | ISO 19650-1 metadata requirements |
| 2 | Identifier valid | `Cde::IdentifierValidator.call(container).ok?` | container identification |
| 3 | Suitability assigned & valid | revision.suitability in vocabulary + assigned_by holds authorized role | suitability codes |
| 4 | Required approvals completed | approval rows: decision=approved, approver role ∈ required, none outstanding | authorization of information |

## Design rules (non-negotiable)

1. **Exactly one transition** into `Published` in the state machine; this gate is its guard. There must be no other code path that sets state to published — no raw `update_column`, no service that flips state directly. The contract checker (grep/arch tests) enforces this.
2. **Non-bypassable guard.** Guards receive the transition context; they must not be skippable via flag/param.
3. **Named refusals.** On failure, report WHICH precondition failed with detail, for compliance reason-capture.
4. **Fail-closed on missing config/vocabulary.** Any error inside a check = FAIL with the exception in detail. Never default to pass.
5. **Both outcomes audited.** Pass emits `revision_published`; fail emits `publish_refused` (with the failed check names in metadata). Audit completeness is the compliance claim.

## Reference implementation

```ruby
module Cde
  class PublicationGate
    Result = Data.define(:allowed?, :checks) # checks: [{name:, passed:, detail:}]

    def self.evaluate(container:, revision:, actor:)
      checks = [
        check_metadata(container),
        check_identifier(container),
        check_suitability(revision, actor:),
        check_approvals(revision),
      ]
      new(container:, revision:, actor:, result: Result.new(checks.all?(&:passed), checks))
    end

    # each check_* wraps its logic in begin/rescue => Check failed with detail "error: ..."
    # so misconfiguration fails CLOSED, never open.
  end
end
```

## State machine wiring (AASM example)

```ruby
state :published
event :publish do
  transitions from: :shared, to: :published, guard: :publication_gate_allows?
  after { Cde::AuditLog.record(self, actor: Current.user, action: "revision_published", reason: @gate_reason) }
end

def publication_gate_allows?
  evaluation = Cde::PublicationGate.evaluate(container:, revision: active_revision, actor: Current.user)
  unless evaluation.result.allowed?
    Cde::AuditLog.record(self, actor: Current.user, action: "publish_refused",
                       reason: evaluation.failed_checks.map(&:name).join(", "))
  end
  evaluation.result.allowed?
end
```

## Audit report generation (Slice 13/14 feeder)

See `cde-audit-event-scaffold` → `compliance_report_for(container)`. The report must end with the **residual human-governed clauses** disclaimer: EIR agreed contractually, TIDP vs actual delivery, originator capability — these are never machine-verified; the report lists them as out-of-band attestations.

## Verification steps

1. Happy path → transition succeeds, `revision_published` event present.
2. Each precondition forced to fail (one at a time) → transition rejected, `publish_refused` names only that check.
3. Combo failure → all failed checks named.
4. Attempt to bypass (direct state write) → contract checker flags it / DB trigger rejects it.
5. Published revision is then immutable (see rule `cde-immutability-published`).
6. Compliance report for a published container reconstructs the full gate evaluation history.

## Ties to other artifacts

- Consumes `cde-identifier-validate` and `cde-metadata-vocabulary`.
- Guard behavior governed by `cde-single-active-working-revision` and `cde-immutability-published` rules.
- Emits via `cde-audit-event-scaffold`.
- `/cde-slice` workflow pre-wires this gate when scaffolding Slice 6.
