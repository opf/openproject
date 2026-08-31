---
title: OpenProject 17.0.2
sidebar_navigation:
    title: 17.0.2
release_version: 17.0.2
release_date: 2026-01-27
---

# OpenProject 17.0.2

Release date: 2026-01-27

We released OpenProject [OpenProject 17.0.2](https://community.openproject.org/versions/2260).
The release contains sa security fix and several bug fixes and we strongly recommend updating to the newest version.
Below you will find a complete list of all changes and bug fixes.

## Security fixes

### CVE-2026-24685 - Argument Injection on Repository Diff allows Arbitrary File Write and Remote Code Execution

An arbitrary file write vulnerability exists in OpenProject’s repository diff download endpoint (/projects/:project\_id/repository/diff.diff) when rendering a single revision via git show. By supplying a specially crafted rev value (for example, rev=--output=/tmp/poc.txt), an attacker can inject git show command-line options. When OpenProject executes the SCM command, Git interprets the attacker-controlled rev as an option and writes the output to an attacker-chosen path.

As a result, any user with the :browse\_repository permission on the project can create or overwrite arbitrary files that the OpenProject process user is permitted to write. The written contents consist of git show output (commit metadata and patch), but overwriting application or configuration files still leads to data loss and denial of service, impacting integrity and availability.

When the user has permissions to write into the repository, they can craft a specific commit to result in a RCE with permission scope of the OpenProject application.

This vulnerability was responsibly disclosed by [sam91281](https://yeswehack.com/hunters/sam91281) as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission. Thank you for your collaboration.

For more information, please see the [GitHub advisory #GHSA-74p5-9pr3-r6pw](https://github.com/opf/openproject/security/advisories/GHSA-74p5-9pr3-r6pw)

### CVE-2026-24772 - SSRF and CSWSH in Hocuspocus Synchronization Server

To enable the real time collaboration on documents, OpenProject 17.0 introduced a [synchronization server](https://github.com/opf/op-blocknote-hocuspocus). The OpenProject backend generates an authentication token that is currently valid for 24 hours, encrypts it with a shared secret only known to the synchronization server. The frontend hands this encrypted token and the backend URL over to the synchronization server to check user&#39;s ability to work on the document and perform intermittent saves while editing.

The synchronization server does not properly validate the backend URL and sends a request with the decrypted authentication token to the endpoint that was given to the server. An attacker could use this vulnerability to decrypt a token that he intercepted by other means to gain an access token to interact with OpenProject on the victim&#39;s behalf.

The vulnerability has been responsibly disclosed through the [YesWeHack bounty program for OpenProject](https://yeswehack.com/programs/openproject) by [Scott Curtis (syndrome\_impostor)](https://yeswehack.com/hunters/syndrome-impostor). Thank you for the responsible disclosure and your collaboration in this report!

For more information, please see the [GitHub advisory #GHSA-r854-p5qj-x974](https://github.com/opf/openproject/security/advisories/GHSA-r854-p5qj-x974)

### CVE-2026-24775 - Forced Actions, Content Spoofing, and Persistent DoS via ID Manipulation in OpenProject Blocknote Editor Extension

In the new editor for collaborative documents based on [BlockNote](https://www.blocknotejs.org/) we added a custom extension that allows to mention OpenProject work packages in the document. To show work package details, the editor loads details about the work package via the OpenProject API. For this API call, the extension to the BlockNote editor did not properly validate the given work package ID to be only a number. This allowed an attacker to generate a document with relative links that upon opening could make arbitrary `GET` requests to any URL within the OpenProject instance.

The vulnerability has been responsibly disclosed through the [YesWeHack bounty program for OpenProject](https://yeswehack.com/programs/openproject) by [Scott Curtis (syndrome\_impostor)](https://yeswehack.com/hunters/syndrome-impostor). Thank you two for the responsible disclosure and your collaboration in this report!

For more information, please see the [GitHub advisory #GHSA-35c6-x276-2pvc](https://github.com/opf/openproject/security/advisories/GHSA-35c6-x276-2pvc)

<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Bugfix: Unable to change to earlier finish date for automatically scheduled successor \[[#65130](https://community.openproject.org/wp/65130)\]
- Bugfix: Meeting outcomes cannot be saved with ctrl/cmd+enter \[[#69974](https://community.openproject.org/wp/69974)\]
- Bugfix: AXe Accessibility error: invalid list structure \[[#70573](https://community.openproject.org/wp/70573)\]
- Bugfix: Fix AXe Accessibility error: Navigation toggler must have discernible text \[[#70574](https://community.openproject.org/wp/70574)\]
- Bugfix: Documents module is missing meaningful html title \[[#70614](https://community.openproject.org/wp/70614)\]
- Bugfix: Users with the &quot;Manage Users&quot; permission did not see links to Lock/Unlock users \[[#70796](https://community.openproject.org/wp/70796)\]
- Bugfix: Cannot authorize OpenProject app with OpenProject when user has 2FA enabled \[[#70966](https://community.openproject.org/wp/70966)\]
- Bugfix: Running docker slim image, runs slim-bim one \[[#70980](https://community.openproject.org/wp/70980)\]
- Bugfix: &#39;For all projects&#39; project attributes are not displayed during new project creation \[[#70982](https://community.openproject.org/wp/70982)\]
- Bugfix: Fix revision parsing in git diff output \[[#71020](https://community.openproject.org/wp/71020)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->
