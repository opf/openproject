---
title: OpenProject 12.1.3
sidebar_navigation:
    title: 12.1.3
release_version: 12.1.3
release_date: 2022-05-12
---

# OpenProject 12.1.3

Release date: 2022-05-12

We released [OpenProject 12.1.3](https://community.openproject.org/versions/1550).
The release contains several bug fixes and we recommend updating to the newest version.

## Settings regression

OpenProject introduced a larger refactoring of the app settings to clean up
the distinction between ENV settings and database-based settings.

Unfortunately, that introduced some constraints that caused the following bugs in downstream products,
warranting another patch level release. We're sorry for the inconvenience caused.

If you experience bugs in installing or using OpenProject, please help us by reporting them to our community.
To read how to do this, please see [reporting a bug in OpenProject](../../../development/report-a-bug/).

## Bug fixes and changes

- Fixed: "openproject configure" reports errors \[[#42349](https://community.openproject.org/wp/42349)\]
- Fixed: Scheduled LDAP User Synchronization doesn't work \[[#42351](https://community.openproject.org/wp/42351)\]
- Fixed: [Packager] configure fails when sendmail was configured for emails \[[#42352](https://community.openproject.org/wp/42352)\]

## Contributions

A big thanks to community members for reporting bugs and helping us identifying and providing fixes.

Special thanks for reporting and finding bugs go to

Ludwig Raffler, Mario Haustein
