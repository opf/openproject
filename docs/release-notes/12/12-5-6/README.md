---
title: OpenProject 12.5.6
sidebar_navigation:
    title: 12.5.6
release_version: 12.5.6
release_date: 2023-06-01
---

# OpenProject 12.5.6

Release date: 2023-06-01

We released [OpenProject 12.5.6](https://community.openproject.org/versions/1794).
The release contains a security related bug fix and we recommend updating to the newest version.

## CVE-2023-31140: Project identifier information leakage through robots.txt

For any OpenProject installation, a robots.txt file is generated through the server to denote which routes shall or shall not be accessed by crawlers. These routes contain project identifiers of all public projects in the instance. Even if the entire instance is marked as "Login required" and prevents all truly anonymous access, the /robots.txt route remains publicly available.

This results in the URL part of the project (i.e., the project identifier) to be publicly visible. As these identifiers are derived from the project name, they may contain sensitive information.

For more information, [please see our security advisory](https://github.com/opf/openproject/security/advisories/GHSA-xjfc-fqm3-95q8).

**Patches**

You can download the following patch file to apply the patch to any OpenProject version > 10.0: https://patch-diff.githubusercontent.com/raw/opf/openproject/pull/12708.patch

**Workaround**
If you are unable to update or apply the provided patch, mark any public project as non-public for the time being and give anyone in need of access to the project a membership.

## Bug fixes and changes

- Changed: Add packaged installation support for SLES 15 \[[#44117](https://community.openproject.org/wp/44117)\]
- Changed: Allow URL behind the application logo to be configurable \[[#48251](https://community.openproject.org/wp/48251)\]
- Fixed: Moving in Kanban board having a "is not" project filter changes the project of the work packages \[[#44895](https://community.openproject.org/wp/44895)\]
- Fixed: Upgrade migration error "smtp_openssl_verify_mode is not writable" \[[#48125](https://community.openproject.org/wp/48125)\]
- Fixed: OpenProject officially supports Debian 9 while Postgres does not anymore.  \[[#48245](https://community.openproject.org/wp/48245)\]
- Fixed: robots.txt leaks public project identifiers \[[#48338](https://community.openproject.org/wp/48338)\]
- Fixed: Unchecked copy options are still copied in the new project \[[#48351](https://community.openproject.org/wp/48351)\]

## Contributions

A big thanks to community members for reporting bugs and helping us identifying and providing fixes.
Special thanks for reporting and finding bugs go to Benjamin Rönnau, Ryan Brownell
