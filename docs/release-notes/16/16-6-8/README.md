---
title: OpenProject 16.6.8
sidebar_navigation:
    title: 16.6.8
release_version: 16.6.8
release_date: 2026-02-18
---

# OpenProject 16.6.8

Release date: 2026-02-18

We released OpenProject [OpenProject 16.6.8](https://community.openproject.org/versions/2276).
The release contains several bug fixes and we recommend updating to the newest version.
Below you will find a complete list of all changes and bug fixes.

<!-- BEGIN CVE AUTOMATED SECTION -->

## Security fixes

### CVE-2026-27006 - Path Traversal on OpenProject BIM Edition leads to Arbitrary File upload on BCF module, resulting in possible RCE when using file-based caching

An authenticated attacker with BCF module access can write arbitrary files to any writable directory on the server through a path traversal vulnerability in the BCF import functionality. For docker-compose based installations, this can be expanded to a remote code execution using cache deserialization.

This vulnerability was reported by user shafouzzz as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission.

For more information, please see the [GitHub advisory #GHSA-4fvm-rrc8-mgch](https://github.com/opf/openproject/security/advisories/GHSA-4fvm-rrc8-mgch)

### CVE-2026-27019 - Path Traversal via Incoming Email Attachments Leads to Arbitrary File Write and RCE

When OpenProject is configured to accept and handle incoming emails, it was possible that an attacker could send an email with a specially crafted attachment that would be written to a predefined location in the filesystem. All files that can be written by the `openproject` system user could be written. This could even be evaluated to a Remote Code Execution vulnerability.

This vulnerability was reported by user [sam91281](https://yeswehack.com/hunters/sam91281) as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission.

For more information, please see the [GitHub advisory #GHSA-r85w-rv9m-q784](https://github.com/opf/openproject/security/advisories/GHSA-r85w-rv9m-q784)

<!-- END CVE AUTOMATED SECTION -->

<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->
