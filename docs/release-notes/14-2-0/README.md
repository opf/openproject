---
title: OpenProject 14.2.0
sidebar_navigation:
    title: 14.2.0
release_version: 14.2.0
release_date: 2024-06-07
---

# OpenProject 14.2.0

Release date: 2024-06-19

We released [OpenProject 14.2.0](https://community.openproject.org/versions/2040).
The release contains several bug fixes and we recommend updating to the newest version.

## Important updates and breaking changes

<!-- Remove this section if empty, add to it in pull requests linking to tickets and provide information -->

<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Bugfix: Misleading Openproject Reconfigure wizard leading to undesired removal of Apache \[[#41293](https://community.openproject.org/wp/41293)\]
- Bugfix: Some buttons are missing on mobile screens on iOS Safari \[[#50724](https://community.openproject.org/wp/50724)\]
- Bugfix: Different headings in permission report and role form \[[#51447](https://community.openproject.org/wp/51447)\]
- Bugfix: Main menu resizer handle misplaced on hover \[[#52670](https://community.openproject.org/wp/52670)\]
- Bugfix: Error when sorting projects list by "latest activity at" \[[#53315](https://community.openproject.org/wp/53315)\]
- Bugfix: Query lost when sorting the project table quickly \[[#53329](https://community.openproject.org/wp/53329)\]
- Bugfix: Seeded demo project "Project plan" view should be in Gantt charts section \[[#53624](https://community.openproject.org/wp/53624)\]
- Bugfix: The label for "Spent time" is still visible after deactiving the module "Time and costs" \[[#53772](https://community.openproject.org/wp/53772)\]
- Bugfix: Text editor is partially out of view on mobile \[[#54128](https://community.openproject.org/wp/54128)\]
- Bugfix: Health e-mail showing storage host URL but unexpectedly linking OP \[[#55137](https://community.openproject.org/wp/55137)\]
- Bugfix: Meetings participants toggle has the wrong color \[[#55169](https://community.openproject.org/wp/55169)\]
- Bugfix: User icon appearing on the share work packages modal in the empty state \[[#55231](https://community.openproject.org/wp/55231)\]
- Bugfix: Favorite colum margin is too big on project list \[[#55251](https://community.openproject.org/wp/55251)\]
- Bugfix: Notifications are sent to the author if the author is member of a @mentioned group \[[#55255](https://community.openproject.org/wp/55255)\]
- Bugfix: New section option not i18n-ed \[[#55275](https://community.openproject.org/wp/55275)\]
- Bugfix: Can't update from 13.1 - main language pt-BR \[[#55318](https://community.openproject.org/wp/55318)\]
- Bugfix: Progress units: Display Work and Remaining work in days and hours \[[#55466](https://community.openproject.org/wp/55466)\]
- Bugfix: Focus ripped from work/remaining work preemptively disrupting input \[[#55515](https://community.openproject.org/wp/55515)\]
- Feature: Exclude by status some work packages from the calculation of totals for % Complete and work estimates \[[#49409](https://community.openproject.org/wp/49409)\]
- Feature: Avoid redundant emails in case of @mentions and email reminder \[[#50140](https://community.openproject.org/wp/50140)\]
- Feature: Record work and remaining work in different units (hours, days, weeks, ...) \[[#50954](https://community.openproject.org/wp/50954)\]
- Feature: Allow renaming persisted project lists \[[#51673](https://community.openproject.org/wp/51673)\]
- Feature: Change default view for meetings module to upcoming invitations \[[#53669](https://community.openproject.org/wp/53669)\]
- Feature: Create a sub-header component in Primer \[[#54043](https://community.openproject.org/wp/54043)\]
- Feature: Embedded work package attributes in PDF export \[[#54377](https://community.openproject.org/wp/54377)\]
- Feature: Configure which projects are activated for a project attribute \[[#54455](https://community.openproject.org/wp/54455)\]
- Feature: Allow meeting invite to be sent out when creating meetings \[[#54469](https://community.openproject.org/wp/54469)\]
- Feature: Extend storage API to include boolean "configured" attribute \[[#55158](https://community.openproject.org/wp/55158)\]
- Feature: Extend primer component PageHeader to support Tabs \[[#55190](https://community.openproject.org/wp/55190)\]
- Feature: Transform remove action from share modals to an IconButton \[[#55230](https://community.openproject.org/wp/55230)\]
- Feature: Localize demo projects when user starts a trial \[[#55323](https://community.openproject.org/wp/55323)\]
- Feature: Track deployment status for OpenProject pull requests in github integration \[[#55425](https://community.openproject.org/wp/55425)\]
- Feature: Warn admins about potential data loss when changing progress calculation modes \[[#55467](https://community.openproject.org/wp/55467)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->

#### Contributions
A big thanks to community members for reporting bugs and helping us identifying and providing fixes.

Special thanks for reporting and finding bugs go to

Ricardo Brenner, Sven Kunze
