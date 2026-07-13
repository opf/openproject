---
title: OpenProject 16.6.4
sidebar_navigation:
    title: 16.6.4
release_version: 16.6.4
release_date: 2026-01-08
---

# OpenProject 16.6.4

Release date: 2026-01-08

We released OpenProject [OpenProject 16.6.4](https://community.openproject.org/versions/2248).

The release contains security relevant bug fixes and we strongly urge updating to the newest version.
Below you will find a complete list of all changes and bug fixes.

## CVEs

### CVE-2026-22600 - Arbitrary File Read via ImageMagick SVG Coder

A Local File Read (LFR) vulnerability exists in the work package PDF export functionality of OpenProject < 16.6.4 . By uploading a specially crafted SVG file (disguised as a PNG) as a work package attachment, an attacker can exploit the backend image processing engine (ImageMagick). When the work package is exported to PDF, the backend attempts to resize the image, triggering the ImageMagick text: coder. This allows an attacker to read arbitrary local files that the application user has permissions to access (e.g., /etc/passwd, all project configuration files, private project data, etc.)

This vulnerability was assigned to the CVE CVE-2026-22605.
For more information, please see the [GitHub Advisory GHSA-m8f2-cwpq-vvhh)](https://github.com/opf/openproject/security/advisories/GHSA-m8f2-cwpq-vvhh).

The vulnerability has been responsibly disclosed through the [YesWeHack bounty program for OpenProject](https://yeswehack.com/programs/openproject) by user [syndrome_imposter](https://yeswehack.com/hunters/syndrome-impostor). This bug bounty program is being sponsored by the European Commission.

<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Bugfix: SVG attachments are interpreted as PNG \[[#70349](https://community.openproject.org/wp/70349)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->
