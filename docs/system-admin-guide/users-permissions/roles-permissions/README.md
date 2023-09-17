---
sidebar_navigation:
  title: Roles and permissions
  priority: 970
description: Manage roles and permissions in OpenProject.
keywords: manage roles, manage permissions
---
# Roles and permissions

## Users

A **user** is any individual who can log into your OpenProject instance.

## Placeholder user



## Permissions

Permissions control what users can see and do within OpenProject. Permission are granted to users by assigning one ore more roles to the users. 



## Roles

A role bundles a collection of permissions. It is an easy, convenient way of granting permissions to multiple users in your organization that need the same permissions or restrictions. 

A user can have one or more roles which grant permissions on different levels: 

| Role type     | Scope of the role                                            | Permission examples                                          | Customization options                                        |
| ------------- | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Administrator | Application-level: Full control of all aspects of the application | Assign administration privileges to other users<br />Create and restore backups in the web interface<br />Create and configure an OAuth app<br />Configure custom fields<br />Archive projects/restore projects<br />Configure global roles<br />Configure project roles | Can not be changed.                                          |
| Global role   | Application-level: Permissions scoped to specific administrative tasks (not restricted to specific projects) | Manage users<br /><br />Create projects                      | Administrators can create new global roles and assign global permissions to those roles |
| Project role  | Project-level: Permissions scoped to individual projects (a user can have different roles for individual projects) | Create work packages (in a project)<br />Delete wiki pages (in a specific project) | Create different project roles with individual permission sets |
| Non-member    | Project-level: Permissions scoped to individual projects for users which are logged in | View work packages for users that are logged in              | Assign different permissions                                 |
| Anonymous     | Project-level: Permissions scoped to individual projects for users which are <u>not</u> logged in | View work packages for users that are not logged in          | Assign different permissions                                 |

### Administrator

Administrators have full access to all settings and all projects in an OpenProject environment. The permissions of the Administrator role can not be changed. 

### Global role

Global roles allow Administrators to delegate administrative tasks to individual users:

* Create project
* Create users
* Create, edit, and delete placeholder users
* Create backup
* Edit users

### Project role

A **project role** is a set of **permissions** that can be assigned to any project member. Multiple roles can be assigned to the same project member.

> **Note:** If a [project module](../../../user-guide/projects/project-settings/modules/) is not enabled for a specific project it is not shown in that project's menu whether the user has permission for that module or not.

### Non-member

**Non member** is the default role of users of your OpenProject instance who have not been added to a project. This only applies if the project has been set as **[public](../user-guide/projects/#set-a-project-to-public)** in the project settings.

The Non-member role can not be deleted. 

### Anonymous 

OpenProject allows to share project information with users anonymous users which are not logged in. This is helpful to communicate projects goals and activities with a public community.

> **Note**: This only applies if you disabled the need for authentication for your instance and if the project is set as **public**.

The Anonymous role can not be deleted. 

## Customize roles and their permissions 

Administrators can customize the roles and the permissions of the different roles in **Administration** -> **Users and permissions** -> **Roles and permissions**.

### Permissions report

The permissions report is a good starting point to get and overview of the current configuration. 

### Create a new project roles

Administrators can create new project roles in **Administration** -> **Users and permissions -> Roles and permissions**.

Complete the following as required:

1. **Role name** - must be entered and be a new name.
3. **Copy workflow from** - select an existing role. The respective [workflows](../../manage-work-packages/work-package-workflows) will be copied to the role to be created.
4. **Permissions** for this role - you can specify the permissions per OpenProject module. Click the arrow next to the module name to expand or compress the permissions list.

Select the permissions which should apply for this role.

> **Note:** If a module is not enabled in a project it is not shown to a user despite having a permission for it.

### Create a new global role

Administrators can create new global role in **Administration** -> **Users and permissions -> Roles and permissions**.

To create a global roles activate the Global role check box in the create form.

### Edit and delete roles

To delete an existing role click on the **delete icon** next to a role in the list. 

> **Note:**  Roles that are assigned to a user can not be deleted. 

## FAQ

### When should I use the permission "Edit users"?

This is a global permission which can be assigned to a global role. This allows the Administrator to delegate the administration of users to other people that should not have full control of the entire OpenProject installation.  

### Can Administrators delegate the task to delete users?

No, only Administrators can delete other users. 

### Can I set a default role for a user that creates a new project?

- [Here](../../system-settings/project-system-settings/#settings-for-new-projects) you can set a default role that users with this permission will have in a project they created.

### Can I grant users the permission to manage the users in their projects?

**Please note**: They can only see the project membership of placeholder users for projects in which they have permission to see the members (e.g. as Project admin or Member). They can only manage project membership of placeholder users for projects in which they have permission to manage members (e.g. as Project admin).

### User do not see the action "Create project" in the main navigation even though they have the create project permission? 

Creating new projects requires the permission "Create"

### What is the difference between a project permission and a global permission?

Project permissions controls what a user can see and do within a project scope. Project permissions are attached to [project roles](#Project role). You can grant a user a permission in a specific project by giving the user one or more project roles in a specific project.

Examples for project permissions:

* Create work packages
* Add comments to a work package   

Global permissions are system wide. They are attached to [global roles](#Global roles) and controls what a user can do and see independent of specific project memberships.

### Can I convert a project role to a global role?

No this is not possible. You need to create a new role instead.