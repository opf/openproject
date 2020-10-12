---
sidebar_navigation:
  title: Manage users
  priority: 990
description: Manage users in OpenProject.
robots: index, follow
keywords: manage users
---

# Manage Users

The users list provides an overview of all users in OpenProject. You can create new users, make changes to existing user accounts, block or delete users from the system. The number of users for your subscription is thus not bound to names. For example, if you block a user you can add a new one without upgrading.

<div class="glossary">
**User** is defined as a person (described by an identifier) who uses OpenProject. New users can be created in the admin settings. Users can become project members by assigning them a role and adding them via the project settings.
</div>


| Feature                                                      | Documentation for                                            |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [User list](#user-list)                                      | Manage all users in OpenProject.                             |
| [Lock users](#lock-users)                                    | Block a user permanently in the system.                      |
| [Filter users](#filter-users)                                | Filter users in the list.                                    |
| [Invite new users](#invite-new-users)                        | Add new users to your OpenProject and invite them via email. |
| [Send user invitation via email](#resend-user-invitation-via-email) | Send user invitation via email.                              |
| [Manage user settings](#manage-user-settings)                | Manage user settings, e.g. language, projects, groups, global roles, rate history, avatar, two-factor authentication. |
| [Delete users](#delete-users)                                | Delete a user from the system.                               |

## User list

You will see the list of all users in your OpenProject with detailed information, such as user name, first name, last name, e-mail address.

You will also see if a user is an Administrator in the system.

Also, you get the information when the user has been created, and when the user had his last login.

![user list](image-20200211141841492.png)

## Lock users

If you want to **block users permanently** in the system, you can click the **Lock permanently** link next to a user.

If you are using the [OpenProject Cloud Edition](../../../cloud-edition-guide), you will then have a new user available to add to the system within your booked plan.

<div class="alert alert-info" role="alert">
**Note**: The previous activities from this locked users will still be displayed in the system.
</div>

![System-admin-guide_lock-users](System-admin-guide_lock-users.png)

## Filter users

Especiall if you have a very long user list, it is essential to filter in this list.

At the top of the list, you can choose to filter for all, altive, or locked users. 
You can then search for the name or email of a user. Click the blue **Apply** button to filter the list.

![filter users](image-20200115155456033.png)

## Invite new users

To invite new users to your system, click the green **+ User** button at the top right.

![Sys-admin-add-users](Sys-admin-add-users.png)

Enter the Email address, first name, and last name of the new user. Check whether the new user should get system administration rights.

Click the blue **Create** button in order to invite the new user via email.

![new user](image-20200115155855409.png)

The **Create and continue** button will bring you to the form to add another new user.

## Resend user invitation via email

If a user did not receive the email invitation, you can send the invitation to the user again if needed. In the user list, click on the user name to whom you want to resend the email with the invitation link to the system.

In the top right, click the **Send invitation** button in order to send the email once again.

![Sys-admin-resend-invitation](Sys-admin-resend-invitation.png)

## View user profile

If you want to see the user profile, click on the user name in the user list to display the activities across all projects from a certain user. Click the **Profile** button on the top right of a user.

![Sys-admin-profile](Sys-admin-profile.png)



You will see all the Activities across all projects from this user, as well as the amount of reported work packages in the system.

![user profile](image-20200115162109669.png)

## Manage user settings

### General settings

You can manage individual user settings if you click on the user name in the list. The settings will overwrite the individual user settings set in the [My Account settings](../../../getting-started/my-account/).

(1) Change username, first name, last name, email address or language. Activate or deactivate **Administrator** permission.

(2) See user based custom fields.

(3) Display last given [user consent](../settings/#user-consent).

(4) Display **authentication provider**.

(5) Change e-mail **notification** settings.

(6) Set **preferences** for time zone and display of comments.

(7) Do not forget to **Save** your changes.

![Sys-admin-user-settings](Sys-admin-user-settings.png)

### Add users to a project

In order to see and work in a project, a user has to be a member of a project and needs to be added with a certain role to this project.

On the **Projects** tab, select the new project from the drop-down list, choose a **role** for this project and click the blue **Add** button.

![Sys-admin-add-project](Sys-admin-add-project.gif)

### Add users to groups

In order to add a user to a group, at least [one group needs to be created](../groups) in the system.

Select or de-select the groups a user should be a member of. Click the blue **Save** button.

![add users to a group](image-20200115165406439.png)



## Delete users

In order to delete users from the system, open the [user list](#user-list).

Click on the **user name** of the user which you want to delete.

To delete a user permanently from the system, press the **Delete** button at the top right. 

![Sys-admin-delete-user](Sys-admin-delete-user.png)

You will then be asked to type in the user's email address in order to delete the user permanently from the system.

![delete user](image-20200115162533470.png)

<div class="alert alert-info" role="alert">
**Note**: Deleting a user account is an irreversible action and cannot easily be restored via the frontend.
</div>
