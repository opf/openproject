# Test runs

A run holds selected cases and their results. States: `new`, `in_progress`, `completed`, `cancelled`.
Completed and cancelled runs freeze statuses; they can be reopened.

## Selection

- `specific` — fixed case list (`caseIds`).
- `all` — every project case, optionally limited by folder subtrees and automation filter
  (`filterOptions.suiteIds`, `filterOptions.automation`). New matching cases are auto-added while
  the run is active.

## Execution

Open a run case to record status and comment. History lists earlier results and iterations.

## Iterations

Manual "start iteration" resets case statuses to untested. Automation can open a new iteration with
`mode: new_iteration` and `targetRun`.

## CI

With CI enabled, a run can be triggered on GitHub ("Run in CI") when a connection has a token and
workflow. The CI page lists active connections and recent automation runs.
