# Test management

Native test management for OpenProject. This scaffold enables the module, Cases
navigation stub, and project/admin settings. Case library CRUD, labels, and the
work package Testing tab ship in later Cases children.

## Navigation (planned)

| Section | Status |
|---|---|
| Cases | Stub index (library in next PRs) |
| Runs | Planned |
| Plans | Planned (project toggle) |
| Milestones | Planned (project toggle) |
| Requirements | Planned (project toggle, default off) |
| CI | Planned (project toggle) |

## Guides

| Guide | Contents |
|---|---|
| [Settings](settings.md) | Enabling the module, project and admin settings |

## Permissions (project)

| Permission | Allows |
|---|---|
| View test cases | Open Cases and the module menu |
| Add / edit / delete test cases | Case library writes (wired with CRUD) |
| Manage test suites | Folder CRUD (wired with folders) |
| Manage test management | Project settings |
