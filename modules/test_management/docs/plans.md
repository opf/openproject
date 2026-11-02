# Test plans

[← User guide](README.md)

A **test plan** is an optional campaign that groups related test runs (and can spawn a configuration
matrix). Standalone runs, iterations, milestones and cases work without plans.

## When to use a plan

| Use a plan when… | Prefer standalone runs when… |
|---|---|
| You need the same case set across browsers/OS combos | One environment, one execution |
| You want complete/rerun of a whole campaign | A long-lived Smoke/Regression with [iterations](runs.md#iterations) |
| Several named entries share one release window | A single ad-hoc run |

## Fields

Name (required), description, optional milestone, assignee, start/end dates, work package
references. State: `active` → **Complete** → `completed` → **Reopen** → `active`.

Progress rolls up from non-cancelled owned runs (same pass-rate rule as runs/milestones).

## Entries

Each entry has a name, case selection (`all` / `specific` / `dynamic`) and optional
[configurations](configurations.md). Saving an entry creates **one run per configuration
combination**, or a single run if none are selected.

## Lifecycle

- **Complete** completes every still-active owned run, then marks the plan completed.
- **Reopen** reopens the plan only (runs stay finished until you reopen them).
- **Rerun** creates a **new** plan + new runs (copy selection/configs; optional status filter /
  copy assignees). Different from starting an [iteration](runs.md#iterations) on one run.
- **Delete** destroys the plan, its entries and owned runs (confirmed in the UI).

## Settings

Project settings → Test management → **Enable test plans** (on by default). When off, plan pages and
plan APIs are hidden; configurations and standalone runs stay available.

## APIv3

- `GET|POST /api/v3/projects/{id}/test_management/plans`
- `GET|PATCH|DELETE /api/v3/test_management/plans/{id}`
- `POST …/plans/{id}/complete|reopen|rerun`
- `POST|PATCH|DELETE …/plans/{id}/entries`

See [API](api.md).
