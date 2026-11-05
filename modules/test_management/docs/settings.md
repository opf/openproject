# Settings

## Project settings

Path: Project → Settings → Test management.

| Setting | Effect |
|---|---|
| Display prefix | Case ID prefix (e.g. `DEMO` → `DEMO-12`) |
| Folder tree layout | `split_pane` or `sidebar` |
| Enable CI | Shows CI page/section, allows tokens and Run in CI; off → triggers return 403. Ingest still works. |
| Enable milestones / test plans / test assistant | Stored for later releases; UI for those features is not in this cut. |

CI connections (GitHub only): name, repository, ingest mode (`new_run` / `new_iteration` + target run
name), token, workflow, ref.

## Administration

Administration → Test management: default display prefix and AI provider list (OpenAI-compatible /
Anthropic). Providers support test-connection before save.
