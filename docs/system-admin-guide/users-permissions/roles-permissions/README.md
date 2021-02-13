---
sidebar_navigation:
  title: Roles & Permissions
  priority: 970
description: Manage roles and permissions in OpenProject.
robots: index, follow
keywords: manage roles, manage permissions
---
# Roles and permissions

A **role** is a set of **permissions** that can be assigned to any project member. Multiple roles can be assigned to the same project member.

When creating a role, the "Global role" field can be ticked, making it a **Global role** that can be assigned to a [users details](../users/#manage-user-settings) and applied across all Projects.

## Permissions

The permissions are pre-defined in the system, and cannot be changed. They define what actions a role can do. If a user has more than one role, including global and project roles, a permission is granted if it exists on any of those roles.

All permissions are shown by OpenProject module in the [create a new role](#create-a-new-role) page.

### Project Modules

If a [project module](../../user-guide/projects/project-settings/modules/) is not enabled it is not shown in the project menus whether the user has permission for that module or not.

### Permissions report

On the Roles list page is a link to the **Permissions report**. This shows a grid of existing roles (horizontally) against permissions (vertically); the intersections are ticked if the role has the permission.

A "Check/uncheck all" tick is shown on each role or permission to allow bulk change. Be careful, this cannot be undone. If you make a mistake do not save the report.

## Create a new role

To create a new role, navigate to the administration and select -> Users & permissions -> Roles and permissions from the menu on the left.

You will see the list of all the roles that have been created so far.

![create roles](image-20200211142134472.png)

After clicking the green **+ New Role** button a form will shown to define the role.

![Sys-admin-create-new-role](Sys-admin-create-new-role.png)

Complete the following as required:

* **Role name** - must be entered and be a new name.
* **Global Role** - this role applies to all projects, and is assigned in the [user details](../users/#manage-user-settings). Once saved this field is not shown if it was not ticked, so it cannot be changed.
* **Work packages...** - tick to allow work packages to be assigned to a user with this role. This does not appear on global roles.
* **Copy workflow from** - select an existing role. The respective [workflows](../../manage-work-packages/work-package-workflows) will be copied to this role.

You can specify the permissions per OpenProject module. Click the arrow next to the module name to expand or compress the permissions list.

Select the permissions which should apply for this role. You can use "check all" or "uncheck all" at the right of a module permissions list. If a module is not enabled in a project it is not shown to a user despite having a permission for it.

Don't forget to click the **Save** button at the bottom of the page.

## Edit and remove roles

To edit a role navigate to the roles overview list and click on the role name (1). If is not a global role it cannot be converted into one.

To remove an existing role click on the delete icon next to a role in the list (2). It cannot be deleted if it is assigned to a user.

![Sys-admin-edit-roles](Sys-admin-edit-roles.png)
