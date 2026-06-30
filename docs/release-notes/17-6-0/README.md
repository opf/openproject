---
title: OpenProject 17.6.0
sidebar_navigation:
    title: 17.6.0
release_version: 17.6.0
release_date: 2026-07-08
---

# OpenProject 17.6.0

Release date: 2026-07-08

We released [OpenProject 17.6.0](https://community.openproject.org/versions/2298).
The release contains several bug fixes and we recommend updating to the newest version.
In these Release Notes, we will give an overview of important feature changes. At the end, you will find a complete list of all changes and bug fixes.

## Important feature changes

OpenProject 17.6 continues our vision of providing a comprehensive open source platform for project management and collaboration. The new XWiki integration brings project management and enterprise knowledge management closer together, while further improvements for Backlogs, Meetings, and administration help teams plan, collaborate, and execute their work more efficiently.

Take a look at our release video showing the most important features introduced in OpenProject 17.6.0:

![Release video of OpenProject 17.6](https://openproject-docs.s3.eu-central-1.amazonaws.com/videos/OpenProject_17_6_release.mp4)

### XWiki integration (Enterprise add-on)

[feature: xwiki_integration ]

OpenProject 17.6 introduces a new integration with XWiki, enabling teams to connect project work and documentation more closely. Together, OpenProject and XWiki provide an **integrated open source solution** for organizations looking to manage both projects and documentation on their own infrastructure. This makes the integration a natural choice for existing XWiki users and for organizations looking to replace proprietary combinations such as Jira and Confluence with a sovereign open source solution. [Learn more about the motivation behind the integration and our collaboration with XWiki in our dedicated blog article](https://www.openproject.org/blog/x.wiki-integration).

![OpenProject XWiki integration: Wiki providers overview with listed XWiki](openproject_system_administration_wiki_providers.png) 

With the new integration, work packages now include a **dedicated Wiki tab** where users can view related wiki pages, create new pages, and link existing content from XWiki. This makes it easier to access relevant documentation directly from the work package where the work is planned and executed.

The integration also supports **references between OpenProject and XWiki**. Users can see which wiki pages reference a work package and insert links to wiki pages directly from descriptions, comments, and documents. This helps teams keep project work and documentation connected across both platforms.

![OpenProject XWiki integration: 'Wikis' tab in a work package, with a linked XWiki and a 'Referenced in' link to another XWiki page, and option to add a wiki](openproject_work_package_xwiki_tab_referenced.png)

> [!NOTE]
> OpenProject's built-in [wiki module](../../user-guide/wiki/) remains available and continues to be supported. In future releases, we also plan to further improve it. The XWiki integration is designed for organizations that require advanced wiki and documentation capabilities. It is available as an Enterprise add-on in the Corporate plan.

### Sprint goals

OpenProject 17.6 introduces sprint goals for Backlogs. When creating or editing a sprint, you can now define a sprint goal directly within the sprint settings.

The sprint goal is then displayed on the sprint header, making it visible to everyone working on the sprint.

![Edit sprint view with field to manually enter a sprint goal](openproject-17-6-sprint-goals.png)

### All sprints overview

OpenProject 17.6 introduces a new **All sprints** view in the Backlogs module. The new page provides an overview of all sprints in a project.

For each sprint, the overview displays key information such as its status, start and finish dates, and the number of assigned work packages.

![OpenProject Agile project, Backlogs module and 'All sprints' view with the following columns: Sprint name, Status (Completed or In planning), Start date, Finish date, Work packages (number included)](openproject-17-6-all-sprints.png)

### Display backlog buckets in work packages

OpenProject 17.6 introduces a new **Backlog bucket attribute for work packages**. If enabled for a work package type, users can view and manage backlog bucket assignments directly from the work package details.

Work packages can now be assigned to backlog buckets without navigating to the Backlogs module. Since a work package can only belong to either a sprint or a backlog bucket, selecting one will automatically remove the other assignment.

![User story work package in OpenProject with backlog bucket dropdown](openproject-17-6-backlog-bucket-work-package.png)

### Group, sort and filter work packages by backlog bucket

OpenProject 17.6 adds support for backlog buckets in work package tables. You can now add the Backlog bucket column to a work package table and use it to filter, sort, and group work packages.

This makes backlog bucket assignments visible in work package tables, allowing teams to organize, filter, and analyze backlog items more effectively.

![Work package table with highlighted Backlog bucket column](openproject-17-6-backlog-bucket-work-package-table-highlighted.png)

### Support project-based (semantic) identifiers in exports

OpenProject 17.6 extends support for project-based (semantic) identifiers across exports. Semantic identifiers are now included consistently in:

- Excel and CSV exports
- Meeting PDF exports
- Timesheet PDF exports

This ensures that exported data uses the same identifiers that users see throughout OpenProject.

### Unreserve old project-based (semantic) identifiers

OpenProject 17.6 extends support for reserved project identifiers to project-based (semantic) identifiers. When a project identifier is renamed, previous identifiers remain reserved so that existing links and integrations continue to work.

Administrators can now unreserve old project-based (semantic) identifiers and make them available for reuse by other projects.

![Admin setting with a list of projects and their identifiers and an "Unreserve" button next to each](openproject-17-6-reserved-project-identifiers.png)

### Convert meeting agenda items into work packages

OpenProject 17.6 adds a new **Convert to work package** action for meeting agenda items. This allows users to turn agenda items directly into work packages without leaving the meeting.

The newly created work package remains linked to the agenda item, helping teams connect meeting discussions with follow-up work.

![Meeting with agenda item three dots (more) menu opened and option to "Convert to work package"](openproject-17-6-meeting-work-packages-highlighted.png)

### Configure cost types per project

OpenProject 17.6 introduces project-specific cost type configuration. Project administrators can now control which cost types are available within each project.

To support this, project settings now include a new Time and costs section with a dedicated Cost types tab where available cost types can be configured.

![Time and Costs setting in a project with Cost types overview](openproject-17-6-cost-types-project-setting.png)

## Important technical changes

### Escape control characters in CSV exports

OpenProject 17.6 improves CSV export security by escaping control characters in exported data. This helps prevent spreadsheet applications from interpreting exported values in unintended ways.

If you need to escape unmodified machine-readable CSV exports, you can disable this flag on the new Exports page Administration → System settings → Exports

### Configure LDAP group synchronization using group member attributes (Enterprise add-on)

[feature: ldap_groups ]

OpenProject 17.6 extends LDAP group synchronization with support for group member attributes. Administrators can now configure synchronization based on attributes such as `member` or `uniqueMember` on LDAP groups, in addition to the existing `memberOf` lookup on user entries.

This improves compatibility with LDAP servers that do not maintain the `memberOf` attribute. Read more about [synchronizing LDAP and OpenProject groups](Enterprise add-on)(../../system-admin-guide/authentication/ldap-connections/ldap-group-synchronization)

### Integrations (e.g. Nextcloud and XWiki) respect global SSRF filters

To increase the security of OpenProject installations, we've added protections against server-side request forgery in previous releases
of OpenProject. These prevent OpenProject from making network requests into private IP address space.

Starting with OpenProject 17.6, these protections also apply to web requests made by storage and wiki integrations.
This means if you have a Nextcloud instance or an XWiki instance reachable via a private (i.e. not publicly routable) IP address, you need to
add it to the SSRF allowlist to be able to keep the integration working. This is usually achieved by defining the following environment variable:

```
OPENPROJECT_SSRF_PROTECTION_IP_ALLOWLIST=2001:db8:100::/48
```

The list accepts one or multiple IP addresses or ranges (in CIDR notation) that shall be exempt from SSRF filtering.

### Meeting API structure changes

OpenProject 17.6 introduces new endpoints for meeting outcomes,
and changes the self link for all meeting related resources to be flat:

That means, some of the responses have changed:

POST/PATCH/DELETE `/api/v3/meetings/:id/agenda_items)` is no longer available,
they have been moved to the `/api/v3/meeting_agendas/` respectively. The same is true for outcomes and sections.

This follows the APIv3 standards, and also fixes a bug related to the self link.

<!-- BEGIN SECURITY FIXES AUTOMATED SECTION -->

<!-- END SECURITY FIXES AUTOMATED SECTION -->
<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Feature: Sprint goals \[[#71059](https://community.openproject.org/wp/71059)\]
- Feature: Display backlog bucket in work package page \[[#73887](https://community.openproject.org/wp/73887)\]
- Feature: &quot;Move to backlog bucket&quot; and &quot;move to backlog inbox&quot; menu option for work packages within the backlog module \[[#73925](https://community.openproject.org/wp/73925)\]
- Feature: &quot;All sprints&quot; view - simple list \[[#74594](https://community.openproject.org/wp/74594)\]
- Feature: Column, ordering and grouping by backlog bucket in work package list \[[#74653](https://community.openproject.org/wp/74653)\]
- Feature: Show message when work package with excluded type/status is moved to backlog and disappears \[[#74845](https://community.openproject.org/wp/74845)\]
- Feature: Fixed width of priority in work package card \[[#75750](https://community.openproject.org/wp/75750)\]
- Feature: Rearrange &quot;More&quot; menu options for backlog/sprint items for easier moving between sprints and backlogs \[[#75783](https://community.openproject.org/wp/75783)\]
- Feature: Check the accessibility on Flash messages \[[#63276](https://community.openproject.org/wp/63276)\]
- Feature: Add a &#39;Security&#39; page in Account settings \[[#65405](https://community.openproject.org/wp/65405)\]
- Feature: Remove newest projects in project widget on homepage \[[#74198](https://community.openproject.org/wp/74198)\]
- Feature: Make project hierarchy collapsable in the global project selector \[[#74625](https://community.openproject.org/wp/74625)\]
- Feature: Create work package out of Meeting Agenda Item \[[#57053](https://community.openproject.org/wp/57053)\]
- Feature: API for Meeting outcomes \[[#75393](https://community.openproject.org/wp/75393)\]
- Feature: Group synchronization through attributes of the group, not member/memberOf \[[#32812](https://community.openproject.org/wp/32812)\]
- Feature: Track working hours and availabilities for each user in the system \[[#34911](https://community.openproject.org/wp/34911)\]
- Feature: Allow cost types to be enabled/disabled per project \[[#42037](https://community.openproject.org/wp/42037)\]
- Feature: Add Departments and Organizational Management to depict the Org Chart \[[#72224](https://community.openproject.org/wp/72224)\]
- Feature: Primerize advanced filters component \[[#74380](https://community.openproject.org/wp/74380)\]
- Feature: Build select panel quickfilter for meeting index \[[#74725](https://community.openproject.org/wp/74725)\]
- Feature: Enforce order of subheader slots/quickfilters \[[#75013](https://community.openproject.org/wp/75013)\]
- Feature: Escape possible control characters in CSV export \[[#75486](https://community.openproject.org/wp/75486)\]
- Feature: Add canonical URL meta tags to Project and WP pages for crawler optimization \[[#73926](https://community.openproject.org/wp/73926)\]
- Feature: Adapt Excel and CSV exports for semantic identifiers \[[#74361](https://community.openproject.org/wp/74361)\]
- Feature: Adapt meeting PDF exports for semantic identifiers \[[#74755](https://community.openproject.org/wp/74755)\]
- Feature: Release old semantic identifiers \[[#74934](https://community.openproject.org/wp/74934)\]
- Feature: Adapt PDF Export of timesheets for semantic identifiers \[[#75015](https://community.openproject.org/wp/75015)\]
- Feature: /wp on an empty line should create a block work-package link, not an inline one \[[#75310](https://community.openproject.org/wp/75310)\]
- Feature: Create, update and delete a wiki provider of type xwiki \[[#72921](https://community.openproject.org/wp/72921)\]
- Feature: Create wiki tab \[[#72969](https://community.openproject.org/wp/72969)\]
- Feature: Create and delete relation wiki page links \[[#72970](https://community.openproject.org/wp/72970)\]
- Feature: Show inline wiki page links \[[#72971](https://community.openproject.org/wp/72971)\]
- Feature: Show list of wiki pages that reference the work package \[[#72972](https://community.openproject.org/wp/72972)\]
- Feature: Add health checks for external wiki integrations \[[#72978](https://community.openproject.org/wp/72978)\]
- Feature: Create macro for creating inline wiki page links with existing pages \[[#72986](https://community.openproject.org/wp/72986)\]
- Feature: Add option to create new wiki pages while inlining it \[[#72987](https://community.openproject.org/wp/72987)\]
- Feature: Create API for wiki page links \[[#73293](https://community.openproject.org/wp/73293)\]
- Feature: Extend wiki permissions \[[#73440](https://community.openproject.org/wp/73440)\]
- Feature: XWiki enterprise banner in admin settings \[[#73842](https://community.openproject.org/wp/73842)\]
- Feature: Restructure wiki tab content for new designs \[[#73909](https://community.openproject.org/wp/73909)\]
- Feature: Render macro in CKEditor editing mode \[[#74710](https://community.openproject.org/wp/74710)\]
- Feature: Update Icon for wiki providers \[[#74833](https://community.openproject.org/wp/74833)\]
- Feature: Expose installation UUID via API \[[#75442](https://community.openproject.org/wp/75442)\]
- Feature: Configure internal wiki provider \[[#75594](https://community.openproject.org/wp/75594)\]
- Feature: Allow to paste wiki page url in  &quot;link existing&quot; dialog \[[#75732](https://community.openproject.org/wp/75732)\]
- Feature: Rename CKEditor Macro to &quot;+ Insert&quot; \[[#75749](https://community.openproject.org/wp/75749)\]
- Feature: Show XWiki&#39;s mentiones in the &quot;Referenced in&quot; section of the tab \[[#75960](https://community.openproject.org/wp/75960)\]
- Feature: Rename inline page links to &quot;Mentioned in description&quot; \[[#75968](https://community.openproject.org/wp/75968)\]
- Bugfix: NoMethodError on GET::API::V3::WorkPackages::WorkPackagesAPI#/work\_packages/  \[[#75693](https://community.openproject.org/wp/75693)\]
- Bugfix: &quot;Move to inbox&quot; menu entry is missing the word &quot;backlog&quot; \[[#76014](https://community.openproject.org/wp/76014)\]
- Bugfix: Copy/paste of a single work package link does not work \[[#74538](https://community.openproject.org/wp/74538)\]
- Bugfix: Dragging text selection containing a inline-link creates a copy instead of moving it \[[#74540](https://community.openproject.org/wp/74540)\]
- Bugfix: Inline-to-card resize should split the surrounding sentence \[[#74978](https://community.openproject.org/wp/74978)\]
- Bugfix: Work package links still use only the numeric ID for copy-paste and markdown generation \[[#75562](https://community.openproject.org/wp/75562)\]
- Bugfix: Dragging a work package link reloads the data via the network \[[#75910](https://community.openproject.org/wp/75910)\]
- Bugfix: Work package titles should not be cut off for inline work package links in documents \[[#75977](https://community.openproject.org/wp/75977)\]
- Bugfix: Inline work package links which the user can not access should have a speaking message \[[#76016](https://community.openproject.org/wp/76016)\]
- Bugfix: Email header and footer language drop-down is misplaced \[[#65906](https://community.openproject.org/wp/65906)\]
- Bugfix: Fix browser warnings \[[#68790](https://community.openproject.org/wp/68790)\]
- Bugfix: A missing full stop at the end of confirmation message of danger dialog  \[[#73899](https://community.openproject.org/wp/73899)\]
- Bugfix: Impossible to open work packages list from the sidebar after visiting team planner \[[#74331](https://community.openproject.org/wp/74331)\]
- Bugfix: Input group with trailing action clipboard copy button + validation error = style broken \[[#75395](https://community.openproject.org/wp/75395)\]
- Bugfix: Status labels are cut off on desktop and mobile \[[#75611](https://community.openproject.org/wp/75611)\]
- Bugfix: FilterableTreeView does not keep default filter arguments  \[[#75617](https://community.openproject.org/wp/75617)\]
- Bugfix: Tree view selection based on path identity breaks use cases where similar paths are allowed \[[#75618](https://community.openproject.org/wp/75618)\]
- Bugfix: Fix tracking expression browser warnings \[[#75676](https://community.openproject.org/wp/75676)\]
- Bugfix: Lazy loaded Action menu positioning is incorrect when opened at the bottom of the page. \[[#76023](https://community.openproject.org/wp/76023)\]
- Bugfix: VoiceOver automatically reads through page controls after full page reload \[[#76040](https://community.openproject.org/wp/76040)\]
- Bugfix: Meeting update banner reload action is difficult to reach by keyboard/screen reader \[[#76041](https://community.openproject.org/wp/76041)\]
- Bugfix: Cannot open project selector on mobile \[[#76065](https://community.openproject.org/wp/76065)\]
- Bugfix: Migrator: Attachment import with exception \[[#76082](https://community.openproject.org/wp/76082)\]
- Bugfix: GET /api/v3/meetings/{id}/agenda\_items returns incorrect section link format — unusable for PATCH and POST requests \[[#75615](https://community.openproject.org/wp/75615)\]
- Bugfix: GET /api/v3/meetings/{meeting\_id}/sections/{id} does not return the backlog section, but backlog items appear in GET /api/v3/meetings/{id}/agenda\_items \[[#75616](https://community.openproject.org/wp/75616)\]
- Bugfix: GET /api/v3/meetings/{id} — \_links.participants count does not match \_embedded.participants count \[[#75696](https://community.openproject.org/wp/75696)\]
- Bugfix: PATCH /api/v3/meetings/{id} — adding an already existing participant via \_links.participants creates a duplicate entry \[[#75697](https://community.openproject.org/wp/75697)\]
- Bugfix: PATCH /api/v3/meetings/{id} - participants cannot be removed via \_links.participants \[[#75701](https://community.openproject.org/wp/75701)\]
- Bugfix:  Data discrepancy between web and API for recurrent meetings \[[#75956](https://community.openproject.org/wp/75956)\]
- Bugfix: Not possible to switch meeting status to &#39;closed&#39; in API  \[[#76100](https://community.openproject.org/wp/76100)\]
- Bugfix: Backlog items are not shown in agenda\_items response \[[#76101](https://community.openproject.org/wp/76101)\]
- Bugfix: WP table configuration: overflow due to the very long CF label \[[#46005](https://community.openproject.org/wp/46005)\]
- Bugfix: Tooltip on Team planner not entirely visible  \[[#48223](https://community.openproject.org/wp/48223)\]
- Bugfix: Problems with GitLab and GitHub integration snippets \[[#56847](https://community.openproject.org/wp/56847)\]
- Bugfix: Misalignment of fields in Work estimates and progress when language=DE \[[#65738](https://community.openproject.org/wp/65738)\]
- Bugfix: Custom text widget pagination bug \[[#66419](https://community.openproject.org/wp/66419)\]
- Bugfix: Arrow for switching years barely visible in dark mode on the calendar \[[#68517](https://community.openproject.org/wp/68517)\]
- Bugfix: Login right side panel dark mode: login form has ugly/unnecessary gray background  \[[#69328](https://community.openproject.org/wp/69328)\]
- Bugfix: Infinite SAML Seeding Loop Causing Disk Space Exhaustion \[[#69339](https://community.openproject.org/wp/69339)\]
- Bugfix: User sees a success banner if they save a letter/word as integer \[[#71650](https://community.openproject.org/wp/71650)\]
- Bugfix: Closed, duplicated meeting disappears from synced calendar \[[#72219](https://community.openproject.org/wp/72219)\]
- Bugfix: Wrong icon used when changing non working days \[[#73372](https://community.openproject.org/wp/73372)\]
- Bugfix: User facing work package link from GitLab tab is not the shortened version \[[#73718](https://community.openproject.org/wp/73718)\]
- Bugfix: Inline text attachments lose UTF-8 charset \[[#75402](https://community.openproject.org/wp/75402)\]
- Bugfix: BCF import permission scope not clear \[[#75457](https://community.openproject.org/wp/75457)\]
- Bugfix: Reading large XML metadata files in SSO configuration freezes page, throws 504 \[[#75459](https://community.openproject.org/wp/75459)\]
- Bugfix: Hide &quot;my meetings&quot; and &quot;favourited projects&quot; widgets for anonymous users \[[#75477](https://community.openproject.org/wp/75477)\]
- Bugfix: Setting mail header via OPENPROJECT\_EMAILS\_\_HEADER\_EN interprets colon as hash \[[#75570](https://community.openproject.org/wp/75570)\]
- Bugfix: Notifications Center count badges clip large numbers \[[#75660](https://community.openproject.org/wp/75660)\]
- Bugfix: Previous work package opens in detail view from the wp list \[[#75819](https://community.openproject.org/wp/75819)\]
- Bugfix: Meeting not shown in &quot;All meetings&quot; in the meetings index page if there are no participants \[[#75957](https://community.openproject.org/wp/75957)\]
- Bugfix: Storage login button does not work \[[#75592](https://community.openproject.org/wp/75592)\]
- Bugfix: Attachment links from activity tab don&#39;t open in new tab as they do in files tab \[[#59942](https://community.openproject.org/wp/59942)\]
- Bugfix: Update text on Notification settings for clarity \[[#61128](https://community.openproject.org/wp/61128)\]
- Bugfix: Non helpful confirmation message after clicking &quot;Cancel&quot; of writing WP comment. Also &quot;Cancel&quot; --&gt; &quot;Dismiss&quot; \[[#62513](https://community.openproject.org/wp/62513)\]
- Bugfix: Comments show wrong date in their headline \[[#64251](https://community.openproject.org/wp/64251)\]
- Bugfix: PG::DatetimeFieldOverflow in Notifications::WorkflowJob#switch\_state \[[#65108](https://community.openproject.org/wp/65108)\]
- Bugfix: Label for the admin document types reflects &quot;priorities&quot; instead of &quot;types&quot; in it&#39;s messaging \[[#69304](https://community.openproject.org/wp/69304)\]
- Bugfix: Quickly clicking &quot;+ Document&quot; several times creates multiple documents \[[#69319](https://community.openproject.org/wp/69319)\]
- Bugfix: Documents admin page: &quot;+Type&quot; button has a wrong label (&quot;+Add&quot;) \[[#69498](https://community.openproject.org/wp/69498)\]
- Bugfix: Documents administration: Double line in more menu when only 1 type left \[[#69518](https://community.openproject.org/wp/69518)\]
- Bugfix: Real-time collaboration admin page: save button visible on read-only non-editable form \[[#69801](https://community.openproject.org/wp/69801)\]
- Bugfix: BlockNote: Drag and drop of table blocks broken \[[#71900](https://community.openproject.org/wp/71900)\]
- Bugfix: Community contribution: GitHub/GitLab - Fix incorrect linking of MR/PR to work packages \[[#72450](https://community.openproject.org/wp/72450)\]
- Bugfix: Copy &amp; Paste Loses Formatting in Documents \[[#73669](https://community.openproject.org/wp/73669)\]
- Bugfix: Chip/block blue border is clipped on the left side at the beginning of a line \[[#74979](https://community.openproject.org/wp/74979)\]
- Bugfix: Documents: impossible to delete characters with backspace after adding a wp link \[[#75669](https://community.openproject.org/wp/75669)\]
- Bugfix: Documents: tooltip on user&#39;s cursor cut off \[[#75682](https://community.openproject.org/wp/75682)\]
- Bugfix: Documents: long wp title causes overflow on wp search on mobile \[[#75683](https://community.openproject.org/wp/75683)\]
- Bugfix: Documents: work package link text and surrounding text not vertically aligned \[[#75690](https://community.openproject.org/wp/75690)\]
- Bugfix: Documents: wp link dropdown cut off at the bottom of the page \[[#75694](https://community.openproject.org/wp/75694)\]
- Bugfix: Documents: letters cut off at the bottom of the inline work package link \[[#75731](https://community.openproject.org/wp/75731)\]
- Bugfix: Documents: missing scroll into view behavior when using arrow key at the bottom of the page \[[#75733](https://community.openproject.org/wp/75733)\]
- Bugfix: Documents not working on exotic browsers \[[#75760](https://community.openproject.org/wp/75760)\]
- Bugfix: Letters after a space in the document type name are lowercase \[[#72838](https://community.openproject.org/wp/72838)\]
- Bugfix: Documents don&#39;t work properly with rails relative url \[[#75269](https://community.openproject.org/wp/75269)\]
- Bugfix: Feature flag for XWiki integration not force enabled \[[#76063](https://community.openproject.org/wp/76063)\]
- Bugfix: Spaces added around inline wiki page links \[[#76080](https://community.openproject.org/wp/76080)\]
- Feature: XWiki integration \[[#53738](https://community.openproject.org/wp/53738)\]
- Feature: Extend CKEditor with Wiki interactions and macros \[[#70554](https://community.openproject.org/wp/70554)\]
- Feature: Wiki tab in work package detail view \[[#70555](https://community.openproject.org/wp/70555)\]
- Feature: Wiki integration setup on OpenProject \[[#70556](https://community.openproject.org/wp/70556)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->

## Contributions

A very special thank you goes to Helmholtz-Zentrum Berlin, City of Cologne, Deutsche Bahn and ZenDiS for sponsoring released or upcoming features. Your support, alongside the efforts of our amazing Community, helps drive these innovations.

Also a big thanks to our Community members for reporting bugs and helping us identify and provide fixes. Special thanks for reporting and finding bugs go to Rince wind, Walid Ibrahim, Gábor Alexovics, Brandon Soonaye, and Mohammed Mohiuddin.

Last but not least, we are very grateful for our very engaged translation contributors on Crowdin, who translated quite a few OpenProject strings! This release we would like to particularly thank the following users:

- [OlhaTrotska](https://crowdin.com/profile/olhatrotska), for a great number of translations into Ukrainian.
- [Daniel Catarino](https://crowdin.com/profile/tradengport), for a great number of translations into Portuguese.
- [Raffaele Brevetti](https://crowdin.com/profile/rbrevetti), for a great number of translations into Italian.

Would you like to help out with translations yourself? Then take a look at our [translation guide](../../contributions-guide/translate-openproject/) and find out exactly how you can contribute. It is very much appreciated!