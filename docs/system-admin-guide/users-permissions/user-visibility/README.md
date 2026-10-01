---
sidebar_navigation:
  title: User visibility
  priority: 955
description: Understand which users and groups a user can see in OpenProject.
keywords: user visibility, visible users, see users, view all users and groups
---

# User visibility

Not every user can see every other user or group in OpenProject. Visibility determines whether a user or group appears in member lists, filters, assignee and user pickers, and the user search. It does **not** grant any additional access to that person's data.

This page explains the rules that determine user visibility and how administrators can expand it.

## Visibility rules

Consider **User A** (who is looking) and **User B** (who should be seen). A can see B if **any** of the following applies:

| Rule                                    | Explanation                                                  |
| --------------------------------------- | ------------------------------------------------------------ |
| **A is an administrator**               | Administrators can see all users and groups.                 |
| **A has the global permission "View all users and groups"** | Grants the same full visibility without being an administrator. See [Global roles](../roles-permissions/#create-a-new-global-role). |
| **A and B share a group**               | If A and B belong to a common group, they can see each other regardless of any shared projects. |
| **A and B are members of the same project** | Both are members of the same project. All project members see each other within that project. This also covers users who are not project members but have a work package in that project [shared](../../../user-guide/work-packages/share-work-packages) with them. |
| **A has access to a project B belongs to** | A project is accessible to A when it is a **public** project, when A is a member of it, or when a work package in it has been shared with A. In each case A can see all members of that project, as well as everyone who has a work package shared with them there. |

## Important considerations

- **Public projects result in visibility.** Members of an active [public project](../../../user-guide/projects/project-settings/project-information/#make-a-project-public) are visible to everyone, including anonymous or non-member users depending on the "Login required" setting, because public projects are accessible to all.
- **Visibility is evaluated per project, not per work package.** Once A can see a project, A can see all of its members, not only the people involved in the specific work package that was shared with A.
- **Visibility grants no permissions.** Being able to see a user only affects whether they appear in lists, pickers, and search. It does not allow A to edit that user's data.

## Extending visibility

If administrators want a user to be able to see all users and groups across the instance, they need to assign a [global role](../roles-permissions/#create-a-new-global-role) that includes the **View all users and groups** permission to bypass any of the above constraints.
