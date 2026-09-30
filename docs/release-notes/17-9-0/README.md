---
title: OpenProject 17.9.0
sidebar_navigation:
    title: 17.9.0
release_version: 17.9.0
release_date: 2026-09-30
---

# OpenProject 17.9.0

Release date: 2026-09-30

We released [OpenProject 17.9.0](https://community.openproject.org/versions/2322).
The release contains several bug fixes and we recommend updating to the newest version.
In these Release Notes, we will give an overview of important feature changes. At the end, you will find a complete list of all changes and bug fixes.


## Important feature changes

OpenProject 17.9 makes it easier to turn ideas and planning documents into actionable work: **work packages can now be created directly from the Documents module**, either with a slash command or from selected text.

With this release, **we are adding the [date alerts](../../user-guide/notifications/notification-settings/#date-alerts) to the Community edition**. All users can receive notifications about approaching start and finish dates and overdue work packages, making it easier for teams to keep track of important deadlines and act before work falls behind.

The release also introduces **filters for Backlogs**, extends the **MCP Server with time tracking and improved work package search**, adds the new **Observed in versions** field, and provides more control when deleting work packages with descendants. Administrators benefit from more flexible PDF export defaults and SSO settings, while the Jira Migrator now provides faster imports with real-time progress.

Take a look at our release video showing the most important features introduced in OpenProject 17.9:

![Release video of OpenProject 17.9](https://openproject-docs.s3.eu-central-1.amazonaws.com/videos/OpenProject_17_9_release.mp4)


### Create work packages directly from Documents

OpenProject 17.9 makes it easier to turn planning content into actionable work without interrupting the flow of writing and collaboration.

Work packages can now be created **directly from the [Documents module](../../user-guide/documents/)**, either using a slash command or from selected text. When creating a work package from selected text, the selection is automatically used as its subject.

![Creating a new work package directly from an OpenProject document](openproject_release_notes_17.9_document_create_work_package.png)

The newly created work package is linked directly in the document, keeping requirements, ideas, and planning notes connected to the work that follows from them.

### Filter work packages in Backlogs

OpenProject 17.9 introduces the first iteration of **filters in the [Backlogs view](../../user-guide/backlogs-scrum/)**, making it easier to focus on the work packages that matter.

The filters familiar from pages like the work package table or boards can be used by the team to reduce a larger set of work packages in the backlog and sprints. Users can simply search for work packages by subject or construct a complex filter set. Filters apply across sprints, backlog buckets, and the backlog inbox, with counters and story points reflecting the currently visible work packages.

![Filtering work packages in the OpenProject Backlogs view](openproject_release_notes_17.9_backlogs_filters.png)

Work packages can still be moved and reordered while filters are active, making it possible to work with a focused subset without losing changes when returning to the full backlog.

> [!NOTE]
> **Saving a filtered Backlogs view is not yet available** in this first iteration.

### More control when deleting work packages with descendants

OpenProject 17.9 gives users more control when deleting work packages with descendants. Users can now choose to **delete only the selected work package** or **delete it together with all its descendants**.

![Message asking you to choose whether to delete descendants when deleting a work package in OpenProject](openproject_release_notes_17.9_delete_work_package_descendants.png)

This helps prevent unintended deletion of entire work package hierarchies while preserving the option to remove them together when needed.

### Observed in versions

OpenProject 17.9 introduces a new **Observed in versions** field for work packages.

While **Target versions** describe the versions a work package is assigned to, **Observed in versions** can be used to record versions in which an issue has been observed. This is particularly useful for bugs that affect multiple product versions.

![A work package of type Bug in OpenProject, showing "Observed in versions" field](openproject_release_notes_17.9_observed_in_versions.png)

The field supports multiple versions, including closed versions, and is enabled by default for work packages of type **Bug**. It can also be enabled for other work package types.

### More MCP capabilities for AI assistants

OpenProject 17.9 further extends the capabilities of the [MCP Server](../../system-admin-guide/integrations/mcp-server/), making it easier and more efficient for AI assistants to work with OpenProject:

- **Track time through MCP:** AI assistants can now find, create, update, and delete time entries.
- **Use work package display IDs with semantic identifiers:** When using semantic identifiers, AI assistants can now work with the familiar work package IDs shown in OpenProject, just as they already could with classic IDs.
- **Get more compact search results:** Work package searches now return more compact responses by default, reducing unnecessary data and making more efficient use of the AI assistant's context. Full information can still be requested when needed.

### Improved PDF exports

OpenProject 17.9 brings several improvements to PDF exports, providing more complete project information and making it easier to create consistent exports.

- **More comprehensive [PMflex artefact exports](../../user-guide/work-packages/exporting/work-package-pdf/):** Project lifecycle information and **project budgets** can now optionally be included in the PDF. Budgets are presented as a cost breakdown, including unit and labor costs and their subtotals. This provides a more complete view of project planning, progress, and costs in a single artefact.

  ![Project lifecycle and budget information in a PMflex artefact PDF export](openproject_release_notes_17.9_pmflex_pdf_export.png)

- **[Default PDF export settings per work package type](../../system-admin-guide/manage-work-packages/work-package-types/pdf-export/):** Administrators can now define default settings for **Attributes, Contract, and PMflex artefact exports** for each work package type. Depending on the template, defaults can include options such as footer text, page orientation, table of contents, and hyphenation. These defaults are automatically applied when starting an export, reducing repetitive configuration and helping teams create more consistent PDFs.

![Default PDF export settings for a work package type](openproject_release_notes_17.9_pdf_export_defaults.png)

### Faster Jira migrations with real-time progress

OpenProject 17.9 improves the performance and transparency of **[migrations from Jira to OpenProject](../../installation-and-operations/jira-migration/)**.

Project data can now be imported using **concurrent jobs**, allowing the Jira Migrator to process work in parallel. The migration interface displays progress in real time, including concurrent jobs, so administrators can see that a longer-running migration is actively progressing.

![Real-time progress of a Jira project migration in OpenProject](openproject_release_notes_17.9_jira_migrator_progress.png)

During the **Import data** stage, administrators can also abort a running migration. An aborted migration can later be **resumed** or **reverted**, providing more control over longer migration processes.

The final approval and revert stage cannot be aborted. At this stage, administrators instead choose whether to approve or revert the imported data.


### Meetings improvements

OpenProject 17.9 brings several improvements to [meetings](../../user-guide/meetings/), making it quicker to create meetings and easier to find them through the API.

New meetings and recurring meetings now default to **today**, with the start time set to the current time rounded up to the next half hour. This better supports creating an agenda for an ad-hoc meeting that is about to start or is already in progress.

The `GET /api/v3/meetings` endpoint now also supports **filtering meetings by title**. Searches use case-insensitive partial matching and also match the series title for occurrences of recurring meetings.

Existing meeting visibility and permission rules continue to apply.

### Cleaner project overview

The **[Subitems](../../user-guide/projects/project-home/project-widgets/)** widget on project overview pages is now shown only where it adds value. For projects, the widget is hidden when there are no subprojects. Users who have permission to create subitems can still do so through a new action in the page header.

![Creating a subitem from the project page header](openproject_release_notes_17.9_project_subitems_action.png)

For programs and portfolios, the Subitems widget remains visible even when it is empty because subitems are an integral part of their structure.

### Allow planned labor to be entered in hours, days, weeks, or months

When adding **planned labor costs to a [budget](../../user-guide/budgets/)**, planned labor can now be entered in **hours, days, weeks, or months**. This makes it easier to estimate planned labor using the unit that best fits the work.

The user selector for planned labor costs has also been improved with an autocompleter, making it easier to find and select project members.

![Entering planned labor using different time units in OpenProject](openproject_release_notes_17.9_planned_labor_time_units.gif)

### Improved wiki page selection for wikis

XWiki users can now **[browse the wiki hierarchy directly](../../user-guide/work-packages/edit-work-package/#link-an-existing-wiki-page)** when selecting a page, making it easier to find content without knowing the page title in advance.

The hierarchy can be expanded to browse nested pages, while search remains available for quickly finding a specific page.

![Browsing the XWiki hierarchy in an OpenProject page selection dialog](openproject_release_notes_17.9_xwiki_tree_browsing.png)

### Administration interface improvements

OpenProject 17.9 continues the modernization of administration pages with Primer UI components.

The **[Roles and permissions](../../system-admin-guide/users-permissions/roles-permissions/)** table has been updated and now includes quick filters. Administrators can search for roles and switch between **Global roles**, **Project roles**, and **All roles**.

![Filters on the Roles and permissions  page in OpenProject administration](openproject_release_notes_17.9_role_administration.png)

The **[Administration → Design → Interface](../../system-admin-guide/design/)** page has also been rebuilt using Primer components for a more consistent administration experience.

### Number custom fields now use minimum and maximum values

Configuration for [integer and floating-point custom fields](../../system-admin-guide/custom-fields/) has been updated to reflect the actual meaning of their validation settings.

Instead of **Min length** and **Max length**, administrators now configure:

- **Minimum value**
- **Maximum value**

![Configuring minimum and maximum values for a number custom field](openproject_release_notes_17.9_number_custom_field_min_max.png)

Integer fields accept integer limits, while floating-point fields support decimal values.
A migration has been added to try and convert the previous length values to their respective minimum and maximum values. In some cases, this migration may not be accurate. 
If you have used this feature in the past, please double-check your configuration.

### Configurable SAML clock drift

[SAML](../../system-admin-guide/authentication/saml/) administrators can now configure an **allowed clock drift** between the SAML Identity Provider and OpenProject.

This can help authentication continue to work in environments where the timestamps of the identity provider and OpenProject cannot be synchronized perfectly.

The `allowed_clock_drift` value can be configured as part of the SAML configuration and can also be supplied through an environment setting.

## Important updates and breaking changes

### Restrict password login for SSO users

OpenProject 17.9 gives administrators using [Single Sign-On](../../system-admin-guide/authentication/) more control over **password-based authentication**.

A new password login policy allows administrators to:

- **Allow password login for everyone** (default).
- **Disallow password login for SSO users**.
- **Disallow password login for everyone**.

For restricted configurations, selected users or groups can be added to a **break-glass allowlist**, ensuring that password-based administrative access remains possible when needed.

![Configuring the password login policy for Single Sign-On in OpenProject](openproject_release_notes_17.9_sso_password_login_policy.png)

Existing environment-based configuration continues to be supported and takes precedence over configuration through the administration interface.

## Security fixes

### GHSA-4p83-c4wg-59q4 -  Meeting agenda item API leaks private work package subjects through the shared representer cache
Caching Work package links in the meeting API endpoints could result in leaking work package subjects to users having no access to them.

Reported through GitHub advisory by user [@kewmine](https://github.com/kewmine)

For more information, please see the [GitHub advisory #GHSA-4p83-c4wg-59q4](https://github.com/opf/openproject/security/advisories/GHSA-4p83-c4wg-59q4)

### GHSA-c5j2-2mfg-49h7 - Reusable direct-upload policy can alter trusted attachment content after antivirus scanning

Direct uploads to S3-compatible attachment storage could be replayed after the upload had completed. A user allowed to add attachments could reuse the signed upload form of their own attachment to replace its content after the antivirus scan had already passed it. Other users downloading that attachment then received the replaced, unscanned content, while OpenProject still listed the attachment as scanned.

Only installations using remote (S3-compatible) attachment storage with direct uploads enabled are affected. Direct uploads are on by default whenever S3 storage is configured. Installations storing attachments on the local filesystem are not affected. The impact is highest where antivirus scanning is used, since the scan result no longer reflects what is served.


### GHSA-q7fh-rhcq-ppg7 - Authorization context mismatch in external-storage upload preparation endpoint
OpenProject contains an authorization-context mismatch in the external-storage upload preparation endpoint. The endpoint `POST /api/v3/storages/:storage_id/files/prepare_upload` selects the target external storage from the `storage_id` path parameter, but performs the `manage_file_links` authorization check against the independently supplied `projectId` request-body parameter.

An authenticated user who can access an external storage through one project, but lacks `manage_file_links` permission on that project, may be able to supply the ID of an unrelated project where they do have `manage_file_links`. This causes authorization to succeed against the unrelated project while the upload preparation operation is performed against the storage selected in the URL.

The demonstrated impact is a cross-project authorization bypass that allows the upload preparation service to be invoked for a storage/project combination the user is not authorized to manage. Downstream access remains subject to the external storage provider’s own authorization rules, and unauthorized provider-side file write access has not been demonstrated.

This vulnerability was reported by Github user **@kaizhi888**

For more information, please see the [GitHub advisory #GHSA-q7fh-rhcq-ppg7](https://github.com/opf/openproject/security/advisories/GHSA-q7fh-rhcq-ppg7)

### GHSA-r374-cr8p-hmp9 - Active sessions remain valid after password change
The application does not invalidate existing authenticated sessions after a user changes their password. As a result, other active sessions for the same account, including sessions on other browsers or devices, remain authenticated and usable after the password change is completed.

This can allow an attacker who has already obtained a valid session token or authenticated browser session to retain access even after the legitimate user changes their password. The issue weakens the effectiveness of password rotation as an account recovery measure and may allow continued unauthorized access to account data and user-level actions until the retained session expires or is manually revoked.

For more information, please see the [GitHub advisory #GHSA-r374-cr8p-hmp9](https://github.com/opf/openproject/security/advisories/GHSA-r374-cr8p-hmp9)

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Feature: 1st iteration of filters within the backlog \[[#74387](https://community.openproject.org/wp/74387)\]
- Feature: Allow to track time through MCP \[[#78402](https://community.openproject.org/wp/78402)\]
- Feature: Limit work package search results responses by default when using MCP \[[#78602](https://community.openproject.org/wp/78602)\]
- Feature: MCP: Allow searching work packages by their display id \[[#79255](https://community.openproject.org/wp/79255)\]
- Feature: Primerize role administration table \[[#79489](https://community.openproject.org/wp/79489)\]
- Feature: Create work package via slash command in a document \[[#67552](https://community.openproject.org/wp/67552)\]
- Feature: Create work package via text selection in a document \[[#78337](https://community.openproject.org/wp/78337)\]
- Feature: Introduce observed in versions \[[#76236](https://community.openproject.org/wp/76236)\]
- Feature: Primerise Interface tab of Admin/Design page \[[#56341](https://community.openproject.org/wp/56341)\]
- Feature: Show subitem widget only when subitems exist \[[#78005](https://community.openproject.org/wp/78005)\]
- Feature: Jira Migrator imports &quot;observed in versions&quot; and &quot;target versions&quot; (Jira fix version) \[[#72428](https://community.openproject.org/wp/72428)\]
- Feature: Make meeting default date today. Time now (rounded) \[[#69574](https://community.openproject.org/wp/69574)\]
- Feature: Add search/filter support for meetings in the GET /api/v3/meetings endpoint \[[#79862](https://community.openproject.org/wp/79862)\]
- Feature: Give users the choice to not include descendants when deleting work packages \[[#77999](https://community.openproject.org/wp/77999)\]
- Feature: Global default settings for PDF exports by type \[[#78333](https://community.openproject.org/wp/78333)\]
- Feature:     Allow planned labor to be entered in hours, days, weeks, or months \[[#78544](https://community.openproject.org/wp/78544)\]
- Feature: PMflex Artefact PDF: Include project phases and budgets \[[#78561](https://community.openproject.org/wp/78561)\]
- Feature: Allow differing time stamps between SAML IdP and SP (OpenProject) within margin (allowed\_clock\_drift) \[[#79019](https://community.openproject.org/wp/79019)\]
- Feature: Allow restricting password login for SSO authenticated users \[[#79300](https://community.openproject.org/wp/79300)\]
- Feature: For number custom fields, replace min and max length with minimum and maximum values \[[#79759](https://community.openproject.org/wp/79759)\]
- Feature: Add the date alert feature to the community edition \[[#78407](https://community.openproject.org/wp/78407)\]
- Feature: Add browsing in the tree view for wikis when no search is conducted \[[#75610](https://community.openproject.org/wp/75610)\]
- Bugfix: Spacing disappeared between the \[Start sprint\] button and the sprint date in the backlog \[[#78595](https://community.openproject.org/wp/78595)\]
- Bugfix: Backlogs: page crashes on projects with lots of work packages when filter is removed \[[#80040](https://community.openproject.org/wp/80040)\]
- Bugfix: Backlogs: Infinite page reload loop when applying Is milestone filter \[[#80057](https://community.openproject.org/wp/80057)\]
- Bugfix: Backlogs: Keyboard focus shifts to Add filter instead of input field after selecting a filter \[[#80072](https://community.openproject.org/wp/80072)\]
- Bugfix: Backlogs: Some filters should not be present \[[#80092](https://community.openproject.org/wp/80092)\]
- Bugfix: Documents: two wps highlighted at once in wp dropdown on ios safari \[[#75812](https://community.openproject.org/wp/75812)\]
- Bugfix: Documents: size menu on wp link closes automatically when tapped on ios safari \[[#75815](https://community.openproject.org/wp/75815)\]
- Bugfix: Documents: overflow in the work package preview when the wp type is long \[[#77690](https://community.openproject.org/wp/77690)\]
- Bugfix: Context menu scrolls over header on mobile \[[#77693](https://community.openproject.org/wp/77693)\]
- Bugfix: Documents: issues with tiny work package link preview on mobile iOS \[[#77720](https://community.openproject.org/wp/77720)\]
- Bugfix: Creating a work package via slash command in a list should render an inline, &quot;regular&quot; sized work package link \[[#78973](https://community.openproject.org/wp/78973)\]
- Bugfix: Linking a work package inside a headline via slash command looks broken \[[#78974](https://community.openproject.org/wp/78974)\]
- Bugfix: Resizing menu of work package links cut off at the bottom of the document \[[#79353](https://community.openproject.org/wp/79353)\]
- Bugfix: Documents: double tap necessary to select a work package on iOS \[[#79742](https://community.openproject.org/wp/79742)\]
- Bugfix: Values in dropdown not shown for required field of type hierarchy \[[#79747](https://community.openproject.org/wp/79747)\]
- Bugfix: Documents: User without permissions to create work packages still sees the command to create a new work package \[[#79943](https://community.openproject.org/wp/79943)\]
- Bugfix: Documents: In create work package modal, subject is hidden when it&#39;s automatically generated \[[#79951](https://community.openproject.org/wp/79951)\]
- Bugfix: Documents: long wp title causes overflow on wp search on mobile \[[#75683](https://community.openproject.org/wp/75683)\]
- Bugfix: Documents: wp link dropdown cut off at the bottom of the page \[[#75694](https://community.openproject.org/wp/75694)\]
- Bugfix: Documents: letters cut off at the bottom of the inline work package link \[[#75731](https://community.openproject.org/wp/75731)\]
- Bugfix: Documents: missing scroll into view behavior when using arrow key at the bottom of the page \[[#75733](https://community.openproject.org/wp/75733)\]
- Bugfix: Paragraph in Firefox document is infinite in width \[[#76694](https://community.openproject.org/wp/76694)\]
- Bugfix: Cleanup job can delete Attachments uploaded to a new work package when attachments drag and drop field is missing during the upload  \[[#76870](https://community.openproject.org/wp/76870)\]
- Bugfix: First headline not rendered correctly when opening a document \[[#77648](https://community.openproject.org/wp/77648)\]
- Bugfix: When work packages are grouped by X, it&#39;s not possible to drag and drop an item to the last line inside the same group \[[#79220](https://community.openproject.org/wp/79220)\]
- Bugfix: Search is missing an index for work\_package\_semantic\_aliases which makes it slow \[[#79497](https://community.openproject.org/wp/79497)\]
- Bugfix: &quot;Only changes&quot; work packages activity filter hides target and observed-in version changes \[[#79498](https://community.openproject.org/wp/79498)\]
- Bugfix: Error when saving a work package outside a project - Observed in versions not writable \[[#80282](https://community.openproject.org/wp/80282)\]
- Bugfix: Deletion state missing from journal timeline when a target version that was previously assigned to a work package is deleted from the database \[[#80343](https://community.openproject.org/wp/80343)\]
- Bugfix: When entering days it defaults to 24h instead of workdays \[[#78588](https://community.openproject.org/wp/78588)\]
- Bugfix: Logging time via the API on a non existing entity, raises an error \[[#76681](https://community.openproject.org/wp/76681)\]
- Bugfix: Create WP button overlaps over long WP type name and long WP subjects \[[#63010](https://community.openproject.org/wp/63010)\]
- Bugfix: Milestones in the project timeline widget cannot be opened with a keyboard or screen reader \[[#79044](https://community.openproject.org/wp/79044)\]
- Bugfix: Inconsistent usage for &quot;built-in&quot; labels \[[#79059](https://community.openproject.org/wp/79059)\]
- Bugfix: Sprints are not clickable in timeline widget \[[#79411](https://community.openproject.org/wp/79411)\]
- Bugfix: &#39;No items&#39; shown on wiki tree view is not translated  \[[#79389](https://community.openproject.org/wp/79389)\]
- Bugfix: Missing caption on &#39;Default colors&#39; tab \[[#79771](https://community.openproject.org/wp/79771)\]
- Bugfix: Remove max-width of 752px from the filter component \[[#79773](https://community.openproject.org/wp/79773)\]
- Bugfix: Save button has the wrong colour in admin/user setttings \[[#79878](https://community.openproject.org/wp/79878)\]
- Bugfix: Personal-data fields do not expose their input purpose \[[#80031](https://community.openproject.org/wp/80031)\]
- Bugfix: Jira import fails when historical issues reference deleted Jira users \[[#78961](https://community.openproject.org/wp/78961)\]
- Bugfix: is\_closed status is not migrated \[[#79025](https://community.openproject.org/wp/79025)\]
- Bugfix: Set work package created and updated date to timestamps of Jira issue &amp; preserve journal timestamps \[[#79041](https://community.openproject.org/wp/79041)\]
- Bugfix: Scale progress wizard better for a big number of projects \[[#79340](https://community.openproject.org/wp/79340)\]
- Bugfix: Attachment cannot be created in OpenProject \[[#79392](https://community.openproject.org/wp/79392)\]
- Bugfix: Jira migration fails because attachment size is too large \[[#80055](https://community.openproject.org/wp/80055)\]
- Bugfix: Jira Migration fails with &quot;undefined method &#39;strip&#39; for nil&quot; \[[#79876](https://community.openproject.org/wp/79876)\]
- Bugfix: Flicker on page when switching between upcoming and past tabs \[[#60296](https://community.openproject.org/wp/60296)\]
- Bugfix: Using the past filter on Meeting index always shows results for &#39;My meetings&#39; \[[#78865](https://community.openproject.org/wp/78865)\]
- Bugfix: Changed schedule does not import/update in OX/Mailbox.org \[[#79337](https://community.openproject.org/wp/79337)\]
- Bugfix: Round corner on the not header box in File Storages \[[#52792](https://community.openproject.org/wp/52792)\]
- Bugfix: Accessibility: Primer Text Field clear button does not show tooltip \[[#69916](https://community.openproject.org/wp/69916)\]
- Bugfix: Popup for copying Calendar url disappears after 5 secs (too short) \[[#73512](https://community.openproject.org/wp/73512)\]
- Bugfix: Seeded meeting agenda items description is not translated \[[#74752](https://community.openproject.org/wp/74752)\]
- Bugfix: HTML numeric entities shown instead of Cyrillic characters in &quot;My spent time&quot; tooltip \[[#75277](https://community.openproject.org/wp/75277)\]
- Bugfix: Sibling morph breaks after OPCE-\* replaceWith in dialog preview \[[#76653](https://community.openproject.org/wp/76653)\]
- Bugfix: Page takes a long time to load and does not sort correctly when removing &#39;Start time&#39; from &#39;All filters&#39; \[[#76655](https://community.openproject.org/wp/76655)\]
- Bugfix: Required user custom fields interfere with LDAP group and department synchronisation \[[#77192](https://community.openproject.org/wp/77192)\]
- Bugfix: Can&#39;t upload IFC file when S3 storage is configured \[[#78085](https://community.openproject.org/wp/78085)\]
- Bugfix: Description field of (new) forum is too small. \[[#78503](https://community.openproject.org/wp/78503)\]
- Bugfix: MeetingOutcome invalid kind value crashes with 500 instead of 422 \[[#78526](https://community.openproject.org/wp/78526)\]
- Bugfix: RecurringMeeting occurrence init crashes with 500 on a draft template \[[#78527](https://community.openproject.org/wp/78527)\]
- Bugfix: UserWorkingHours create crashes with 500 when a weekday is nil \[[#78528](https://community.openproject.org/wp/78528)\]
- Bugfix: wiki\_page\_links pagination silently ignores offset \[[#78529](https://community.openproject.org/wp/78529)\]
- Bugfix: Writing end\_time on a time entry crashes with NoMethodError (500) \[[#78530](https://community.openproject.org/wp/78530)\]
- Bugfix: time\_entries hours-to-duration serialization truncates instead of rounds \[[#78531](https://community.openproject.org/wp/78531)\]
- Bugfix: Backup via web ui is missing the option to include attachments \[[#78559](https://community.openproject.org/wp/78559)\]
- Bugfix: User Filter cannot show Departments, Groups, Projects and Status \[[#78800](https://community.openproject.org/wp/78800)\]
- Bugfix: Groups: Subgroup does not inherit parent group&#39;s project role assignments despite correctly set Parent group \[[#79043](https://community.openproject.org/wp/79043)\]
- Bugfix: Tooltip for &quot;My spent time&quot; entries that are only partially visible is shown in wrong place \[[#79486](https://community.openproject.org/wp/79486)\]
- Bugfix: When trying to login with password, and password login being disabled for SSO users, the error message does not say about this \[[#79693](https://community.openproject.org/wp/79693)\]
- Bugfix: Failed Turbo frame requests can cause an infinite page reload loop \[[#80091](https://community.openproject.org/wp/80091)\]
- Bugfix: PDF export: user without permission to see budgets sees the budget name \[[#80175](https://community.openproject.org/wp/80175)\]
- Bugfix: Creating a PIR project from a template with no active fields crashes on displaying the wizard \[[#77992](https://community.openproject.org/wp/77992)\]
- Bugfix: Date picker is shown behind the modal, when the filter component is used in a modal \[[#79936](https://community.openproject.org/wp/79936)\]
- Bugfix: Misleading scheduling conflict, when the user has no working schedule planned for the entire allocation \[[#80101](https://community.openproject.org/wp/80101)\]
- Bugfix: RuntimeError in Storages::AutomaticallyManagedStorageSyncJob#perform \[[#79458](https://community.openproject.org/wp/79458)\]
- Bugfix: When a wiki page is added to the WP description on the WP page, the page is not shown on the mentioned description box \[[#78133](https://community.openproject.org/wp/78133)\]
- Bugfix: Persist collaped state for the wiki blocks when wiki tab is updated \[[#78978](https://community.openproject.org/wp/78978)\]
- Bugfix: Return URL is not visible if a user enters their own client ID for wiki integration \[[#79508](https://community.openproject.org/wp/79508)\]
- Feature: Jira Migrator shows progress during import of projects, leveraging concurrency \[[#73094](https://community.openproject.org/wp/73094)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->

## Contributions
A very special thank you goes to Helmholtz-Zentrum Berlin, City of Cologne, Deutsche Bahn, and ZenDiS for sponsoring released and upcoming features. Your support, alongside the efforts of our amazing Community, helps drive these innovations.

Also a big thanks to our Community members for reporting bugs and helping us identify and provide fixes. Special thanks for reporting and finding bugs go to Daniel Paulo Dos Santos, Max Tachkov, Tobias Nowakow, Michael Gillen, Jürgen Tauschl, Raphael Zoppoth, and Paul Grimes.

Last but not least, we are very grateful for our very engaged translation contributors on Crowdin, who translated quite a few OpenProject strings! This release we would like to particularly thank the following users:

- [Jonatan Nyberg](https://crowdin.com/profile/nickwick), for translations into Swedish,
- [BigSeung](https://crowdin.com/profile/BigSeung) for translations into Korean.

Would you like to help out with translations yourself? Then take a look at our [translation guide](../../contributions-guide/translate-openproject/) and find out exactly how you can contribute. It is very much appreciated!
