# CI and automation

Upload Playwright JSON or JUnit XML reports into test runs. Optionally trigger a
GitHub Actions workflow from OpenProject ("Run in CI").

## Files

| File | Use |
|---|---|
| `github-actions-playwright.yml` | Example workflow: Playwright + upload |
| `op-tm-upload.sh` | Multipart upload helper (`report` + `metadata`) |

## Upload

```
POST /api/v3/projects/{project}/test_management/automation/results
```

Multipart: `report` (file) and optional `metadata` (JSON). JSON body: `content` / `report` / `tests`
plus options.

Useful options: `externalRef`, `mode` (`new_run` / `new_iteration`), `targetRun`, `name`,
`createMissing`, `closeRun`, `caseMatcher`, `runId`, `iterationId`.

Replaying the same digest on the same run returns the earlier import (`replay: true`).

## CI connections

Project settings → Test management → CI connections (GitHub only): repository, ingest mode, token,
workflow file, ref. With **Enable CI** off, "Run in CI" returns 403; uploads still work.

## Run in CI

Requires a connection with token + workflow. OpenProject dispatches
`workflow_dispatch` with `op_run_id`, `op_iteration_id`, `op_project`, `op_grep`.
