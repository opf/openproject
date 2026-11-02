# Test runs

[← User guide](README.md)

Test management → **Runs** lists the project's runs with the filters **Active**, **Completed**,
**Cancelled** and **All**. A run executes a set of test cases and records one result per case.

## Creating a run

**New run** (or <kbd>n</kbd> <kbd>t</kbd> <kbd>r</kbd>), needs **Manage test runs**:

- Name, description, assignee (the initial assignee of every case in the run), start and end date,
  references (work packages the run relates to, e.g. a release or a feature) and milestone.
- **Test cases**:

| Mode | Cases | New cases |
|---|---|---|
| Include all test cases | Every case of the project | Added automatically while the run is active |
| Select specific test cases | The cases you tick (ticking a folder includes its subfolders) | Not added |
| Dynamic filtering | Cases matching labels (any of), automation (any / automated / manual) and optional folders | New or changed matching cases are added while the run is active |

## Executing a run

- Each case in the run has a **status**: `untested`, `passed`, `failed`, `blocked`, `retest`,
  `in progress`, `skipped`. Setting statuses needs **Execute test runs** (or Manage test runs).
- Files (screenshots, logs) can be attached to a run case or to the run. CI uploads attach their
  artifacts automatically.
- The run page shows the statistics (status breakdown, chart, pass rate), the schedule, the
  references and the description.
- **Pass rate** = passed / (total − skipped). Skipped cases are counted separately.

### Run states

`new` → (first result) → `in progress` → **Complete** → `completed`, or **Cancel** → `cancelled`.
**Reopen** returns a finished run to `in progress`. Completing or cancelling freezes the statuses
and writes the final result into each case's history.

## Step results and errors

Click **Details** on a case in a run to open the run case view. It shows the case steps with the
expected result and, for the latest result, a **step result** per step: status (*Passed*, *Failed*,
*Blocked*, *Skipped*, *Not run*), duration, how it was matched (marker, position, title or manual),
the step's error, sub-steps and attachments. Steps of an automated test that matched no case step
are listed below as **reported steps**.

- **Error**: a failed result shows its error message; the stack trace is in a collapsed *Stack
  trace* section. The run page, the result history, the work package *Testing* tab and the exports
  show "Failed at step N: <first line of the error>".
- **Manual execution**: with *Execute test runs* the view has a form with a status and an **actual
  result** per step, an optional error message and a comment. Leave the status at *From the step
  results* to derive it: any failed step → failed, else blocked → blocked, all passed → passed,
  otherwise in progress.
- **Automated results**: the step markers and matching rules are in
  [CI and automation → Test steps](ci/README.md#test-steps). After the failed step the remaining case
  steps are *Not run* (or *Blocked* with `stepsAfterFailure: blocked`). A failure outside any step
  (e.g. in a hook) fails no step: the steps keep their reported status and the error is shown on the result.
- All texts are shown as plain text; HTML in error messages is never rendered.
- Exports (CSV, XLS, PDF) have the columns *Failed step* and *Error* (first 1,000 characters); the
  PDF lists the failures with their error below the table.

## Iterations

A run can be executed many times; each execution is an **iteration**.

- **Start new iteration** on the run page (or the API, or a CI upload with `new_iteration`) resets
  every case to *Untested*. Results of earlier iterations are kept.
- The iteration history shows each iteration's source (manual or CI), start, counts and pass rate.
  A switcher opens an older iteration read-only.
- Typical use: one long-lived *Smoke* or *Regression* run that gets a new iteration per build.

## Automated runs

Runs created or filled by CI show the CI connection, repository, branch, commit, CI run link,
the uploads (format, parsed / matched / created / unmatched tests) and the **unmatched tests**
with a reason. **Run in CI** on a run, a folder or an automated case starts the CI job from
OpenProject. See [CI and automation](ci/README.md).

## Configurations, plans and milestones

- Optional [configurations](configurations.md) can tag a standalone run (at most one value per
  group). If none are defined in the project, the run form shows a hint linking to Project
  settings → Test management.
- A run may belong to an optional [test plan](plans.md) (spawned from a plan entry) or stay
  standalone. Plan **rerun** creates new runs; use **iterations** to re-execute the same run id.
- A run can be assigned to a [milestone](milestones.md) in its form or in *Run in CI*.

## Mixed manual and automated cases

A large run may contain both automated cases (with automation references) and manual cases.

1. Create the run from the UI (or let CI create it).
2. Target that run with `OP_RUN_ID` / the API / **Run in CI**.
3. After the upload, **only matched automated cases** get new statuses. Manual cases and unmatched
   rows are left unchanged.
4. Completing the OpenProject run stays explicit (`Complete`, API complete, or `OP_CLOSE_RUN`) —
   CI finishing does not force-complete the run unless you ask for it.

Do **not** use `OP_MODE=new_iteration` when you only want a partial update: a new iteration resets
every case in the run to *untested*.

## Milestones and exports

- A run can be assigned to a [milestone](milestones.md) in its form or in *Run in CI*.
- **Export** a run as CSV, XLS or PDF.
