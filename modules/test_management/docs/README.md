# Test management

Cases live in folders. Runs collect results for a set of cases (specific selection or all matching
filters). Automation uploads fill runs from CI. GitHub connections can trigger workflows ("Run in CI").

| Guide | Contents |
|---|---|
| [Cases](cases.md) | Folders, cases, steps |
| [Runs](runs.md) | Selection, execution, iterations |
| [CI](ci/README.md) | Connections, ingest, Run in CI |
| [Settings](settings.md) | Project and admin settings |
| [API](api.md) | APIv3 overview |

## Navigation

**Cases · Runs · CI** — CI is shown when the project has CI enabled and the user can manage CI or
trigger automation.

## Permissions (project)

| Permission | Allows |
|---|---|
| View test cases | Browse folders and cases |
| Add / edit / delete test cases | Case library writes |
| Manage test suites | Folder CRUD |
| View / add / execute / delete test runs | Runs and results |
| Upload test results | Automation ingest |
| Manage test CI | CI connections in project settings |
| Trigger test automation | Run in CI |
| Manage test management | Project settings |
