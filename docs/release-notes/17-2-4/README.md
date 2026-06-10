---
title: OpenProject 17.2.4
sidebar_navigation:
    title: 17.2.4
release_version: 17.2.4
release_date: 2026-05-13
---

 # OpenProject 17.2.4

 Release date: 2026-05-13

 We released [OpenProject 17.2.4](https://community.openproject.org/versions/2300).
 The release contains several bug fixes and we recommend updating to the newest version.
 Below you will find a complete list of all changes and bug fixes.

<!-- BEGIN CVE AUTOMATED SECTION -->

## Security fixes



### CVE-2026-46386 - Docker Container starts with SECRET_KEY_BASE default value

When an attacker knew the secret key base that the application used to derive internal keys from, they could construct encrypted cookies that on the server side were decoded using [Object Marshalling](https://docs.ruby-lang.org/en/4.0/Marshal.html) which allowed the attacker to execute almost arbitrary ruby code within the container, up to a complete remote code execution. This was especially present in Docker containers that shipped with a default value as the secret key base, when it was not manually overwritten, as mentioned in the documentation.



As a fix, the docker containers now validate that a proper `SECRET_KEY_BASE` environment variable is set Otherwise the application aborts the boot process with an error message. The documentation has been updated to make it even clearer, that the `SECRET_KEY_BASE` env variable must be set. And the decoding of the encrypted cookies has been updated to use JSON encoding instead of Object Marshalling.&nbsp;



**Administrators that have not set a `SECRET_KEY_BASE` environment before need to set one now. Otherwise the application will not boot.**



**This will force all users using 2 factor authentication to authenticate on their next login, even if they have saved a cookie to skip 2FA for the next 14 days.**



This vulnerability was responsibly reported by GitHub user [hkolvenbach](https://github.com/hkolvenbach).



For more information, please see the [GitHub advisory #GHSA-r85r-gjq2-f83r](https://github.com/opf/openproject/security/advisories/GHSA-r85r-gjq2-f83r)



### CVE-2026-44731 - Improper Access Control on OpenProject through /projects/[projectName]/meetings via "invited_user_id" in GET parameter "filters" leads to user names disclosure

The web application&#39;s meetings filter feature leaks whether a given user ID corresponds to a valid account and discloses the user&#39;s full name, allowing an attacker to enumerate all existing user accounts by probing user IDs and observing differences in the server response.



This vulnerability was reported by user tuannq\_gg as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission.



For more information, please see the [GitHub advisory #GHSA-x7j3-cfgf-7mc4](https://github.com/opf/openproject/security/advisories/GHSA-x7j3-cfgf-7mc4)



### CVE-2026-44732 - IDOR on OpenProject through /api/v3/documents/{id} via PATCH parameter "project_id" leads to Unauthorized Modification of Resources

OpenProject exposes a document update endpoint used to modify existing documents. The target document is loaded with visibility checks and then updated .



During update, attacker-controlled attributes are applied to the persisted record before authorization is enforced. As a result, a user without `:manage_documents` in the source project can move and modify foreign project documents by setting `project_id` in a single PATCH request.



This vulnerability was reported by sam91281 as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission.



For more information, please see the [GitHub advisory #GHSA-mqvv-5mvc-7pg7](https://github.com/opf/openproject/security/advisories/GHSA-mqvv-5mvc-7pg7)



### CVE-2026-44733 - Business Logic Error on OpenProject through PATCH request to /api/v3/users/me permits to bypass password requirements

A password validation flaw in the change password behavior allows attackers to change a user&#39;s password only with an active session takeover.



<br>



This vulnerability was reported by user herdiyanitdev as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission.



For more information, please see the [GitHub advisory #GHSA-px7f-cj9f-7m4m](https://github.com/opf/openproject/security/advisories/GHSA-px7f-cj9f-7m4m)



### CVE-2026-44734 - Improper Access Control on OpenProject through the POST request to /projects/[PROJECT_NAME]/cost_reports/[REPORT_ID]/rename

A Missing Authorization vulnerability exists in OpenProject&#39;s CostReportsController. The rename and update actions allow any authenticated user to modify the name, filters, and grouping of any Public cost report in the system without verifying ownership or permission level.

An attacker who discovers or guesses a public report&#39;s numeric ID can rename or overwrite its filter configuration without any warning to the report&#39;s owner.



This vulnerability was reported by user herdiyanitdev as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission.



For more information, please see the [GitHub advisory #GHSA-c767-34gh-gh2h](https://github.com/opf/openproject/security/advisories/GHSA-c767-34gh-gh2h)



### CVE-2026-44735 - Shares API Information Disclosure

The `GET /api/v3/shares` endpoint returns share details for ALL work packages in a project to any user with the `view_shared_work_packages` permission. The authorization check operates at the **project level** only — it does not verify the requesting user can actually view each individual shared work package.



This vulnerability was reported by GitHub user [DAVIDAROCA27](https://github.com/DAVIDAROCA27).



For more information, please see the [GitHub advisory #GHSA-cfg3-f34w-9xx5](https://github.com/opf/openproject/security/advisories/GHSA-cfg3-f34w-9xx5)


<!-- END CVE AUTOMATED SECTION -->

<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->


<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->
