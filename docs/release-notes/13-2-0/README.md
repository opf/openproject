---
title: OpenProject 13.2.0
sidebar_navigation:
    title: 13.2.0
release_version: 13.2.0
release_date: TBD
---

# OpenProject 13.2.0

Release date: TBD

We released [OpenProject 13.2.0](https://community.openproject.com/versions/1979).
The release contains several bug fixes and we recommend updating to the newest version.


## Important updates and breaking changes

<!-- Remove this section if empty, add to it in pull requests linking to tickets and provide information -->

<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Fixed: "Spent time" is not translated on overview page \[[#42646](https://community.openproject.com/wp/42646)\]
- Fixed: Notifications view is cut off on Samsung Galaxy S21 \[[#44221](https://community.openproject.com/wp/44221)\]
- Fixed: Project "Members" list names groups that are irrelevant for the project \[[#47613](https://community.openproject.com/wp/47613)\]
- Fixed: Dismiss action of the primer banner is not translated \[[#51360](https://community.openproject.com/wp/51360)\]
- Fixed: In mobile view, the primer banner does not take the full width \[[#51370](https://community.openproject.com/wp/51370)\]
- Fixed: Project.visible scope slower than it should be \[[#51706](https://community.openproject.com/wp/51706)\]
- Fixed: Ongoing meetings are not visible via the Meetings tab in work packages \[[#51715](https://community.openproject.com/wp/51715)\]
- Fixed: The Access Token expiry date not updated on refresh for FileStorage tokens \[[#51749](https://community.openproject.com/wp/51749)\]
- Fixed: Work package share permissions not in Work package permission group \[[#52086](https://community.openproject.com/wp/52086)\]
- Fixed: lockVersion missing in payload for API WP form when only having change_work_package_status permission \[[#52089](https://community.openproject.com/wp/52089)\]
- Fixed: Status cannot be changed in backlogs when only having change_work_package_status permission \[[#52090](https://community.openproject.com/wp/52090)\]
- Fixed: Primer tooltips are cut off in OpenProject \[[#52099](https://community.openproject.com/wp/52099)\]
- Fixed: Remaining hours field not renamed in backlogs forms \[[#52107](https://community.openproject.com/wp/52107)\]
- Fixed: WP full view applies the wrong styles \[[#52120](https://community.openproject.com/wp/52120)\]
- Fixed: Estimated time is not updated when a sub-WP is delete. \[[#52125](https://community.openproject.com/wp/52125)\]
- Changed: Shared with users can become assignee of the work package \[[#49527](https://community.openproject.com/wp/49527)\]
- Changed: Allow status change without Edit WP rights \[[#50849](https://community.openproject.com/wp/50849)\]
- Changed: Change calculation and name of Work and Remaining work \[[#50953](https://community.openproject.com/wp/50953)\]
- Changed: Gantt: shorten menu and add "Show relations" action \[[#51170](https://community.openproject.com/wp/51170)\]
- Changed: Enable manual project folders for OneDrive/SharePoint storages \[[#51362](https://community.openproject.com/wp/51362)\]
- Changed: Filter project member list \[[#51484](https://community.openproject.com/wp/51484)\]
- Changed: Use the new defaults on the project index page for page header and sidebar \[[#51678](https://community.openproject.com/wp/51678)\]
- Changed: Teaser the share feature in the Community edition \[[#51704](https://community.openproject.com/wp/51704)\]
- Changed: Show file links of files that are not available to the user in the cloud storage \[[#52013](https://community.openproject.com/wp/52013)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->

#### Contributions
A big thanks to community members for reporting bugs and helping us identifying and providing fixes.

Special thanks for reporting and finding bugs go to

Arun M, Patrick Massé, Richard Richter
