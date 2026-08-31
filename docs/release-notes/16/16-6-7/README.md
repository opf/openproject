---
title: OpenProject 16.6.7
sidebar_navigation:
    title: 16.6.7
release_version: 16.6.7
release_date: 2026-02-06
---

# OpenProject 16.6.7

Release date: 2026-02-06

We released OpenProject [OpenProject 16.6.7](https://community.openproject.org/versions/2265).
The release contains several bug fixes and we recommend updating to the newest version.
Below you will find a complete list of all changes and bug fixes.

<!-- BEGIN CVE AUTOMATED SECTION -->

## Security fixes

### GHSA-q523-c695-h3hp - Stored HTML injection on time tracking

An HTML injection vulnerability occurs in the time tracking function of OpenProject version 17.0.2. The application does not escape HTML tags, an attacker with administrator privileges can create a work package with the name containing the HTML tags and add it to the `Work package` section when creating time tracking.

Responsibly disclosed by Researcher: Nguyen Truong Son ([truongson526@gmail.com](mailto:truongson526@gmail.com)) through the GitHub advisory.

For more information, please see the [GitHub advisory #GHSA-q523-c695-h3hp](https://github.com/opf/openproject/security/advisories/GHSA-q523-c695-h3hp)

### GHSA-x37c-hcg5-r5m7 - Command Injection on OpenProject repositories leads to Remote Code Execution

An arbitrary file write vulnerability exists in OpenProject’s repository changes endpoint (`/projects/:project_id/repository/changes`) when rendering the “latest changes” view via `git log`.

By supplying a specially crafted `rev` value (for example, `rev=--output=/tmp/poc.txt`), an attacker can inject `git log` command-line options. When OpenProject executes the SCM command, Git interprets the attacker-controlled `rev` as an option and writes the output to an attacker-chosen path.

As a result, any user with the `:browse_repository` permission on the project can create or overwrite arbitrary files that the OpenProject process user is permitted to write. The written contents consist of `git log` output, but by crafting custom commits the attacker can still upload valid shell scripts, ultimately leading to RCE. The RCE lets the attacker create a reverse shell to the target host and view confidential files outside of OpenProject, such as `/etc/passwd`.

This vulnerability was reported by user [sam91281](https://yeswehack.com/hunters/sam91281) as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission.

For more information, please see the [GitHub advisory #GHSA-x37c-hcg5-r5m7](https://github.com/opf/openproject/security/advisories/GHSA-x37c-hcg5-r5m7)

<!-- END CVE AUTOMATED SECTION -->

<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->
