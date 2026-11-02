# API

[← User guide](README.md)

The module adds APIv3 endpoints under the tag **Test Management** (OpenAPI files in
`docs/api/apiv3/paths/test_management_*.yml`). Authenticate like any APIv3 call, e.g. with an API
token from *My account → Access tokens* (`Authorization: Bearer <token>` or basic auth
`apikey:<token>`). Every POST needs `Content-Type: application/json` (multipart for uploads).
Permissions are the same as in the UI.

Test cases and folders have no API in this PoC.

## Test runs

| Method and path | Purpose |
|---|---|
| `GET /api/v3/projects/{id}/test_management/runs` | List runs (filters `state`, `source`, `name`, `externalRef`, `milestoneId`) |
| `GET /api/v3/test_management/runs/{id}` | A run with its counts and pass rate |
| `POST /api/v3/test_management/runs/{id}/complete` · `…/cancel` | Finish a run |
| `GET, POST /api/v3/test_management/runs/{id}/iterations` | List or start iterations |
| `GET /api/v3/test_management/runs/{id}/iterations/{number}` | One iteration |
| `GET /api/v3/test_management/run_cases/{id}` | A case in a run with its results (with `errorMessage`, `errorTrace`, `failedStep`, `stepResults`) |
| `POST /api/v3/test_management/run_cases/{id}/results` | Record a manual result: `status?`, `comment?`, `errorMessage?`, `stepResults: [{ testStepId, status, actualResult? }]` (201; 409 for a finished run; 422 for invalid steps) |
| `GET /api/v3/test_management/results/{id}` | One result with its error and step results |
| `GET, POST …/runs/{id}/attachments` · `…/run_cases/{id}/attachments` | Attachments |

## Automated results

| Method and path | Purpose |
|---|---|
| `POST /api/v3/projects/{id}/test_management/automation/results` | Upload a report (Playwright JSON, JUnit XML, native JSON, Allure results, Cucumber JSON or messages) with metadata and artifacts; `stepsAfterFailure` |
| `POST /api/v3/projects/{id}/test_management/runs/{run_id}/results` | Upload into a given run |
| `GET /api/v3/test_management/automation/imports/{id}` · `GET …/runs/{id}/imports` | Upload summaries, unmatched tests |

Step results (`_type` `TestManagementStepResult`: `kind`, `position`, `testStepId`, `status`,
`matchedBy`, `durationMs`, `errorMessage`, `errorTrace`, `actualResult`, `substeps`, `attachments`) are
plain text; clients must not render them as HTML. Step markers: [Test steps](ci/README.md#test-steps).

Matching, run selection (`runId`, `externalRef`, `mode: new_iteration` + `targetRun`) and the
upload script: [CI and automation](ci/README.md).

## CI connections and Run in CI

| Method and path | Purpose |
|---|---|
| `GET, POST /api/v3/projects/{id}/test_management/ci_connections` | List or create connections (**Manage test CI**) |
| `GET, PATCH, DELETE /api/v3/test_management/ci_connections/{id}` | Read, change or delete one. Tokens and CA certificates are write-only. |
| `POST /api/v3/projects/{id}/test_management/ci_triggers` | *Run in CI*: 201 triggered, 502 the provider refused, 422 invalid |

## Milestones

| Method and path | Purpose |
|---|---|
| `GET, POST /api/v3/projects/{id}/test_management/milestones` | List (filters `status`, `parentId`) or create |
| `GET, PATCH, DELETE /api/v3/test_management/milestones/{id}` | Read, change, delete |
| `POST /api/v3/test_management/milestones/{id}/start` · `…/complete` · `…/reopen` | Status changes (409 when not allowed) |

## Configurations

| Method and path | Purpose |
|---|---|
| `GET, POST /api/v3/projects/{id}/test_management/configuration_groups` | List or create groups (**Manage test management** to create) |
| `GET, PATCH, DELETE /api/v3/test_management/configuration_groups/{id}` | Read, rename or delete a group |

## Test plans

| Method and path | Purpose |
|---|---|
| `GET, POST /api/v3/projects/{id}/test_management/plans` | List (filters `state`, `milestoneId`) or create |
| `GET, PATCH, DELETE /api/v3/test_management/plans/{id}` | Read, change, delete |
| `POST …/plans/{id}/complete` · `…/reopen` · `…/rerun` | Lifecycle (rerun returns 201 with the new plan) |
| `POST …/plans/{id}/entries` | Add an entry (spawns runs; body: `name`, `selectionMode`, `caseIds?`, `configurationIds?`, `filterOptions?`) |
| `PATCH, DELETE …/plans/{id}/entries/{entryId}` | Update or delete an entry |

Run resources may include optional `planId`, `configurationIds` and `configurationLabel`.

### Automation ingest modes (summary)

| Goal | Options |
|---|---|
| Create + fill (+ optional close) | omit `runId`; optional `externalRef`, `milestone`, `closeRun` |
| Partial update of an existing run | `runId` (matched cases only; manual untouched) |
| New iteration | `mode: new_iteration` + `targetRun` or `runId` |

## Test Assistant

| Method and path | Purpose |
|---|---|
| `POST /api/v3/projects/{id}/test_management/assistant/generations` | Queue a generation (202) |
| `GET /api/v3/test_management/assistant/generations/{id}` | Poll it until `status` is `done` or `failed` (own generations only; `usage` when done) |
| `POST /api/v3/test_management/assistant/generations/{id}/save` | Save drafts as cases (201; 409 while not done) |

The chat has no API.
