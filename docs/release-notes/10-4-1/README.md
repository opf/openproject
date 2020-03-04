---
title: OpenProject 10.4.1
sidebar_navigation:
    title: 10.4.1
release_version: 10.4.1
release_date: 2020-03-04
---

# OpenProject 10.4.1

We released [OpenProject 10.4.1](https://community.openproject.com/versions/1417).
The release contains several bug fixes and we recommend updating to the newest version.

<!--more-->

### Time entry corruption in 10.4.0 update

The migration scripts that ran as part of the OpenProject 10.4.0 upgrade include an unfortunate bug that leads to some installations suffering data loss. Installations, that had time entry activities enabled/disabled per project, will have all their time entries assigned to a single time entry activity.



If you have updated to 10.4.0 and were using project-based time entry activities, please use the following guide to restore them:

[Fixing time entries corrupted by upgrading to 10.4.0](https://docs.openproject.org/installation-and-operations/misc/time-entries-corrupted-by-10-4/).



#### Bug fixes and changes

- Fixed: Can not delete queries on community.openproject.com \[[#32326](https://community.openproject.com/wp/32326)\]
- Fixed: Special characters displayed as ASCII code in My Spent Time widget \[[#32328](https://community.openproject.com/wp/32328)\]
- Fixed: Custom Design gone after change color schema \[[#32356](https://community.openproject.com/wp/32356)\]
- Fixed: Project activities no more filtered when logging time \[[#32358](https://community.openproject.com/wp/32358)\]
- Fixed: Cost control - activity types lost after upgrade to 10.4 \[[#32360](https://community.openproject.com/wp/32360)\]
- Fixed: Unexpected submit when using IME \[[#32423](https://community.openproject.com/wp/32423)\]

#### Contributions
A big thanks to community members for reporting bugs and helping us identifying and providing fixes.

Special thanks for reporting and finding bugs go to

Freddy Trotin, Harald Holzmann, Wojciech Niziński, Kanta Ebihara
