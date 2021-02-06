---
sidebar_navigation:
  title: Manage users
  priority: 990
description: Manage users in OpenProject.
robots: index, follow
keywords: manage users
---

# Manage users

To manage users click on your avatar (top right corner) and select "Administration". Select "Users and Permissions", then select "Users". The list of current users is shown.

<div class="glossary">
**User** is defined as a person (described by an identifier) who uses OpenProject. Users can become project members by assigning them a role and adding them via the project settings.
</div>

In the Community edition there is no limit to the number of users. In subscription editions the limit for users is given in your subscription.

| Topic                                         | Content                                                      |
| --------------------------------------------- | ------------------------------------------------------------ |
| [User list](#user-list)                       | Manage all users in OpenProject.                             |
| [Filter users](#filter-users)                 | Filter users in the list.                                    |
| [Lock users](#lock-users)                     | Block and unblock users.                                     |
| [Delete users](#delete-users)                 | Delete a user from the system.                               |
| [Manage user settings](#manage-user-settings) | Manage user details.                                         |
| [Create users](#create-users)                 | Create new users.                                            |
| [Authentication](#authentication)             | Set and use authentication methods.                          |

## User list

The User List is where users are managed. They can be added, edited or deleted from this list, which can be filtered if required.

![user list](image-20200211141841492.png)

Column headers can be clicked to toggle sort direction. Arrows indicate sort order, up for ascending (a-z/0-9) and down for descending (z-a/9-0). Paging controls are shown at the bottom of the list.

### Filter users

At the top of the user list is a filter box. Filter by Status or Name, then click the blue **Apply** button to filter the list. Click the **Clear** button to reset the filter fields and refresh the list.

* **Status** - select from Active, All or Locked Temporarily. Each selection shows the number of users. There maybe other status values depending on settings.
* **Name** - enter any text; this can contain a "%" wild card for 0 or more characters. The filter applies to Username, First Name, Last Name and Email.

![filter users](image-20200115155456033.png)

### Lock users

Handling locked users is also done from the list. To disable a users access click the **Lock permanently** link next to a user.

If you are using the [Enterprise Edition](../../../enterprise-edition-guide), you will then have a new user available to add to the system within your booked plan.

<div class="alert alert-info" role="alert">
**Note**: The previous activities from a locked user will still be displayed in the system.
</div>

![System-admin-guide_lock-users](System-admin-guide_lock-users.png)

If a user has repeated failed logins their user will be locked and a "Reset failed logins" link is shown in the user list. Click the link to unlock it now, or wait and it is unlocked automatically. See [Other authentication settings](../../authentication/authentication-settings/#other-authentication-settings) for failed attempts and time blocked.

### Delete users

Two [settings](../settings/#user-deletion/) allow users to be deleted from the system:
* **User accounts deletable by admins** - if ticked, a "Delete" button is shown on the user details page.
* **Users allowed to delete their accounts** - if ticked, a "Delete account" menu entry is shown in the "My Account" page.

To delete another user's account open the [user list](#user-list). Click on the **user name** of the user which you want to delete. Click the "Delete" button at the top right.

![Sys-admin-delete-user](Sys-admin-delete-user.png)

You will then be asked to type in the username in order to delete the user permanently from the system, then confirm this with your password.

![delete user](image-20200115162533470.png)

<div class="alert alert-info" role="alert">
**Note**: Deleting a user account is an irreversible action and cannot be reversed. The previous activities from this user will still be displayed in the system but reassigned to "deleted user".
</div>

## Manage user settings

You can manage individual user details if you click on the user name in the list.

### General settings

On the General tab the following fields are shown:

* **Status** - this is set by the system.
* **Username** - this defaults to the email for a new user. It can be changed on this page. Users cannot change their own username.
* **First name**, **Last name**, **Email** - these fields are filled from the new user page. Users can change them on their Profile page; they are mandatory.
* **Language** - this defaults from the [user settings](../settings/#default-preferences). Users can change this on their Profile page.
* **Administrator** - Activate or deactivate this permission. Users cannot change this.
* **Custom Fields** - if these have been created they are shown here.
* **User consent** - if this has been [configured](../settings/#user-consent) the consent status is hown here.
* **Authentication** - the content of this section depends on the type of [authentication method](#authentication) being used.
* **Email notifications** - users can change these on their Profile page.
* **Preferences** - users can change these on their Profile page. Time zone defaults from chosen language.

**Do not forget** to "Save" your changes.

![Sys-admin-user-settings](Sys-admin-user-settings.png)

### Add users to a project

In order to see and work in a project, a user has to be a member of a project and needs to be added with a certain role to this project.

On the **Projects** tab, select the new project from the drop-down list, choose the **roles** for this project and click the blue **Add** button.

![Sys-admin-add-project](Sys-admin-add-project.gif)

### Add users to groups

On the **Groups** tab you can see the groups the user belongs to. If a group is shown, click a group name link. If no groups are shown, click the **Manage groups** link to [edit groups](../groups).

![add users to a group](image-20200115165406439.png)

### Global roles

In order to add a global role to a user, at least [one global role needs to be created](../roles-permissions) in the system (a role with the "Global role" field ticked).

On the **Global roles** tab, select or de-select the global role(s) for this user. Click the **Add** button.

### Rate history

The rate history shows the rates applied to the user. The **Default rate** applies on projects with no rate defined. All projects that the user is a member of are listed with the users rates.

### Avatar

The **Avatar** tab shows the default icon to be shown for this user. A custom image can be uploaded as the avatar. The user can manage this in their Profile. This feature can be disabled in [settings](../avatars).

## Create users

New users can be created and configured by an administrator, a single user or multiple users. A person can create their own user from the home page by clicking on the "Sign in" button (top right), then on the "Create a new account" link in the sign in box.

### Create user (Sign in link)

Click the "Create a new account" link in the sign in box. In the "Create a new account" window, enter values in all fields (they cannot be left blank). The Email field must be a valid email address that is not used in this system. Click the "Create" button. Your account is created but must be activated by the administrator.

### Create user (Administration)

From the user list, click the "+User" button to open the "New user" form.

![new user](image-20200115155855409.png)

Enter the Email address, First name, and Last name of the new user. Tick the box to make them an administrator user.

Note: the Email field must be a valid format and be unique or it will be rejected on clicking the button.

Click the "Create" button to add the user and show that users details page. Click the "Create and continue" button to add the user and stay on the new user form to add another user. When adding the last of multiple users you can click on "Create" or click the "Users" link. The users list is shown. Click each user in turn to edit their details.

### Set initial details

You can edit the details of a newly created user. Useful fields might be **Username**, **Language** and **Time zone**. You might also fill **Projects**, **Groups** and **Rates**, or leave these to the "Project creator".

Also consider the **[authentication](#authentication) settings**. See [Manage user settings](#manage-user-settings) for full details.

### Activate users

Open the user list. If a user has created their own account it is shown in the list with an "Activate" link on the right. Click this link and continue to add details to this user as above. There is also an "Activate" button at the top of the user details page.

## Authentication

The available authentication methods affect the content of the Authentication section in the user details.  See [authentication settings](../../authentication/authentication-settings/) for details.

Use the **self-registration** field to give the following controls over a new user's access.

### Manual account activation

The user details Authentication section has fields **Assign random password**, **Password**, **Confirmation** and **Enforce password change**.

* If you are near the new user, you can enter a password and confirmation then tell the user what it is. They can then sign in. It is recommended that you also tick the enforce password change tickbox, so that the user is prompted to change their password after they sign in.
* You can phone the new user or send them an email, not using OpenProject, to give them the password. In this case it is more important to tick the enforce password change tickbox.
* Tick the Assign random password, and probably the enforce password change tickbox. When the details are saved OpenProject will send an email to the new user with their password.

### Account activation by email

Leave all fields blank. When the details are saved OpenProject will send an email to the new user with a link inviting the user to OpenProject. They click the link to get the registration page to complete creating their account.

## Resend user invitation via email

If a user did not receive the email invitation, you can send the invitation to the user again if needed. In the user list, click on the user name to whom you want to resend the email with the invitation link to the system.

In the top right, click the **Send invitation** button in order to send the email once again.

![Sys-admin-resend-invitation](Sys-admin-resend-invitation.png)

## FAQ - What do I configure before I add users?

A general configuration of the system is required.

Before adding users the following sections should be checked and configured to set up OpenProject ready for adding users:

| Topic                                         | Set up content |
| [Language settings](../../system-settings/display-settings/) | Languages, time and date formats, display options |
| [User settings](../settings/) | Default user settings, user deletion, user consent |
| [Roles and permissions](../roles-permissions/) | What users can do (Roles) and the permissions for those roles |
| [User groups](../groups/) | Create groups that are linked to projects, with a role, and users |
| [Avatars](../avatars/) | Allow users to upload their photo |
| [General settings](../../system-settings/general-settings/) | Set Host name, port and protocol, welcome text |
| [Authentication](../../authentication/) | Set up authentification methods for users |
| [Configure outbound emails](../../../installation-and-operations/configuration/outbound-emails/) | Set up SMTP on the server to send email |
| [Configure inbound emails](../../../installation-and-operations/configuration/inbound-emails/) | Receiving email by the server |
| [Email configuration](../../email/) | Set up email notifications, email provider and incoming email |
| [Announcements](../../announcement/) | Set an announcement to be shown to users on login |
| [Start page](../../../user-guide/start-page) | Set up the home page, shown after login |

Now you can procede to the Manage Users tasks.
