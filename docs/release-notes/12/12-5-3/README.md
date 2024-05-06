---
title: OpenProject 12.5.3
sidebar_navigation:
    title: 12.5.3
release_version: 12.5.3
release_date: 2023-04-24
---

# OpenProject 12.5.3

Release date: 2023-04-24

We released [OpenProject 12.5.3](https://community.openproject.org/versions/1694).
The release contains several bug fixes and we recommend updating to the newest version.

## Bug fixes and changes

- Fixed: Titles of related work packages are unnecessarily truncated. Full titles are not accessible. \[[#44828](https://community.openproject.org/wp/44828)\]
- Fixed: Date picker: selected dates in mini calendar don't have a hover (primary dark) \[[#46436](https://community.openproject.org/wp/46436)\]
- Fixed: Non-working Days/Holidays selection with 12.5 update \[[#47057](https://community.openproject.org/wp/47057)\]
- Fixed: Project filter values drop down cut off \[[#47072](https://community.openproject.org/wp/47072)\]
- Fixed: In projects filter selected values keep being suggested  \[[#47074](https://community.openproject.org/wp/47074)\]
- Fixed: Activity page not working correctly \[[#47203](https://community.openproject.org/wp/47203)\]
- Fixed: XLS export of work package with description cannot be opened by Excel if the description contains a table \[[#47513](https://community.openproject.org/wp/47513)\]
- Fixed: Cannot archive a project that has archived sub-projects \[[#47599](https://community.openproject.org/wp/47599)\]
- Fixed: 'TypeError: can't cast Array' during db:migrate \[[#47620](https://community.openproject.org/wp/47620)\]
- Fixed: Anyone can sign up using Google even if user registration is disabled \[[#47622](https://community.openproject.org/wp/47622)\]
- Fixed: inbound emails uses "move_on_success" and "move_on_failure" error \[[#47633](https://community.openproject.org/wp/47633)\]

## Contributions

A big thanks to community members for reporting bugs and helping us identifying and providing fixes.

Special thanks for reporting and finding bugs go to

Daniel Grabowski, Sebastian Bialek, Chris Quin, Gordon Yeung, YK L
