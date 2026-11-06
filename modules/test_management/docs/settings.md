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

Feature toggles (CI, milestones, plans, assistant, requirements) are added in the
stage that ships each feature.

## Administration

Administration → Test management: default display prefix (used when a project has
none). Integration links and import/export arrive in later stages.
