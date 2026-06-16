---
title: OpenProject 17.6.0
sidebar_navigation:
    title: 17.6.0
release_version: 17.6.0
release_date: 2026-06-10
---

# OpenProject 17.6.0

Release date: 2026-06-10

We released [OpenProject 17.6.0](https://community.openproject.org/versions/2298).
The release contains several bug fixes and we recommend updating to the newest version.
In these Release Notes, we will give an overview of important feature changes. At the end, you will find a complete list of all changes and bug fixes.
## Important feature changes

<!-- Inform about the major features in this section -->

## Important updates and breaking changes

### Integrations (e.g. Nextcloud and XWiki) respect global SSRF filters

To increase the security of OpenProject installations, we've added protections against server-side request forgery in previous releases
of OpenProject. These prevent OpenProject from making network requests into private IP address space.

Starting with OpenProject 17.6, these protections expand into the code that's responsible for web requests of storage and wiki integrations as well.
This means if you have a Nextcloud instance or an XWiki instance reachable via a private (i.e. not publicly routable) IP address, you need to
add it to the SSRF allowlist to be able to keep the integration working. This is usually achieved by defining the following environment variable:

```
OPENPROJECT_SSRF_PROTECTION_IP_ALLOWLIST=2001:db8:100::/48
```

The list accepts one or multiple IP addresses or ranges (in CIDR notation) that shall be exempt from SSRF filtering.

### Meeting API structure changes

17.6. introduces new endpoints for meeting outcomes,
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

- Feature: Exclude certain work package types from automated backlog (per project) \[[#71305](https://community.openproject.org/wp/71305)\]
- Feature: Container header (Sprint/Bucket/Inbox) restyling \[[#72945](https://community.openproject.org/wp/72945)\]
- Feature: Restyled work package card in &quot;Backlogs and sprints&quot; view \[[#73089](https://community.openproject.org/wp/73089)\]
- Feature: Bring sprint sharing (SAFe) to corporate plan \[[#74147](https://community.openproject.org/wp/74147)\]
- Feature: Create work package links through # notation in documents / BlockNote \[[#73664](https://community.openproject.org/wp/73664)\]
- Feature: Create a WorkPackageCard component  \[[#73968](https://community.openproject.org/wp/73968)\]
- Feature: Extend the SubHeader component to support quick filter components \[[#73972](https://community.openproject.org/wp/73972)\]
- Feature: Jira Migrator imports project-based semantic issue identifiers \[[#72427](https://community.openproject.org/wp/72427)\]
- Feature: Jira Migrator supports due date, estimated hours and remaining hours. \[[#74807](https://community.openproject.org/wp/74807)\]
- Feature: Meeting series: Add monthly scheduling options \[[#61522](https://community.openproject.org/wp/61522)\]
- Feature: Debounce emails for meetings \[[#66645](https://community.openproject.org/wp/66645)\]
- Feature: Primerize Types form configuration page \[[#69524](https://community.openproject.org/wp/69524)\]
- Feature: Expand work package mentions (##, ###) macros inside CKEditor \[[#74641](https://community.openproject.org/wp/74641)\]
- Feature: Allow Custom Fields on UserQuery \[[#74758](https://community.openproject.org/wp/74758)\]
- Feature: Primerize users administration to allow all filters \[[#74763](https://community.openproject.org/wp/74763)\]
- Feature: Workflows UX improvement: Allow multi-selection of roles in workflow \[[#72242](https://community.openproject.org/wp/72242)\]
- Feature: Administration setting for project-based work package identifiers \[[#71633](https://community.openproject.org/wp/71633)\]
- Feature: Background job for converting project-based semantic work package identifiers \[[#71645](https://community.openproject.org/wp/71645)\]
- Feature: Allow inline Work Package links within text paragraphs in the Documents module \[[#72817](https://community.openproject.org/wp/72817)\]
- Feature: Adapt creation of projects through the API for semantic identifiers \[[#73175](https://community.openproject.org/wp/73175)\]
- Feature: Define database model for project-based work package identifiers \[[#73315](https://community.openproject.org/wp/73315)\]
- Feature: Adapt work package show view for project-based semantic work package identifiers \[[#73716](https://community.openproject.org/wp/73716)\]
- Feature: Adapt work package lists for project-based semantic work package identifiers \[[#73717](https://community.openproject.org/wp/73717)\]
- Feature: Adapt routes for project-based semantic work package identifiers \[[#73756](https://community.openproject.org/wp/73756)\]
- Feature: Search work packages by their identifier \[[#73761](https://community.openproject.org/wp/73761)\]
- Feature: Adapt email notifications for project-based work package identifiers \[[#73827](https://community.openproject.org/wp/73827)\]
- Feature: Adapt work package link blocks in BlockNote for project-based semantic work package identifiers \[[#74115](https://community.openproject.org/wp/74115)\]
- Feature: Adapt work package links in CKEditor for project-based semantic work package identifiers \[[#74116](https://community.openproject.org/wp/74116)\]
- Feature: Adapt GitHub and GitLab modules for semantic identifiers \[[#74364](https://community.openproject.org/wp/74364)\]
- Feature: Adapt work package PDF exports for semantic identifiers \[[#74366](https://community.openproject.org/wp/74366)\]
- Feature: Add better progress indicator to identifier conversion page \[[#74903](https://community.openproject.org/wp/74903)\]
- Feature: Put &quot;Beta&quot; label on the setting for enabling semantic identifiers \[[#74975](https://community.openproject.org/wp/74975)\]
- Feature: Admin panel for releasing old classic project aliases \[[#74992](https://community.openproject.org/wp/74992)\]
- Bugfix: Closed work packages are still considered to be part of the bucket. \[[#74773](https://community.openproject.org/wp/74773)\]
- Bugfix: Inconsistent handling of &quot;Definition of Done&quot; \[[#74796](https://community.openproject.org/wp/74796)\]
- Bugfix: Backlogs: Missing space on mobile \[[#75188](https://community.openproject.org/wp/75188)\]
- Bugfix: Sprint field is sometimes not visible on the wp page \[[#75194](https://community.openproject.org/wp/75194)\]
- Bugfix: Backlog settings tab switching doesn&#39;t persist in url \[[#75239](https://community.openproject.org/wp/75239)\]
- Bugfix: No &quot;Undisclosed&quot; mention for the parent work package on the wp card for a user without permissions to see the parent \[[#75241](https://community.openproject.org/wp/75241)\]
- Bugfix: Incorrect resize behavior for pasted inline-links \[[#74190](https://community.openproject.org/wp/74190)\]
- Bugfix: Inserting &quot;#&quot; inside text removes content after cursor \[[#74325](https://community.openproject.org/wp/74325)\]
- Bugfix: Сards converting to hash links on copy-paste and DnD \[[#74327](https://community.openproject.org/wp/74327)\]
- Bugfix: Type colors are not applied correctly at the beginning \[[#74330](https://community.openproject.org/wp/74330)\]
- Bugfix: Inconsistent contrast for type colors when switching themes \[[#74332](https://community.openproject.org/wp/74332)\]
- Bugfix: Dropdown option order changes depending on selected item \[[#74333](https://community.openproject.org/wp/74333)\]
- Bugfix: Inconsistent inline-link heights in text flow \[[#74341](https://community.openproject.org/wp/74341)\]
- Bugfix: Inline work package chip has no visual highlight when selected \[[#74385](https://community.openproject.org/wp/74385)\]
- Bugfix: Arrow-down selection for link work package block prevented by tooltip \[[#74393](https://community.openproject.org/wp/74393)\]
- Bugfix: Wrong cursor placement after inserting links to Work Packages in BlockNote \[[#74397](https://community.openproject.org/wp/74397)\]
- Bugfix: Improve size menu and remove L+XL blocks \[[#74651](https://community.openproject.org/wp/74651)\]
- Bugfix: Click position is lost when activating an inline edit field \[[#72837](https://community.openproject.org/wp/72837)\]
- Bugfix: Doubled scrollbar on a Board \[[#73714](https://community.openproject.org/wp/73714)\]
- Bugfix: Quick filters don&#39;t react good to medium screen sizes \[[#74832](https://community.openproject.org/wp/74832)\]
- Bugfix: Hide pagination buttons when they are disabled \[[#75258](https://community.openproject.org/wp/75258)\]
- Bugfix: Horizontal ellipsis button misaligned when text expanded on Permissions Report/Workflows pages \[[#75275](https://community.openproject.org/wp/75275)\]
- Bugfix: Jira Migrator: misalignement between the status badge and the import name \[[#72840](https://community.openproject.org/wp/72840)\]
- Bugfix: Imprecise error for unallowed IP when testing Jira connection \[[#75031](https://community.openproject.org/wp/75031)\]
- Bugfix: Imprecise error for SSL errors when testing Jira connection \[[#75032](https://community.openproject.org/wp/75032)\]
- Bugfix: Jira Migrator cannot import a user with non-alphanumeric characters in their name \[[#75238](https://community.openproject.org/wp/75238)\]
- Bugfix: Jira Migrator stops the import for non-existing user in user mention \[[#75248](https://community.openproject.org/wp/75248)\]
- Bugfix: Remove extra space in Jira Migrator backup warning dialog \[[#75353](https://community.openproject.org/wp/75353)\]
- Bugfix: Jira Migrator does not scope issues between import runs. \[[#75355](https://community.openproject.org/wp/75355)\]
- Bugfix: Jira Migrator shows 0 issues info if server does not include the data in serverInfo endpoint \[[#75380](https://community.openproject.org/wp/75380)\]
- Bugfix: Jira Migrator gives unhelpful error message if user email is blank \[[#75381](https://community.openproject.org/wp/75381)\]
- Bugfix: No way to find jira import run history page \[[#75382](https://community.openproject.org/wp/75382)\]
- Bugfix: Enabled rate limiting on Jira instance breaks projects selector. \[[#75391](https://community.openproject.org/wp/75391)\]
- Bugfix: Wrong wording on import page in admin \[[#75422](https://community.openproject.org/wp/75422)\]
- Bugfix: Jira Migrator: Do not disable the new configuration button if the instance is not switched to semantic identifiers \[[#75674](https://community.openproject.org/wp/75674)\]
- Bugfix: Cancel occurence action item is called &#39;Delete&#39; on My Meetings page and Meeting index page &#39;Past&#39; tab \[[#74303](https://community.openproject.org/wp/74303)\]
- Bugfix: User cannot restore a cancelled occurrence if series has a deleted WP on the agenda \[[#74304](https://community.openproject.org/wp/74304)\]
- Bugfix: Show default section more clearly when using the section selector for a meeting with no sections \[[#74321](https://community.openproject.org/wp/74321)\]
- Bugfix: Meetings endpoint /api/v3/recurring\_meetings/:id/occurrences/:start\_time/init is not properly authorized \[[#75449](https://community.openproject.org/wp/75449)\]
- Bugfix: ActiveRecord::InvalidForeignKey on RecurringMeetingsController#end\_series \[[#75463](https://community.openproject.org/wp/75463)\]
- Bugfix: Work package configuration dialog&#39;s highlighting tab has no space between radio buttons and labels \[[#64359](https://community.openproject.org/wp/64359)\]
- Bugfix: Log time modal dropdown&#39;s bottom border is indistignuishable from the modal&#39;s bottom border \[[#65523](https://community.openproject.org/wp/65523)\]
- Bugfix: Wrong calendar week in My time tracking \[[#68272](https://community.openproject.org/wp/68272)\]
- Bugfix: Asterisks on Project attributes displaced \[[#68633](https://community.openproject.org/wp/68633)\]
- Bugfix: \[Meetings\] Exception raised while trying to update Stale Object \[[#68703](https://community.openproject.org/wp/68703)\]
- Bugfix: Clicking work package tabs triggers page reload and flickering \[[#69210](https://community.openproject.org/wp/69210)\]
- Bugfix: Mobile - Include project on WP list is missing spacing \[[#69451](https://community.openproject.org/wp/69451)\]
- Bugfix: Roles selectable as &quot;Role given to a non-admin user who creates a project&quot; that lack essential permissions \[[#69496](https://community.openproject.org/wp/69496)\]
- Bugfix: Text overflow in Baseline modal banner \[[#69526](https://community.openproject.org/wp/69526)\]
- Bugfix: Fix accessibility errors found by ERB Lint \[[#70166](https://community.openproject.org/wp/70166)\]
- Bugfix: Role not created properly when unselecting all permissions \[[#73494](https://community.openproject.org/wp/73494)\]
- Bugfix: POST/PATCH/DELETE requests to APIv3 return unauthorized \[[#73499](https://community.openproject.org/wp/73499)\]
- Bugfix: &quot;Upgrade&quot; button label should not be underlined \[[#73570](https://community.openproject.org/wp/73570)\]
- Bugfix: Not possible to filter for blocked users in time and cost report \[[#73660](https://community.openproject.org/wp/73660)\]
- Bugfix: Not possible to follow link custom field from work package list view \[[#73673](https://community.openproject.org/wp/73673)\]
- Bugfix: Black font in dark mode on wp description \[[#74697](https://community.openproject.org/wp/74697)\]
- Bugfix: Add upcoming/past filter to meetings index page filters \[[#74743](https://community.openproject.org/wp/74743)\]
- Bugfix: Redirect to /login is missing the URL query params \[[#74778](https://community.openproject.org/wp/74778)\]
- Bugfix: Missing space between user avatar and name \[[#74853](https://community.openproject.org/wp/74853)\]
- Bugfix: LDAP seeding via OPENPROJECT\_SEED\_LDAP\_\* uses a different (and self-contradictory) key convention than the rest of the env-var settings \[[#75361](https://community.openproject.org/wp/75361)\]
- Bugfix: Incorrect confirmation message when deleting a OAuth token \[[#72958](https://community.openproject.org/wp/72958)\]
- Bugfix: Roles select panel button should be &quot;Apply&quot; \[[#74560](https://community.openproject.org/wp/74560)\]
- Bugfix: Nextcloud integration shows &quot;No connection to Nextcloud&quot; for folders that have &quot;&amp;&quot; in the name \[[#73855](https://community.openproject.org/wp/73855)\]
- Bugfix: Shared work package not showing images of comments \[[#69056](https://community.openproject.org/wp/69056)\]
- Bugfix: Lists of work packages should sort correctly by semantic id \[[#74156](https://community.openproject.org/wp/74156)\]
- Bugfix: Automatically converting project identifiers should not lead to usage of reserved keywords \[[#74161](https://community.openproject.org/wp/74161)\]
- Bugfix: Moving work packages after switching to semantic and back should not lead to errors \[[#74192](https://community.openproject.org/wp/74192)\]
- Bugfix: After migration job is complete save button is visible and clicking it triggers a 404 \[[#74623](https://community.openproject.org/wp/74623)\]
- Bugfix: Admin page for semantic IDs: grammatical issue \[[#74681](https://community.openproject.org/wp/74681)\]
- Bugfix: Admin page for semantic IDs: long ids cause overflow \[[#74730](https://community.openproject.org/wp/74730)\]
- Bugfix: Numeric ID still in the URL of the link opened from the email notification \[[#74760](https://community.openproject.org/wp/74760)\]
- Bugfix: Numeric ID in the email notification after adding watchers \[[#74762](https://community.openproject.org/wp/74762)\]
- Bugfix: Numeric ID copied instead of semantic ID in &quot;Copy work package ID&quot; on Backlogs page \[[#74826](https://community.openproject.org/wp/74826)\]
- Bugfix: Numeric ID in URL of the wp link when opened from search results \[[#74834](https://community.openproject.org/wp/74834)\]
- Bugfix: Semantic ID is not shown in search results in different places \[[#74844](https://community.openproject.org/wp/74844)\]
- Bugfix: Numeric ID instead of semantic one in the spent time calendar  \[[#74900](https://community.openproject.org/wp/74900)\]
- Bugfix: Numeric ID instead of semantic one on the Activity page \[[#74912](https://community.openproject.org/wp/74912)\]
- Bugfix: Numeric ID instead of semantic one in Roadmap \[[#74913](https://community.openproject.org/wp/74913)\]
- Bugfix: Numeric ID instead of semantic one in bulk edit work packages \[[#74926](https://community.openproject.org/wp/74926)\]
- Bugfix: Unable to change a parent on bulk edit of work packages with semantic ID  \[[#74927](https://community.openproject.org/wp/74927)\]
- Bugfix: Numeric ID instead of semantic one on the error message on bulk edit \[[#74928](https://community.openproject.org/wp/74928)\]
- Bugfix: Numeric ID instead of semantic one on the table of related work packages \[[#74942](https://community.openproject.org/wp/74942)\]
- Bugfix: Numeric ID instead of semantic one on the Time and costs report \[[#74943](https://community.openproject.org/wp/74943)\]
- Bugfix: Numeric ID instead of semantic one on the wp delete confirmation dialogue \[[#74944](https://community.openproject.org/wp/74944)\]
- Bugfix: All-numeric project identifiers are not properly handled in classic mode \[[#74993](https://community.openproject.org/wp/74993)\]
- Bugfix: Numeric ID visible in edit mode in links with #  \[[#75180](https://community.openproject.org/wp/75180)\]
- Bugfix: Inconsistent naming on admin page \[[#75362](https://community.openproject.org/wp/75362)\]
- Bugfix: Reserved project identifiers: UI fails silently with 404 console error when acting on a deleted project \[[#75483](https://community.openproject.org/wp/75483)\]
- Bugfix: workPackageValue:ID:attribute macros failing with semantic IDs \[[#75574](https://community.openproject.org/wp/75574)\]
- Bugfix: Numeric ID showing in Github tab on work packages without links to PRs \[[#75636](https://community.openproject.org/wp/75636)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->

## Contributions
A very special thank you goes to our sponsors for this release.
Also a big thanks to our Community members for reporting bugs and helping us identify and provide fixes.
Special thanks for reporting and finding bugs go to Rince wind, Walid Ibrahim, Gábor Alexovics, Brandon Soonaye, Mohammed Mohiuddin.

Last but not least, we are very grateful for our very engaged translation contributors on Crowdin, who translated quite a few OpenProject strings!
Would you like to help out with translations yourself?
Then take a look at our translation guide and find out exactly how you can contribute.
It is very much appreciated!
