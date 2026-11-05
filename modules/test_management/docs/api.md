# Test management API

Full OpenAPI: APIv3 docs tag **Test Management**. Summaries:

## Settings, folders, cases

| Method | Path |
|---|---|
| GET, PATCH | `/api/v3/projects/{id}/test_management/settings` |
| GET, POST | `/api/v3/projects/{id}/test_management/folders` |
| GET, PATCH, DELETE | `/api/v3/test_management/folders/{id}` |
| GET, POST | `/api/v3/projects/{id}/test_management/cases` |
| GET, PATCH, DELETE | `/api/v3/test_management/cases/{id}` (`lockVersion` required on PATCH) |

## Runs and results

| Method | Path |
|---|---|
| GET, POST | `/api/v3/projects/{id}/test_management/runs` |
| GET, PATCH, DELETE | `/api/v3/test_management/runs/{id}` |
| POST | `…/complete`, `…/cancel`, `…/reopen` |
| GET, POST | `…/iterations`; GET `…/iterations/{number}` |
| GET | `/api/v3/test_management/run_cases/{id}` |
| POST | `/api/v3/test_management/run_cases/{id}/results` (`status`, `comment`) |
| GET | `/api/v3/test_management/results/{id}` |

## Automation and CI

| Method | Path |
|---|---|
| POST | `/api/v3/projects/{id}/test_management/automation/results` (multipart `report` or JSON) |
| POST | `/api/v3/projects/{id}/test_management/runs/{run_id}/results` |
| GET | `/api/v3/test_management/automation/imports/{id}` |
| GET, POST | `/api/v3/projects/{id}/test_management/ci_connections` |
| GET, PATCH, DELETE | `/api/v3/test_management/ci_connections/{id}` |
| POST | `/api/v3/projects/{id}/test_management/ci_triggers` |

## Assistant providers (admin)

| Method | Path |
|---|---|
| GET, POST | `/api/v3/test_management/assistant/providers` |
| GET, PATCH, DELETE | `/api/v3/test_management/assistant/providers/{id}` |
| POST | `…/default`, `…/test_connection` |
