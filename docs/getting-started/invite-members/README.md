---
sidebar_navigation:
  title: Invite members
  priority: 800
description: Invite team members to OpenProject.
robots: index, follow
keywords: invite members, add users
---

# Invite members

In order to see a project and work in it, you have to be a member of a project. Therefore, you have to **add team members to a project**.

<div class="glossary">
**Member** is defined as a project member in a project. Project members are added in the members tab in the project settings.
</div>
<div class="alert alert-info" role="alert">
**Note**: If you are not a member of a project, you do not see the project in the Project selection nor in the project list.
</div>


| Topic                                                        | Content                                                    |
| ------------------------------------------------------------ | ---------------------------------------------------------- |
| [View members](#view-members)                                | View the list of members in your project.                  |
| [Add existing members](#add-existing-members)                | Add existing members to a project.                         |
| [Invite new members](#invite-new-members)                    | Invite new members to a project in OpenProject.            |
| [Groups a project members](#behavior-of-groups-as-project-members) | Understand the effects of adding groups a project members. |

<video src="https://www.openproject.org/wp-content/uploads/2020/12/OpenProject-Invite-and-Manage-Members.mp4" type="video/mp4" controls="" style="width:100%"></video>

## View members

To view the list of **all project members and their roles** in the project, select Members in the project menu.

![list of all members](image-20191112141214533.png)



## Add existing members

To add existing users or groups to a project, [select the project](../projects/#select-a-project) where you want to add members. In the project menu on the left, select the **Members** menu item.

In the Members list you will get an overview of the current members of this project.

![project-members](1566223836715.png)

Click the green **+ Member** button in the top right corner.

Type the name of the team member or group which you want to add. You can also choose several members at once. **Assign a role** to the new member(s) and click the blue **Add** button.

Please note that you will have to click on the new member's name or press the Enter key before clicking in the Add button.

![add-members](1566224199456.png)

## Invite new members

You can also invite new members who have not yet an OpenProject account. [Select the project](../projects/#select-a-project) where you want to add members. In the project menu on the left, select the **Members** menu item.

Type in the email address of the new member. If OpenProject does not find an existing user, the **Invite** information will automatically be put before the email address. Press the Enter key or select the text "Invite ...". Assign a role to this new member and click the blue **Add** button.

An email invitation will be sent out to the user with a link to [create an account](../sign-in-registration/#create-a-new-account) for OpenProject.

![invite-new-members](1566224961670.png)

You can now collaborate with your team in OpenProject.



## Behavior of groups as project members

Groups have the following impact on a project members list and behave slightly different than individual users:

- the group shows as a separate line on the project members list
- the group members cannot be removed from the members list individually (no delete icon)
- adding a group with members who are already in a project member list will add the group's role to their (the members') project roles
- a project member belonging to a group can have additional roles added individually
- the group role cannot be changed for individual group members

Find out more about the management of groups [here](../../system-admin-guide/users-permissions/groups/).



