---
title: OpenProject 17.9.3
sidebar_navigation:
    title: 17.9.3
release_version: 17.9.3
release_date: 2026-10-22
---

# OpenProject 17.9.3

Release date: 2026-10-22

We released [OpenProject 17.9.3](https://community.openproject.org/versions/2336).
The release contains several bug fixes and we recommend updating to the newest version.
Below you will find a complete list of all changes and bug fixes.
<!-- BEGIN SECURITY FIXES AUTOMATED SECTION -->
## Security fixes

### GHSA-998q-c58p-qf78 - Improper input validation in PDF hyphenation language allows local file load
The work package PDF export accepts a hyphenation\_language parameter that the server does not validate properly and passes the same value to its background job

For more information, please see the [GitHub advisory #GHSA-998q-c58p-qf78](https://github.com/opf/openproject/security/advisories/GHSA-998q-c58p-qf78)

<!-- END SECURITY FIXES AUTOMATED SECTION -->
<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Bugfix: Pasting image in a description displays a broken link \[[#80962](https://community.openproject.org/wp/80962)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->
