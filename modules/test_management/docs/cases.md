# Test cases

Cases belong to a project and optionally to a folder (suite). Each case has title, description,
preconditions, priority, status, optional automation reference, and ordered steps.

## Folders

Folders form a tree. The index shows a folder tree and a case table for the current folder
(including subfolders). Unfiled cases use the special `root` filter.

## Cases

- IDs are global integers, shown as `{displayPrefix}-{id}` (project prefix, else instance default).
- Deleting a case is permanent; it is removed from all runs.
- Steps are replaced as a whole when saved through the API (`steps` on PATCH).

## Permissions

View / add / edit / delete test cases; manage test suites for folders.
