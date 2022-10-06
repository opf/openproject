---
title: OpenProject 12.3.0
sidebar_navigation:
    title: 12.3.0
release_version: 12.3.0
release_date: 2022-10-06
---

# OpenProject 12.3.0

Release date: 2022-10-06

We released [OpenProject 12.3.0](https://community.openproject.com/versions/1514).
The release contains several bug fixes and we recommend updating to the newest version.

<!--more-->
#### Bug fixes and changes

- Epic: Define weekly work schedule (weekends) \[[#18416](https://community.openproject.com/wp/18416)\]
- Epic: Duration (deriving duration from dates, deriving dates from duration, updated datepicker, duration field elsewhere) \[[#31992](https://community.openproject.com/wp/31992)\]
- Fixed: Quick-add menu not showing on smaller screens \[[#37539](https://community.openproject.com/wp/37539)\]
- Fixed: Attachments are not going to be copied, when using "Copy to other project" function \[[#43005](https://community.openproject.com/wp/43005)\]
- Fixed: Filters are not working after adding a custom field with default value  \[[#43085](https://community.openproject.com/wp/43085)\]
- Fixed: BIM edition unavailable on Ubuntu 22.04 packaged installation \[[#43531](https://community.openproject.com/wp/43531)\]
- Fixed: Can't delete WPs from board view \[[#43761](https://community.openproject.com/wp/43761)\]
- Fixed: Insufficient contrast ratio between activity font color and background \[[#43874](https://community.openproject.com/wp/43874)\]
- Fixed: SystemStackError (stack level too deep) when trying to assign new parent or children to a work package \[[#43894](https://community.openproject.com/wp/43894)\]
- Fixed: Strange arrangement of files when creating a new work package \[[#44052](https://community.openproject.com/wp/44052)\]
- Fixed: CKEditor not wrapping the words at the end of the sentence (edit and view mode) \[[#44125](https://community.openproject.com/wp/44125)\]
- Fixed: File storage OAuth setting fields should not get translated \[[#44146](https://community.openproject.com/wp/44146)\]
- Fixed: Log out user when delete work package from board \[[#44161](https://community.openproject.com/wp/44161)\]
- Fixed: Work packages can have start_dates > due_dates \[[#44243](https://community.openproject.com/wp/44243)\]
- Fixed: Backup failed: pg_dump: password authentication failed for user "openproject" \[[#44251](https://community.openproject.com/wp/44251)\]
- Fixed: "Group by" options in Cost report are broken \[[#44265](https://community.openproject.com/wp/44265)\]
- Fixed: Files list: inconsistencies in spacing and colours  \[[#44266](https://community.openproject.com/wp/44266)\]
- Fixed: API call for custom_options does not work custom fieleds in time_entries \[[#44281](https://community.openproject.com/wp/44281)\]
- Fixed: Email Reminder:  Daily reminders can only be configured to be delivered at a full hour. \[[#44300](https://community.openproject.com/wp/44300)\]
- Changed: Cleanup placeholders of editable attributes \[[#40133](https://community.openproject.com/wp/40133)\]
- Changed: Updated date picker drop modal (including duration and non-working days) \[[#41341](https://community.openproject.com/wp/41341)\]
- Changed: Copying a project shall also copy file links attached to all work packages \[[#41530](https://community.openproject.com/wp/41530)\]
- Changed: Administration page for changing the global work schedule - Weekends only \[[#42316](https://community.openproject.com/wp/42316)\]
- Changed: Add meaningful tooltips to the most essential actions \[[#43299](https://community.openproject.com/wp/43299)\]
- Changed: Hide time stamp and avatar when there are hover actions  \[[#43308](https://community.openproject.com/wp/43308)\]
- Changed: Use a disabled mouse style and tooltip for inactive files \[[#43399](https://community.openproject.com/wp/43399)\]
- Changed: Update work package table view for duration \[[#43636](https://community.openproject.com/wp/43636)\]
- Changed: Update gantt chart for duration and non-working days \[[#43637](https://community.openproject.com/wp/43637)\]
- Changed: Update team planner and calendar for duration and non-working days \[[#43638](https://community.openproject.com/wp/43638)\]
- Changed: Delete/Unlink modal \[[#43663](https://community.openproject.com/wp/43663)\]
- Changed: Add information toast to the Nextcloud Setup Documentation \[[#43851](https://community.openproject.com/wp/43851)\]
- Changed: Disregard distance (not lag) between related work packages when scheduling FS-related work packages \[[#44053](https://community.openproject.com/wp/44053)\]
- Changed: Add packaged installation support for SLES 15 \[[#44117](https://community.openproject.com/wp/44117)\]
- Changed: Replace toggles for scheduling mode and working days with on/off-switches \[[#44147](https://community.openproject.com/wp/44147)\]
- Changed: New release teaser block for 12.3 \[[#44212](https://community.openproject.com/wp/44212)\]
- Changed: Add the Switch component and Switch Field pattern to the design system \[[#44213](https://community.openproject.com/wp/44213)\]

#### Contributions
A big thanks to community members for reporting bugs and helping us identifying and providing fixes.

Special thanks for reporting and finding bugs go to

Stuart Malt, Herbert Cruz, Matthias Weber, Alexander Seitz, Daniel Hug, Christian Noack, Christina Vechkanova, Noel Lublovary, Hans-Gerd Sandhagen, Sky Racer

