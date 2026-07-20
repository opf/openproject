---
title: OpenProject 17.7.0
sidebar_navigation:
    title: 17.7.0
release_version: 17.7.0
release_date: 2026-07-16
---

# OpenProject 17.7.0

Release date: 2026-07-16

We released [OpenProject 17.7.0](https://community.openproject.org/versions/2304).
The release contains several bug fixes and we recommend updating to the newest version.
In these Release Notes, we will give an overview of important feature changes. At the end, you will find a complete list of all changes and bug fixes.
## Important feature changes

<!-- Inform about the major features in this section -->

## Important updates and breaking changes

<!-- Remove this section if empty, add to it in pull requests linking to tickets and provide information -->

<!-- BEGIN SECURITY FIXES AUTOMATED SECTION -->

<!-- END SECURITY FIXES AUTOMATED SECTION -->
<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Feature: Add multi-select drop-down for sprint and backlog buckets \[[#73611](https://community.openproject.org/wp/73611)\]
- Feature: Add existing work packages within sprint and backlog containers menu \[[#74386](https://community.openproject.org/wp/74386)\]
- Feature: Foundations for improved Drag and Drop, gesture support \[[#76076](https://community.openproject.org/wp/76076)\]
- Feature: &quot;Add new work package&quot; option within the context menu for backlog buckets and backlog inbox \[[#76097](https://community.openproject.org/wp/76097)\]
- Feature: Multiple active sprints without sharing \[[#77079](https://community.openproject.org/wp/77079)\]
- Feature: Create a work package link when pasting a work package URL into BlockNote editor (Paste from clipboard) \[[#68818](https://community.openproject.org/wp/68818)\]
- Feature: Adapt BCF Export and Import for semantic identifiers \[[#74362](https://community.openproject.org/wp/74362)\]
- Feature: Remove the Beta label from semantic identifier mode \[[#75975](https://community.openproject.org/wp/75975)\]
- Feature: Short WP link should open the canonical URL of a work package \[[#76098](https://community.openproject.org/wp/76098)\]
- Feature: Move Colours page into a tab of Admin/Design page \[[#56343](https://community.openproject.org/wp/56343)\]
- Feature: Move Avatars setting into Account setttings \[[#69308](https://community.openproject.org/wp/69308)\]
- Feature: User danger dialog when deleting placeholder users \[[#70726](https://community.openproject.org/wp/70726)\]
- Feature: Configurable loading indication for filterable tree views with async filter input \[[#75620](https://community.openproject.org/wp/75620)\]
- Feature: Show project attributes as separate tab in a WorkPackage \[[#75699](https://community.openproject.org/wp/75699)\]
- Feature: Extend WorkPackage export to include PMflex artefacts export \[[#75702](https://community.openproject.org/wp/75702)\]
- Feature: User danger dialog when deleting repositories \[[#76540](https://community.openproject.org/wp/76540)\]
- Feature: Replace outdated danger zone when creating a backup \[[#77184](https://community.openproject.org/wp/77184)\]
- Feature: Add caption to recurring meeting create/edit forms to show end date/no. of occurrences \[[#71922](https://community.openproject.org/wp/71922)\]
- Feature: Add ability to fetch agenda items by WorkPackage ID via the API \[[#76296](https://community.openproject.org/wp/76296)\]
- Feature: Track working hours and availabilities for each user in the system \[[#34911](https://community.openproject.org/wp/34911)\]
- Feature: New Administration for User Custom Fields and Custom Field Sections \[[#72005](https://community.openproject.org/wp/72005)\]
- Feature: Add Departments and Organizational Management to depict the Org Chart \[[#72224](https://community.openproject.org/wp/72224)\]
- Feature: Extend LDAP Sync to build org structure \[[#73883](https://community.openproject.org/wp/73883)\]
- Feature: Build User Card View for Resource Management \[[#74095](https://community.openproject.org/wp/74095)\]
- Feature: Build Primer quickfilter \[[#74577](https://community.openproject.org/wp/74577)\]
- Feature: Add a field to the user profile that can be used to set the department \[[#75959](https://community.openproject.org/wp/75959)\]
- Feature: Select entire semantic ID on click on the work package ID \[[#76268](https://community.openproject.org/wp/76268)\]
- Feature: Extend demo seeds with departments, more users, working schedule \[[#76434](https://community.openproject.org/wp/76434)\]
- Feature: Special roles for User Attributes \[[#76451](https://community.openproject.org/wp/76451)\]
- Feature: Additional calculation operators for calculated fields \[[#76642](https://community.openproject.org/wp/76642)\]
- Feature: Improve date picker of the resource management pages \[[#76557](https://community.openproject.org/wp/76557)\]
- Feature: Add a setting to disable users editing their own email address \[[#76754](https://community.openproject.org/wp/76754)\]
- Feature: Improve status filtering for user administration \[[#76862](https://community.openproject.org/wp/76862)\]
- Feature: Optimise ARIA labels for inline page links and macros \[[#73930](https://community.openproject.org/wp/73930)\]
- Feature: PDF template &quot;Contract&quot;: remove forced header background and bold font style \[[#77447](https://community.openproject.org/wp/77447)\]
- Feature: Allow to configure SCIM client via environment variables \[[#76550](https://community.openproject.org/wp/76550)\]
- Feature: Filter project by portfolio and programm \[[#74718](https://community.openproject.org/wp/74718)\]
- Feature: Overview widget for project phases and gates \[[#76748](https://community.openproject.org/wp/76748)\]
- Feature: Setup an internal wiki from a project \[[#73260](https://community.openproject.org/wp/73260)\]
- Feature: Allow setup of Wiki Integration via environment variables \[[#73292](https://community.openproject.org/wp/73292)\]
- Feature: Promote wiki page with work package reference from list to relation wiki page link \[[#73344](https://community.openproject.org/wp/73344)\]
- Feature: Show wiki page hierarchy in search dialog \[[#75532](https://community.openproject.org/wp/75532)\]
- Feature: Add &quot;as parent&quot; badge to referencing wiki pages \[[#76145](https://community.openproject.org/wp/76145)\]
- Feature: Global wiki page index \[[#76743](https://community.openproject.org/wp/76743)\]
- Bugfix: Backlogs on mobile: cards move on scroll \[[#75139](https://community.openproject.org/wp/75139)\]
- Bugfix: Starting a sprint fails with HTTP 422 and generic error banner \[[#75958](https://community.openproject.org/wp/75958)\]
- Bugfix: Sprint link opens Backlog and sprints page without scrolling to a selected sprint \[[#76559](https://community.openproject.org/wp/76559)\]
- Bugfix: Backlogs: long title isn&#39;t truncated on &quot;add existing work packages&quot; modal \[[#77334](https://community.openproject.org/wp/77334)\]
- Bugfix: Backlogs: work packages from subprojects show on &quot;add existing work packages&quot; modal of the parent project \[[#77338](https://community.openproject.org/wp/77338)\]
- Bugfix: Address remaining open points \[[#77451](https://community.openproject.org/wp/77451)\]
- Bugfix: Multiple active sprints coexist with sharing if there was one active sprint in the subproject before sharing was enabled \[[#77498](https://community.openproject.org/wp/77498)\]
- Bugfix: Inline work package links which the user can not access should have a speaking message \[[#76016](https://community.openproject.org/wp/76016)\]
- Bugfix: Documents: block from the pasted link is highlighted  \[[#77456](https://community.openproject.org/wp/77456)\]
- Bugfix: Documents: cursor misplaced after block is created on work package url copy-paste \[[#77458](https://community.openproject.org/wp/77458)\]
- Bugfix: Mobile web: When deep linking to a comment the comment is not fully scrolled into view \[[#68221](https://community.openproject.org/wp/68221)\]
- Bugfix: Updating the activity anchor URL without a page load does not highlight the relevant target element \[[#68262](https://community.openproject.org/wp/68262)\]
- Bugfix: Quickly clicking &quot;+ Document&quot; several times creates multiple documents \[[#69319](https://community.openproject.org/wp/69319)\]
- Bugfix: Community contribution: GitHub/GitLab - Fix incorrect linking of MR/PR to work packages \[[#72450](https://community.openproject.org/wp/72450)\]
- Bugfix: Documents: impossible to delete characters with backspace after adding a wp link \[[#75669](https://community.openproject.org/wp/75669)\]
- Bugfix: Documents: Drag and drop of blocks only works when dragging over editor content \[[#76200](https://community.openproject.org/wp/76200)\]
- Bugfix: Activity tab: a comment arriving via polling is not reliably scrolled into view \[[#76458](https://community.openproject.org/wp/76458)\]
- Bugfix: Numeric id shown instead of semantic one on the error message while moving work packages between projects \[[#76912](https://community.openproject.org/wp/76912)\]
- Bugfix: WorkPackage::SemanticIdentifier::UnsupportedLookup in BulkController \[[#77341](https://community.openproject.org/wp/77341)\]
- Bugfix: Activity tab floods page with &quot;not found&quot; banners after session expiry \[[#77493](https://community.openproject.org/wp/77493)\]
- Bugfix: Comment field content overflows tooltip in &#39;My Spent Time&#39; calendar \[[#64175](https://community.openproject.org/wp/64175)\]
- Bugfix: \[minor\] Clarification needed in GitLab integration documentation (user vs role confusion) \[[#71353](https://community.openproject.org/wp/71353)\]
- Bugfix: Low contrast in dark mode: markdown-text editor \[[#64462](https://community.openproject.org/wp/64462)\]
- Bugfix: &quot;Subproject of&quot; dropdown border missing at bottom / dropdown cut off \[[#64592](https://community.openproject.org/wp/64592)\]
- Bugfix: A missing full stop at the end of confirmation message of danger dialog  \[[#73899](https://community.openproject.org/wp/73899)\]
- Bugfix: Lazy loaded Action menu positioning is incorrect when opened at the bottom of the page. \[[#76023](https://community.openproject.org/wp/76023)\]
- Bugfix: Cancelling inplace edit fields results in an error \[[#77246](https://community.openproject.org/wp/77246)\]
- Bugfix: &quot;New work package&quot; outcome form does not update placeholder description on changing types \[[#76440](https://community.openproject.org/wp/76440)\]
- Bugfix: For some meetings, moving from Agenda to Backlog cause 422 error \[[#77215](https://community.openproject.org/wp/77215)\]
- Bugfix: Translation error in &quot;add work package&quot; macro in WYSWIG \[[#40221](https://community.openproject.org/wp/40221)\]
- Bugfix: Misalignment of radio buttons on WP deletion \[[#44467](https://community.openproject.org/wp/44467)\]
- Bugfix: Custom text widget pagination bug \[[#66419](https://community.openproject.org/wp/66419)\]
- Bugfix: Arrow for switching years barely visible in dark mode on the calendar \[[#68517](https://community.openproject.org/wp/68517)\]
- Bugfix: Sign up errors are showing behind new account creation modal \[[#69793](https://community.openproject.org/wp/69793)\]
- Bugfix: WP search dropdown: wp created by deleted user has a weird layout with missing avatar \[[#70580](https://community.openproject.org/wp/70580)\]
- Bugfix: Inaccurate/incomplete error messaging when removing a WP type from a project \[[#70921](https://community.openproject.org/wp/70921)\]
- Bugfix: User sees a success banner if they save a letter/word as integer \[[#71650](https://community.openproject.org/wp/71650)\]
- Bugfix: Meeting global search resolves links in wrong project context \[[#74626](https://community.openproject.org/wp/74626)\]
- Bugfix: Multi-select workflows cannot bulk select/unselect rows/columns \[[#76541](https://community.openproject.org/wp/76541)\]
- Bugfix: Impossible to create team planner as it redirects to work packages page \[[#76651](https://community.openproject.org/wp/76651)\]
- Bugfix: When user receives a new notification while having the top one open in split view, then both top notifications look active \[[#76693](https://community.openproject.org/wp/76693)\]
- Bugfix: Users can deleted descendent work packages in projects they are not authorized to \[[#76930](https://community.openproject.org/wp/76930)\]
- Bugfix: ActionView::MissingTemplate in Search controller on unsupported content type \[[#77081](https://community.openproject.org/wp/77081)\]
- Bugfix: Use Label component to indicate user status \[[#76263](https://community.openproject.org/wp/76263)\]
- Bugfix: Form errors not shown during trial activation \[[#77340](https://community.openproject.org/wp/77340)\]
- Bugfix: Impossible to search for archived projects, page reverts to active projects list on its own \[[#71971](https://community.openproject.org/wp/71971)\]
- Bugfix: Nextcloud Anbindung Fehler &quot;&lt;Nextcloud-Hostname&gt; has no public IP addresses&quot; \[[#77278](https://community.openproject.org/wp/77278)\]
- Feature: New frontend for &#39;My account&#39; based on design system \[[#56584](https://community.openproject.org/wp/56584)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->
