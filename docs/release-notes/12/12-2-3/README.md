---
title: OpenProject 12.2.3
sidebar_navigation:
    title: 12.2.3
release_version: 12.2.3
release_date: 2022-09-12
---

# OpenProject 12.2.3

Release date: 2022-09-12

We released [OpenProject 12.2.3](https://community.openproject.org/versions/1598).
The release contains several bug fixes and we recommend updating to the newest version.

## Fixed: Installing custom plugins in packaged installations

Newer bundler versions would prevent custom plugins being installed in packaged installation.
This has been fixed in this released version. For more information, please see [#44058](https://community.openproject.org/wp/44058)

## Bug fixes and changes

- Fixed: RPM/DEB installation fails with a custom gemfile \[[#44058](https://community.openproject.org/wp/44058)\]
