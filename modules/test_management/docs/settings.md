# Settings

## Enabling the module

**Actor:** Project admin (or any user who can manage project modules).

**Entry:** Project → Settings → Modules.

Check **Test management**. Then:

- The project menu shows **Test management → Cases**.
- Project settings gains a **Test management** page.
- Disabling the module hides menu and settings for that project; stored data is kept.

## Project settings

Path: Project → Settings → Test management.

Requires `manage_test_management`.

| Setting | Effect |
|---|---|
| Display prefix | Case ID prefix (for example `DEMO` → `DEMO-12`) |
| Folder tree layout | `split_pane` or `sidebar` |
| Enable CI | Stored for later; CI UI ships in a later stage |
| Enable milestones / test plans / test assistant | Stored for later releases |
| Enable requirements | Default **off**; Requirements ships in a later stage |

## Administration

Administration → Test management:

- Default display prefix (used when a project has none)
- Links to GitHub and GitLab integration settings
- Xray / TestRail import placeholders (**Planned**)
