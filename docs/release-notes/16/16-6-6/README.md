---
title: OpenProject 16.6.6
sidebar_navigation:
    title: 16.6.6
release_version: 16.6.6
release_date: 2026-01-27
---

# OpenProject 16.6.6

Release date: 2026-01-27

We released OpenProject [OpenProject 16.6.6](https://community.openproject.org/versions/2261).
The release contains security related bug fixes and we strongly urge you to update to the newest version.
Below you will find a complete list of all changes and bug fixes.

## Security fixes

### CVE-2026-24685 - Argument Injection on Repository Diff allows Arbitrary File Write and Remote Code Execution

An arbitrary file write vulnerability exists in OpenProject’s repository diff download endpoint (/projects/:project\_id/repository/diff.diff) when rendering a single revision via git show. By supplying a specially crafted rev value (for example, rev=--output=/tmp/poc.txt), an attacker can inject git show command-line options. When OpenProject executes the SCM command, Git interprets the attacker-controlled rev as an option and writes the output to an attacker-chosen path.

As a result, any user with the :browse\_repository permission on the project can create or overwrite arbitrary files that the OpenProject process user is permitted to write. The written contents consist of git show output (commit metadata and patch), but overwriting application or configuration files still leads to data loss and denial of service, impacting integrity and availability.

When the user has permissions to write into the repository, they can craft a specific commit to result in a RCE with permission scope of the OpenProject application.

This vulnerability was responsibly disclosed by [sam91281](https://yeswehack.com/hunters/sam91281) as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission. Thank you for your collaboration.

For more information, please see the [GitHub advisory #GHSA-74p5-9pr3-r6pw](https://github.com/opf/openproject/security/advisories/GHSA-74p5-9pr3-r6pw)

<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Bugfix: Fix revision parsing in git diff output \[[#71019](https://community.openproject.org/wp/71019)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->
