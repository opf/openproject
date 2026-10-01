---
title: OpenProject 16.0.1
sidebar_navigation:
    title: 16.0.1
release_version: 16.0.1
release_date: 2025-06-05
---

# OpenProject 16.0.1

Release date: 2025-06-05

We released OpenProject [OpenProject 16.0.1](https://community.openproject.org/versions/2200).
The release contains several bug fixes and we recommend updating to the newest version.
In these Release Notes, we will give an overview of important feature changes.
At the end, you will find a complete list of all changes and bug fixes.

<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Feature: Add internal:boolean property to activity comments (read) API \[[#62130](https://community.openproject.org/wp/62130)\]
- Bugfix: Some dates and scheduling mode are lost when creating project from template \[[#62426](https://community.openproject.org/wp/62426)\]
- Bugfix: Edge case when creating a section for an empty non-blankslate meeting \[[#63422](https://community.openproject.org/wp/63422)\]
- Bugfix: Error when dragging a work package to its children in work packages list \[[#63499](https://community.openproject.org/wp/63499)\]
- Bugfix: Creation of sub-items in hierarchy custom field not possible (error 500) \[[#63855](https://community.openproject.org/wp/63855)\]
- Bugfix: Missing/wrong error handling for periodic activity tab updates \[[#64073](https://community.openproject.org/wp/64073)\]
- Bugfix: Polling meeting updates can cause Browser&#39;s Basic auth pop-up \[[#64088](https://community.openproject.org/wp/64088)\]
- Bugfix: Polling work package activity updates can cause Browser&#39;s Basic auth pop-up \[[#64091](https://community.openproject.org/wp/64091)\]
- Bugfix: NoMethodError on PATCH::API::V3::WorkPackages::WorkPackagesAPI#/work\_packages/:id/  \[[#64133](https://community.openproject.org/wp/64133)\]
- Bugfix: Database migration 20240405131352\_create\_meeting\_sections fails on Update \[[#64298](https://community.openproject.org/wp/64298)\]
- Bugfix: Internal comments can be added without a valid token in some cases \[[#64324](https://community.openproject.org/wp/64324)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->
