---
sidebar_navigation:
  title: Pre-Migration Checklist
description: Checklist of tasks to complete before migrating from Jira to OpenProject
keywords: Jira migration, pre-migration checklist
---

# Jira to OpenProject Pre-Migration Checklist

Actions to take in Jira, in OpenProject and in your migration planning before you start an import run, to reduce the number of surprises and manual clean-up steps afterward.

## Jira/instance-side prerequisites

- [ ] Confirm your Jira instance is Data Center 10.x / 11.x. Server is officially not supported, but depending on your configuration is still likely to work. Cloud is not supported at all at the moment — plan a different route if you're on Cloud.
- [ ] If your organization logs into OpenProject via LDAP, check whether Jira usernames match your LDAP login names. If they do, flag this to your team now — those users' real LDAP passwords will stop working right after migration until an admin fixes each affected account (see [Post-Migration checklist](../post-migration-checklist/)). Not relevant if you only use local/password accounts.
- [ ] Sync your external user directories (LDAP/AD) in Jira before migrating (Administration → User Management → User Directories → Sync). The migrator reads user data (email, display name) directly from Jira at the time of migration — if the sync is stale, that stale data gets carried over.
- [ ] Run Jira's built-in **Database Integrity Checker** (Administration → System → Integrity Checker) and/or the **Integrity Check for Jira** Marketplace app before migrating. These catch broken/orphaned data (e.g. required fields with no value, dangling references) that could otherwise cause unexpected errors partway through the import.
- [ ] For large migrations, check your Jira instance's capacity for the migration window: heap size, database connection pool, and free disk space. The migrator makes a large number of API calls (per-issue fetches, per-project/issue-type metadata lookups for custom fields), which can strain an under-resourced instance the same way any bulk API consumer would.
- [ ] For large or attachment-heavy migrations, test your network bandwidth beforehand to get a realistic sense of how long the import will take.
- [ ] Back up your Jira instance as well, not just OpenProject — several items in this checklist ask you to make changes in Jira (archiving issues, renaming fields, cleaning up duplicate accounts) before migrating.
- [ ] Identify any external integrations, webhooks, or tools that reference Jira's raw issue/project/comment IDs directly (e.g. custom scripts, reporting tools). These numeric IDs don't carry over to OpenProject — Jira issue *keys* (e.g. `PROJECT-123`) keep working via OpenProject's semantic aliasing, but anything relying on the underlying numeric ID will need to be reconfigured after migration. Make a list now so you know exactly what to go fix afterward, rather than finding out when something breaks.

## Confirm you can accept what doesn't yet migrate

Review this against how your teams actually use Jira. If anything here would be a blocker, get in touch with us before migrating.

**Not migrated at all, for any issue:**

