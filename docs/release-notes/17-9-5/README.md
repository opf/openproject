---
title: OpenProject 17.9.5
sidebar_navigation:
    title: 17.9.5
release_version: 17.9.5
release_date: 2026-10-30
---

# OpenProject 17.9.5

Release date: 2026-10-30

We released [OpenProject 17.9.5](https://community.openproject.org/versions/2341).
The release contains several bug fixes and we recommend updating to the newest version.
Below you will find a complete list of all changes and bug fixes.
<!-- BEGIN SECURITY FIXES AUTOMATED SECTION -->
## Security fixes

### GHSA-2qr3-mhmh-xfwj - Work-package budget link discloses budget subject to users lacking view_budgets
Authenticated users who is a member of a project that uses the Budgets module, when having t
`view_work_packages` but not `view_budgets`, can see budget subjects if they are linked to a work package through the work package&#x27;s API form response.

This report has been responsibly disclosed by GitHub user barnessomer through GitHub advisories.

For more information, please see the [GitHub advisory #GHSA-2qr3-mhmh-xfwj](https://github.com/opf/openproject/security/advisories/GHSA-2qr3-mhmh-xfwj)

<!-- END SECURITY FIXES AUTOMATED SECTION -->
<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Bugfix: Work package identifiers not updated after alleged successful migration \[[#75941](https://community.openproject.org/wp/75941)\]
- Bugfix: Project copy blocks all work package creates until the copy completes \[[#82056](https://community.openproject.org/wp/82056)\]
- Bugfix: OpenTelemetry logs &quot;invalid span attribute value type Hash&quot; for every S3 request made through fog \[[#82184](https://community.openproject.org/wp/82184)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->
