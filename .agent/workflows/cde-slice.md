# /cde-slice Workflow

Scaffolds a complete ISO 19650-informed vertical slice into `modules/cde/`, satisfying
the completion contract enforced by `cde-slice-contract-check`.

## Usage
```
/cde-slice <slice-number-or-name> [--dry-run]
```

## What it generates

For slice `N` (e.g. `5` suitability, `6` publication):

1. **Migration** — `db/migrate/<ts>_cde_slice_<n>_<name>.rb` with new tables/columns.
2. **Model(s)** — `modules/cde/app/models/cde/...` with AASM states where applicable.
3. **Service** — `modules/cde/app/services/cde/...` with transition guards + audit event emission.
4. **API** — Rails controller + Grape/Grape-Entity representer for `/api/v3/cde/...`.
5. **Front-end** — Angular component + route (or Rails view for MVP) with permission-aware rendering.
6. **Permissions** — extend `config/cde_permissions.seed.yml` if new capability introduced.
7. **Audit** — `Cde::Audit.record` hooks on every mutating path.
8. **Tests**:
   - model specs (invariants via `cde-invariant-verifier`)
   - policy specs (capability matrix conformance)
   - request specs (API + authorization)
   - system spec for the UI path
9. **Docs** — slice README + update `docs/cde/compliance-map.md`.

## Behavior
1. Load slice definition from `docs/cde/vertical-slices.md` (the artifact already in repo).
2. Ask for clarifications only when a decision materially changes the schema (e.g. code list).
3. Generate files under `modules/cde/` following OpenProject plugin conventions.
4. Run generators in dependency order; stop on any generator failure and surface the diff.
5. Emit a summary listing created files + next manual steps (i18n keys, routes mount, etc.).

## Failure modes
- Slice not found in the slices doc → refuses.
- Generated file path collides with existing file → asks for `--force` or skips with note.
- Missing conventions file → aborts (Slices 0 must land first).

## Related
- `cde-slice-contract-check` — run after scaffold to confirm all 7 dimensions are present.
- `vertical-slice-generator` — generic version (this is the CDE-specialized one).
