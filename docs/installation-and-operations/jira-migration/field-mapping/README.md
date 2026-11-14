---
sidebar_navigation:
  title: Field Mapping Reference
description: Reference for how Jira fields are mapped to OpenProject fields during migration
keywords: Jira migration, field mapping
---

# Jira to OpenProject Field Mapping Reference

## Project-level fields

| Jira field               | Becomes in OpenProject          | What you should know                                         |
| ------------------------ | ------------------------------- | ------------------------------------------------------------ |
| Old/renamed project keys | Project identifier              | If a Jira project was renamed, the old key still resolves to the same project afterward |
| Project description      | Project description             | -                                                            |
| Project key              | Project identifier              | -                                                            |
| Project name             | Project name                    | -                                                            |

Every migrated project is created **private** and **active**, with no parent — this isn't based on anything in Jira, it's just how the tool creates them.

## Issue → Work package fields

| Jira field                                         | Becomes in OpenProject    | What you should know                                         |
| -------------------------------------------------- | ------------------------- | ------------------------------------------------------------ |
| Affects Versions                                   | Observed in Versions      | —                                                            |
| Assignee                                           | Assignee                  | —                                                            |
| Attachments                                        | Attachments               | Re-uploaded to the work package, original author preserved where possible |
| Change history (status changes, field edits, etc.) | Activity entries          | Preserved, but grouped more coarsely than Jira's own history — see the [Post-Migration checklist](../post-migration-checklist/) |
| Comments                                           | Activity/notes            | Author and date preserved; text converted from Jira markup   |
| Components                                         | **Not migrated**          | — (planned: [JIM-107](https://community.openproject.org/projects/JIM/work_packages/JIM-107)) |
| Creator                                            | Author                    | —                                                            |
| Description                                        | Description               | Converted from Jira's markup to OpenProject's — headings, bold/italic, links, code/quote blocks, and tables all convert. Some elements don't: `{info}`/`{warning}`/`{note}`/`{tip}` boxes, `{toc}`, and `{expand}`/`{section}`/`{column}` layouts aren't recognized at all — their content is kept, but the raw `{macro}` tag text is left behind, visible and unconverted, rather than being cleanly stripped or styled. Bare issue-key links like `[PROJECT-123]` and attachment links like `[^file.pdf]` are also left as literal, non-clickable text. See the [Pre-Migration checklist](../pre-migration-checklist/) and [Post-Migration checklist](../post-migration-checklist/) |
| Due date                                           | Due date                  | -                                                            |
| Environment                                        | **Not migrated**          | —                                                            |
| Fix Versions                                       | Target versions           | -                                                            |
| Issue creation date                                | Work package created date | -                                                            |
| Issue id                                           | **Not migrated**          | Internal Jira ID (planned: [JIM-8](https://community.openproject.org/projects/JIM/work_packages/JIM-8)) |
| Issue key (e.g. `PROJECT-123`)                     | Work package identifier   | Old/renamed issue keys also keep working afterward, the same way as project keys |
| Issue links (blocks, relates to, etc.)             | **Not migrated**          | — (planned: [JIM-76](https://community.openproject.org/projects/JIM/work_packages/JIM-76)) |
| Issue type                                         | Type                      | Matched by name (not case-sensitive); a new Type is created automatically if nothing matches, and it's attached to the right projects (mirroring Jira's per-project Issue Type Scheme). Only the name comes across. No migrated type is marked as the project's default, even if it was the default in Jira. |
| Labels                                             | Labels                    | Matched by name (not case-sensitive); created automatically if missing. |
| Logged work / time entries                         | Time entries              | Each worklog becomes a time entry of the same user on the work package, keeping its duration, comment and start date and time in the user's OpenProject time zone. No activity is set, and comments longer than 1,000 characters are shortened. Time entry comments in OpenProject are plain text, so Jira formatting in worklog comments, such as bold text, links or mentions, shows as Jira markup (for example `*bold*`). Worklogs restricted to a Jira role or group are migrated too and become visible to everyone allowed to see time entries in the project |
| Original time estimate                             | Work                      | -                                                            |
| Priority                                           | Priority                  | Matched by name (not case-sensitive); created automatically if missing. If an issue has no priority in Jira, OpenProject's default priority is used. Only the name comes across — Jira's severity order, colors, and icons aren't preserved, and this matters beyond appearance: OpenProject falls back to whichever priority ends up first in the list when an issue has none set |
| Remaining time estimate                            | Remaining work            | -                                                            |
| Reporter                                           | **Not migrated**          | Jira's "Reporter" concept doesn't exist in OpenProject and is dropped; only Creator becomes Author |
| Resolution                                         | (Appended to status)      | Jira tracks *why* an issue was closed (Fixed, Won't Fix, Duplicate, Cannot Reproduce) separately from its workflow state (Status). The "Resolution" concept does not exist in OpenProject. Each resolution value is mapped to a dedicated status, where the name is a combination of Status and Resolution (e.g. "Done - Fixed"). Can be turned off per import configuration, in which case only the status name is used. Broader native support is tracked as [FND-231](https://community.openproject.org/projects/FND/work_packages/FND-231). |
| Resolution date                                    | Resolution Date           | Imported as a *datetime* custom field, when any issue in the project has a resolution date set. It is displayed in the "Jira Import" section of each work package. Can be turned off per import configuration. |
| Security Level                                     | **Not migrated**          | —                                                            |
| Sprint                                             | Sprint                    | Only the sprint the issue is currently in. See [Sprints](#sprints) |
| Status                                             | Status                    | Matched by name (not case-sensitive); created automatically if missing. The status category is set based on Jira's status category: "new" → to-do, "indeterminate" → in progress, "done" → closed, "undefined" → no category. Note that this only happens the *first* time a status with that name is created. If the same status name already exists (e.g. reused across projects with inconsistent status categories), it is reused and the existing category value is kept. |
| Sub-tasks / parent-child links                     | **Not migrated**          | — (planned: [JIM-75](https://community.openproject.org/projects/JIM/work_packages/JIM-75)) |
| Summary                                            | Subject                   | -                                                            |
| Votes                                              | **Not migrated**          | Does not exist in OpenProject (workaround planned: [JIM-207](https://community.openproject.org/projects/JIM/work_packages/JIM-207)) |
| Watchers                                           | Watchers                  | Users who only watch an issue are imported as well. All users are added as watchers without receiving a notification. |
| Web link                                           | **Not migrated**          | Does not exist in OpenProject (workaround planned: [JIM-206](https://community.openproject.org/projects/JIM/work_packages/JIM-206)) |


## Sprints

Jira sprints become native OpenProject [sprints](../../../user-guide/backlogs-scrum/), not custom fields.

| Jira sprint     | Becomes in OpenProject | What you should know                                         |
| --------------- | ---------------------- | ------------------------------------------------------------ |
| Name            | Name                   | A sprint without a name is called `Sprint <Jira sprint id>`  |
| State: future   | Status: in planning    | -                                                            |
| State: active   | Status: active         | An active sprint without a start or end date is imported as in planning, since an active sprint in OpenProject needs both |
| State: closed   | Status: completed      | -                                                            |
| Start date      | Start date             | -                                                            |
| End date        | Finish date            | An end date before the start date is set to the start date   |
| Activated date  | Started at             | -                                                            |
| Complete date   | Completed at           | -                                                            |
| Goal            | Sprint goal            | Stored as the goal of the owning project. Goals longer than 500 characters are shortened |
| Board           | **Not migrated**       | See [Agile data that is not migrated](#agile-data-that-is-currently-not-migrated) |

### Requirements in Jira

- **Jira Software with a valid license.** Sprints are only available through the Jira Software (Agile) API. On Jira without Jira Software, or with an expired Jira Software license, the import still completes, but without any sprints. The only trace is a warning in the server log: `Jira Agile API unavailable, no sprints are imported`.
- **The token user must be able to see the boards.** A Jira administrator cannot see every board automatically: a board is visible to a user only if its saved filter is shared with them. The migrator finds sprints through the boards the token user can see. It also fetches sprints by id when an imported issue names one, but Jira refuses that too when the token user cannot see the board the sprint was created on. Such sprints are skipped with a `Skipping sprint` warning in the server log, and their issues are imported without a sprint. Before migrating, make sure the token user can open every Scrum board of the projects you import.
- **The Sprint field must be on the issues.** Sprints and assignments are read from the Sprint field of the imported issues. If the field is hidden in a project's field configuration, that project gets no sprints.

### Which sprints are imported

- A sprint is imported when at least one imported issue is in it, or was in it. Sprints without any imported issue, for example empty future sprints, are not imported.
- Each work package gets the sprint its issue is currently in: the open (future or active) sprint if there is one, otherwise the sprint that was completed last. Earlier sprints of an issue remain visible in the imported change history only.
- Kanban boards have no sprints, so they add nothing.

### Sprints that span several projects

A Jira board can show issues of several projects, so a sprint can contain issues of several imported projects. In OpenProject, every sprint belongs to exactly one project:

- The sprint belongs to the project with the most issues in it. On a tie, it belongs to the project whose Jira key comes first alphabetically.
- Work packages of the other projects keep their sprint, and the sprint appears in those projects because their work packages are in it. Sprint sharing is not set up by the import.
- If these projects are imported in separate runs, the first run creates the sprint and later runs reuse it: their work packages are assigned to the existing sprint, which keeps its project, name, dates and goal. Reuse works as long as the sprint still exists in OpenProject and the Jira connection uses the same URL.
- If the last work package of such a project is removed from the sprint, the sprint is no longer available in that project. Set up [sprint sharing](../../../user-guide/projects/project-settings/backlogs-settings/#sharing-sprints) (Enterprise add-on) if these projects should keep planning in shared sprints.

### Several active sprints in one project

Jira allows one active sprint per board, so a project covered by several boards can have several active sprints. OpenProject allows this only when [multiple active sprints](../../../user-guide/projects/project-settings/backlogs-settings/#multiple-active-sprints) is enabled for the project. The import enables it on every project that ends up with more than one active sprint, also on the Community edition, and logs a warning. Enabling the setting again later requires the Enterprise add-on. While it is enabled, the project's sprint sharing cannot be changed, and it can only be disabled once at most one sprint of the project is active.

### Project setup and permissions

- The **Backlogs** module is enabled in every project that owns or shows an imported sprint.
- The `JiraMember` role created by the import can view sprints, backlogs and boards. It cannot move work packages between sprints, because that also requires permission to edit work packages. Grant those permissions to the role, or use another role, where members should plan sprints.
- If a `JiraMember` role already exists from an earlier import, it is reused unchanged and does not get the sprint permissions. Add **View sprints** and **View boards** to it manually.
- Reverting the import deletes the sprints it created together with the imported projects. A sprint reused from an earlier import stays, only the work packages of the reverted projects leave it. If a later import still uses a sprint of the reverted import, the sprint moves to the project with most of its remaining work packages instead of being deleted.

### Agile data that is currently not migrated

The migrator imports sprints and the current sprint of each issue. Everything else around Jira Software boards and planning is not migrated for now:

- **Boards**: Scrum and Kanban boards with their filters, columns, column constraints (WIP limits), swimlanes, quick filters, card layout and estimation settings. Recreate them with OpenProject's [Backlogs](../../../user-guide/backlogs-scrum/) or [Agile boards](../../../user-guide/agile-boards/) (planned: [JIM-106](https://community.openproject.org/projects/JIM/work_packages/JIM-106)).
- **Backlog order**: the Jira rank of issues is not migrated, so backlogs and sprints in OpenProject do not show Jira's order.
- **Sprint history**: only the current sprint of an issue is assigned. Earlier sprints, and work moved between sprints, are visible in the imported change history only.
- **Sprints without imported issues**, for example empty future sprints.
- **Time of day of sprint dates**: the planned start and end become dates without a time. When the sprint was actually started and completed is kept with the time.
- **Reports**: sprint reports, burndown, burnup, velocity and control charts, cumulative flow diagrams.
- **Epics**: Epic Link, Epic Name, Epic Status and Epic Color. Epic issues themselves are imported as work packages of the type "Epic", but their issues are not linked to them.
- **Story points**: the Jira "Story Points" field is a number field and is imported as a custom field of the same name, not into OpenProject's own story points attribute. Backlogs and burndown charts therefore show no story points.
- **Advanced Roadmaps data**: Parent Link, Target start, Target end, Original story points, plans, teams and releases of plans.

## Users & groups

| Jira field            | Becomes in OpenProject       | What you should know                                         |
| --------------------- | ---------------------------- | ------------------------------------------------------------ |
| Active flag           | Account status               | Created locked; unlocked automatically only after you Approve the import, and only for users who were active in Jira |
| Display name          | First / last name            | Split automatically; single-word names get used for both     |
| Email                 | Email                        | If a Jira user has no email, a placeholder one is generated so the account can still be created. Not always a direct 1:1 copy of the Jira value — see the email/username collision handling below |
| Jira group membership | OpenProject Group membership | Matched or created by name. Note: pulls in the user's entire Jira group list, not just groups relevant to the migrated projects |
| Username              | Username                     | Not always a direct 1:1 copy either — see the email/username collision handling below |
| Password              | Randomly generated           | Jira passwords can't be migrated, so every new user needs a password reset or invitation afterward (planned: [JIM-116](https://community.openproject.org/projects/JIM/work_packages/JIM-116)) |
| Time zone             | Time zone                    | Taken from Jira when OpenProject offers the same zone, otherwise OpenProject's default is used. Existing accounts that are reused keep their own |

## Custom fields

For field type mapping, supported/unsupported types, and edge cases, see the [Custom fields migration](../custom-fields/) documentation.


------

## Behavior worth knowing about

- **Status/Type/Priority matching ignores case, not spelling.** `"To Do"` and `"TO DO"` will correctly match to the same status. But `"To-Do"` vs `"To Do"`, or `"Doing"` vs `"In Progress"`, will each create their own separate status/type/priority. Standardize naming across Jira projects beforehand if you want them to merge.
- **Change history is grouped, not copied 1:1.** Multiple edits by the same person within the same minute are merged into a single activity entry (unless two of them both touch the description) — so OpenProject's activity tab will look chunkier than Jira's raw history, and won't always render field-change details in OpenProject's usual format. There's also a more serious confirmed bug beyond just grouping: comment timestamps occurring right after a Jira transition-with-comment can come out corrupted, showing the migration date instead of the real one. Tracked as [JIM-152](https://community.openproject.org/projects/JIM/work_packages/JIM-152).
- **Inline images stay pointed at the original Jira server.** Images embedded in descriptions/comments are not re-hosted in OpenProject — they'll break once the Jira instance is decommissioned, unless re-uploaded manually. Tracked as [JIM-53](https://community.openproject.org/projects/JIM/work_packages/JIM-53).
- **The importer has no concept of LDAP.** Every new user is created as a plain local account with a random password — it's never linked to an LDAP source, even if your OpenProject uses LDAP login. If a Jira username matches a real LDAP login, that person's real LDAP password will stop working after migration, because the newly created local account "claims" the login first. This needs a manual fix per affected account — see the [Pre-Migration checklist](../pre-migration-checklist/) and [Post-Migration checklist](../post-migration-checklist/).
- **Attachments are the one exception to "everything fails loudly."** Everywhere else, a problem during import raises an error and aborts the whole run. Attachments don't work that way: a failed download or a rejected upload is silently logged and skipped, and the import carries on and can complete successfully with some attachments simply missing. There's no summary or warning shown anywhere in the review/approval screen — see the [Post-Migration checklist](../post-migration-checklist/) for how to check for this.
- **Re-running an import is safe for users** — previously imported users aren't duplicated on a retry. The user account itself isn't recreated, but their group membership is re-synced each time.
- **Email/username collisions are resolved, not rejected.** If a Jira user's email already exists in OpenProject, the importer doesn't fail outright. It reuses the existing account if that account isn't already linked to a different Jira user within the same import run; otherwise, it disambiguates by appending the Jira user key to the email (e.g. `email+JIRAKEY@domain.com`) so both accounts can coexist. If a Jira user’s username already exists in OpenProject, the importer disambiguates it by appending the Jira user key to the username (e.g. `name+JIRAKEY`).
- **User activation on Approve is conditional, not automatic.** Every imported user is created `locked`, regardless of their status in Jira. Approving the import only unlocks users who were both (a) newly created by this specific run — not reused from an existing OpenProject account — and (b) marked `active` in Jira. Reused/matched accounts are left exactly as they were.
- **@mentions are resolved via a live API lookup, not just from already-known users.** For each distinct `[~username]` mention found in a description or comment, the importer calls Jira's user endpoint directly — even if that person isn't otherwise referenced anywhere else in the imported data (e.g. never an assignee, author, or watcher). If resolved and imported, the mention renders as a genuine OpenProject `<mention>` tag (clickable, triggers a notification); if not resolvable, it falls back to flat `@username` text.
- **Name splitting is naive.** `firstname`/`lastname` are derived by splitting Jira's `displayName` on the *last* whitespace character — not real name-parsing logic. A single-word display name gets duplicated into both fields. Characters not valid in an OpenProject name are stripped beforehand.
- **Work package sequence counters are backfilled per project after import**, set to the highest sequence number found among the imported work packages — purely so that new work packages created after migration don't collide with an imported identifier.
