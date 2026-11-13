---
title: OpenProject 17.9.7
sidebar_navigation:
    title: 17.9.7
release_version: 17.9.7
release_date: 2026-11-09
---

# OpenProject 17.9.7

Release date: 2026-11-09

We released [OpenProject 17.9.7](https://community.openproject.org/versions/2346).
The release contains several bug fixes and we recommend updating to the newest version.
Below you will find a complete list of all changes and bug fixes.
<!-- BEGIN SECURITY FIXES AUTOMATED SECTION -->
## Security fixes

### GHSA-773c-7fc3-342g - Open redirect on /external_redirect without a session
The external link page (`/external_redirect`) redirected visitors straight to any given URL when external link capture was disabled or not covered by an Enterprise token. No login was needed. A link on the domain of an OpenProject instance could therefore send visitors to any website, which could be used for phishing.

The page now always shows the "Leaving OpenProject" warning with the target address. Visitors have to confirm before they leave, whether or not external link capture is enabled.

This report has been responsibly disclosed by GitHub user [gputier](https://github.com/gputier) through GitHub advisories.

For more information, please see the [GitHub advisory #GHSA-773c-7fc3-342g](https://github.com/opf/openproject/security/advisories/GHSA-773c-7fc3-342g)

### GHSA-9c69-v342-vqr7 - Arbitrary zero-argument method invocation on visible projects via unvalidated attribute parameter in `InplaceEditFieldsController`
This release fixes a critical vulnerability (CVSS 3.1 score **9.4**) in the in-place editing endpoint for project attributes. Users who could view a project were able to trigger unintended operations on it, including deleting the project and its subprojects and reading information they were not permitted to see. On public instances, without required login, this was possible for anonymous users. All versions from 17.2.0 onward are affected. Outside of our usual policy to only release patches for the currently supported version, for this critical vulnerability we will be issuing patches for versions 17.9.7, 17.8.2, 17.7.3, 17.6.1 and 17.5.2. Installations running 17.2 to 17.4 should upgrade to one of these releases.

Thanks to GitHub user [ccsimplyspolit](https://github.com/ccsimplyspolit) for responsibly disclosing this issue.

For more information, please see the [GitHub advisory #GHSA-9c69-v342-vqr7](https://github.com/opf/openproject/security/advisories/GHSA-9c69-v342-vqr7)

### GHSA-g75c-9rjg-8cvj - Read-only repository members can push to Git repositories through a query string in the Smart HTTP URL
OpenProject decides if a Git Smart HTTP request is a read or a write by matching the request URI against a pattern for `git-receive-pack`. The pattern is anchored at the end of the URI and includes the query string. When a query string is added or the parameters are reordered, the request is treated as a read.

A project member with only the "Browse repository" permission can therefore push to a managed Git repository that is served through the Apache integration, although pushing requires the "Commit access" permission.

This report has been responsibly disclosed by GitHub user [OXWaidwerk](https://github.com/ChristianTeroerde) through GitHub advisories.

For more information, please see the [GitHub advisory #GHSA-g75c-9rjg-8cvj](https://github.com/opf/openproject/security/advisories/GHSA-g75c-9rjg-8cvj)

### GHSA-jwhj-v5mg-3f4f -  POST /api/v3/storages: a normal non-admin user reaches constantize.new because the admin check runs after the object is built
`POST /api/v3/storages` resolved the requested storage provider type with `constantize` before checking permissions. An authenticated non-admin user could make the server look up and instantiate arbitrary classes, but the request always ended in an error response for that user. No data was exposed or changed, and other users weren't affected. Provider types are now resolved against a fixed list of known storage providers.

The vulnerability was responsibly disclosed by GitHub user [0xVijay](https://github.com/0xVijay) via GitHub security advisories.

For more information, please see the [GitHub advisory #GHSA-jwhj-v5mg-3f4f](https://github.com/opf/openproject/security/advisories/GHSA-jwhj-v5mg-3f4f)

### GHSA-pggp-67cq-xgrg - Arbitrary zero-argument method invocation on visible projects and work packages via attribute macros in exports and emails
Attribute macros (`workPackageValue:…` / `projectValue:…`) in rich text are resolved on the server when the text is exported or sent by email. The attribute name in the macro is not validated and is used as a method name on the referenced record. A user who can write rich text can therefore make the server call arbitrary public zero-argument methods on any work package or project visible to the user who exports the text or receives the email. This allows deleting records (e.g. `destroy`) as well as reading data that is not exposed otherwise (e.g. `attributes`).

Found internally by the OpenProject team during a code audit following GHSA-9c69-v342-vqr7.

For more information, please see the [GitHub advisory #GHSA-pggp-67cq-xgrg](https://github.com/opf/openproject/security/advisories/GHSA-pggp-67cq-xgrg)

### GHSA-pv79-v2hf-5gg8 - Anonymous password change endpoint has no per-account limit and works on normal accounts
This report has been responsibly disclosed by GitHub user gputier through GitHub advisories.

For more information, please see the [GitHub advisory #GHSA-pv79-v2hf-5gg8](https://github.com/opf/openproject/security/advisories/GHSA-pv79-v2hf-5gg8)

### GHSA-q9gv-q2h3-7g3x - Second factor bypass through authentication stages kept in the session
OpenProject left authentication-stage data in the session when a new password login starts. The session is supposed to drop the previous stage, its completion secret, and the stored back URL, but they were not fully cleaned up.

When an authentication stage is active, such as TOTP, a remote attacker who already knows another user&#x27;s password and can complete the stage for their own account can reuse their own stage completion link, in the same browser session, after submitting the other user&#x27;s password. The session is then logged in as that user, and that user&#x27;s stage is never completed.

For more information, please see the [GitHub advisory #GHSA-q9gv-q2h3-7g3x](https://github.com/opf/openproject/security/advisories/GHSA-q9gv-q2h3-7g3x)

### GHSA-rhcj-h663-7v7w - Arbitrary zero-argument method invocation on visible work packages via the date picker `focused_field` parameter
The work package date picker passes the `focused_field` request parameter unvalidated into the date form component, which uses it as a method name on the work package (`public_send`). Any user who can view a work package can call arbitrary public zero-argument methods on it — including `destroy` — with a single GET request.

Found internally by the OpenProject team during a code audit following GHSA-9c69-v342-vqr7.

For more information, please see the [GitHub advisory #GHSA-rhcj-h663-7v7w](https://github.com/opf/openproject/security/advisories/GHSA-rhcj-h663-7v7w)

### GHSA-vjqq-p9g9-42wx - Activity page discloses the names of users outside the reader's visibility
The activity page accepts a `user_id` parameter to filter the activity by author. OpenProject looks up any active user with this ID and shows the user's name in the page title and in the Atom feed.

A user who can view project activity can read the names of all active users by their ID, including users they cannot see anywhere else.

This report has been responsibly disclosed by GitHub user turboflexer through GitHub advisories.

For more information, please see the [GitHub advisory #GHSA-vjqq-p9g9-42wx](https://github.com/opf/openproject/security/advisories/GHSA-vjqq-p9g9-42wx)

### GHSA-vpg6-crgp-fc2h - Relations filter returns relations of work packages the user cannot see
In the relations endpoint of the API (`/api/v3/relations`), the `involved`, `from` and `to` filters did not check work package visibility for operators other than &quot;is&quot; (`=`) and &quot;is not&quot; (`!`). An authenticated user could combine the `involved` filter with an operator such as `>=`, `<=` or `*` to list relations across the whole instance, including work package titles from projects they are not a member of. The `from` and `to` filters failed with a server error for these operators instead of returning data.

These filters now only accept the &quot;is&quot; and &quot;is not&quot; operators. Requests that use any other operator are rejected as invalid. Requests that use &quot;is&quot; or &quot;is not&quot;, including those the OpenProject web interface sends, are not affected.

This report has been responsibly disclosed by GitHub user [gputier](https://github.com/gputier) through GitHub advisories.

For more information, please see the [GitHub advisory #GHSA-vpg6-crgp-fc2h](https://github.com/opf/openproject/security/advisories/GHSA-vpg6-crgp-fc2h)

### GHSA-x252-j3fp-j593 - Mention emails render work package references with the author's permissions
The email that is sent when a user is mentioned in a comment is rendered with the permissions of the comment's author, not of the recipient. Work package references such as `###123` in the comment show the referenced work package's type, status and subject.

When the author can see a work package that the recipient cannot see, the recipient gets these details in the email. In the web interface, the same reference is shown only as a number.

This report has been responsibly disclosed by GitHub user zerodaybugs through GitHub advisories.

For more information, please see the [GitHub advisory #GHSA-x252-j3fp-j593](https://github.com/opf/openproject/security/advisories/GHSA-x252-j3fp-j593)

### GHSA-xpmj-x5hg-hq6j - Work package activity shows the project phase to users without view_project_phases
Changes to the project phase of a work package are recorded in the work package activity. The activity shows the name of the phase without checking the "View project phases" permission.

A user who can view work packages but not project phases can read the phase of work packages through the activity tab and the activities API.

This report has been responsibly disclosed by GitHub user turboflexer through GitHub advisories.

For more information, please see the [GitHub advisory #GHSA-xpmj-x5hg-hq6j](https://github.com/opf/openproject/security/advisories/GHSA-xpmj-x5hg-hq6j)

<!-- END SECURITY FIXES AUTOMATED SECTION -->
<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Bugfix: Slow project overview page due to members widget loading data slowly  \[[#81738](https://community.openproject.org/wp/81738)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->
