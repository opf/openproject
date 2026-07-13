---
title: OpenProject 16.3.1
sidebar_navigation:
    title: 16.3.1
release_version: 16.3.1
release_date: 2025-08-13
---

# OpenProject 16.3.1

Release date: 2025-08-13

We released OpenProject [OpenProject 16.3.1](https://community.openproject.org/versions/2218).

A bug was identified that prevents the user account menu from displaying correctly if you use a [direct login provider](../../../system-admin-guide/authentication/login-registration-settings/) instead of the standard login form.
If you are not using a direct login provider, you are not affected by this.

The release also contains some additional bug fixes that were not ready in time for the 16.3.0 release.

Below, we will give an overview of all bug fixes

<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Bugfix: OIDC post logout redirect uri not working \[[#65910](https://community.openproject.org/wp/65910)\]
- Bugfix: ArgumentError in VersionsController#show \[[#66534](https://community.openproject.org/wp/66534)\]
- Bugfix: Opendesk Projects UI shows unnecessary login button \[[#66537](https://community.openproject.org/wp/66537)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->
