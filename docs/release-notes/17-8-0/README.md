---
title: OpenProject 17.8.0
sidebar_navigation:
title: 17.8.0
release_version: 17.8.0
release_date: 2026-09-02
---

# OpenProject 17.8.0

Release date: 2026-09-02

We released [OpenProject 17.8.0](https://community.openproject.org/versions/2313). The release contains several bug fixes and we recommend updating to the newest version. In these Release Notes, we will give an overview of important feature changes. At the end, you will find a complete list of all changes and bug fixes.

## Important feature changes

OpenProject 17.8 brings powerful new possibilities for connecting AI assistants with your project work: the **MCP Server can now create and update work packages**, add comments, and manage work package relations. The release also introduces **multiple target versions per work package**, adds **sprints and milestones to the project timeline**, and brings further improvements to wikis, Backlogs, meetings, and administration.

And there is good news for Community users: **displaying relations in the work package table is now available in the free Community edition**. This makes it easier to see and work with relationships between work packages directly from the table.

Take a look at our release video showing the most important features introduced in OpenProject 17.8:

![Release video of OpenProject 17.8](https://openproject-docs.s3.eu-central-1.amazonaws.com/videos/OpenProject_17_8_release.mp4)

### AI: Create and update work packages with the MCP Server

[feature: mcp_server ]

![AI assistant creating a work package in OpenProject with the MCP Server](openproject_ai_mcp_wp.gif)

OpenProject 17.8 significantly extends the capabilities of the [MCP Server](../../system-admin-guide/integrations/mcp-server/). AI assistants can now **create and update work packages directly in OpenProject**, instead of being limited to searching and reading project information.

The new `create_work_package` and `update_work_package` MCP tools follow the same permissions and business rules as the regular OpenProject UI and API. This includes required fields and `lock_version` checks for updates.

The MCP Server also gains several additional capabilities:

- **Work package comments:** AI assistants can list existing comments, including emoji reactions, and create new comments.
- **Work package relations:** Relations can now be created, modified, and deleted. Relations can also be retrieved, allowing assistants to understand dependencies between work packages.
- **Custom fields:** Custom fields can now be properly identified and set when creating or updating work packages. Possible values for hierarchy-type custom fields can also be retrieved.
- **Pagination metadata:** Collection responses now include information such as page size and total count, making questions such as "How many work packages exist?" easier to answer without additional requests.

Responses from the MCP Server have also been streamlined to reduce unnecessary information sent to AI assistants. Unnecessary action links and the HTML representation of formattable properties such as descriptions and comments are removed from responses. Output schemas have also been removed from MCP tool definitions.

Internally, MCP tools and resources are now registered through a registry pattern, making the server easier to extend in the future.

### Display relations in the work package table now available in the Community edition

**Displaying [work package relations](../../user-guide/work-packages/work-package-relations-hierarchies/) in the work package table is now available to all OpenProject users in the free Community edition**.

Displaying relations as columns in the work package table makes it easier to see how work packages are connected without having to open individual work packages.

### Assign multiple target versions to a work package

OpenProject 17.8 introduces **multiple target versions for work packages**. The existing **Version** field is renamed to **Target versions** and changes from a single-value field to a multi-value field. This allows a work package to be assigned to several versions at the same time, for example when a fix is included in several release lines or a feature spans multiple milestones.

For existing OpenProject installations, this conversion does not happen automatically with the 17.8 update. Administrators can enable it manually under *Administration → Work packages → Versions and categories*. New installations have multiple target versions enabled by default.

> [!IMPORTANT]
> Enabling multiple target versions is a one-way conversion and cannot be reverted.

![Versions and categories in OpenProject administration](openproject_release_notes_17.8_versions_and_categories.png)

Existing version assignments are preserved during the conversion so no data is lost. And once **multiple values** is enabled users can start assigning more than a single version to a work package.

![Multiple target versions assigned to a work package](openproject_release_notes_17.8_multiple_target_versions.png)

Existing functionality such as roadmaps, version boards, bulk editing, project copying, queries, filters, exports, and notifications continues to work with target versions.

For API clients, a new `targetVersions` property replaces the single-value `version` field. Integrations that manage version assignments should migrate to `targetVersions` BEFORE enabling multiple versions on the OpenProject instance.

For more information about the change, migration options, and API compatibility, see the [multiple target versions documentation](../../system-admin-guide/manage-work-packages/versions-and-categories/#multiple-target-versions).

OpenProject 17.8 also extends CKEditor's attribute value macros with a `singleline` and `multiline` layout argument. This allows multi-value attributes to be displayed either as a comma-separated line within a sentence or as a list.

### Configurable global restrictions for time entries

[feature: time_entry_time_restrictions ]

Administrators can now configure **global restrictions for time entries** under *Administration → Time & Costs → Time*.

![Global restrictions for time entries in OpenProject administration](openproject_release_notes_17.8_time_entry_restrictions.png)

For example, administrators can:

- limit the number of hours allowed in an individual time entry,
- limit the number of hours a user can log per day,
- restrict time entries to a user's defined working hours,
- prevent time from being logged on non-working days,
- prevent entries from being added to months that have already ended.

All validations are disabled by default, so existing OpenProject behavior remains unchanged after updating. These settings are instance-wide. 

Project-specific overrides are not yet included and are planned as a future enhancement.

For more information about recording time in OpenProject, see the [time tracking documentation](../../user-guide/time-and-costs/time-tracking/).


### Backlogs and agile improvements

OpenProject 17.8 brings several improvements to [Backlogs and sprints](../../user-guide/backlogs-scrum/).

Users can now change **sprints and backlog buckets using bulk edit**, making it easier to reorganize multiple work packages at once.

Changes to a work package's **backlog bucket** are now recorded in the Activity tab, just like changes to sprint assignments.

![Changes to a backlog bucket shown under activity tab of a work package in OpenProject](openproject_release_notes_17.8_backlog_bucket_changes_shown_under_activity_tab.png)

Sprint and backlog bucket cards can now be **dragged into external applications**. Depending on the target application, dropping a card into a chat, text editor, another browser window, or rich-text editor provides a usable link to the OpenProject work package.

When creating a new Scrum demo project, the default **Epic** and **User story** work package types now include an embedded related work package table showing their children. This makes it easier to see related work directly on the work package page and demonstrates how embedded related work package tables can be used.


### Wiki improvements

OpenProject 17.8 brings further improvements to [project wikis](../../user-guide/wiki/).

The term **internal wiki** has been replaced with **project wiki** throughout the interface, making the distinction from external wiki integrations such as XWiki clearer. The project wiki provider is called OpenProject.

The project wiki settings remain accessible even when project wikis have been disabled instance-wide, with an explanation of why the feature is unavailable.

The **project wiki sidebar now makes it easier to navigate the wiki hierarchy**. Pages are collapsed by default and can be expanded to show their sub-pages. When opening a page, its parent pages are automatically expanded, and a search field lets users filter the hierarchy while showing where matching pages are located.

![Wiki pages navigation on a project level in OpenProject](openproject_release_notes_17.8_wiki_page_navigation.png)



The [create and edit page](../../user-guide/wiki/create-edit-wiki/) has been updated with a modernized user interface.

![Creating a project wiki page with the updated interface](openproject_release_notes_17.8_wiki_create_page.png)

The **Create page** dialog improves a parent page selection, making it possible to create root pages directly. The parent selection step is now labeled **Parent**.

![Adding a wiki as the parent when creating a new wiki page in OpenProject](openproject_release_notes_17.8_wiki_new_page_creation_parent.png)

Finally, wiki link and creation macros, such as **Existing wiki page** and **New wiki page**, are available in more rich text editors, including meeting descriptions, outcomes, comments, wiki page content, and text custom fields.

### Milestones and sprints are displayed in the project timeline widget

The **[Project timeline](../../user-guide/projects/project-home/)** widget on the project overview now provides a more complete picture of important project dates by displaying **milestones and sprints alongside project phases**.

![Milestones and sprints displayed in the project timeline widget](openproject_release_notes_17.8_project_timeline_milestones_sprints.png)

Milestones are displayed below the project phases and link directly to their work package full view. A footer link also lets users open all milestones in the Gantt chart.

Sprints are displayed below milestones. They are shown as read-only items and cannot be moved using drag and drop. A footer link leads to the sprints overview.

If the Backlogs module is disabled for a project, sprints are automatically hidden from the timeline. If a user lacks necessary permissions, the widget remains empty.  

### Improved work package identifiers and search

Search results and autocompleters now **prioritize exact identifier matches over fuzzy matches**. OpenProject also distinguishes correctly between project-based identifiers such as `ACSMT-5` and numerical work package IDs, including when identifiers are entered with a `#` prefix.

If a work package URL does not contain the canonical identifier of the work package, OpenProject now automatically corrects the URL in the browser without redirecting or reloading the page.

Searching for work packages from the BlockNote editor has also been improved. Searches triggered using shortcuts such as `#` or `/` now display a loading indicator as well as clear **No results** and **Error** states.

The BlockNote editor extensions additionally support a separate `proxyUrl` alongside `baseUrl`. This ensures that links generated for pasted or typed work package references point directly to OpenProject instead of through an integration proxy.

> [!NOTE]
> Project identifiers should not be treated as confidential information, even for private projects when project-based work package identifiers are enabled. Identifiers can become visible through public documents, anonymous access, or cross-project references.

### Meeting activity visible directly in work packages

The connection between [meetings](../../user-guide/meetings/) and work packages is more visible.

The **Activity** tab of a work package now shows when the work package was **added to a meeting, removed from a meeting, moved between meetings, or discussed in a meeting**. This also applies to meeting templates and meeting series.

![Meeting updates displayed in the Activity tab of a work package](openproject_release_notes_17.8_work_package_meeting_activity.png)

This gives users important meeting context directly in the work package without requiring them to open the separate Meetings tab.

For users who prefer a less detailed activity stream, a new **Hide meeting updates** filter can be used to collapse these entries.

### Administration and account page improvements

OpenProject 17.8 continues the modernization of administration and account pages with Primer UI components.

The **Create new account** page, project Overview actions, and additional legacy pages have received updated interfaces and improved inline validation.

The **More actions** menus on the project Overview and under *Project settings → Information* have also been reorganized and standardized. Archiving a project now uses a consistent danger-styled confirmation.

The authentication setting controlling who can create projects now includes a note explaining that users may be able to see project identifiers.

The page for creating a new two-factor authentication device during an enforced 2FA login has also been updated to the modern Primer-based interface. For more information, see the [two-factor authentication (2FA) documentation](../../system-admin-guide/authentication/two-factor-authentication/).

## Important updates and breaking changes

The Activity tab polling interval can now be configured using the `WORK_PACKAGES_ACTIVITIES_TAB_POLLING_INTERVAL_IN_MS` setting. Previously, this interval was hardcoded or configurable only through an environment variable.

Users can also reduce the minimum width of split-screen views to **430 px**, providing more room for the main content area. This applies to all split-screen views except the Gantt chart.

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Feature: Add possibility to order backlog buckets and sprints manually \[[#73610](https://community.openproject.org/wp/73610)\]
- Feature: Multi-select cards within backlog and sprints \[[#73729](https://community.openproject.org/wp/73729)\]
- Feature: Show children as related wp table for Epic and User story (default seeding) \[[#75940](https://community.openproject.org/wp/75940)\]
- Feature: Journalized backlog bucket  \[[#76020](https://community.openproject.org/wp/76020)\]
- Feature: Remove html from formattable properties \[[#72514](https://community.openproject.org/wp/72514)\]
- Feature: Prune links in MCP responses \[[#72515](https://community.openproject.org/wp/72515)\]
- Feature: Remove structured output schema functionality \[[#75403](https://community.openproject.org/wp/75403)\]
- Feature: Add pagination meta data to responses \[[#75404](https://community.openproject.org/wp/75404)\]
- Feature: Adjust CKEditor version macros: single-line/multi-line layout argument for attribute value macros \[[#76876](https://community.openproject.org/wp/76876)\]
- Feature: Fix the work package URL if it does not use the canoncial identifier of a work package \[[#77262](https://community.openproject.org/wp/77262)\]
- Feature: Primerise Branding tab of Admin/Design page \[[#56340](https://community.openproject.org/wp/56340)\]
- Feature: Implement a primerized page for creating a new 2FA device  \[[#56848](https://community.openproject.org/wp/56848)\]
- Feature: Create a new TableComponent based on Primer React&#39;s DataTable \[[#70204](https://community.openproject.org/wp/70204)\]
- Feature: Automatically upload PDF artefacts to project folder \[[#77321](https://community.openproject.org/wp/77321)\]
- Feature: Grouped types index page \[[#76546](https://community.openproject.org/wp/76546)\]
- Feature: Variants are shown everywhere using their parent type&#39;s name \[[#76547](https://community.openproject.org/wp/76547)\]
- Feature: Move workflows as a tab under type edit \[[#77228](https://community.openproject.org/wp/77228)\]
- Feature: All open view with default sort order to show the latest on top (ID descending) \[[#57962](https://community.openproject.org/wp/57962)\]
- Feature: Restrict Email addresses to certain domains \[[#70521](https://community.openproject.org/wp/70521)\]
- Feature: Annotate auth setting UI with security comment on project creation \[[#76856](https://community.openproject.org/wp/76856)\]
- Feature: Add milestones to the project lifecycle widget \[[#76749](https://community.openproject.org/wp/76749)\]
- Feature: Add sprints to the project lifecycle widget \[[#76750](https://community.openproject.org/wp/76750)\]
- Feature: Main menu item for Wikis linking to index page for all wiki pages \[[#74719](https://community.openproject.org/wp/74719)\]
- Feature: Select wiki to create main pages when creating new pages \[[#76146](https://community.openproject.org/wp/76146)\]
- Feature: Update internal wiki create/edit page with modern UI \[[#77225](https://community.openproject.org/wp/77225)\]
- Bugfix: &quot;Search&quot; placeholder is missing on the dropdown on sprints and backlog buckets \[[#76641](https://community.openproject.org/wp/76641)\]
- Feature: Planned and actual labour costs for generic project roles (placeholder users) \[[#48257](https://community.openproject.org/wp/48257)\]
- Feature: Automation to create PM²/PMflex artefacts \[[#69055](https://community.openproject.org/wp/69055)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->

## Contributions

A very special thank you goes to Helmholtz-Zentrum Berlin, City of Cologne, Deutsche Bahn and ZenDiS for sponsoring released or upcoming features. Your support, alongside the efforts of our amazing Community, helps drive these innovations.


Special thanks for reporting and finding bugs go to Christoph Jansen, Chris Kerrison, Laurent Redor, Gernot Hollinger, Thomas Knäuper, Gábor Alexovics, Rince wind.

Last but not least, we are very grateful for our very engaged translation contributors on Crowdin, who translated quite a few OpenProject strings. This release we would like to particularly thank the following users:

- [erdei.p](https://crowdin.com/profile/erdei.p), for translations into Turkish,
- [Tom Hykel](https://crowdin.com/profile/thykel) for translations into Czech,
- [Christophe Gesché](https://crowdin.com/profile/Moosh-be), for translations into French.

Would you like to help out with translations yourself? Then take a look at our [translation guide](../../contributions-guide/translate-openproject/) and find out exactly how you can contribute. It is very much appreciated!
