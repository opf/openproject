# Jira to OpenProject Post-Migration Checklist
Things to do by hand after an import, given the tool's current scope. If you're migrating in multiple batches, repeat the "Right after import" steps for each batch — they're not a one-time event.

## Right after import

- [ ] While still in **review mode**, spot-check a sample of imported work packages, attachments, and custom fields before approving — once approved, it can't be undone.
- [ ] **Specifically verify attachment migration errors.** Unlike everything else the migrator imports, a failed attachment (broken download, rejected upload) doesn't stop the import or show up anywhere in the review screen — it's silently skipped, with the only trace being a line in the server log: `Attachment creation failed for <filename>` or `Download attachment failed for <filename>`. Search for these before approving, and check the work packages they mention to confirm what's missing and whether it matters.
- [ ] Approve once satisfied, or revert and adjust if not.
- [ ] **Reset passwords / send invitations** for all newly-created users, since Jira passwords can't be migrated. There's an open feature request to automate this on approval: [JIM-116](https://community.openproject.org/projects/JIM/work_packages/JIM-116).
- [ ] **If you're on LDAP, check for and fix login collisions.** Compare imported logins against your LDAP directory; for any match, edit that user and assign the correct LDAP source manually — otherwise their real LDAP login will keep failing. There's no automatic way to fix this in bulk; it has to be done per affected account. Do this after every batch, since new users can be introduced in each one.

## Things you'll need to recreate manually

This is where you act on what you decided in the "confirm you can accept what doesn't migrate" review before you started. For anything you chose to keep rather than accept the loss of:

- [ ] **Workflows** (which status transitions are allowed for which roles) — only a basic, permissive setup is created automatically. Recreate the transitions you need under Administration → Work packages → Workflows. Planned: [JIM-153](https://community.openproject.org/projects/JIM/work_packages/JIM-153).
- [ ] **Permission schemes / roles**, beyond the one basic role the import creates — set these up under Administration → Roles and permissions. Planned: [JIM-97](https://community.openproject.org/projects/JIM/work_packages/JIM-97).
- [ ] **Agile boards** (Scrum/Kanban setup, filters, swimlanes) — recreate using OpenProject's Backlogs or Agile boards module. Planned: [JIM-106](https://community.openproject.org/projects/JIM/work_packages/JIM-106).
- [ ] **Issue relations and sub-task/parent hierarchies** — recreate manually via the work package relations panel, or script it against the API if you exported the structure beforehand. Planned: [JIM-76](https://community.openproject.org/projects/JIM/work_packages/JIM-76) (issue links), [JIM-75](https://community.openproject.org/projects/JIM/work_packages/JIM-75) (sub-tasks).
- [ ] **Sprint assignments, Epic Links, Story Points** — recreate from whatever you exported beforehand.
- [ ] **Logged time entries** — only estimates transfer, not actual time logged. Re-enter via OpenProject's time tracking, or bulk-import via the API using your exported worklog data. Planned: [JIM-93](https://community.openproject.org/projects/JIM/work_packages/JIM-93).
- [ ] **Watchers** on individual work packages — re-add manually from the list you exported beforehand. Planned: [JIM-180](https://community.openproject.org/projects/JIM/work_packages/JIM-180).
- [ ] Anything from **Confluence** — entirely out of scope for this tool; plan a separate migration for it if needed.

## Clean-up and verification

- [ ] Reorganize the new custom fields — they land in a generic group unattached to most projects by default.
- [ ] If you didn't standardize **Type** names in Jira beforehand (see [Pre-Migration checklist](../pre-migration-checklist/)), consolidate any that ended up duplicated because the Jira names genuinely differed (not just by casing). You need to reassign the affected work packages to the correct one and then delete the now-unused duplicate type. Fixing the naming in Jira before a future run avoids having to redo this by hand.
- [ ] If you didn't standardize **Status** names in Jira beforehand (see [Pre-Migration checklist](../pre-migration-checklist/)), consolidate any that ended up duplicated because the Jira names genuinely differed (not just by casing). You need to update the affected work packages to the correct ones and then delete the now-unused duplicate states. Fixing the naming in Jira before a future run avoids having to redo this by hand.
- [ ] If you didn't standardize **Priority** names in Jira beforehand (see [Pre-Migration checklist](../pre-migration-checklist/)), consolidate any that ended up duplicated because the Jira names genuinely differed (not just by casing). For each unwanted value, delete it and select the priority value to reassign the affected work packages to and then delete the now-unused duplicate priorities. Fixing the naming in Jira before a future run avoids having to redo this by hand.
- [ ] **Mark migrated statuses as closed where appropriate.** None of them are flagged as "closed" automatically, even ones that represented a finished state in Jira (Done, Closed, Resolved, etc.) — go through Administration → Work packages → Status and set this manually, or filtering/reporting on open vs. finished work will be wrong.
- [ ] **Reorder priorities and set default types per project**, if you noted this as something to fix in the [Pre-Migration checklist](../pre-migration-checklist/).
- [ ] **Fix estimated/remaining hours** — Due to an existing [bug]((https://community.openproject.org/projects/JIM/work_packages/JIM-185): Divide affected values by 60, either manually or via a bulk update/script.
- [ ] **Find and fix inline images** in descriptions/comments — they still point at the original Jira server and will break once Jira is decommissioned.
- [ ] Spot-check activity history on a few heavily-edited issues against Jira's original view, since near-simultaneous edits get merged into fewer entries, and comment timestamps after a transition-with-comment have been confirmed to sometimes show the migration date instead of the original one ([JIM-152](https://community.openproject.org/projects/JIM/work_packages/JIM-152)).
- [ ] Manually clean up formatting that didn't convert: find and remove the leftover raw `{info}`/`{warning}`/`{note}`/`{tip}`/`{toc}`/`{expand}`/`{section}`/`{column}` tag text sitting in descriptions and comments (the content itself is intact, just the tags are ugly and unconverted), and turn bare issue-key links (`[PROJECT-123]`) and attachment links (`[^file.pdf]`) back into working links manually.
- [ ] Update the external integrations, webhooks, or tools you identified in the [Pre-Migration checklist](../pre-migration-checklist/).
