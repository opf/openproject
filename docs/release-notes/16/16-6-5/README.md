---
title: OpenProject 16.6.5
sidebar_navigation:
    title: 16.6.5
release_version: 16.6.5
release_date: 2026-01-16
---

# OpenProject 16.6.5

Release date: 2026-01-16

We released OpenProject [OpenProject 16.6.5](https://community.openproject.org/versions/2253).
The release contains several bug fixes and we recommend updating to the newest version.
Below you will find a complete list of all changes and bug fixes.

## Security Fixes

### CVE-2026-23646 - Users can delete other user's session, causing them to be logged out

Users in OpenProject have the ability to view and end their active sessions via **Account Settings → Sessions**. When deleting a session, it was not properly checked if the session belongs to the user. As the ID that is used to identify these session objects use incremental integers, users could iterate requests using `DELETE /my/sessions/:id` and thus unauthenticate other users.

Users did not have access to any sensitive information (like browser identifier, IP addresses, etc) of other users that are stored in the session.

This vulnerability was assigned as CVE-2026-23646.
For more information, please see the [GitHub Advisory GHSA-w422-xf8f-v4vp)](https://github.com/opf/openproject/security/advisories/GHSA-w422-xf8f-v4vp).

The vulnerability has been responsibly disclosed through the [YesWeHack bounty program for OpenProject](https://yeswehack.com/programs/openproject). This bug bounty program is being sponsored by the European Commission.

### CVE-2026-23721 - Users with "View Members" permission in any project can view all Group memberships

When using [groups](../../../system-admin-guide/users-permissions/groups/) in OpenProject to manage users, the group members should only be visible to users that have the _View Members_ permission in **any project** that the group is also a member of.
Due to a failed permission check, if a user had the _View Members_ permission in any project, they could enumerate all Groups and view which other users are part of the group.

This vulnerability was assigned as CVE-2026-23721.
For more information, please see the [GitHub Advisory GHSA-vj77-wrc2-5h5h)](https://github.com/opf/openproject/security/advisories/GHSA-vj77-wrc2-5h5h).

The vulnerability has been responsibly disclosed through the [YesWeHack bounty program for OpenProject](https://yeswehack.com/programs/openproject). This bug bounty program is being sponsored by the European Commission.

### CVE-2026-23625 - Stored XSS regression on OpenProject using attachments and script-src self

OpenProject versions >= 16.3.0, < 16.6.5, < 17.0.1 is affected by a stored XSS vulnerability in the Roadmap view. OpenProject’s roadmap view renders the “Related work packages” list for each version. When a version contains work packages from a different project (e.g., a subproject), the helper link_to_work_package prepends package.project.to_s to the link and returns the entire string with .html_safe. Because project names are user-controlled and no escaping happens before calling html_safe, any HTML placed in a subproject name is injected verbatim into the page.

This vulnerability was assigned as CVE-2026-23625.
For more information, please see the [GitHub Advisory GHSA-cvpq-cc56-gwxx)](https://github.com/opf/openproject/security/advisories/GHSA-cvpq-cc56-gwxx).

The vulnerability has been responsibly disclosed through the [YesWeHack bounty program for OpenProject](https://yeswehack.com/programs/openproject). This bug bounty program is being sponsored by the European Commission.

<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Bugfix: Add default framework headers removed in secure\_headers \[[#70384](https://community.openproject.org/wp/70384)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->
