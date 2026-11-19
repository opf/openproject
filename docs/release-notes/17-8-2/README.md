---
title: OpenProject 17.8.2
sidebar_navigation:
    title: 17.8.2
release_version: 17.8.2
release_date: 2026-11-09
---

# OpenProject 17.8.2

Release date: 2026-11-09

We released [OpenProject 17.8.2](https://community.openproject.org/versions/2352).
The release contains several bug fixes and we recommend updating to the newest version.
Below you will find a complete list of all changes and bug fixes.
<!-- BEGIN SECURITY FIXES AUTOMATED SECTION -->
## Security fixes

### GHSA-9c69-v342-vqr7 - Arbitrary zero-argument method invocation on visible projects via unvalidated attribute parameter in `InplaceEditFieldsController`
This release fixes a critical vulnerability (CVSS 3.1 score **9.4**) in the in-place editing endpoint for project attributes. Users who could view a project were able to trigger unintended operations on it, including deleting the project and its subprojects and reading information they were not permitted to see. On public instances, without required login, this was possible for anonymous users. All versions from 17.2.0 onward are affected. Outside of our usual policy to only release patches for the currently supported version, for this critical vulnerability we will be issuing patches for versions 17.9.7, 17.8.2, 17.7.3, 17.6.1 and 17.5.2. Installations running 17.2 to 17.4 should upgrade to one of these releases.

Thanks to GitHub user [ccsimplyspolit](https://github.com/ccsimplyspolit) for responsibly disclosing this issue.

For more information, please see the [GitHub advisory #GHSA-9c69-v342-vqr7](https://github.com/opf/openproject/security/advisories/GHSA-9c69-v342-vqr7)

### GHSA-pggp-67cq-xgrg - Arbitrary zero-argument method invocation on visible projects and work packages via attribute macros in exports and emails
Attribute macros (`workPackageValue:…` / `projectValue:…`) in rich text are resolved on the server when the text is exported or sent by email. The attribute name in the macro is not validated and is used as a method name on the referenced record. A user who can write rich text can therefore make the server call arbitrary public zero-argument methods on any work package or project visible to the user who exports the text or receives the email. This allows deleting records (e.g. `destroy`) as well as reading data that is not exposed otherwise (e.g. `attributes`).

Found internally by the OpenProject team during a code audit following GHSA-9c69-v342-vqr7.

For more information, please see the [GitHub advisory #GHSA-pggp-67cq-xgrg](https://github.com/opf/openproject/security/advisories/GHSA-pggp-67cq-xgrg)

### GHSA-q9gv-q2h3-7g3x - Second factor bypass through authentication stages kept in the session
OpenProject left authentication-stage data in the session when a new password login starts. The session is supposed to drop the previous stage, its completion secret, and the stored back URL, but they were not fully cleaned up.

When an authentication stage is active, such as TOTP, a remote attacker who already knows another user&#x27;s password and can complete the stage for their own account can reuse their own stage completion link, in the same browser session, after submitting the other user&#x27;s password. The session is then logged in as that user, and that user&#x27;s stage is never completed.

For more information, please see the [GitHub advisory #GHSA-q9gv-q2h3-7g3x](https://github.com/opf/openproject/security/advisories/GHSA-q9gv-q2h3-7g3x)

### GHSA-rhcj-h663-7v7w - Arbitrary zero-argument method invocation on visible work packages via the date picker `focused_field` parameter
The work package date picker passes the `focused_field` request parameter unvalidated into the date form component, which uses it as a method name on the work package (`public_send`). Any user who can view a work package can call arbitrary public zero-argument methods on it — including `destroy` — with a single GET request.

Found internally by the OpenProject team during a code audit following GHSA-9c69-v342-vqr7.

For more information, please see the [GitHub advisory #GHSA-rhcj-h663-7v7w](https://github.com/opf/openproject/security/advisories/GHSA-rhcj-h663-7v7w)

<!-- END SECURITY FIXES AUTOMATED SECTION -->
<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->


<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->
