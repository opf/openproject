---
title: OpenProject 11.4.0
sidebar_navigation:
    title: 11.4.0
release_version: 11.4.0
release_date: 2021-10-04
---

# OpenProject 11.4.0

Release date: 2021-10-04

We released [OpenProject 11.4.0](https://community.openproject.org/versions/1485).
The release contains several bug fixes and we recommend updating to the newest version.

## Debian 11 support

OpenProject 11.4.0 adds packaged installation support for Debian 11 "Bullseye".

## Bug fixes and changes

- Fixed: Work package exports fail when column "BCF snapshot" active \[[#33448](https://community.openproject.org/wp/33448)\]
- Fixed: Regression: On touch devices, Select, Info and Erase buttons don't work. \[[#38005](https://community.openproject.org/wp/38005)\]
- Fixed: Expired enterprise edition locking users out of OpenProject and all enterprise add-ons \[[#38588](https://community.openproject.org/wp/38588)\]
- Fixed: Unable to export work packages - undefined method `bcf_thumbnail' \[[#38673](https://community.openproject.org/wp/38673)\]
- Fixed: Wiki menu item scrolling does not work with two main wiki items \[[#38878](https://community.openproject.org/wp/38878)\]
- Fixed: Imminent user limit warning shown prematurely \[[#38893](https://community.openproject.org/wp/38893)\]
- Fixed: Custom S3 compatible upload providers blocked by CSP \[[#38900](https://community.openproject.org/wp/38900)\]
- Fixed: \[Github Integration\] Webhook fails for pull_request event without body \[[#38919](https://community.openproject.org/wp/38919)\]
- Fixed: IFC upload not working since attachment whitelisting \[[#38954](https://community.openproject.org/wp/38954)\]
- Fixed: BIM seed are missing snapshots \[[#39009](https://community.openproject.org/wp/39009)\]
- Fixed: Regression: Typing S while focus in viewer opens the OP global search \[[#39029](https://community.openproject.org/wp/39029)\]
- Changed: Outgoing webhook for attachment create events \[[#37891](https://community.openproject.org/wp/37891)\]
- Changed: Amend clipping plane direction \[[#37894](https://community.openproject.org/wp/37894)\]
- Changed: Refresh button \[[#38028](https://community.openproject.org/wp/38028)\]
- Changed: BCF module: Change default order to ID DESC. \[[#38032](https://community.openproject.org/wp/38032)\]
- Changed: Integrate latest Xeokit version v2.3.1 \[[#38981](https://community.openproject.org/wp/38981)\]

## Contributions

A big thanks to community members for reporting bugs and helping us identifying and providing fixes.
Special thanks for reporting and finding bugs go to pat mac
