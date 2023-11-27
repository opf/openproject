---
sidebar_navigation:
  title: Share work packages
  priority: 963
description: How to share work packages in OpenProject.
keywords: work package, share, share work packages
---

# Share work packages

Since the 13.1 it is possible to share work packages with users that are not members of a project or are not yet registered on your instance. In the latter case a user will need to register in order to view the work package.

> **Note**: Sharing work packages with non-member is an Enterprise add-on and can only be used with [Enterprise cloud](../../../enterprise-guide/enterprise-cloud-guide/) or  [Enterprise on-premises](../../../enterprise-guide/enterprise-on-premises-guide/). An upgrade from the free community edition is easy and helps support OpenProject.

To share a work package with a project non-member select the detailed view of a work package and click the **Share** button.

![Share button in OpenProject work packages](openproject_user_guide_share_button_wp.png)

A dialogue window will open, showing the list of all users, who this work package has already been shared with. If the work package has not yet been shared, the list will empty. 

![List of users with access to a work package in OpenProject](openproject_user_guide_shared_with_list.png)

If the list contains multiple users you can filter it by Type or Role. 

Following user types are available as filters:

![Filter list of users by user type](openproject_user_guide_sharing_member_type_filter.png)

- Project member - returns all users that are project members
- Not project member - returns all users that are not project members
- Project group - returns all users that are members of the group, which includes the project
- Not project group - returns all users that are not members of the group, which includes the project

Following user roles are available as filters:

![Filter list of users by user role](openproject_user_guide_sharing_member_role_filter.png)

You can search for a user via a user name or an email address. You can either select an existing user from the dropdown menu or enter an email address for an entirely new user, who will receive an invitation to create an account on your instance.

![search for a new user to share a work package](openproject_user_guide_shared_search.png)

A user with whom you shared the work package will be added to the members of the project with the role **Work Package Viewer** and will be visible in the list of the project members. IS THIS TRUE? THEN WHY ARE THERE NON-PROJECT MEMBER ROLES AVAILABLE AS FILTERS?

A user with whom you shared the work package will be added to the members of the project with the role **Work Package Viewer** and will be visible in the list of the project members.

You can always adjust the viewing rights of a user by selecting an option from the dropdown menu next to the user name. 

![](openproject_user_guide_shared_with_list_change_role.png)

You can also remove the user from the list by clicking on **Remove** next to the user name.

