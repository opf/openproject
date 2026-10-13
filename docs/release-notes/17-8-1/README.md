---
title: OpenProject 17.8.1
sidebar_navigation:
    title: 17.8.1
release_version: 17.8.1
release_date: 2026-09-30
---

# OpenProject 17.8.1

Release date: 2026-09-30

We released [OpenProject 17.8.1](https://community.openproject.org/versions/2324).
The release contains several bug fixes and we recommend updating to the newest version.
Below you will find a complete list of all changes and bug fixes.
<!-- BEGIN SECURITY FIXES AUTOMATED SECTION -->
## Security fixes

### GHSA-4p83-c4wg-59q4 -  Meeting agenda item API leaks private work package subjects through the shared representer cache
Caching Work package links in the meeting API endpoints could result in leaking work package subjects to users having no access to them.

Reported through GitHub advisory by user [@kewmine](https://github.com/kewmine)

For more information, please see the [GitHub advisory #GHSA-4p83-c4wg-59q4](https://github.com/opf/openproject/security/advisories/GHSA-4p83-c4wg-59q4)

### GHSA-c5j2-2mfg-49h7 - Reusable direct-upload policy can alter trusted attachment content after antivirus scanning
### Impact

Direct uploads to S3-compatible attachment storage could be replayed after the upload had completed. A user allowed to add attachments could reuse the signed upload form of their own attachment to replace its content after the antivirus scan had already passed it. Other users downloading that attachment then received the replaced, unscanned content, while OpenProject still listed the attachment as scanned.

Only installations using remote (S3-compatible) attachment storage with direct uploads enabled are affected. Direct uploads are on by default whenever S3 storage is configured. Installations storing attachments on the local filesystem are not affected. The impact is highest where antivirus scanning is used, since the scan result no longer reflects what is served.

Affected versions: 16.5.0 and later.

### Patches

The issue is fixed in OpenProject 17.8.1 and 17.9.0. Direct uploads now go to a separate staging location, and OpenProject copies the file to its final location itself once the upload is complete. The upload form can no longer write to a completed attachment.

Upload forms also expire sooner now: after 4 hours instead of 10. You can adjust this with the new `OPENPROJECT_FOG__DIRECT__UPLOAD__EXPIRES__IN` setting (in seconds), for example to allow more time for very large uploads over slow connections.

Staged files of uploads that were abandoned or never completed can remain in the bucket. We recommend adding a lifecycle rule to clean them up, as described in [Cleaning up staged direct uploads](https://www.openproject.org/docs/installation-and-operations/configuration/#cleaning-up-staged-direct-uploads).

Upload forms issued before the upgrade stay valid until they expire. To invalidate them immediately, rotate the S3 access key used by OpenProject after upgrading.

### Workarounds

Disable direct uploads by setting `OPENPROJECT_DIRECT__UPLOADS=false`. Uploads are then routed through the OpenProject server instead of going straight to S3.

This vulnerability was reported by [**Yutaka Sasaki**](https://github.com/SAYUTIM)

For more information, please see the [GitHub advisory #GHSA-c5j2-2mfg-49h7](https://github.com/opf/openproject/security/advisories/GHSA-c5j2-2mfg-49h7)

### GHSA-r374-cr8p-hmp9 - Active sessions remain valid after password change
The application does not invalidate existing authenticated sessions after a user changes their password. As a result, other active sessions for the same account, including sessions on other browsers or devices, remain authenticated and usable after the password change is completed.

This can allow an attacker who has already obtained a valid session token or authenticated browser session to retain access even after the legitimate user changes their password. The issue weakens the effectiveness of password rotation as an account recovery measure and may allow continued unauthorized access to account data and user-level actions until the retained session expires or is manually revoked.

For more information, please see the [GitHub advisory #GHSA-r374-cr8p-hmp9](https://github.com/opf/openproject/security/advisories/GHSA-r374-cr8p-hmp9)

<!-- END SECURITY FIXES AUTOMATED SECTION -->
<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Bugfix: Marking type as default not possible with feature flag off \[[#79698](https://community.openproject.org/wp/79698)\]
- Bugfix: Versions PG::UndefinedTable during a query  \[[#78827](https://community.openproject.org/wp/78827)\]
- Bugfix: Search is missing an index for work\_package\_semantic\_aliases which makes it slow \[[#79497](https://community.openproject.org/wp/79497)\]
- Bugfix: Backup job memory leak crashing worker \[[#79753](https://community.openproject.org/wp/79753)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->
