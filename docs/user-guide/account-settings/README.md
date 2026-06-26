---
sidebar_navigation:
  title: Account settings
  priority: 999
description: Learn how to configure account settings.
keywords: my account, account settings, change language
---

# Account settings

Change your personal settings under Account settings (earlier called My account). Here you can adapt, e.g. the language, edit notifications, or add an avatar. Moreover you can manage access tokens and sessions.

| Topic                                                     | Content                                                      |
| --------------------------------------------------------- | ------------------------------------------------------------ |
| [Open account settings](#open-account-settings)           | How to open your personal settings in OpenProject            |
| [Edit your user information](#edit-your-user-information) | How to change the name or email address in OpenProject       |
| [Language and region](#language-and-region-settings)      | How to change the language and the time zone in OpenProject  |
| [Security](#security)                                     | How to change your password and set up two factor authentication in OpenProject |
| [Access tokens](#access-tokens)                           | How to set up access tokens in OpenProject                   |
| [Session management](#session-management)                 | How to manage your OpenProject sessions                      |
| [Notification and email](#notification-and-email)         | How to change in-app notifications and email reminders in OpenProject |
| [Set an Avatar](#set-an-avatar)                           | How to set an avatar in OpenProject and change the profile picture |
| [Delete account](#delete-account)                         | How to delete my own account                                 |

## Open account settings

To open your personal settings in OpenProject, click on your user icon in the top right corner in the header of the application.

Choose **Account settings**.

![Account settings in OpenProject](openproject_select_account_settings.png)

## Edit your user information

To change your email address or your name, navigate to **Profile** on the left side menu of **Account settings** page.

Here you can **update** or delete your profile. If you're changing the email address of your account, you will be requested to confirm your account password before you can continue. 

> [!NOTE] 
> This applies only to internal accounts where OpenProject can verify the password.

> [!TIP]
> Please note that 'Hide my email' checkbox was removed from account settings with OpenProject 15.0.  The function was replaced by [the new Standard global role](../../system-admin-guide/users-permissions/roles-permissions/#standard), which regulates this permission on an instance level. 

![Profile settings in OpenProject](openproject_account_settings_profile.png)

## Delete account

You can delete your own account in **Account settings**.

To delete your account, navigate to *Account settings* -> *Account* and click the **Delete** button in the top right corner.  You will be asked to confirm that you understand that this deletion is permanent. 

![Confirmation dialog to delete account under OpenProject account settings](openproject_account_settings_delete_account.png)

> [!WARNING]
> Deleting a user account is permanent and cannot be reversed.

If you cannot see the entry **Delete** button under your **Account settings**, make sure the option "Users allowed to delete their account" is [activated in the administration](../../system-admin-guide/users-permissions/settings/#user-deletion).

## Language and region settings

Within the **Language and region** section of **Account settings** page you can change the language of OpenProject and adapt the time zone.

![OpenProject personal account settings](openproject_account_settings_language_and_regions.png)


### Change your language

To change the language in OpenProject, navigate to the **Account settings** and choose the menu point **Language and region**.

Here you can choose between multiple languages.

OpenProject is translated to more than 30 languages, like German, Chinese, French, Italian, Korean, Latvian, Lithuanian, Polish, Portuguese, Russian, Spanish, Turkish and many more. If you do not see your preferred language in your account settings, the language needs to be activated by your system administrator in the [system's settings](../../system-admin-guide/system-settings/languages/).

Pressing the **Save** button will save your changes.

If you want to help us to add further languages or to add the translations in your language, you can contribute to the Crowdin translations project [here](https://crowdin.com/project/openproject).

### Change your time zone

You can choose a time zone in which you work from the dropdown menu of the respective field.

Pressing the **Save** button will save your changes.

## Interface

Under the **Interface** section of project settings you can adjust the color mode, activate alerts and adjust backlog settings. Settings here are grouped into two sections: *Look and feel* and *Alerts*.

### Look and feel

In the **Look and feel** section under **Interface** in your profile settings (accessible via the left-hand menu), you can select your preferred display color mode and adjust the order in which comments appear in the **Activity list** for work packages.

You can also **disable keyboard shortcuts** . This is useful if you rely on a screen reader or want to avoid triggering actions by accident.

Click **Update look and feel** to save your changes.

!["Look and feel" section under Interface settings in OpenProject account settings](openproject_account_settings_interface_look_and_feel.png)

#### Select the high contrast color mode

In the dropdown menu **Color mode** you can pick the color mode. The default setting is the **Light mode**. You can increase the contrast by activating the **Increase contrast** setting, which will significantly increase the contrast and override the color theme of the OpenProject instance for you.

This mode is recommended for users with visuals impairment.

![Light mode with increased contrast selected in OpenProject account settings](openproject_account_settings_settings_light_high_contrast_mode.png)

#### Select the dark mode

In the dropdown menu **Color mode** you can pick the color mode. The default setting is **Light mode**. You can also alternatively select **Dark** mode and activate the **Increase contrast** setting for the **Dark high contrast** mode.

> [!NOTE]
> Custom colors and themes are only supported in Light mode and changing color modes may override most or all custom configuration. Only some colors (accent and primary button color) are kept but adapted for appropriate contrast in certain modes like dark mode.

![Dark mode in OpenProject account settings](openproject_account_settings_dark_mode.png)

#### Select automatic color mode

In the dropdown menu Color mode, you can now also select the **Automatic option, which will match the color mode of your operating system**. 

![Automatic color mode in OpenProject account settings](openproject_account_settings_automatic_os_mode.png)

If this option is selected, OpenProject will automatically match your operating system’s light or dark theme, including the system's contrast settings. You will also see additional settings to force high-contrast when Light or Dark mode is selected — this would ensure that OpenProject always increases contrast in automatic mode, regardless of the system contrast settings.

If your operating system is set to high contrast mode, OpenProject will also automatically switch to the corresponding high contrast mode (light or dark).

> [!NOTE]
> This is a user-specific preference and only affects your own account.

#### Change the order to display comments

You can select the order of the comments (for example of the comments for a work package which appear in the Activity tab). You can select the **newest at the bottom** or **newest on top** to display the comments.

If you choose newest on top, the latest comment will appear on top in the Activity list.

#### Disable keyboard shortcuts

If you use a screen reader or want to avoid accidentally triggering an action with a  shortcut, you can choose to disable default [keyboard shortcuts](../../user-guide/keyboard-shortcuts-access-keys/) by selecting the respective option.

### Alerts
Under **Alerts** section you can activate a **warning if you are leaving a work package with unsaved changes**.

Additionally, you can activate to **auto-hide success notifications** from the system. This (only) means that the green pop-up success notifications will be removed automatically after five seconds.

![Alerts section under interface settings in OpenProject account settings](openproject_account_settings_interface_alerts.png)

## Security

To reset your password, add a two-factor authentication and generate backup codes, navigate to  **Account settings** and choose **Security** in the menu.

### Change password

Enter your current password.

Enter your new password and ensure all password requirements are met.

Confirm it a second time.

Press the **Change password** button in order to confirm the password changes.

![Change password under security section in user account settings](openproject_account_settings_change_password.png)

> [!NOTE]
> You cannot reset your Google password in OpenProject. If you authenticate with a Google/Gmail account, please go to your Google account administration in order to change your password.

### Two-factor authentication devices

In order to activate the two-factor authentication for your OpenProject installation, click the  **+2FA device** button.  If you have not added any device yet, this list will be empty.

![Two-factor authentication under security section in OpenProject account settings](openproject_account_settings_two_factor_authentication.png)

If you have already registered one or multiple 2FA devices, you will see the list of all activated 2FA devices here. You can change, which of them you prefer to have set as a default option.

![List of two-factor authenticated devices](openproject_account_settings_two_factor_authentication_devices_overview.png)

In order to register a new device for two-factor authentication, click the **+ 2FA device** button and select one of the options. The options you see will depend on what your system administrator has [activated for your instance](../../system-admin-guide/authentication/two-factor-authentication/):

- Mobile phone
- App-based authenticator
- WebAuthn

![Authentication options under security section in OpenProject account settings](openproject_account_settings_two_factor_authentication_options.png)

You can remove or approve 2FA applications by confirming your password. Note that this applies only to internally authenticated users.

### Use your mobile phone

You can use your mobile phone as a 2FA device. The field *Identifier* will be pre-filled out, you will need to add your phone number, choose a preferred delivery channel and click the green **Continue** button.

![Add a new mobile phone as a 2FA device in OpenProject](openproject_account_settings_two_factor_authentication_mobile.png)

### Use your app-based authenticator

Register an application authenticator for use with OpenProject using the time-based one-time password authentication standard. Common examples are Google Authenticator or Authy. 

Open your app and follow the instructions to add a new application. The easiest way is to scan the QR code. Otherwise, you can register the application manually by entering the displayed details.

Click the green **Continue** button to finish the registration.

![openproject_my_account_authenticator_app](openproject_account_settings_authenticator_app.png)

### Use the WebAuthn authentication

Use Web Authentication to register a FIDO2 device (like a YubiKey) or  the secure enclave of your mobile device as a second factor. After you have chosen a name, you can click the green **Continue**  button.

![OpenProject WebAuth authentication](openproject_account_settings_authenticator_webauth.png)

Your browser will prompt you to present your WebAuthn device (depending on your operational system and your browser, your options may vary). When you have  done so, you are done registering the device.

### Backup codes

If you are unable to access your two-factor devices, you can use a backup code to regain access to your account. Click the **Generate backup codes** button to generate a new set of backup codes.

If you have created backup codes before, they will be invalidated and will no longer work.

![Generate backup codes under security section in OpenProject account settings](openproject_account_settings_backup_codes.png)



## Access tokens

To view and manage your OpenProject access tokens navigate to **Account settings** and choose **Access tokens** from the menu. Access tokens allow you to grant external applications access to resources in OpenProject. 

![Access tokens overview in OpenProject account settings](openproject_account_settings_access_tokens.png)

Access tokens are organized into two tabs: Provider tokens and Client tokens. Provider tokens are generated by OpenProject and enable other applications to connect to it. Client tokens are generated by external applications and allow OpenProject to connect to them.

### Provider tokens

Provider tokens are created in OpenProject and allow external applications to access OpenProject. They include API, iCalendar, iCalendar for meetings, OAuth, and RSS tokens.

#### API

API tokens allow third-party applications to communicate with this OpenProject instance via REST APIs. If no API tokens were created yet, this list will be empty. You can enable API REST web service and CORS under [*Administration -> API and webhooks*](../../system-admin-guide/api-and-webhooks/).

![Access tokens in OpenProject account settings](openproject_account_settings_access_tokens_api.png)

To create a new API Token, click the **+ API Token**, name the token in the form that opens and click *Create* button. 

![Name and create a new API token in OpenProject](openproject_account_settings_access_tokens_api_create_new.png)

A new API token will be generated and displayed. Please keep in mind that each token will only be displayed once when it is created, so it's important to copy and safely save it. Should you lose this information, you CAN delete old tokens and generate new ones. 

> [!TIP]
> We recommend using each token only for one purpose (e.g. a single application), so that you know exactly what needs to be replaced, should you need to delete it. 

![A message confirming successful generation of a new API storage in OpenProject](openproject_account_settings_access_tokens_api_generated.png)

#### iCalendar

iCalendar tokens allow users to subscribe to OpenProject calendars and view up-to-date work package information from external clients.
This list will be empty if you have no calendar subscriptions yet. 

![OpenProject calendar list under account settings showing no calendars were subscribed to yet](openproject_account_settings_access_tokens_calendar_list.png)

Once you [subscribe to a calendar](../../user-guide/calendar/#subscribe-to-a-calendar), a list of all the calendars that you have subscribed to will appear here. The name of the calendar is clickable and will lead you directly to the respective calendar in OpenProject.

![OpenProject calendar list under account settings showing calendar tokens](openproject_account_settings_access_tokens_calendar_list_with_content.png)

You can delete an entry in the iCalendar list by clicking on the **Delete** icon. This will trigger a warning message asking you to confirm the decision to delete.  By deleting this token you will no longer have access to OpenProject information in all the linked clients using this token.

![OpenProject delete calendar under account settings](openproject_account_settings_access_tokens_delete_calendar.png)

You will then see a message informing you that the the token und the iCal URL are now invalid.

![OpenProject calendar access token is invalid](openproject_account_settings_access_tokens_calendar_invalid.png)

#### iCalendar for meetings
iCalendar meeting tokens allow users to subscribe to all their meetings and view up-to-date meeting information in external clients. 

This list will be empty if you have no calendar subscriptions yet. Once you subscribe to a meetings calendar, a list of all the iCalendar meeting tokens will appear here. 

To subscribe click the **Subscribe to calendar** button directly in your account settings or in the [meetings module](../meetings/#subscribe-to-meetings). 

![A "subscribe to calendar" button to subscribe to OpenProject meetings under account settings](openproject_account_settings_access_tokens_subscribe_button.png)

You can then name the subscription meeting token and click **Create subscription**.

![Form to create a new iCal subscription token for meetings in OpenProject account settings](openproject_account_settings_access_tokens_subscribe_meetings_form.png)

You will then see the newly generated token. 

> [!IMPORTANT]
> This is the only time that it will be displayed. Make sure that you copy it and safely save it. 

![A newly generated iCal meeting subscription token in OpenProject account settings](openproject_account_settings_access_tokens_subscribe_meetings_form_confirmation.png)

To delete an iCal meeting token under Account settings click the *Delete* icon next to the respective token name. 

![Delete icon to remove a meeting iCal token under OpenProject account settings](openproject_account_settings_access_tokens_meetings_delete.png)

#### OAuth

OAuth tokens allow third-party applications to connect with this OpenProject instance, for example Nextcloud (see [here](../../user-guide/file-management/nextcloud-integration/) how to set up Nextcloud integration).  OAuth applications can be created under [*Administration-> Authentication*](../../system-admin-guide/authentication/).

OAuth tokens are not created directly in OpenProject. Instead, the authorization process is started from the external application. During setup, you will be redirected to OpenProject to confirm access and then returned to the external application to complete the connection.

If no third-party application integration has been activated yet, this list will be empty. Please contact your administrator to help you set it up. 

Once integrations exist, their tokens will appear here. You can revoke access at any time by selecting the **Delete** icon. Removing a token immediately removes the external application’s permission to act on your behalf, meaning it can no longer make API calls in your name. If you want to use the integration again, you will need to authorize it again.

![OpenProject OAuth tokens under My Account](openproject_account_settings_access_tokens_oauth.png)

#### RSS

RSS tokens allow users to keep up with the latest changes in this OpenProject instance via an external RSS reader.  You can only have one active RSS token.

Create a new token by clicking the **RSS token** button. 

![OpenProject RSS token under account settings](openproject_account_settings_access_tokens_rss.png)
This will create your token and trigger a message showing you the access token.

> [!IMPORTANT]
> You will only be able to see the RSS access token once, directly after you create it. Make sure to copy it.

![New RSS token created in OpenProject](openproject_account_settings_access_tokens_rss_new.png)

Once an  RSS token was created, you will see the details here and will be able to delete it by clicking the **Delete** icon.

![Delete RSS token icon under OpenProject account settings](openproject_account_settings_access_tokens_rss_delete.png)

### Client tokens 

Client tokens are generated by external applications and enable OpenProject to connect to them.

#### OAuth

OAuth client tokens allow this OpenProject instance to connect with external applications.

If you have not yet linked your account to any of the integrations activated for your instance, this list will be empty. You can delete tokens by clicking the **Delete** icon.

![File storages access tokens under Account settings in OpenProject](openproject_account_settings_access_tokens_file_storages.png)


## Session management

To view and manage your OpenProject sessions navigate to **Account settings** and choose **Sessions management** from the menu.

![Sessions management in OpenProject account settings](openproject_account_settings_sessions_management.png)

Here you can view and manage all of your active and remembered sessions in one place. Each row shows the browser, device, expiration date and last connection timestamp. For your current session the “Last connection” column displays **“Current (this device)”**.

You can revoke a session at any time by clicking the **×** icon at the end of the row. Hover over the icon to see the **“Revoke”** tooltip. When you click, a confirmation message appears.

Sessions expire automatically according to your instance’s authentication settings. Remembered sessions show their expiration in relative time (for example “in 5 days”).

> [!NOTE]
> Closing a browser does not necessarily terminate the session. It might still be displayed in the list and will be reactivated if you open the browser. This depends on both your browser's and the OpenProject instance's settings.

## Notification and email

To configure the notification settings which you receive from the system, navigate to **Account settings** and choose **Notification and email** from the menu.

### Notification settings

![Notification settings in OpenProject account settings](openproject_account_settings_notification_settings.png)

![More notification settings in Openproject account settings](openproject_account_settings_more_notification_settings.png)

In-app notifications can be configured and customized various ways. For a detailed guide, [click here](../../user-guide/notifications/notification-settings/).

Please also see our detailed [in-app notifications](../../user-guide/notifications/) guide to gain a general understanding.

### Email reminders

To configure the email reminders which you receive from the system, switch to the **email reminders tab.** Your system administrator can also set them for you or change the global default settings.

![Email reminders section in OpenProject account settings](openproject_account_settings_email_reminders.png)

![Second part of the page of email reminders section in OpenProject account settings](openproject_account_settings_more_email_reminders.png)

You can choose between several email reminders.

Default: Enable daily email reminders: 2am, Monday - Friday.

You can choose to receive emails immediately, or only on certain days and times, temporarily pause reminder emails, or opt for no reminders at all.

> [!IMPORTANT]
> If you have selected the *immediately when someone mentions me* option, you will only be notified once, i.e. this reminder will not be duplicated in a daily reminder.

You can also opt-in to receive **email alerts for other items (that are not work packages)** whenever one of your project members:

- **News added** - ...adds or updates news in the [News Page](../../user-guide/news/)
- **Comment on a news item** - ...adds a comment on a news item
- **Documents added** - ...adds a document somewhere in the project (i.e. a work package)
- **New forum message** - ...sends a new message into the [Forum](../../user-guide/forums/)
- **Wiki page added** - ...adds a new [Wiki page](../../user-guide/wiki/)
- **Wiki page updated** - ...updates a [Wiki page](../../user-guide/wiki/)
- **Membership added** - ...adds you to a new [Work package](../../getting-started/work-packages-introduction/)
- **Membership updated** - ...updates your membership associations

## Set an avatar

To change your profile picture in OpenProject you can set an avatar in your **Account settings** settings. Navigate to **Avatar** in the menu.

![Set avatar in OpenProject account settings](openproject_account_settings_avatar.png)

OpenProject uses Gravatar as default profile image. It displays a preview of your avatar.

Also, you can upload a **Custom Avatar** by choosing a Avatar to be uploaded from a file. Press the blue **Update** button to change your profile picture.

> [!TIP]
> The optimum size to upload a new profile picture is 128 by 128 pixels. Larger files will be cropped.