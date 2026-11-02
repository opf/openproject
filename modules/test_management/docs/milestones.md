# Milestones

[← User guide](README.md)

A milestone groups test runs (and optionally [test plans](plans.md)) towards a goal: a release, a
sprint, a regression cycle, UAT and so on. The menu entry is Test management → **Milestones**.
Milestones are optional — runs and plans work without them.

- **Fields**: name (required), description, start and due date, parent milestone, Version and
  references (linked work packages).
- **Sub-milestones**: one level only, e.g. sprints under a release. A parent's progress includes
  the runs of its sub-milestones.
- **Status**: `open` → **Start** → `started` → **Complete** → `completed` → **Reopen** → `started`.
  A milestone that was never started reopens as `open`. Dates are a plan only and never change
  the status. A milestone past its due date that is not completed is shown as **overdue**.
- **Progress**: the latest status of every case in every run assigned to the milestone or to one
  of its sub-milestones, with cancelled runs excluded. Pass rate = passed / (total − skipped),
  the same rule as on run pages.
- **Assigning runs**:
  - the Milestone field in the run form;
  - the Milestone selector in **Run in CI** (new runs only; a new iteration stays in its run's milestone);
  - the `milestone` option of CI uploads (id, `M12` or name). An unknown or completed
    milestone only adds a warning to the upload.

  Completed milestones are not offered. Runs that are already assigned stay assigned when the
  milestone is completed.
- **Deleting** a milestone keeps its runs (they become unassigned). Its sub-milestones become
  top-level milestones.
- **Exports**: CSV, XLS and PDF summaries, with the milestone info and totals, plus one row per run.
- **Permissions**: viewing needs **View test runs**. **Manage milestones**
  (`manage_test_milestones`) covers create, edit, start, complete, reopen and delete. Assigning a
  run needs **Manage test runs** (`add_test_runs`).
- **Switch**: Project settings → Test management → **Enable milestones** (on by default). When
  it is off, pages, selectors, the API and the work package section are hidden. The data is kept.
- **APIv3**:
  - `GET|POST /api/v3/projects/{id}/test_management/milestones` (filters `status`, `parentId`);
  - `GET|PATCH|DELETE /api/v3/test_management/milestones/{id}`;
  - `POST …/milestones/{id}/start|complete|reopen` (no body, but `Content-Type: application/json` as for every APIv3 POST; 409 when the status does not allow it);
  - runs have `_links.milestone` and a `milestoneId` filter;
  - `POST …/ci_triggers` accepts `milestone`.

## When to use milestones

| Scenario | Set-up |
|---|---|
| Release | A parent milestone per release, tied to the OpenProject Version. Its due date is the release date. Runs: regression, new features, smoke. |
| Sprint / iteration | A sub-milestone per sprint under the release, linked to the sprint's work packages or Version. |
| Regression cycle | A milestone per full regression pass, with one run per area or platform. |
| Smoke / sanity | A short milestone per build or deployment. CI uploads and Run in CI file automated runs into it. |
| Hotfix / patch | A small milestone with a tight due date, linked to the bugs it fixes. The overdue badge shows the risk. |
| UAT | A milestone for business testers. Completing it is the sign-off. |
| Beta / pilot / canary | A milestone per wave, with runs per pilot customer or environment. |
| Compliance / audit | Security, accessibility, privacy or certification test sets. The PDF/XLS export serves as evidence. |
| Performance / load | Load and soak runs before a launch. |
| Migration / upgrade | Data-migration verification runs, linked to the migration epic. |
| Platform certification | Sub-milestones per device or OS family under one certification milestone. |
| Launch readiness | A go-live gate: the pass rate with nothing left untested is the exit criterion. |
