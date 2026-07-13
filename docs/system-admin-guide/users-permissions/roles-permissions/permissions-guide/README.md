---
sidebar_navigation:
  title: Permissions guide
  priority: 960
description: Understand project permissions in OpenProject.
keywords: permissions, roles, project permissions, global permissions
---

# Permissions guide

Permissions determine what users can see and do in OpenProject. They are assigned to users through project roles and global roles.

Most permissions are self-explanatory. This guide explains the purpose of each permission and highlights important dependencies and behaviors where applicable.

> [!TIP]
> Some permissions only have an effect if the corresponding module is enabled for the project. If a module is disabled, the related permissions are ignored.

## Project permissions

- **Archive project** – Allows users to archive and restore a project.

- **Edit project** – Allows users to access **Project settings** and edit the project's configuration.

- **Select project modules** – Allows users to enable or disable project modules.

- **View project attributes** – Allows users to view project information and attributes.

- **Export projects** – Allows users to export project information.

- **Edit project attributes** – Allows users to edit project attributes on the overview page.

- **Select project attributes** – Allows users to configure which project attributes are available.

- **View project phases** – Allows users to view project life cycle phases.

- **Edit project phases** – Allows users to edit project life cycle phases.

- **Select project phases** – Allows users to activate or deactivate project phases. Inactive phases are hidden from the project overview and project list.

- **Manage members** – Allows users to add, remove and manage project members and their roles.

- **Invite members by email** – Allows users to invite project members by email. This includes both new users to the OpenProject instance and existing users who are not visible to them because of the current [user visibility settings](../../user-visibility).

  > [!NOTE]
  > Requires the **Manage members** permission.

- **View members** – Allows users to view project members.

- **Manage versions** – Allows users to create, edit and delete project versions.

- **Select types** – Allows users to configure the work package types available in the project.

- **Select custom fields** – Allows users to configure which custom fields are available in the project.

- **Create subprojects** – Allows users to create subprojects.

- **Copy projects** – Allows users to create a new project by copying an existing project.

  For project templates, this permission also allows users to create new projects based on the template.

  > [!NOTE]
  > When a user copies a project, they are assigned the configured **New role for users that create projects** in the new project. Depending on your configuration, this role may grant additional permissions compared to their role in the source project.
  >
  > To access the **Copy** action from **Project settings**, users must also be able to open the project settings, which typically requires the **Edit project** permission. Alternatively, users can create a new project from a project template.
  
- **Manage dashboards** – Allows users to create and edit project dashboards.

- **Manage files in project** – Allows users to manage project file storages.

- **Automatically managed project folders: Read files** – Allows users to read files in automatically managed project folders.

- **Automatically managed project folders: Write files** – Allows users to modify files in automatically managed project folders.

- **Automatically managed project folders: Create files** – Allows users to create files in automatically managed project folders.

  > [!NOTE]
  > Only available for Nextcloud file storages.

- **Automatically managed project folders: Delete files** – Allows users to delete files from automatically managed project folders.

  > [!NOTE]
  > Only available for Nextcloud file storages.

- **Automatically managed project folders: Share files** – Allows users to share files from automatically managed project folders.

  > [!NOTE]
  > Only available for Nextcloud file storages.

## Work packages and Gantt chart permissions

- **View work packages** – Allows users to view work packages. 
- **Add work packages** – Allows users to create work packages.
- **Edit work packages** – Allows users to edit work packages.
- **Move work packages** – Allows users to move work packages between projects.
- **Duplicate work packages** – Allows users to duplicate work packages.
- **Add comments** – Allows users to comment on work packages.
- **Edit own comments** – Allows users to edit their own comments.
- **Moderate comments** – Allows users to edit comments created by any user.
  > [!IMPORTANT]
  > Users with this permission can edit comments created by other users.

