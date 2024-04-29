---
title: OpenProject 11.2.2
sidebar_navigation:
    title: 11.2.2
release_version: 11.2.2
release_date: 2021-03-24
---

# OpenProject 11.2.2

Release date: 2021-03-24

We released [OpenProject 11.2.2](https://community.openproject.org/versions/1473).
The release contains several bug fixes and we recommend updating to the newest version.

<!--more-->
## Bug fixes and changes

- Fixed: Column filter in Action Boards (e.g.  Assignee, status, version, ...) is case sensitive \[[#35744](https://community.openproject.org/wp/35744)\]
- Fixed: Create new role: "Check all" / "Uncheck all" for new role not working \[[#36291](https://community.openproject.org/wp/36291)\]
- Fixed: Missing localization string for "Derived estimated hours" \[[#36712](https://community.openproject.org/wp/36712)\]
- Fixed: Serious Problem: OpenProject not running after Upgrade to 11.2.1 – rake aborted!  NoMethodError: undefined method `patch_gem_version' for OpenProject::Patches:Module \[[#36717](https://community.openproject.org/wp/36717)\]

## Contributions

A big thanks to community members for reporting bugs and helping us identifying and providing fixes.

Special thanks for reporting and finding bugs go to

Björn Schümann, Jan F. Orth
