# Workflow: `cde-review-workflow <pr-number>`

> Purpose: structured PR review for CDE slices — ensures the domain invariants are actually exercised, not just code-shaped.

## When to run
- Before merging any `modules/cde/**` change.
- On completion of any slice in the delivery plan.

## Steps

1. **Load the PR diff** + list changes at the slice level (models, services, controllers, components, migrations, specs).
2. **Run `cde-invariant-verifier` against HEAD + diff** — invariants must still hold.
3. **Run domain reviewers in order:**
   - `domain-reviewer` — check scope: slice implements exactly its spec'd capabilities, no scope creep.
   - `cde-security-reviewer` — permissions matrix reference for every controller action; no open endpoints.
   - `rails-reviewer` — Rails-specific code quality: service contracts, ArQuery usage, view component purity.
   - `cde-domain-reviewer` — semantic check: Identifier/Status/Suitability semantics, not just shape.
4. **Verify audit trail** — for every mutation introduced, confirm an audit event exists. If a mutation writes without audit, reject the PR.
5. **Check the immutable-states invariant** — no update path on Published/Archived records.
6. **Slice completion verdict** — for each slice touched, check the 7-part completion contract (UI, API, persistence, authorization, audit, tests, docs). Output:
   - ✅ done — all 7 present and passing CI
   - 🟡 partial — what's missing + blocker
   - ❌ fail — invariant violated or spec clause skipped
7. **Merge recommendation** — if all done, suggest merge with slice-completion note in the PR body.

## Tools used
- `gh` CLI or `git diff`
- `cde-invariant-verifier` — `D:\nexuscde\.agent\skills\cde-invariant-verifier\scripts\check.rb`
- `cde-publication-precondition-gate` — any state-mutation PR must demonstrate gate behavior.

## Output
A structured markdown review with pass/fail per slice/domain rule, and the merge recommendation. Keep it concise — this becomes the PR comment.
