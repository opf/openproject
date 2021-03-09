---
title: OpenProject 11.2.0
sidebar_navigation:
    title: 11.2.0
release_version: 11.2.0
release_date: 2021-03-09
---

# OpenProject 11.2.0

We released [OpenProject 11.2.0](https://community.openproject.com/versions/1461).
The release contains several bug fixes and we recommend updating to the newest version.

<!--more-->
#### Bug fixes and changes

- Changed: Make the cost reporting navigation consistent with the other modules \[[#32928](https://community.openproject.com/wp/32928)\]
- Changed: Add work package filter for child work packages \[[#33163](https://community.openproject.com/wp/33163)\]
- Changed: Swap background colors of sum rows and group rows \[[#34711](https://community.openproject.com/wp/34711)\]
- Changed: Backend: Introduce the concept of "placeholder users" in data layer, API, services, contracts \[[#35505](https://community.openproject.com/wp/35505)\]
- Changed: Backend: Disable all notifications for placeholder users \[[#35506](https://community.openproject.com/wp/35506)\]
- Changed: Backend: Add global permission for creating users (and invite)  \[[#35507](https://community.openproject.com/wp/35507)\]
- Changed: Backend: Add global permission for creating and editing placeholder users \[[#35508](https://community.openproject.com/wp/35508)\]
- Changed: Backend: Add global permission for modifying users \[[#35533](https://community.openproject.com/wp/35533)\]
- Changed: Backend: Don't count placeholder users in user limits of plans/subscriptions \[[#35535](https://community.openproject.com/wp/35535)\]
- Changed: Backend: Show and manage placeholder users in user administration \[[#35536](https://community.openproject.com/wp/35536)\]
- Changed: Frontend: Show placeholder user in user type drop downs \[[#35571](https://community.openproject.com/wp/35571)\]
- Changed:  Backend: Delete placeholder user \[[#35648](https://community.openproject.com/wp/35648)\]
- Changed: Add group show page similar to users \[[#35815](https://community.openproject.com/wp/35815)\]
- Changed: Remove setting "Allow assignment to groups"  \[[#36056](https://community.openproject.com/wp/36056)\]
- Changed: Accomodate placeholder users in project members administration \[[#36136](https://community.openproject.com/wp/36136)\]
- Changed: Add work package filter by id \[[#36358](https://community.openproject.com/wp/36358)\]
- Fixed: OAuth login has CSP issues when user already had authorized the app \[[#34554](https://community.openproject.com/wp/34554)\]
- Fixed: Unclear error message when subproject column for action board cannot be displayed due to missing permissions \[[#34840](https://community.openproject.com/wp/34840)\]
- Fixed: Impossible to enter time with dots \[[#34922](https://community.openproject.com/wp/34922)\]
- Fixed: Cannot sort user columns (in administration) \[[#35012](https://community.openproject.com/wp/35012)\]
- Fixed: create new child returns version error (duplicate usage of type for backlogs sprint and task) \[[#35157](https://community.openproject.com/wp/35157)\]
- Fixed: Taskboard story height to be increased. Assignee and Story name out of box \[[#35735](https://community.openproject.com/wp/35735)\]
- Fixed: PDF export opens in same tab \[[#36051](https://community.openproject.com/wp/36051)\]
- Fixed: LDAP connection retrieves at max 1000 elements regardless of server limit \[[#36206](https://community.openproject.com/wp/36206)\]
- Fixed: Deletion of users and groups is incomplete and results in corrupted data \[[#36238](https://community.openproject.com/wp/36238)\]
- Fixed: Breadcrumbs missing for both users and placeholder users administration pages when not admin \[[#36250](https://community.openproject.com/wp/36250)\]
- Fixed: Section header "Custom fields" was removed in user details in administration \[[#36257](https://community.openproject.com/wp/36257)\]
- Fixed: Error "Project filter has invalid values" shown when filtering by Parent on global WP page \[[#36287](https://community.openproject.com/wp/36287)\]
- Fixed: Error "Project filter has invalid values" shown when filtering by Parent on My page \[[#36288](https://community.openproject.com/wp/36288)\]
- Fixed: Empty authentication section shown for some users in adminstration (for users who have global role to view / edit / create users) \[[#36294](https://community.openproject.com/wp/36294)\]
- Fixed: Error 500 when accessing "Member" list in project while user name display format is set to email \[[#36297](https://community.openproject.com/wp/36297)\]
- Fixed: Role "Create and edit users" can see GDPR and billing although not allowed to \[[#36298](https://community.openproject.com/wp/36298)\]
- Fixed: Role "Create and edit users" can not change user name \[[#36299](https://community.openproject.com/wp/36299)\]
- Fixed: Internal error when accessing project work package page after deleting placeholder user \[[#36300](https://community.openproject.com/wp/36300)\]
- Fixed: Translation missing for placeholder Enterprise Edition page \[[#36302](https://community.openproject.com/wp/36302)\]
- Fixed: Logged hours not visible in widget on My Page for languages other than English \[[#36304](https://community.openproject.com/wp/36304)\]
- Fixed: Grouping by assignee through settings menu does not work \[[#36318](https://community.openproject.com/wp/36318)\]
- Fixed: Work package alignment incorrect when updating work package values / opening details view \[[#36330](https://community.openproject.com/wp/36330)\]
- Fixed: Wrong error message when trying to log time for a placeholder user \[[#36353](https://community.openproject.com/wp/36353)\]
- Fixed: Cannot create work package if a version custom field is configured \[[#36395](https://community.openproject.com/wp/36395)\]
- Fixed: Buttons and queries not working after filtering for custom field \[[#36440](https://community.openproject.com/wp/36440)\]
- Fixed: Trying to sort placeholder users by name leads to Error 500 \[[#36517](https://community.openproject.com/wp/36517)\]
- Epic: Support for placeholder users that do not have an email address yet \[[#35933](https://community.openproject.com/wp/35933)\]

#### Contributions
A big thanks to community members for reporting bugs and helping us identifying and providing fixes.

Special thanks for reporting and finding bugs go to

Rémi Schillinger, Sander Kleijwegt, Tibor Budai