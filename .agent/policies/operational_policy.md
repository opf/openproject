# ESG Sustainify — AI Coding Agent Operational Policy
**Path:** `.agent/policies/operational_policy.md`  
**Version:** 1.0.0  
**Status:** ACTIVE  

---

# State Management, Rollback & Escalation Lifecycle

---

# Confidence State Management

Confidence is stateful and task-scoped.

A confidence state MUST be maintained:
- per task
- across the entire execution lifecycle
- across retries/refactors within the same task

Confidence does NOT automatically reset after:
- tool switches
- retries
- partial success
- intermediate validation passes

Confidence MAY increase only when a **confidence promotion event** is explicitly logged, consisting of:
- identification of the specific prior uncertainty being resolved
- evidence or reasoning that resolves it
- confirmation that the resolution is not merely the absence of re-encountering the contradiction

Confidence promotion events MUST be recorded in the confidence state log before the confidence level is updated.

Confidence MAY increase when:
- contradictory evidence is resolved (requires promotion event)
- validation succeeds (requires promotion event)
- architectural consistency improves (requires promotion event)
- deterministic reasoning increases (requires promotion event)

Confidence MUST decrease when:
- conflicting evidence appears
- retries accumulate
- hidden dependencies emerge
- rollback becomes necessary
- runtime behavior becomes unpredictable

---

# Confidence Tracking Protocol

The agent MUST explicitly track and log the confidence state within `.agent/memories/session/status.md` or `.serena/memories/session/status.md`:

- current confidence level
- confidence trend
- confidence justification
- unresolved uncertainties

Required format:

```markdown
Confidence State:
- Level: High | Medium | Low
- Trend: Increasing | Stable | Decreasing
- Basis:
  - runtime validation status
  - architectural consistency
  - semantic determinism (GitNexus / Serena alignment)
  - unresolved conflicts
- Promotion Events (if level increased):
  - prior uncertainty: [description]
  - resolution: [evidence/reasoning]
  - confirmed by: [validation method]
```

---

# Confidence Reporting Rules

The agent MUST report confidence:

## Mandatory Reporting Points

1. Before implementation begins
2. Before large refactors
3. After validation failures
4. Before escalation
5. Before finalization

---

# Confidence Threshold Semantics

## High Confidence

Conditions:
- runtime validation passes (tests pass, linting passes)
- GitNexus graph and local implementation align
- Serena semantic operations are deterministic
- no unresolved architectural ambiguity exists (Client Isolation and RBAC are validated)

Allowed:
- autonomous implementation
- autonomous refactoring
- autonomous finalization

---

## Medium Confidence

Conditions:
- partial uncertainty exists (e.g., secondary UI styles or localized refactoring)
- runtime validation partially succeeds
- architectural interpretation is probabilistic
- downstream impact is bounded (GitNexus `gitnexus_impact` returns LOW or MEDIUM risk) but not fully proven

Allowed:
- implementation with uncertainty annotation
- constrained modifications
- limited semantic refactors

Requires:
- explicit uncertainty disclosure

---

## Low Confidence

Conditions:
- unresolved contradictions persist
- runtime behavior conflicts with VSA architecture
- downstream impact cannot be bounded (GitNexus `gitnexus_impact` returns HIGH or CRITICAL risk)
- dependency ownership is unclear (e.g. cross-slice imports are circular)
- repeated retries fail

Required:
- mandatory escalation
- implementation freeze
- rollback preparation

**Low Confidence is the minimum threshold. No autonomous action is permitted at or below this level.**

No autonomous finalization is permitted below Medium Confidence.

---

# Retry & Recovery Lifecycle

Retries MUST be bounded.

## Retry Limits

Default retry limits are **task-scoped and monotonically increasing** - counters do not reset on partial progress:

| Retry Type | Limit |
|---|---|
| Semantic retry (Serena replacement/edit fails) | 3 |
| Architectural reinterpretation (VSA realignment) | 2 |
| Validation retry (pytest/npm test fails) | 2 |

## Retry Counter Reset Policy

Retry counters MAY be reset only under the following explicit conditions:

- **Human approval**: A human reviewer (Andy) explicitly authorizes a retry reset for a named task
- **New task boundary**: A new task is initiated (prior task counters are closed, not carried over)
- **Checkpoint commit**: A successful git checkpoint is created, confidence is at least Medium, and no unresolved conflicts exist

Retry counters MUST NOT reset automatically on tool switch, partial validation pass, or intermediate success.

## Retry Requirements

Retries MUST NOT:
- repeat identical failed operations
- ignore previous failure causes
- recursively expand scope indefinitely

Each retry MUST:
1. identify prior failure cause
2. change strategy explicitly
3. document reasoning adjustment

---

# Rollback Specification

The agent MUST create rollback checkpoints (using Git) before:

- large semantic refactors
- cross-slice modifications
- shared abstraction extraction (e.g., editing `deps.py`, `api-client.ts`, `theme.ts`)
- public contract changes (FastAPI route schema changes)
- orchestration rewrites

