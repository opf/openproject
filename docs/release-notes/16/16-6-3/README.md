---
title: OpenProject 16.6.3
sidebar_navigation:
    title: 16.6.3
release_version: 16.6.3
release_date: 2025-12-11
---

# OpenProject 16.6.3

Release date: 2025-12-11

We released OpenProject [OpenProject 16.6.3](https://community.openproject.org/versions/2247).
The release contains security relevant bug fixes and we strongly urge updating to the newest version.
Below you will find a complete list of all changes and bug fixes.

## CVEs

### CVE-2026-22605 - Insecure Direct Object Reference in Meetings

OpenProject versions <= 16.6.2 allows users with the View Meetings permission on any project, to access meeting agenda and section titles, notes, and text outcomes of meetings that belonged to projects, the user does not have access to. Linked work packages to projects the user is not allowed to see, are not affected.

This vulnerability was assigned to the CVE CVE-2026-22605.
For more information, please see the [GitHub Advisory GHSA-fq4m-pxvm-8x2j](https://github.com/opf/openproject/security/advisories/GHSA-fq4m-pxvm-8x2j).

This vulnerability was reported as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission.

<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Bugfix: Shared WP inaccessible to non-project members (Error 404) #68852 \[[#68921](https://community.openproject.org/wp/68921)\]
- Bugfix: User not fully deleted if that user created a recurring meeting \[[#69517](https://community.openproject.org/wp/69517)\]
- Bugfix: No message when using &quot;forgot password&quot; with unknown email \[[#69730](https://community.openproject.org/wp/69730)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->
