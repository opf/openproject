---
title: OpenProject 12.3.1
sidebar_navigation:
    title: 12.3.1
release_version: 12.3.1
release_date: 2022-10-24
---

# OpenProject 12.3.1

Release date: 2022-10-24

We released [OpenProject 12.3.1](https://community.openproject.org/versions/1605).
The release contains several bug fixes and we recommend updating to the newest version.

## Bug fixes and changes

- Fixed: Frontend including editor and time logging unusable when there are many activities \[[#40373](https://community.openproject.org/wp/40373)\]
- Fixed: Attachments are not going to be copied, when using "Copy to other project" function \[[#43005](https://community.openproject.org/wp/43005)\]
- Fixed: Custom fields are enabled on project creation \[[#43763](https://community.openproject.org/wp/43763)\]
- Fixed: "Reorder values alphabetically" does not work reliably \[[#43832](https://community.openproject.org/wp/43832)\]
- Fixed: Time and costs: Project filter set to "is not (includes subprojects)" not working as expected \[[#44217](https://community.openproject.org/wp/44217)\]
- Fixed: Unchecking 'Display subprojects work packages on main projects by default' causes WP Export list to be empty \[[#44248](https://community.openproject.org/wp/44248)\]
- Fixed: Datepicker modal jumps up when in parent toggling manual scheduling \[[#44330](https://community.openproject.org/wp/44330)\]
- Fixed: "Logged by" column is showing the wrong value ("Deleted user") in the cost report \[[#44352](https://community.openproject.org/wp/44352)\]
- Fixed: Duplicate cancel buttons in mobile modals \[[#44398](https://community.openproject.org/wp/44398)\]
- Fixed: Update dates on Gantt chart based on its duration \[[#44405](https://community.openproject.org/wp/44405)\]
- Fixed: After moving a work package card on the calendar, update dates based on its duration \[[#44406](https://community.openproject.org/wp/44406)\]
- Fixed: Datepicker (mobile): number keyboard does not include all necessary characters on iOS \[[#44420](https://community.openproject.org/wp/44420)\]
- Fixed: Not possible to disable direct uploads \[[#44492](https://community.openproject.org/wp/44492)\]
- Fixed: Date-picker and time logging should not be blocked on non-working days \[[#44496](https://community.openproject.org/wp/44496)\]
- Fixed: Tokens not cleaned up on user deletion \[[#44500](https://community.openproject.org/wp/44500)\]
- Fixed: Creating work package starting on a non-working day should not be possible \[[#44509](https://community.openproject.org/wp/44509)\]
- Fixed: Email reminders should be enabled by default for Monday-Friday \[[#44526](https://community.openproject.org/wp/44526)\]
- Fixed: Removed project members remain in invitation list when copying meetings \[[#44536](https://community.openproject.org/wp/44536)\]
- Fixed: Feature Teaser not translated into German \[[#44582](https://community.openproject.org/wp/44582)\]
- Fixed: "missing translation" pop-up message on a newly created cloud instance \[[#44583](https://community.openproject.org/wp/44583)\]
- Fixed: OpenProject upgrade fails with "column roles.assignable does not exist" error during AddStoragesPermissionsToRoles migration \[[#44616](https://community.openproject.org/wp/44616)\]

## Contributions

A big thanks to community members for reporting bugs and helping us identifying and providing fixes.

Special thanks for reporting and finding bugs go to

Matthias Weber, Klaas van Thoor, Sven Kunze, Stefan B, Luka Bradesko, Jörg Mollowitz, Maya Berdygylyjova
