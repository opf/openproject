---
title: OpenProject 13.3.0
sidebar_navigation:
    title: 13.3.0
release_version: 13.3.0
release_date: 2024-02-14
---

# OpenProject 13.3.0

Release date: 2024-02-14

We released [OpenProject 13.3.0](https://community.openproject.org/versions/1487).
The release contains several bug fixes and we recommend updating to the newest version.


## Important updates and breaking changes

<!-- Remove this section if empty, add to it in pull requests linking to tickets and provide information -->

<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Feature: Separate Gantt charts module \[[#32764](https://community.openproject.org/wp/32764)\]
- Feature: Automatically managed project folders with SharePoint \[[#50988](https://community.openproject.org/wp/50988)\]
- Feature: Template folder and file structure when using SharePoint/OneDrive \[[#52177](https://community.openproject.org/wp/52177)\]
- Bugfix: PDF doesn't contain cell color \[[#47169](https://community.openproject.org/wp/47169)\]
- Bugfix: Save Team Planner view as 2 weeks view not only 1 week view. \[[#48355](https://community.openproject.org/wp/48355)\]
- Bugfix: Delete work package API requires content-type header \[[#51317](https://community.openproject.org/wp/51317)\]
- Bugfix: Lookbook is broken \[[#51787](https://community.openproject.org/wp/51787)\]
- Bugfix: Anonymous Users (without signing in) cannot load board content \[[#51850](https://community.openproject.org/wp/51850)\]
- Bugfix: Multi-select user custom field broken in table \[[#52289](https://community.openproject.org/wp/52289)\]
- Bugfix: [AppSignal] undefined method `status' for HTTPX::ErrorResponse \[[#52446](https://community.openproject.org/wp/52446)\]
- Bugfix: Untranslated work package roles \[[#52598](https://community.openproject.org/wp/52598)\]
- Bugfix: Users involved in work packages sharing are duplicated in project storage members list.  \[[#52673](https://community.openproject.org/wp/52673)\]
- Feature: Nudge admin to go through OAuth flow \[[#49396](https://community.openproject.org/wp/49396)\]
- Feature: Inform an admin via email about an unhealthy automatically managed file storage \[[#50913](https://community.openproject.org/wp/50913)\]
- Feature: "% Complete" field split to own value and derived value \[[#51188](https://community.openproject.org/wp/51188)\]
- Feature: Adapt onboardoing tour to new Gantt module \[[#51354](https://community.openproject.org/wp/51354)\]
- Feature: Add column "Shared with" in the work packages table \[[#51491](https://community.openproject.org/wp/51491)\]
- Feature: Show number of "Shared users" in the share button \[[#51492](https://community.openproject.org/wp/51492)\]
- Feature: Have persisted project lists (only filters) \[[#51666](https://community.openproject.org/wp/51666)\]
- Feature: Add and remove user from automatically managed folders on SharePoint/OneDrive \[[#51711](https://community.openproject.org/wp/51711)\]
- Feature: Add, remove and rename folders in SharePoint/OneDrive \[[#51712](https://community.openproject.org/wp/51712)\]
- Feature: Move filters toggle and "+Project"-Button from header into content \[[#51778](https://community.openproject.org/wp/51778)\]
- Feature: User identifier saved in OAuthToken \[[#51783](https://community.openproject.org/wp/51783)\]
- Feature: Create/edit SharePoint/OneDrive storages for automatically managed folders \[[#51841](https://community.openproject.org/wp/51841)\]
- Feature: Add link from work / estimated work sum to detailed query view \[[#52076](https://community.openproject.org/wp/52076)\]
- Feature: Make renamed attributes searchable with old names ("% complete", "work" and "remaining work") \[[#52119](https://community.openproject.org/wp/52119)\]
- Feature: Clean menu structure on project lists page \[[#52149](https://community.openproject.org/wp/52149)\]
- Feature: Copy automatically managed project folder on project copy for SharePoint/OneDrive \[[#52175](https://community.openproject.org/wp/52175)\]
- Feature: Remove Derived remaining work from Work package form configuration \[[#52252](https://community.openproject.org/wp/52252)\]
- Feature: (Kopie) Project list: Truncate long text fields and disable expand action \[[#52259](https://community.openproject.org/wp/52259)\]
- Feature: Maintain manually managed project folder on project copy for SharePoint/OneDrive \[[#52363](https://community.openproject.org/wp/52363)\]
- Feature: Add toggle to deactivate/activate admin health notification for a storage \[[#52449](https://community.openproject.org/wp/52449)\]
- Feature: Copy template folder command for SharePoint \[[#52450](https://community.openproject.org/wp/52450)\]
- Feature: Rename "Managed folder status" heading in Storage form \[[#52456](https://community.openproject.org/wp/52456)\]
- Feature: File Storage Permissions explanation \[[#52571](https://community.openproject.org/wp/52571)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->

#### Contributions
A big thanks to community members for reporting bugs and helping us identifying and providing fixes.

Special thanks for reporting and finding bugs go to

James Neale, Jeff Li, Christian Jeschke, Sreekanth Gopalakris, Jörg Mollowitz