- [ ] Reporter (Jira's Reporter and Creator become the same thing in OpenProject: only Creator/Author survives)
- [ ] Watchers (planned: [JIM-180](https://community.openproject.org/projects/JIM/work_packages/JIM-180))
- [ ] Sub-tasks and parent/child hierarchy (planned: [JIM-75](https://community.openproject.org/projects/JIM/work_packages/JIM-75))
- [ ] Issue links (blocks, relates to, duplicates, etc.) (planned: [JIM-76](https://community.openproject.org/projects/JIM/work_packages/JIM-76))
- [ ] Web links (workarond planned: [JIM-206](https://community.openproject.org/projects/JIM/work_packages/JIM-206)).
- [ ] Labels (planned: [JIM-109](https://community.openproject.org/projects/JIM/work_packages/JIM-109))
- [ ] Logged work / time entries (only the *estimated* and *remaining* hours fields come across — actual time logged does not) (planned: [JIM-93](https://community.openproject.org/projects/JIM/work_packages/JIM-93))
- [ ] Votes (workaround planned: [JIM-207](https://community.openproject.org/projects/JIM/work_packages/JIM-207), open feature request: [OP-3251](https://community.openproject.org/projects/OP/work_packages/OP-3251))
- [ ] Resolution and Resolution date (planned as custom field: [JIM-149](https://community.openproject.org/projects/JIM/work_packages/JIM-149); broader native support: [FND-231](https://community.openproject.org/projects/FND/work_packages/FND-231))
- [ ] Environment
- [ ] Security Level
- [ ] Components (planned: [JIM-107](https://community.openproject.org/projects/JIM/work_packages/JIM-107))
- [ ] Fix Versions and Affects Versions (planned: [JIM-154](https://community.openproject.org/projects/JIM/work_packages/JIM-154))
- [ ] Archived issues (skipped entirely, don't appear in OpenProject in any form)

**Not migrated, specific to custom fields:**

- [ ] Date Time Picker: the time-of-day (the date itself is migrated — see [Custom fields migration](../custom-fields/#date-time-picker))      
- [ ] Epic Link / Epic Name
- [ ] Sprint field
- [ ] Story Points
- [ ] User picker / multi-user picker values, unless the referenced user is also referenced elsewhere on an imported issue (as creator, assignee, comment or attachment author, or an @mention). Otherwise the value comes across empty, with no reliable way to prevent this in advance. 
- [ ] Version-picker
- [ ] Any third-party plugin-provided custom field type e.g. Scripted Fields
- [ ] Per-context custom field values (Jira Field Contexts) - At the moment OpenProject does not support different option sets per project or issue type; a custom field's options are always global. 

**Not migrated, beyond individual issues:**

- [ ] Workflows (which status transitions are allowed for which roles) (planned: [JIM-153](https://community.openproject.org/projects/JIM/work_packages/JIM-153)). Note that at the moment, OpenProject workflows are defined globally per Type, not per project. If different Jira projects used different workflow schemes for the same issue type, that distinction cannot be preserved at the moment. (in development: [AUTOWORK-67](https://community.openproject.org/projects/AUTOWORK/work_packages/AUTOWORK-67)) 
- [ ] Permission schemes / roles (planned: [JIM-97](https://community.openproject.org/projects/JIM/work_packages/JIM-97))
- [ ] Agile boards (Scrum/Kanban setup, filters, swimlanes) (planned: [JIM-106](https://community.openproject.org/projects/JIM/work_packages/JIM-106))
- [ ] Integration with Confluence (planned: [JIM-193](https://community.openproject.org/projects/JIM/work_packages/JIM-193))
- [ ] Any Marketplace app data (e.g. Tempo time tracking, Xray/Zephyr test management, Structure hierarchies) — the migrator only handles core Jira issue/project/user data and the specific custom field types listed above. Inventory which apps your teams actually depend on and decide separately how to handle each one's data.

For anything on this list your teams actually rely on, decide now how you'll handle it — export it separately, accept the loss, or plan to recreate it manually after migration (see the [Post-Migration checklist](../post-migration-checklist/) for what that looks like). Don't discover this after the fact.

## Preparation

- [ ] For anything you decided to keep from the "what doesn't migrate" review above, export it separately now (e.g. via CSV) before you lose easy access to it.
- [ ] **Decide how to handle Resolution if your team relies on it.** Jira's Resolution (Fixed, Won't Fix, Duplicate, Cannot Reproduce, etc.) doesn't migrate at all — only Status does, and multiple resolutions can collapse into one status. If this distinction matters, either export Resolution values separately, or consider splitting your Jira statuses beforehand so the outcome is captured in the status name itself (e.g. "Done - Won't Fix" as a distinct status from "Done - Fixed"). There's an open feature request to migrate Resolution as a custom field automatically: [JIM-149](https://community.openproject.org/projects/JIM/work_packages/JIM-149).
- [ ] **Note your Jira priority order (severity ranking) before migrating.** The migrator doesn't preserve priority order, colors, or icons — only the name. Since OpenProject falls back to whichever priority is first in the list when an issue has none set, you'll likely need to manually reorder priorities in OpenProject afterward to match your actual severity ranking.
- [ ] **Note which issue type is the default per project, if that matters to you.** No migrated type is marked as default, regardless of what was default in Jira — you'll need to set this manually in OpenProject after migration.

## OpenProject-side prerequisites

- [ ] Confirm your Jira instance is reachable from OpenProject by using [the connection test](../#test-configuration).
- [ ] If you're on an OpenProject Enterprise plan, check your available user seats against the number of currently-active Jira users you're about to migrate. Not relevant if you're on the free Community edition. Increase your seat count before the migration.
- [ ] **Check OpenProject's maximum attachment size setting** (Administration → Files → Attachments) against the largest attachments in your Jira data. OpenProject doesn't impose a total storage quota, but it does enforce a per-file size limit — a Jira attachment larger than this limit will fail to import. Since attachment failures are silently logged and skipped rather than stopping the run, this can otherwise go unnoticed until you check attachment counts post-migration. Raise the limit beforehand if needed.
- [ ] **Enable project-based semantic identifiers** in OpenProject.
- [ ] **Disable "Use current date as start date for new work packages" setting** in OpenProject. This is currently needed due to a [known issue](https://community.openproject.org/projects/JIM/work_packages/JIM-155/activity) in the importer.
- [ ] **Take a full OpenProject backup.** Approving an import run is irreversible; reverting is only possible while the run is still "in review."
- [ ] **Audit existing OpenProject custom fields** for name collisions with fields you expect to import, especially fields of types List and Hierarchy — these never reuse/merge into an existing field of the same name, so a collision results in an auto-renamed extra field (e.g., My Field (2)) rather than keeping the original name. Rename or delete the conflicting OpenProject field beforehand if you'd rather it merge with the imported one, or plan to consolidate them manually after migration.
- [ ] **Check for Jira group names that collide with existing, unrelated OpenProject groups.** Groups are matched/created by name — if you already have an OpenProject group called e.g. "Developers" that has nothing to do with Jira, and Jira also has a "Developers" group, the migrator will add Jira members into your existing group rather than keeping them separate. Rename one side beforehand if that's not what you want.
- [ ] Decide now whether you have (or plan to buy) the **Enterprise custom-field-hierarchies add-on** — it changes how cascading-select fields import (native hierarchy vs. flattened list), and there is no automated way right now to change this afterwards.

## Jira data clean-up

- [ ] To reduce what gets imported, archive unwanted issues in Jira first. Archived issues are skipped by the migration.
- [ ] Check that all Jira project keys are 10 characters or shorter. OpenProject's project identifiers are limited to 10 characters as per Jira default. Projects with a longer key cannot be imported. Shorten any long project keys in Jira before migrating. Confirmed bug: [JIM-172](https://community.openproject.org/projects/JIM/work_packages/JIM-172).
- [ ] Check that all Jira project keys only contain uppercase letters, digits, and underscore and that they start with a letter (Regular expression: `\A[A-Z][A-Z0-9_]*\z`). Jira's default rules already enforce this, but a custom `jira.projectkey.pattern` can override it. OpenProject currently does not support other formats: [JIM-190](https://community.openproject.org/projects/JIM/work_packages/JIM-190).
- [ ] If cascading-select or Labels-type custom fields are in use, be aware the migrator can only recover option values that actually appear on an imported issue — values that exist in Jira's config but were never used won't come across as selectable options. If you want them migrated to OpenProject, add the values at least temporarily to at least one Jira issue.
- [ ] Minimize your Jira data customizations as described [here](https://support.atlassian.com/migration/docs/clean-up-your-server-instance-before-migration/#Minimize-your-Jira-data-customizations).
- [ ] Standardize Type, Status, and Priority names across all projects you intend to migrate together where you actually want them to merge into one OpenProject record. Matching/uniqueness is case-insensitive, but genuinely different spellings (`"To-Do"` vs `"To Do"`, `"Doing"` vs `"In Progress"`) are treated as distinct and will each become their own OpenProject status/type/priority.
- [ ] Check Jira usernames for characters other than letters, digits, and `_ - @ . +` or spaces and remove all other characters. OpenProject logins only accept that set. A username with anything else will cause the import to fail. Rename any offending usernames in Jira to only use these characters before migrating. Confirmed bug (comma specifically): [JIM-177](https://community.openproject.org/projects/JIM/work_packages/JIM-177).
- [ ] Strip leading and trailing whitespace from email addresses in Jira before migrating. Confirmed bug (trailing space specifically): [JIM-182](https://community.openproject.org/projects/JIM/work_packages/JIM-182).
- [ ] Check for duplicate emails or logins across different Jira user accounts. Jira can allow this (e.g. across multiple user directories, or leftover accounts from user history), but OpenProject doesn't — email and login must be unique. The importer handles a genuine collision by giving the second account a disambiguated email/login (e.g. `name+JIRAKEY@domain.com`) rather than merging the two people together, but that means one of them ends up with a login that doesn't match what they actually use in Jira. If you don’t want this, clean up duplicate accounts in Jira beforehand so each person has one clearly correct, unique email — or at least know in advance which users will get an auto-generated address so you can communicate it to them.
- [ ] Check for user references that may no longer resolve in Jira — for example, comment authors, attachment authors, or assignees who have since been removed from Jira. This is not handled gracefully: any of these failing to resolve aborts the whole import. Open bug: [JIM-184](https://community.openproject.org/projects/JIM/work_packages/JIM-184). @mentions inside descriptions/comments are the one exception — they fall back to plain text instead of failing. Worth testing your actual data for this rather than assuming it's fine. Re-create the users in Jira, manually create them before the import in OpenProject or remove the reference from the Jira issue if possible.
- [ ] Consolidate custom field contexts for select-type and cascading-select fields. If a Jira custom field has different allowed values configured per project or issue type (different "contexts"), each distinct set becomes its own separate OpenProject field. Aligning these into one consistent set of options in Jira beforehand avoids ending up with several OpenProject fields for what's really one field. Note that this only helps within a single import run. If you're migrating in separate batches, this same field will still get a new, separate OpenProject field in each batch, even with identical options. If you don’t want this behavior, design the batches accordingly. 
- [ ] Rewrite descriptions/comments that rely on markup the converter doesn't recognize, if you want to avoid post-migration cleanup: `{info}`/`{warning}`/`{note}`/`{tip}` callout boxes, `{toc}`, and `{expand}`/`{section}`/`{column}` layouts all leave their raw tag text behind unconverted rather than being dropped or styled. If specific issues use these heavily, replacing them with plain text/headings in Jira beforehand avoids leftover clutter in OpenProject. Same applies to bare issue-key links (`[PROJECT-123]`) and attachment links (`[^file.pdf]`) — these come across as plain, non-clickable text, so rewriting them as full URLs in Jira first is the only way to keep them working as links.


## Batching approach

If you're not migrating everything in a single run, decide this deliberately rather than defaulting to "one project at a time" — it affects more than just convenience.

- [ ] **Group projects that share custom field options into the same batch.** If a Jira custom field has identical allowed values across several projects, they only merge into a single OpenProject field if those projects are imported together in one run. Splitting them across separate batches means each batch creates its own separate field, even with identical options — see the custom fields clean-up item above.
- [ ] **Users and groups are safe to split across batches.** If the same person is a member of projects in different batches, they won't end up duplicated — a later batch recognizes their existing OpenProject account (matched by email or login) and reuses it rather than creating a second one. The same applies to groups, matched by name. You don't need every project a person touches in the same batch just to avoid duplicate accounts.
- [ ] **Consider using batches to manage Enterprise seat limits.** Each batch only activates the users it newly creates when you approve it — so if you don't have enough seats to activate everyone in Jira at once, splitting the migration into batches lets you approve and activate people incrementally instead of hitting the seat limit in one go.
- [ ] Decide your overall batching approach — project by project, or grouped batches — with the above in mind.
