---
title: OpenProject 17.4.1
sidebar_navigation:
    title: 17.4.1
release_version: 17.4.1
release_date: 2026-06-08
---

# OpenProject 17.4.1

Release date: 2026-06-08

We released [OpenProject 17.4.1](https://community.openproject.org/versions/2301).
The release contains several bug fixes and we recommend updating to the newest version.
Below you will find a complete list of all changes and bug fixes.
<!-- BEGIN SECURITY FIXES AUTOMATED SECTION -->
## Security fixes

### CVE-2026-47193 - Journal diff endpoint bypasses object, journal, and field visibility checks
This vulnerability was reported as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission.

For more information, please see the [GitHub advisory #GHSA-f2rx-x2qj-2hgj](https://github.com/opf/openproject/security/advisories/GHSA-f2rx-x2qj-2hgj)

### CVE-2026-49355 - Private work package data disclosure through single meeting agenda item API
`GET /api/v3/meetings/:meeting_id/agenda_items/:agenda_item_id` discloses private work package data from a linked work package that belongs to a private/inaccessible project.

This vulnerability was reported as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission.

For more information, please see the [GitHub advisory #GHSA-g387-6rm2-xw88](https://github.com/opf/openproject/security/advisories/GHSA-g387-6rm2-xw88)

### GHSA-3vpx-94qx-xpw6 - IDOR through /projects/<A>/settings/project_storages/<A_ps_id> via PATCH parameter "storages_project_storage[project_folder_id]" leads to Access to Unauthorized Resources
A project-admin in one project can hijack the managed Nextcloud or OneDrive folder of another project on the same storage by writing the victim project&#39;s `project_folder_id` into the attacker&#39;s `Storages::ProjectStorage` row. The next managed-folder sync overwrites the ACL on the referenced folder with the attacker project&#39;s user list.

This vulnerability was reported as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission.

For more information, please see the [GitHub advisory #GHSA-3vpx-94qx-xpw6](https://github.com/opf/openproject/security/advisories/GHSA-3vpx-94qx-xpw6)

### GHSA-6crw-7f5r-4qj9 - CSRF on TARGET through /users/:id via POST parameter "user[admin]"
Turbo Drive auto-injects CSRF tokens (from `<meta name="csrf-token">`) on forms injected via the XSS&#39;s `append` Turbo Stream action. A second action, `dispatch_event` with `name="submit"`, auto-submits the form with no victim interaction beyond viewing the work package, resulting in a CSRF attack

This vulnerability was reported as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission.

For more information, please see the [GitHub advisory #GHSA-6crw-7f5r-4qj9](https://github.com/opf/openproject/security/advisories/GHSA-6crw-7f5r-4qj9)

### GHSA-98vw-2r87-fx2r - SQL injection in timestamps functionality
OpenProject baseline comparison allows callers to request historic work-package attributes using the `timestamps` parameter.

The timestamp parser accepts a relative date keyword on the first line because its regular expression uses line anchors. The parser validates the input, but the original multi-line string is kept and later interpolated into a raw SQL `CASE ... THEN '<timestamp>'` expression.

An authenticated user who can save a query can persist a timestamp array value containing literal commas and trigger a top-level data-modifying CTE. This gives the attacker a generic database write primitive as the OpenProject application database role.

The demonstrated impact is administrator privilege escalation: the attacker uses that write primitive to update their own account record, setting the account&#39;s administrator flag to true. The same injection also allows in-band data disclosure through work-package timestamp metadata.

This vulnerability was reported as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission.

For more information, please see the [GitHub advisory #GHSA-98vw-2r87-fx2r](https://github.com/opf/openproject/security/advisories/GHSA-98vw-2r87-fx2r)

### GHSA-h83w-5q5x-pq27 - Information Disclosure (cleartext storage of data) on localhost through memcached via Others "storage.<id>.httpx_access_token" leads to Sensitive Data Exposure
OpenProject&#39;s Storages module writes the OneDrive/SharePoint userless OAuth `access_token` plaintext to `Rails.cache` under the deterministic key `storage.<id>.httpx_access_token`, repopulated continuously by an hourly cron and every userless-OAuth call site (see Write cadence). None of the three allowed cache backends (`file_store`, `memcache`, `redis`) encrypts at rest. An attacker with read access to the cache backend recovers the Azure-AD application-tier bearer with an anonymous `get` over the memcached binary protocol (or the equivalent against Redis)

This vulnerability was reported as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission.

For more information, please see the [GitHub advisory #GHSA-h83w-5q5x-pq27](https://github.com/opf/openproject/security/advisories/GHSA-h83w-5q5x-pq27)

### GHSA-q33w-f822-hg8x - Stored XSS on openproject.example.com through /api/v3/projects/{project}/work_packages via POST parameter "description"
The HTML sanitizer grants `<macro>` elements unrestricted `data-*` attributes via `:data` wildcard. An attacker injects `data-controller="poll-for-changes"` into a work package description, causing Stimulus.js to mount a controller that fetches an attacker-uploaded attachment and passes it to `renderStreamMessage()`. This executes arbitrary Turbo Stream actions — including `redirect_to` — in every victim&#39;s authenticated browser session, redirecting them to an attacker-controlled server.

This vulnerability was reported as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission.

For more information, please see the [GitHub advisory #GHSA-q33w-f822-hg8x](https://github.com/opf/openproject/security/advisories/GHSA-q33w-f822-hg8x)

### GHSA-qj96-f42f-6336 - Cache store poisoning leads to Remote Code Execution (RCE)
This vulnerability was reported as part of the [YesWeHack.com OpenProject Bug Bounty program](https://yeswehack.com/programs/openproject), sponsored by the European Commission.

For more information, please see the [GitHub advisory #GHSA-qj96-f42f-6336](https://github.com/opf/openproject/security/advisories/GHSA-qj96-f42f-6336)

<!-- END SECURITY FIXES AUTOMATED SECTION -->
<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Bugfix: Migration 20250929070310 failing due to update code failing on not-yet fully migrated schema \[[#75286](https://community.openproject.org/wp/75286)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->

## Contributions
A big thanks to our Community members for reporting bugs and helping us identify and provide fixes.
This release, special thanks for reporting and finding bugs go to Alexander Aleschenko.