- **View internal comments** – Allows users to view internal comments.
> [!TIP]
>  [Internal comments](../../../../user-guide/work-packages/edit-work-package/#internal-comments-enterprise-add-on) are only visible to users who have this permission:
- **Write internal comments** – Allows users to create internal comments.
- **Edit own internal comments** – Allows users to edit their own internal comments.
- **Moderate internal comments** – Allows users to edit internal comments created by any user.

  > [!IMPORTANT]
  > Users with this permission can edit internal comments created by other users.

- **Add attachments** – Allows users to upload attachments to work packages.

  > [!NOTE]
  > This permission works independently of **Edit work packages**.

- **Manage work package categories** – Allows users to create, edit, and delete work package categories.
- **Export work packages** – Allows users to export work packages.
- **Delete work packages** – Allows users to delete work packages.
- **Manage work package relations** – Allows users to create, edit, and remove work package relations.
- **Manage work package hierarchies** – Allows users to manage parent-child relationships between work packages.
- **Manage public views** – Allows users to create, edit, and delete public work package views. This permission also affects other work package related views, such as team planner and calendar public views.
- **Save views** – Allows users to save personal work package views.
- **View watchers list** – Allows users to see who is watching a work package.
- **Add watchers** – Allows users to add watchers to work packages.
- **Delete watchers** – Allows users to remove watchers from work packages.
- **Share work packages** – Allows users to share work packages with other users.
- **View work package shares** – Allows users to view existing work package shares.
- **Assign versions** – Allows users to assign versions to work packages.
- **Change work package status** – Allows users to change the status of work packages.

  > [!NOTE]
  > This permission works independently of **Edit work packages**.

- **Become assignee/responsible** – Allows work packages to be assigned to users or groups with this role in the project.
- **View file links** – Allows users to view file links attached to work packages.
- **Manage file links** – Allows users to create, edit, and remove file links.
- **Manage wiki page links** – Allows users to create, edit, and remove wiki page links.

## Boards permissions

- **View boards** – Allows users to view boards.
- **Manage boards** – Allows users to create, edit, and delete boards.

## Backlogs permissions

- **View sprints** – Allows users to view sprints.
- **Select backlog types and statuses** – Allows users to configure which work package types appear in the backlog and which statuses are considered completed.
- **Create sprints** – Allows users to create sprints.
- **Start/complete sprint** – Allows users to start and complete sprints.
- **Manage sprint items** – Allows users to manage sprint contents.
- **Share sprint** – Allows users to share sprint information.

## Budgets permissions

- **View budgets** – Allows users to view project budgets.
- **Edit budgets** – Allows users to create, edit, and delete project budgets.

## Calendars permissions

- **View calendars** – Allows users to view calendars.
- **Edit calendars** – Allows users to create, edit, and delete calendars.
- **Subscribe to iCalendars** – Allows users to subscribe to calendar feeds.

## Documents permissions

- **View documents** – Allows users to view project documents.
- **Manage documents** – Allows users to create, edit, and delete project documents.

## Forums permissions

- **Manage forums** – Allows users to create, edit, and delete forums.
- **Post messages** – Allows users to post messages in forums.
- **Edit messages** – Allows users to edit any forum message.
- **Edit own messages** – Allows users to edit their own forum messages.
- **Delete messages** – Allows users to delete any forum message.
- **Delete own messages** – Allows users to delete their own forum messages.

## GitHub permissions

- **Show GitHub content** – Allows users to view GitHub integration content.

## GitLab permissions

- **Show GitLab content** – Allows users to view GitLab integration content.

## Meetings permissions

- **View meetings** – Allows users to view meetings.
- **Create meetings** – Allows users to create meetings.
- **Edit meetings** – Allows users to edit meetings.
- **Delete meetings** – Allows users to delete meetings.
- **Send meeting invites and outcomes to participants** – Allows users to send meeting invitations and meeting outcomes to participants.
- **Manage agendas** – Allows users to create, edit, and delete agenda items.
- **Manage outcomes** – Allows users to create, edit, and delete meeting outcomes.

## News permissions

- **Manage news** – Allows users to create, edit, and delete news posts.
- **Comment news** – Allows users to comment on news.

## Team planner permissions

- **View team planner** – Allows users to view the Team planner.
- **Manage team planner** – Allows users to create, edit, and configure the Team planner.

## Time and costs permissions

- **View spent time** – Allows users to view all logged time.
- **View own spent time** – Allows users to view their own logged time.
- **Log own time** – Allows users to log their own time.
- **Log time for other users** – Allows users to log time on behalf of other users.
- **Edit own time logs** – Allows users to edit their own time entries.
- **Edit time logs for other users** – Allows users to edit time entries created by other users.
- **Manage project activities** – Allows users to create, edit, and delete project activities used for time tracking.
- **View own hourly rate** – Allows users to view their own hourly rate.
- **View all hourly rates** – Allows users to view hourly rates of all users.
- **Edit own hourly rates** – Allows users to edit their own hourly rate.
- **Edit hourly rates** – Allows users to edit hourly rates for all users.
- **View cost rates** – Allows users to view cost rates.
- **Book unit costs for oneself** – Allows users to book unit costs for themselves.
- **Book unit costs** – Allows users to book unit costs for other users.
- **Edit own booked unit costs** – Allows users to edit their own booked unit costs.
- **Edit booked unit costs** – Allows users to edit booked unit costs for all users.
- **View booked costs** – Allows users to view all booked costs.
- **View own booked costs** – Allows users to view their own booked costs.
- **Save public cost reports** – Allows users to save public cost reports.
- **Save private cost reports** – Allows users to save private cost reports.

## Wiki permissions

- **View wiki** – Allows users to view wiki pages.
- **View wiki history** – Allows users to view the revision history of wiki pages.
- **Edit wiki pages** – Allows users to create and edit wiki pages.
- **Manage wiki** – Allows users to manage the project wiki, including renaming and deleting wiki pages.

## Common permission dependencies

Some permissions depend on additional permissions or have behavior that is not immediately obvious.

| Permission | Additional information |
|------------|------------------------|
| Invite members by email | Requires **Manage members**. |
| Copy projects | Users are assigned the configured **New role for users that create projects** in the copied project. <br>Accessing **Copy** from **Project settings** typically also requires **Edit project**. |
| Add attachments | Can be granted independently of **Edit work packages**. |
| Change work package status | Can be granted independently of **Edit work packages**. |
| Become assignee/responsible | Controls whether a user or group can be selected as assignee or responsible for work packages. |