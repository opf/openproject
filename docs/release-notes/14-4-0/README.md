---
title: OpenProject 14.4.0
sidebar_navigation:
    title: 14.4.0
release_version: 14.4.0
release_date: 2024-08-01
---

# OpenProject 14.4.0

Release date: 2024-08-01

We released OpenProject [OpenProject 14.4.0](https://community.openproject.org/versions/2063). The release contains several bug fixes and we recommend updating to the newest version. 

In these Release Notes, we will give an overview of important technical updates as well as important feature changes. At the end, you will find a complete list of all changes and bug fixes.

## Important technical updates

### Extend API authentication to accept JWT issued by OpenID provider to other client

OpenProject 14.4 introduces a new feature that allows OpenID clients, such as Nextcloud servers, to use access tokens obtained from an OpenID provider, like Keycloak, as an authentication mechanism for the OpenProject API. This enhancement enables users to skip the OAuth grant flow, streamlining the authentication process.

With this feature, the OpenProject API will validate access tokens issued by the OpenID provider (Keycloak) by checking the token's signature and authenticating the user using the sub claim value. This integration ensures secure and efficient API authentication for OpenID clients.

For more details, see https://community.openproject.org/wp/55643.

### Improve error messages and logs of AMPF synchronization services/jobs

Text

For more details, see https://community.openproject.org/wp/56861.

## Important feature changes

### Personal settings: Dark mode

Text

For more details, see https://community.openproject.org/wp/36233.

### Project attributes: Separate permissions for viewing and editing

Text

For more details, see https://community.openproject.org/wp/50844.

### Status-based progress reporting: Freely input % complete values for statuses

Text

For more details, see https://community.openproject.org/wp/55803.

### Nextcloud storages: Connection validation

Text

For more details, see https://community.openproject.org/wp/55836.

### Project lists: Select/Exclude projects in project list explicitly via filter

Text

For more details, see https://community.openproject.org/wp/55233.

### Meetings: Saving a new agenda item does not automatically add another empty one

Text

For more details, see https://community.openproject.org/wp/55423.

### Meetings tab on work packages: Display related meetings chronologically

Text

For more details, see https://community.openproject.org/wp/56651.

### Design: Improve avatar color generation so that users with same names are distinguishable

Text

For more details, see https://community.openproject.org/wp/56325.

### Dropdown menu on work packages: Move "Copy link to clipboard" up

Text

For more details, see https://community.openproject.org/wp/56058.

### Add link to storage provider in storage edit view

Text

For more details, see https://community.openproject.org/wp/56045.

### Show changes of long text custom fields in the activity similar to changes in the description

Text

For more details, see https://community.openproject.org/wp/55280.

<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Bugfix: Project custom field set to searchable is not searchable  \[[#34363](https://community.openproject.org/wp/34363)\]
- Bugfix: Unclear that status cannot be updated when required custom field is set \[[#35556](https://community.openproject.org/wp/35556)\]
- Bugfix: Missing property in the response of api/v3/work\_packages/{id} JSON (path: \_links/copy)  \[[#41053](https://community.openproject.org/wp/41053)\]
- Bugfix:  undefined method \`path' for nil:NilClass when click attanchment \[[#41852](https://community.openproject.org/wp/41852)\]
- Bugfix: Breadcrumb and menu structure is inconsistent for user administration \[[#50109](https://community.openproject.org/wp/50109)\]
- Bugfix: "Time 1" label in Email reminders truncated when language=FR \[[#50607](https://community.openproject.org/wp/50607)\]
- Bugfix: Primer::OpenProject::InputGroup component text input breaks with captions \[[#51376](https://community.openproject.org/wp/51376)\]
- Bugfix: Cannot use placeholder user in filter "Assignee or belonging group" \[[#51399](https://community.openproject.org/wp/51399)\]
- Bugfix: Built-in API v3 DOC doesn't run REQUESTS (requested URL was not found on this server) \[[#51847](https://community.openproject.org/wp/51847)\]
- Bugfix: Can't escape from "Latest activity" query \[[#52759](https://community.openproject.org/wp/52759)\]
- Bugfix: Static queries are not highlighted in the side menu \[[#52954](https://community.openproject.org/wp/52954)\]
- Bugfix: Adding new task in a board shows unnecessary warning message when switching type \[[#53571](https://community.openproject.org/wp/53571)\]
- Bugfix: Default value is not saved on custom field creation, only on update \[[#53574](https://community.openproject.org/wp/53574)\]
- Bugfix: 'Mark all as read' clears already read notifications  \[[#53587](https://community.openproject.org/wp/53587)\]
- Bugfix: Status board: Column 'new' can be displayed twice \[[#53967](https://community.openproject.org/wp/53967)\]
- Bugfix: Project filters allow selection of archived projects: trigger an error \[[#54278](https://community.openproject.org/wp/54278)\]
- Bugfix: Milestones are showing the children ticket section \[[#54983](https://community.openproject.org/wp/54983)\]
- Bugfix: Copying a meeting in a project with no members omits creator as attendee \[[#55623](https://community.openproject.org/wp/55623)\]
- Bugfix: Docker-Compose OpenProject assets can't be loaded after update \[[#55776](https://community.openproject.org/wp/55776)\]
- Bugfix: Wiki: history compares only with most recent version and ignores previous selection \[[#55932](https://community.openproject.org/wp/55932)\]
- Bugfix: OneDrive/SharePoint storage with AMPF can be added as manual folder \[[#55939](https://community.openproject.org/wp/55939)\]
- Bugfix: Date CF cannot be set for users \[[#56033](https://community.openproject.org/wp/56033)\]
- Bugfix: \[BUG\] Gantt Diagrams not sorted alphabetically in the left side menu \[[#56042](https://community.openproject.org/wp/56042)\]
- Bugfix: Can't change default work package lists columns \[[#56059](https://community.openproject.org/wp/56059)\]
- Bugfix: Spacing between title and tabs in page headers is too small \[[#56060](https://community.openproject.org/wp/56060)\]
- Bugfix: \[AppSignal\]  TypeError for Gitlab Merge Request without description \[[#56065](https://community.openproject.org/wp/56065)\]
- Bugfix: Automatically created private view should be localized \[[#56138](https://community.openproject.org/wp/56138)\]
- Bugfix: Loading gif in notification center and enterprise videos have white background in dark mode \[[#56157](https://community.openproject.org/wp/56157)\]
- Bugfix: Not Display Attribute help texts for Date \[[#56189](https://community.openproject.org/wp/56189)\]
- Bugfix: Archived & Activated projects are not clearly distinguishable in project autocompleter. \[[#56247](https://community.openproject.org/wp/56247)\]
- Bugfix: Share drop down cut of when only a single user is shared with \[[#56292](https://community.openproject.org/wp/56292)\]
- Bugfix: Small Octicon changes required \[[#56337](https://community.openproject.org/wp/56337)\]
- Bugfix: Searching for text in work packages is not intuitive \[[#56398](https://community.openproject.org/wp/56398)\]
- Bugfix: NoMethodError in SlackNotificationJob#perform \[[#56435](https://community.openproject.org/wp/56435)\]
- Bugfix: Static queries are not highlighted in side menu \[[#56436](https://community.openproject.org/wp/56436)\]
- Bugfix: New agenda item cut off if the page is already filled \[[#56437](https://community.openproject.org/wp/56437)\]
- Bugfix: URI::InvalidURIError in SlackNotificationJob#perform \[[#56439](https://community.openproject.org/wp/56439)\]
- Bugfix: Buttons in Attribute help text modal are too close \[[#56445](https://community.openproject.org/wp/56445)\]
- Bugfix: Info banner breaks autocompleter dropdown in status board \[[#56447](https://community.openproject.org/wp/56447)\]
- Bugfix: Meetings: Invitation e-mail sent out even though "send e-mails" is de-selected (re-invite) \[[#56493](https://community.openproject.org/wp/56493)\]
- Bugfix: Breadcrumb and menu structure is inconsistent for work package administration \[[#56585](https://community.openproject.org/wp/56585)\]
- Bugfix: Some pages of Administration/Projects are missing a breadcrumb \[[#56586](https://community.openproject.org/wp/56586)\]
- Bugfix: Some administration pages are missing breadcrumbs and html titles \[[#56587](https://community.openproject.org/wp/56587)\]
- Bugfix: Community edition demo videos do not render \[[#56602](https://community.openproject.org/wp/56602)\]
- Bugfix: Background of login screen is inconistent \[[#56608](https://community.openproject.org/wp/56608)\]
- Bugfix: \[AppSignal\] TypeError Further errors for other hooks with missing information \[[#56609](https://community.openproject.org/wp/56609)\]
- Bugfix: Breadcrumb and menu structure is inconsistent for Email administration \[[#56614](https://community.openproject.org/wp/56614)\]
- Bugfix: Breadcrumb and menu structure is inconsistent for Authentication administration \[[#56615](https://community.openproject.org/wp/56615)\]
- Bugfix: Slack Integration page in Admin doesn't have breadcrumbs \[[#56622](https://community.openproject.org/wp/56622)\]
- Bugfix: Search bar stays open when redirecting to search results page \[[#56704](https://community.openproject.org/wp/56704)\]
- Bugfix: Meeting timestamp in edit form not the same as in details \[[#56771](https://community.openproject.org/wp/56771)\]
- Bugfix: Switching public state should also change the empty state \[[#56795](https://community.openproject.org/wp/56795)\]
- Bugfix: Dark mode: Wrong text color in Member selection \[[#56805](https://community.openproject.org/wp/56805)\]
- Bugfix: Slack Integration page in Admin doesn't have Save button \[[#56813](https://community.openproject.org/wp/56813)\]
- Bugfix: Don't blink custom fields form when hiding parts depending on field format \[[#56842](https://community.openproject.org/wp/56842)\]
- Bugfix: User cannot delete Nextcloud storage \[[#56845](https://community.openproject.org/wp/56845)\]
- Feature: Dark Mode for OpenProject \[[#36233](https://community.openproject.org/wp/36233)\]
- Feature: New permissions for project attributes on project level \[[#50844](https://community.openproject.org/wp/50844)\]
- Feature: Create a "Sidepanel" component for the right side panel of a layout (e.g. on Meetings page) \[[#54033](https://community.openproject.org/wp/54033)\]
- Feature: Replace angular sub menu with rails component \[[#55182](https://community.openproject.org/wp/55182)\]
- Feature: Select/Exclude projects in project list explicitly via filter \[[#55233](https://community.openproject.org/wp/55233)\]
- Feature: Show changes of long text custom fields in the activity similar to changes in the description \[[#55280](https://community.openproject.org/wp/55280)\]
- Feature: Meetings: Saving a new agenda item does not automatically add another empty one \[[#55423](https://community.openproject.org/wp/55423)\]
- Feature: Status-based progress mode: Allow users to freely input % complete values for statuses \[[#55803](https://community.openproject.org/wp/55803)\]
- Feature: Add "Connection validation" functionality for Nextcloud storages \[[#55836](https://community.openproject.org/wp/55836)\]
- Feature: Add link to storage provider in storage edit view \[[#56045](https://community.openproject.org/wp/56045)\]
- Feature: Move "Copy link to clipboard" \[[#56058](https://community.openproject.org/wp/56058)\]
- Feature: Add Nexctcloud back links to waffle menu \[[#56150](https://community.openproject.org/wp/56150)\]
- Feature: Add Nextcloud color theme and enable it \[[#56152](https://community.openproject.org/wp/56152)\]
- Feature: Create release 14.4 teaser, incl. feature image \[[#56218](https://community.openproject.org/wp/56218)\]
- Feature: Improve avatar color generation so that users with same names are distinguishable \[[#56325](https://community.openproject.org/wp/56325)\]
- Feature: Require explicit type selection on project change \[[#56331](https://community.openproject.org/wp/56331)\]
- Feature: Color of text and icons of primary buttons shall adapt when color is light \[[#56463](https://community.openproject.org/wp/56463)\]
- Feature: Transform modules menu in top menu into a Primer menu \[[#56507](https://community.openproject.org/wp/56507)\]
- Feature: Meetings tab: Display related meetings chronologically \[[#56651](https://community.openproject.org/wp/56651)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->

## Contributions
A very special thank you goes to our sponsors for this release.
Also a big thanks to our Community members for reporting bugs and helping us identify and provide fixes.
Special thanks for reporting and finding bugs go to Johan Bouduin, 俊侯 何, Sven Kunze, Marcel Carvalho, mac edit, Ivan Kuchin.

Last but not least, we are very grateful for our very engaged translation contributors on Crowdin, who translated quite a few OpenProject strings!
Would you like to help out with translations yourself?
Then take a look at our translation guide and find out exactly how you can contribute.
It is very much appreciated!
