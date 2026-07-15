---
title: OpenProject 15.0.1
sidebar_navigation:
    title: 15.0.1
release_version: 15.0.1
release_date: 2024-11-13
---

# OpenProject 15.0.1

Release date: 2024-11-13

We released OpenProject [OpenProject 15.0.1](https://community.openproject.org/versions/2157).
This release contains an important fix for OpenID Connect providers using Microsoft Entra.
The tenant of the Azure environment was not correctly communicated to the provider, resulting in failing logins.

This has been fixed. If you are affected by this issue, please update to 15.0.1 and logins should be restored.

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Bugfix: OpenID Connect Microsoft Entra: Tenant not correctly output \[[#59261](https://community.openproject.org/wp/59261)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->
