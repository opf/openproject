# Jira to OpenProject Field Mapping Reference

## Project-level fields

| Jira field               | Becomes in OpenProject          | What you should know                                         |
| ------------------------ | ------------------------------- | ------------------------------------------------------------ |
| Old/renamed project keys | Also work as project identifier | If a Jira project was renamed, the old key still resolves to the same project afterward |
| Project description      | Project description             | Copied as-is                                                 |
| Project key              | Project identifier              | You must enable **project-based semantic identifiers** in OpenProject before importing |
| Project name             | Project name                    | Copied as-is                                                 |

Every migrated project is created **private** and **active**, with no parent — this isn't based on anything in Jira, it's just how the tool creates them.

## Issue → Work package fields

| Jira field                                         | Becomes in OpenProject    | What you should know                                         |
| -------------------------------------------------- | ------------------------- | ------------------------------------------------------------ |
| Affects Versions                                   | **Not migrated**          | —                                                            |
| Assignee                                           | Assignee                  | —                                                            |
| Attachments                                        | Attachments               | Re-uploaded to the work package, original author preserved where possible |
| Change history (status changes, field edits, etc.) | Activity entries          | Preserved, but grouped more coarsely than Jira's own history — see the [Post-Migration Checklist](https://www.openproject.org/docs/installation-and-operations/jira-migration/post-migration-checklist/) |
| Comments                                           | Activity/notes            | Author and date preserved; text converted from Jira markup   |
| Components                                         | **Not migrated**          | — (planned: [JIM-107](https://community.openproject.org/projects/JIM/work_packages/JIM-107)) |
| Creator                                            | Author                    | —                                                            |
| Description                                        | Description               | Converted from Jira's markup to OpenProject's — headings, bold/italic, links, code/quote blocks, and tables all convert. Some elements don't: `{info}`/`{warning}`/`{note}`/`{tip}` boxes, `{toc}`, and `{expand}`/`{section}`/`{column}` layouts aren't recognized at all — their content is kept, but the raw `{macro}` tag text is left behind, visible and unconverted, rather than being cleanly stripped or styled. Bare issue-key links like `[PROJECT-123]` and attachment links like `[^file.pdf]` are also left as literal, non-clickable text. See the [Pre-Migration Checklist](https://www.openproject.org/docs/installation-and-operations/jira-migration/pre-migration-checklist/) and [Post-Migration Checklist](https://www.openproject.org/docs/installation-and-operations/jira-migration/post-migration-checklist/) |
| Due date                                           | Due date                  | Copied as-is                                                 |
| Environment                                        | **Not migrated**          | —                                                            |
| Fix Versions                                       | **Not migrated**          | — (planned: [JIM-154](https://community.openproject.org/projects/JIM/work_packages/JIM-154)) |
| Issue creation date                                | Work package created date | Matches when the issue was originally created in Jira, not when the migration ran |
| Issue id                                           | **Not migrated**          | Internal Jira ID (planned: [JIM-8](https://community.openproject.org/projects/JIM/work_packages/JIM-8)) |
| Issue key (e.g. `PROJECT-123`)                     | Work package identifier   | Old/renamed issue keys also keep working afterward, the same way as project keys |
| Issue links (blocks/relates to/etc.)               | **Not migrated**          | — (planned: [JIM-76](https://community.openproject.org/projects/JIM/work_packages/JIM-76)) |
| Issue type                                         | Type                      | Matched by name (not case-sensitive); a new Type is created automatically if nothing matches, and it's attached to the right projects (mirroring Jira's per-project Issue Type Scheme). Only the name and description come across — no migrated type is marked as the project's default, even if it was the default in Jira, and there's no equivalent to Jira's dedicated "Sub-task" type behavior |
| Logged work / time entries                         | **Not migrated**          | Only the two estimate fields above come across, not actual logged time (planned: [JIM-93](https://community.openproject.org/projects/JIM/work_packages/JIM-93)) |
| Original time estimate                             | Estimated hours           | ⚠️ **values come out 60× too high.** Jira's seconds value is divided by 60 (giving minutes) instead of 3600 (giving hours) — e.g. entering `1d` (8 hours) in Jira results in `480` in OpenProject's Estimated hours field. Divide the migrated value by 60 to get the real number. Tracked as [JIM-185](https://community.openproject.org/projects/JIM/work_packages/JIM-185) |
| Priority                                           | Priority                  | Matched by name (not case-sensitive); created automatically if missing. If an issue has no priority in Jira, OpenProject's default priority is used. Only the name comes across — Jira's severity order, colors, and icons aren't preserved, and this matters beyond appearance: OpenProject falls back to whichever priority ends up first in the list when an issue has none set |
| Remaining time estimate                            | Remaining hours           | ⚠️ Same 60× inflation as Estimated hours above. Tracked as [JIM-185](https://community.openproject.org/projects/JIM/work_packages/JIM-185) |
| Reporter                                           | **Not migrated**          | Jira's "Reporter" concept doesn't exist in OpenProject and is dropped; only Creator becomes Author |
| Resolution                                         | **Not migrated**          | Jira tracks *why* an issue was closed (Fixed, Won't Fix, Duplicate, Cannot Reproduce) separately from its workflow state (Status). Only Status comes across — the reason is dropped entirely, and several different Jira resolutions can end up mapped to the same single OpenProject status with no trace of which one applied (planned as a custom field: [JIM-149](https://community.openproject.org/projects/JIM/work_packages/JIM-149); broader native support tracked as [FND-231](https://community.openproject.org/projects/FND/work_packages/FND-231)) |
| Resolution date                                    | **Not migrated**          | —                                                            |
| Security Level                                     | **Not migrated**          | —                                                            |
| Status                                             | Status                    | Matched by name (not case-sensitive); created automatically if missing. Only the name comes across — a migrated status is never automatically marked as "closed" in OpenProject, even if it represented a finished state in Jira (e.g. Done, Closed, Resolved). This affects any filtering or reporting that depends on knowing which work packages are actually finished |
| Sub-tasks / parent-child links                     | **Not migrated**          | — (planned: [JIM-75](https://community.openproject.org/projects/JIM/work_packages/JIM-75)) |
| Summary                                            | Subject                   | Copied as-is                                                 |
| Votes                                              | **Not migrated**          | —                                                            |
| Watchers                                           | **Not migrated**          | — (planned: [JIM-180](https://community.openproject.org/projects/JIM/work_packages/JIM-180)) |


## Users & groups

| Jira field            | Becomes in OpenProject       | What you should know                                         |
| --------------------- | ---------------------------- | ------------------------------------------------------------ |
| Active flag           | Account status               | Created locked; unlocked automatically only after you Approve the import, and only for users who were active in Jira |
| Display name          | First / last name            | Split automatically; single-word names get used for both     |
| Email                 | Email                        | If a Jira user has no email, a placeholder one is generated so the account can still be created. Not always a direct 1:1 copy of the Jira value — see the email/login collision handling below |
| Jira group membership | OpenProject Group membership | Matched or created by name. Note: pulls in the user's entire Jira group list, not just groups relevant to the migrated projects
| Username              | Login                        | Not always a direct 1:1 copy either — same collision handling as Email, below |
| Password              | Randomly generated           |  Jira passwords can't be migrated, so every new user needs a password reset or invitation afterward |

## Custom fields

For field type mapping, supported/unsupported types, and edge cases (checkboxes, cascading selects, Labels, Field Contexts, deduplication behavior — including how both interact with separate import runs/batches), see the official [Custom fields migration](https://www.openproject.org/docs/installation-and-operations/jira-migration/custom-fields/) documentation.


------

## Behavior worth knowing about

- **Status/Type/Priority matching ignores case, not spelling.** `"To Do"` and `"TO DO"` will correctly match to the same status. But `"To-Do"` vs `"To Do"`, or `"Doing"` vs `"In Progress"`, will each create their own separate status/type/priority. Standardize naming across Jira projects beforehand if you want them to merge.
- **Change history is grouped, not copied 1:1.** Multiple edits by the same person within the same minute are merged into a single activity entry (unless two of them both touch the description) — so OpenProject's activity tab will look chunkier than Jira's raw history, and won't always render field-change details in OpenProject's usual format. There's also a more serious confirmed bug beyond just grouping: comment timestamps occurring right after a Jira transition-with-comment can come out corrupted, showing the migration date instead of the real one. Tracked as [JIM-152](https://community.openproject.org/projects/JIM/work_packages/JIM-152).
- **Inline images stay pointed at the original Jira server.** Images embedded in descriptions/comments are not re-hosted in OpenProject — they'll break once the Jira instance is decommissioned, unless re-uploaded manually. Tracked as [JIM-53](https://community.openproject.org/projects/JIM/work_packages/JIM-53).
- **The importer has no concept of LDAP.** Every new user is created as a plain local account with a random password — it's never linked to an LDAP source, even if your OpenProject uses LDAP login. If a Jira username matches a real LDAP login, that person's real LDAP password will stop working after migration, because the newly created local account "claims" the login first. This needs a manual fix per affected account — see the [Pre-Migration Checklist](https://www.openproject.org/docs/installation-and-operations/jira-migration/pre-migration-checklist/) and [Post-Migration Checklist](https://www.openproject.org/docs/installation-and-operations/jira-migration/post-migration-checklist/).
- **Attachments are the one exception to "everything fails loudly."** Everywhere else, a problem during import raises an error and aborts the whole run. Attachments don't work that way: a failed download or a rejected upload is silently logged and skipped, and the import carries on and can complete successfully with some attachments simply missing. There's no summary or warning shown anywhere in the review/approval screen — see the [Post-Migration Checklist](https://www.openproject.org/docs/installation-and-operations/jira-migration/post-migration-checklist/) for how to check for this.
- **Re-running an import is safe for users** — previously-imported users aren't duplicated on a retry. The user account itself isn't recreated, but their group membership is re-synced each time.
- **Email/login collisions are resolved, not rejected.** If a Jira user's email or login already exists in OpenProject, the importer doesn't fail outright. It reuses the existing account if that account isn't already linked to a different Jira user within the same import run; otherwise, it disambiguates by appending the Jira user key to the email/login (e.g. `name+JIRAKEY@domain.com`) so both accounts can coexist.
- **User activation on Approve is conditional, not automatic.** Every imported user is created `locked`, regardless of their status in Jira. Approving the import only unlocks users who were both (a) newly created by this specific run — not reused from an existing OpenProject account — and (b) marked `active` in Jira. Reused/matched accounts are left exactly as they were.
- **@mentions are resolved via a live API lookup, not just from already-known users.** For each distinct `[~username]` mention found in a description or comment, the importer calls Jira's user endpoint directly — even if that person isn't otherwise referenced anywhere else in the imported data (e.g. never an assignee, author, or watcher). If resolved and imported, the mention renders as a genuine OpenProject `<mention>` tag (clickable, triggers a notification); if not resolvable, it falls back to flat `@username` text.
- **Name splitting is naive.** `firstname`/`lastname` are derived by splitting Jira's `displayName` on the *last* whitespace character — not real name-parsing logic. A single-word display name gets duplicated into both fields. Characters not valid in an OpenProject name are stripped beforehand.
- **Work package sequence counters are backfilled per project after import**, set to the highest sequence number found among the imported work packages — purely so that new work packages created after migration don't collide with an imported identifier.
