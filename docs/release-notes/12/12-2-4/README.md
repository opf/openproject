---
title: OpenProject 12.2.4
sidebar_navigation:
    title: 12.2.4
release_version: 12.2.4
release_date: 2022-09-15
---

# OpenProject 12.2.4

Release date: 2022-09-15

We released [OpenProject 12.2.4](https://community.openproject.org/versions/1599).
The release contains several bug fixes and we recommend updating to the newest version.

## Pending journal cleanup database migration

With OpenProject 12.2.2, a journal cleanup migration was introduced to fix a data corruption bug in the 12.2.0 release.

That migration would fail for some customers that have some invalid journal references in their datasets. The ones we found and confirmed were due to historical data being invalid, so these journals can be safely destroyed.

A migration was added to this release to do just that, and ensure that the 12.2.2 migration can successfully be ran.

For more information on that change, please see the discussion in [Bug #44132](https://community.openproject.org/wp/44132)

## Bug fixes and changes

- Fixed: Remaining hours sum not well formed \[[#43833](https://community.openproject.org/wp/43833)\]
- Fixed: Destroy journals with invalid data_type associations \[[#44132](https://community.openproject.org/wp/44132)\]
- Fixed: Internal error / Illegal instruction error \[[#44155](https://community.openproject.org/wp/44155)\]
- Fixed: Dragging images to CKEditor on Grid custom texts not working with direct upload \[[#44156](https://community.openproject.org/wp/44156)\]

## Contributions

A big thanks to community members for reporting bugs and helping us identifying and providing fixes.
Special thanks for reporting and finding bugs go to Nico Aymet
