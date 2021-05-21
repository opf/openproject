---
sidebar_navigation:
  title: My account
  priority: 400
description: Learn how to configure account settings.
robots: index, follow
keywords: my account, account settings, change language, Deutsch
---

# My account

Change your personal settings in My account. Here you can adapt, e.g. the language, edit notifications, or add an avatar.

| Topic                                                        | Content                                                      |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [Open My account settings](#open-my-account-settings)        | How to open your personal settings in OpenProject?           |
| [Change password](#change-password)                          | How to change my password?                                   |
| [Edit your user information](#edit-your-user-information)    | How to change the name or email address in OpenProject?      |
| [Profile settings: change your language, time zone or display of comments](#profile-settings) | How to change the language, time zone or display of comments in OpenProject? |
| [Two-factor authentication](#two-factor-authentication-premium-feature) | How to set up a two-factor authentication?                   |
| [Email notifications](#email-notifications)                  | How to change email notifications sent by OpenProject?       |
| [Set an Avatar](#set-an-avatar)                              | How to set an avatar in OpenProject and change the profile picture? |
| [Delete account](#delete-account)                            | How to delete my own account?                                |

## Open My account settings

To open your personal settings in OpenProject, click on your user icon in the top right corner in the header of the application.

Choose **My account**.

![my-account](my-account.png)

## Change password

In order to reset your password, navigate to the My account section and choose **Change password** in the menu.

Enter your current password.

Enter your new password and confirm it a second time.

Press the blue **Save** button in order to confirm the password changes.

![change password](1572880507527.png)

<div class="alert alert-info" role="alert">
Note: You cannot reset your Google password in OpenProject. If you authenticate with a Google/Gmail account, please go to your Google account administration in order to change your password.
</div>

## Edit your user information

To change your email address or your name, navigate to the **Profile** page in the menu of your My account settings.

Here you can adapt the information and **save** your changes with the blue button.

## Profile settings

Within the My account settings you can change the language of OpenProject, adapt the time zone and change the order how comments are displayed in the Activity list for work packages.

Also, you can activate a **warning if you are leaving a work package with unsaved changes**.

Additionally, you can activate to **auto-hide success notifications** from the system. This (only) means that the green pop-up success notifications will be removed automatically after five seconds.

![my-account-settings](image-20210503211553255.png)

### Change your language

To change the language in OpenProject, navigate to the **My account** settings and choose the menu point **Settings**.

Here you can choose between multiple languages.

![select a language](1572882728878.png)

OpenProject is translated to more than 30 languages, like German, Chinese, French, Italian, Korean, Latvian, Lithuanian, Polish, Portuguese, Russian, Spanish, Turkish and many more. If you do not see your preferred language in the My account settings, the language needs to be activated by your system administrator in the [system's settings](../../system-admin-guide/system-settings/display-settings).

Pressing the blue **Save** button will save your changes.

If you want to help us to add further languages or to add the translations in your language, you can contribute to the CrowdIn translations project [here](https://crowdin.com/project/openproject).

### Change your time zone

You can choose a time zone in which you work and how the comments and changes will be saved.

![time zone](1572882881007.png)

Pressing the blue **Save** button will save your changes.

### Change the order to display comments

You can select the order of the comments (for example of the comments for a work package which appear in the Activity tab). You can select the **chronological** or **reverse chronological order** to display the comments.

If you choose reverse chronological order the latest comment will appear on top in the Activity list.

![display comments](1572883259523.png)

### Backlogs settings

There are two personal settings available for the [Backlogs module](../../user-guide/backlogs-scrum):
**Task color**: Here you can enter the color in which your tasks on the task board (on the Backlogs page) are displayed. Tasks on the task board are color-coded based on who they are assigned to. Every user has a default color assigned but if you prefer a different color, you can change it here.
**Show versions folded**: When you navigate to the "Backlogs" module in a project, the available versions (e.g. Product backlog, Sprints) are displayed. By default they are expanded, i.e. all work packages included in those versions are shown right away. If you have a large number of versions that are shown on the "Backlogs" page, you may opt to collapse them by default. This way you see all the versions on a page and can then choose to expand those versions for which you want to see details.

## Two-factor authentication (Premium feature)

In order to activate the two-factor authentication for your OpenProject installation, navigate to your **My account** and choose the **Two-factor authentication** in the menu.

![Two-factor authentication](1571992032476.png)

In order to register a new device for two-factor authentication, lick the green button to add a **new 2FA device**.

You can either use your mobile phone number to receive the second factor via SMS. Or you can register to use an app-based authenticator, such as Google Authenticator or Authy.

![add new 2fa device](1572876883531.png)

### Register your mobile phone number for delivery of OpenProject one-time passwords.

To register your phone number to receive a one time password via SMS, click on the **Register device** button under the **Use your mobile phone** section.

- Choose an identifier how you want your phone to be named.
- Enter your phone number in the following format.

![two-factor authentication](1572878991958.png)

Press the blue **Continue** button to confirm your device.

### Backup codes

If you are unable to access your two-factor devices, you can use a backup code to regain access to your account. Use the grey button **Generate backup codes** to generate a new set of backup codes.

If you have created backup codes before, they will be invalidated and will no longer work.

### Use your app-based authenticator

Register an application authenticator for use with OpenProject using the time-based one-time password authentication standard. Common examples are Google Authenticator or Authy.

Click the grey **Register device** button to register an authentication app. Open your app and follow the instructions to add a new application. The easiest way is to scan the barcode. Otherwise, you can register the application manually by entering the displayed details.

Click the blue **Continue** button to finish the registration.

![register authentication app](1572879640187.png)



## Email notifications

To configure the email notifications which you receive from the system, navigate to **My account** and choose **Email notifications** in the menu. Your system administrator can also set them for you or [change](../../system-admin-guide/email/#email-notifications-settings) the global default settings.

You can choose between several email notifications.
**Default: Send email notifications Only for things I watch or I'm involved in.**

You can choose to receive emails for any events in certain projects or for no events at all.

![Email notifications](1571835165758.png)

The following options are available for the email notifications (ranging from receiving emails on a lot of events to receiving no emails at all):

- **For any event on all my projects** - When selecting this option you receive an email for any action in the projects you are a member of (independent of whether or not you are involved in this action). This can be useful for managers who want to always stay up to date of all developments without having to log into OpenProject. This setting will typically lead to receiving a lot of emails.
- **For any event on the selected projects only** - This option lets you choose the projects for which you receive all email updates. In addition, you receive email notifications from other projects about activities you watch or are involved in (e.g. when you are the author, assignee or responsible of a work package.). This is useful for project managers who need to be informed about any change in the project(s) they manage but who want to only receive email notifications from other projects if the activities directly affect them.
- **Only for things I watch or I am involved in** - This is the default option for new users (unless configured differently in the [administration (email notification settings)](../../system-admin-guide/email)). Users with this setting receive emails for activities in which they are involved (i.e. if they are the author, assignee or responsible or are set as watcher). This option is usually the best option since users only get email updates about activities in which they are involved therefore reducing the number of emails they receive. No emails are sent to users who only added a comment or changed the work package.
- **Only for things I am assigned to** - With this email setting you only receive email updates of activities to which you are assigned (e.g. work packages). This is useful for users who want to only be notified via email if they are actively working on a task, not if they are responsible for or watching the activity.
- **Only for things I am the owner of** - When you select this setting you only receive email updates for activities which you created (e.g. work packages, wiki pages). This makes sense if you are not actively involved in a project but want to only be notified if your activities are updated.
- **No event** - With this setting you receive no emails at all. You need to log into OpenProject to verify the status of your tasks. Unless you check the status within OpenProject very frequently or are not actively involved in any project, this setting is typically too restrictive.

When someone [mentions](../../user-guide/work-packages/edit-work-package/#-notification-mention) you in e.g. a work package description or comment you will only receive a notification if you are a member of the respective project and did not choose "No event" as notification setting.

By default you do not receive any email notifications about your own changes. If you want to receive emails for your own changes (e.g. to make sure that emails for changes you made have been sent), activate the check-box **I want to be notified of changes that I make myself**.

Please read [these instructions](../../system-admin-guide/email) to learn about the global settings for email notifications and [these FAQ](../../system-admin-guide/email/faq) if you have questions.



## Set an avatar

To change your profile picture in OpenProject you can set an avatar in your My account settings. Navigate to **Avatar** in the menu.

OpenProject uses Gravatar as default profile image. It displays a preview of your avatar.

Also, you can upload a **Custom Avatar** by choosing a Avatar to be uploaded from a file. Press the blue **Update** button to change your profile picture.

<div class="alert alert-info" role="alert">
Note: The optimum size to upload a new profile picture is 128 by 128 pixel. Larger files will be cropped.
</div>

![Avatar](1571844887353.png)



# Delete account

You can delete your own account in **My account**.

If you cannot see the entry **Delete account** in the **My account** side menu, make sure the option "Users allowed to delete their account" is [activated in the administration](../../system-admin-guide/users-permissions/settings/#user-deletion).

To delete your account, select **Delete account** from the side menu and enter your login to confirm the deletion.

![delete account](1572881984371.png)

<div class="alert alert-info" role="alert">
Important: Deleting a user account is permanent and cannot be reversed.
</div>
