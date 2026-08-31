---
title: OpenProject 16.6.2
sidebar_navigation:
    title: 16.6.2
release_version: 16.6.2
release_date: 2025-12-02
---

# OpenProject 16.6.2

Release date: 2025-12-02

We released OpenProject [OpenProject 16.6.2](https://community.openproject.org/versions/2243).
The release contains security relevant bug fixes and we strongly urge updating to the newest version.
Below you will find a complete list of all changes and bug fixes.

The reported vulnerabilities have been reported as part of a Pentest by [Mantodea Security GmbH](https://mantodeasecurity.de/).
Thank you for your cooperation and responsible disclosure of the vulnerabilities

## CVEs

### CVE-2026-22601 - Code Execution in E-Mail function

For OpenProject version 16.6.1 and below, a registered administrator can execute arbitrary command by configuring sendmail binary path and sending a test email.

This vulnerability was assigned to the CVE CVE-2026-22601.
For more information, please see the [GitHub Advisory GHSA-9vrv-7h26-c7jc)](https://github.com/opf/openproject/security/advisories/GHSA-9vrv-7h26-c7jc).

### CVE-2026-22602 - User Enumeration via User ID

A low‑privileged logged-in user can view the full names of other users. The full name corresponding to any arbitrary user ID can be retrieved via the following URL, even if the requesting account has only minimal permissions:

This vulnerability was assigned to the CVE CVE-2026-22602.
For more information, please see the [GitHub Advisory GHSA-7fvx-9h6h-g82j](https://github.com/opf/openproject/security/advisories/GHSA-7fvx-9h6h-g82j).

### CVE-2026-22603 - No protection against brute-force attacks in the Change Password function

OpenProject’s unauthenticated password-change endpoint (/account/change_password) was not protected by the same brute-force safeguards that apply to the normal login form.
In affected versions, an attacker who can guess or enumerate user IDs can send unlimited password-change requests for a given account without triggering lockout or other rate-limiting controls.

This vulnerability was assigned to the CVE CVE-2026-22603.
For more information, please see the [GitHub Advisory GHSA-93x5-prx9-x239](https://github.com/opf/openproject/security/advisories/GHSA-93x5-prx9-x239).

### CVE-2026-22604 - User enumeration via the change password function

When sending a POST request to the /account/change_password endpoint with an arbitrary User ID as the password_change_user_id parameter, the resulting error page would show the username for the requested user. Since this endpoint is intended to be called without being authenticated, this allows to enumerate the user names of all accounts registered in an OpenProject instance.

This vulnerability was assigned to the CVE CVE-2026-22604.
For more information, please see the [GitHub Advisory GHSA-q7qp-p3vw-j2fh](https://github.com/opf/openproject/security/advisories/GHSA-q7qp-p3vw-j2fh).

<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Bugfix: Error when creating a new work package after the previous one is opened in details view \[[#67980](https://community.openproject.org/wp/67980)\]
- Bugfix: OpenID Connect: Claims escaped twice \[[#69079](https://community.openproject.org/wp/69079)\]
- Bugfix: Disable editing of sendmail attributes through UI \[[#69577](https://community.openproject.org/wp/69577)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->

## Contributions

A big thanks to our Community members for reporting bugs and helping us identify and provide fixes.
This release, special thanks for reporting and finding bugs go to Александр Татаринцев.