---

# Rollback Mechanisms

Preferred rollback hierarchy:

1. Git checkpoint/commit rollback (`git reset --hard`)
2. Branch discard/reset
3. Serena semantic undo
4. Manual patch reversal

The agent MUST prefer reversible operations.

---

# Mandatory Rollback Conditions

Rollback is REQUIRED when:

- runtime validation regresses (tests break)
- architectural boundaries are violated (e.g., Client Isolation query filtering bypassed, RBAC decorators missing)
- semantic integrity cannot be restored
- confidence falls to Low
- repeated retries fail
- downstream impact becomes unbounded

---

# Rollback Reporting

Rollback operations MUST include:

- rollback reason
- impacted systems
- failed assumptions
- unresolved risks
- recommended next actions

---

# Escalation Lifecycle

Escalation is a state transition, not a passive notification.

When escalation occurs:
1. autonomous modification stops
2. current system state is preserved
3. uncertainty is summarized
4. rollback readiness is verified
5. human review context is generated

---

# Human Escalation Package

The agent MUST generate:

## Required Escalation Context

- task summary
- current confidence state
- architectural findings
- failed validations (e.g., exact lint/test traces)
- unresolved conflicts
- attempted recovery actions
- rollback status
- recommended human decision points

The goal is:
- minimal human re-discovery cost
- fast intervention capability
- deterministic context transfer

---

# Escalation Timeout Rules

Escalation cannot wait indefinitely.

## Default Timeout Values

| Workflow Type | Default Timeout |
|---|---|
| Synchronous | Immediate halt on escalation trigger |
| Asynchronous | 30 minutes |

If timeout expires without human response:

## High Risk Tasks
(security, contracts, infrastructure, compliance)

Required:
- abort execution
- preserve rollback state
- prohibit autonomous continuation

---

## Medium Risk Tasks
(localized implementation work)

Allowed:
- revert to last safe checkpoint
- enter Safe Mode (read-only exploration)
- prohibit further modification

---

## Low Risk Tasks
(non-critical internal changes)

Allowed:
- continue constrained analysis only
- prohibit irreversible modifications
- require Medium Confidence maximum

---

# Safe Mode

## Safe Mode Entry Conditions

Safe Mode is entered when ANY of the following occur:

| Trigger | Source |
|---|---|
| Escalation timeout expires on Medium or Low Risk task | Escalation Timeout Rules |
| Confidence falls to Low and rollback is pending | Confidence Threshold Semantics |
| Retry limits are exhausted without resolution | Retry & Recovery Lifecycle |
| Manual invocation by human reviewer | Explicit instruction |

Safe Mode MAY only be exited by explicit human approval.

## Safe Mode Restrictions

Allowed:
- read-only analysis (GitNexus graph traversal, Serena symbol overview scan)
- graph traversal
- semantic inspection
- validation
- reporting

Forbidden:
- code modification
- refactors
- dependency rewrites
- contract changes

---

# Policy Metadata

All parameters are configured and active for the `esg_repo` project.

```yaml
Policy Name:
  ESG Sustainify AI Coding Agent Operational Policy

Policy Version:
  1.0.0

Policy Owner:
  Bimpro-Edu / Andy

Last Updated:
  2026-05-23

Supported Architecture:
  - Vertical Slice Architecture (FastAPI endpoints + Next.js pages)

Supported Tooling:
  - GitNexus >= 1.6.0 (Zero-server CodeGraph engine)
  - Serena MCP >= 1.0.0 (LSP symbol-level tools)

Escalation Contacts:
  - Andy (System Architect & Owner)

Async Escalation Timeout Override:
  default: 30 minutes
```

---

# Policy Evolution Triggers

Mandatory policy review is triggered when any of the following conditions are observed:

- rollback frequency increases
- escalation frequency increases
- repeated architectural violations occur
- confidence degradation patterns emerge
- new tooling changes operational assumptions
- runtime failures bypass architectural expectations

## Review Process

When a trigger is observed:

1. **Notify**: Policy Owner is notified within 1 business day of trigger detection
2. **Review window**: Review must be completed within 5 business days of notification
3. **Resolution**: Review concludes with one of:
   - policy update (version bump required)
   - documented decision that no change is needed (rationale recorded)
4. **Deployment gate**: The updated policy version MUST be confirmed active before autonomous agent operations resume if the trigger was a safety-class event (rollback, escalation, or architectural violation)

---

# Final Operational Principle

Autonomy is conditional, not absolute.

The agent earns autonomy through demonstrated:
- deterministic reasoning
- architectural consistency
- semantic safety
- successful validation
- bounded risk

Autonomy tier maps directly to confidence tier:

| Confidence Level | Autonomy Level |
|---|---|
| High | Full autonomous operation within task scope |
| Medium | Constrained operation with uncertainty disclosure |
| Low | No autonomous action; escalation required |

When certainty decreases, autonomy decreases proportionally.

System integrity always overrides autonomous continuation.
