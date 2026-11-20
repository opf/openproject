---
title: OpenProject 17.9.8
sidebar_navigation:
    title: 17.9.8
release_version: 17.9.8
release_date: 2026-11-19
---

# OpenProject 17.9.8

Release date: 2026-11-19

We released [OpenProject 17.9.8](https://community.openproject.org/versions/2355).
The release contains several bug fixes and we recommend updating to the newest version.
Below you will find a complete list of all changes and bug fixes.
<!-- BEGIN SECURITY FIXES AUTOMATED SECTION -->
## Security fixes

### GHSA-27qw-695p-p8gg - Missing authorization (CWE-862/CWE-639) in meeting agenda items new renders foreign meeting section titles
A broken authorization call resulted in rendering arbitrary meeting section titles in the show component functionality of a meeting.

This report has been responsibly disclosed by GitHub user [TianMaXingK](https://github.com/TianMaXingK) through GitHub advisories.

For more information, please see the [GitHub advisory #GHSA-27qw-695p-p8gg](https://github.com/opf/openproject/security/advisories/GHSA-27qw-695p-p8gg)

### GHSA-cm9j-c5pc-q325 - Activity-details cache replays phase-journal details to users lacking view_project_phases
OpenProject 17.9.7 returns permission-gated work package activity details through a shared representation cache. After a user with `view_project_phases` renders an activity, a member who can read the same work package but lacks that permission receives the phase-journal text. The same applies to changes of work package custom fields the member is not allowed to see: once a user who can see the custom field has rendered the activity, the member receives the old and new values of that field. When the unpermitted member renders first, the cached denial is returned to an authorized reader.

This report has been responsibly disclosed by GitHub user [turboflexer](https://github.com/turboflexer) through GitHub advisories.

For more information, please see the [GitHub advisory #GHSA-cm9j-c5pc-q325](https://github.com/opf/openproject/security/advisories/GHSA-cm9j-c5pc-q325)

### GHSA-gp67-gx74-36wg - Missing authorization (CWE-862/CWE-639) in meeting agenda items cancel_new renders foreign meeting section titles
A broken authorization call resulted in rendering arbitrary meeting section titles in the `cancel_new` functionality of a meeting.

This report has been responsibly disclosed by GitHub user [TianMaXingK](https://github.com/TianMaXingK) through GitHub advisories.

For more information, please see the [GitHub advisory #GHSA-gp67-gx74-36wg](https://github.com/opf/openproject/security/advisories/GHSA-gp67-gx74-36wg)

### GHSA-hg98-84jc-26px - Invitation mails render the message as the inviter, leaking a private work package's subject
The email sent when a user is added to a project, or their roles are changed, can include a message written by the sender. That message is rendered with the permissions of the sender, not of the recipient. Work package references such as `###123` in the message show the referenced work package's type, status and subject.

When the sender can see a work package that the recipient cannot see, the recipient gets these details in the email.

This report has been responsibly disclosed by [EZO Labs Security](https://ezolabs.net/) through e-mail.

For more information, please see the [GitHub advisory #GHSA-hg98-84jc-26px](https://github.com/opf/openproject/security/advisories/GHSA-hg98-84jc-26px)

### GHSA-hrw9-6pqq-mmrq - Server-side request forgery via Subversion and Git repository URLs
The repository module allowed project members with the &quot;Manage repository&quot; permission to link Subversion and Git repositories by URL without restricting the target host. This allowed using the server&#x27;s &#x60;svn&#x60; and &#x60;git&#x60; clients to send requests to internal hosts, such as loopback addresses, private network ranges or cloud metadata endpoints. The responses were not returned to the user: error details were only written to the server log, and the user could only tell whether the repository loaded, and how long the attempt took. If an internal Subversion or Git server was reachable without authentication, however, its contents could be browsed through OpenProject.

Repository URLs are now checked against the [SSRF protection](https://www.openproject.org/docs/installation-and-operations/configuration/ssrf-protection/) when they are set, i.e. when a repository is linked or its URL is changed. Since the `svn` and `git` clients resolve the host themselves on every access, this check cannot protect against DNS rebinding, where a hostname resolves to a public address during the check and to an internal address later. Administrators who do not need remote repositories should consider disabling them. See [SSRF protection for remote repositories](https://www.openproject.org/docs/installation-and-operations/configuration/repositories/#ssrf-protection-for-remote-repositories) for details.

This report has been responsibly disclosed by GitHub user [soloway-alt](https://github.com/soloway-alt) through GitHub advisories.

For more information, please see the [GitHub advisory #GHSA-hrw9-6pqq-mmrq](https://github.com/opf/openproject/security/advisories/GHSA-hrw9-6pqq-mmrq)

### GHSA-m4jc-3j97-vrxv - API v3 work-package representer cache is shared across users with different custom-field visibility, leaking admin-only custom-field values to non-admins
The API v3 JSON cache for work packages is keyed by object + locale + project + the work package&#x27;s available custom fields, but not by the requesting user. The representer class, however, is chosen per user: admins get a class with admin-only custom-field properties injected, non-admins get a class without them. As those custom fields get cached between requests, they are rendered into the shared cached response. When an admin&#x27;s response is cached first, a non-admin reading the same work package receives the admin-only custom fields with their values. The reverse also occurs (a non-admin&#x27;s cached response omits fields from admin responses). But, it was never intended to build work package custom fields that got visibility only for admins. Admins could create them with a crafted request to the server, which is now also prevented.

This report has been responsibly disclosed by GitHub user [Ravin06](https://github.com/Ravin06) through GitHub advisories.

For more information, please see the [GitHub advisory #GHSA-m4jc-3j97-vrxv](https://github.com/opf/openproject/security/advisories/GHSA-m4jc-3j97-vrxv)

### GHSA-m6gr-38w2-w34w - Download location of external storage attachments ignores the virus scan status
When attachments are stored in an external object storage, the API returns a signed storage URL as the download location. The URL is returned even when the attachment is quarantined by the virus scanner or is still waiting for its scan.

A user who can see the attachment's container can download quarantined files, and files that were not scanned yet, directly from the storage. This only applies when virus scanning is enabled and attachments are stored in an external object storage.

This report has been responsibly disclosed by GitHub user SAYUTIM through GitHub advisories.

For more information, please see the [GitHub advisory #GHSA-m6gr-38w2-w34w](https://github.com/opf/openproject/security/advisories/GHSA-m6gr-38w2-w34w)

### GHSA-xvh8-793v-rp59 - PATCH /api/v3/meeting_outcomes/:id can move another user's outcome out of a meeting the caller may only view: the contract checks manage_outcomes on the new agenda item only
An incorrect authorization check resulted in meeting outcomes being moved to another meeting the user has no access to.

This report has been responsibly disclosed by GitHub user [tsurutanmen](https://github.com/tsurutanmen) through GitHub advisories.

For more information, please see the [GitHub advisory #GHSA-xvh8-793v-rp59](https://github.com/opf/openproject/security/advisories/GHSA-xvh8-793v-rp59)

<!-- END SECURITY FIXES AUTOMATED SECTION -->
<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->


<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->
