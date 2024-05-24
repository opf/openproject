---
title: OpenProject 14.0.2
sidebar_navigation:
    title: 14.0.2
release_version: 14.0.2
release_date: 2024-05-22
---

# OpenProject 14.0.2

Release date: 2024-05-22

We released [OpenProject 14.0.2](https://community.openproject.org/versions/2057).
The release contains several bug fixes and we recommend updating to the newest version.

### Fixes a stored XSS vulnerability in the cost report functionality (CVE-2024-135224)
OpenProject Cost Report functionality uses improper sanitization of user input. This can lead to Stored XSS via the header values of the report table. This attack requires the permissions "Edit work packages" as well as "Add attachments".

For more information, [please see our security advisory](https://github.com/opf/openproject/security/advisories/GHSA-h26c-j8wg-frjc).

<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Bugfix: Improper escaping of custom field values in cost report \[[#55198](https://community.openproject.org/wp/55198)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->

## Credits

Thanks for finding and disclosing the vulnerability responsibly go to [Sean Marpo](https://github.com/seanmarpo). Thank you for reaching out to us and helping in identifying this issue.
