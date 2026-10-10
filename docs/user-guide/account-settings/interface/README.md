---
sidebar_navigation:
  title: Interface
  priority: 600
description: Learn how to configure user interface in OpenProject.
keywords: my account, account settings, change language
---

# Interface

Under the **Interface** section of project settings you can adjust the color mode, activate alerts and adjust backlog settings. Settings here are grouped into two sections: _Look and feel_ and _Alerts_.

## Look and feel

In the **Look and feel** section under **Interface** in your profile settings (accessible via the left-hand menu), you can select your preferred display color mode and adjust the order in which comments appear in the **Activity list** for work packages.

You can also **disable keyboard shortcuts** . This is useful if you rely on a screen reader or want to avoid triggering actions by accident.

If you often select and copy text from work packages, you can **require a double click to edit fields**.

Click **Update look and feel** to save your changes.

!["Look and feel" section under Interface settings in OpenProject account settings](openproject_account_settings_interface_look_and_feel.png)

### Select the high contrast color mode

In the dropdown menu **Color mode** you can pick the color mode. The default setting is the **Light mode**. You can increase the contrast by activating the **Increase contrast** setting, which will significantly increase the contrast and override the color theme of the OpenProject instance for you.

This mode is recommended for users with visuals impairment.

![Light mode with increased contrast selected in OpenProject account settings](openproject_account_settings_settings_light_high_contrast_mode.png)

### Select the dark mode

In the dropdown menu **Color mode** you can pick the color mode. The default setting is **Light mode**. You can also alternatively select **Dark** mode and activate the **Increase contrast** setting for the **Dark high contrast** mode.

> [!NOTE]
> Custom colors and themes are only supported in Light mode and changing color modes may override most or all custom configuration. Only some colors (accent and primary button color) are kept but adapted for appropriate contrast in certain modes like dark mode.

![Dark mode in OpenProject account settings](openproject_account_settings_dark_mode.png)

### Select automatic color mode

In the dropdown menu Color mode, you can now also select the **Automatic option, which will match the color mode of your operating system**. 

![Automatic color mode in OpenProject account settings](openproject_account_settings_automatic_os_mode.png)

If this option is selected, OpenProject will automatically match your operating system’s light or dark theme, including the system's contrast settings. You will also see additional settings to force high-contrast when Light or Dark mode is selected — this would ensure that OpenProject always increases contrast in automatic mode, regardless of the system contrast settings.

If your operating system is set to high contrast mode, OpenProject will also automatically switch to the corresponding high contrast mode (light or dark).

> [!NOTE]
> This is a user-specific preference and only affects your own account.

### Change the order to display comments

You can select the order of the comments (for example of the comments for a work package which appear in the Activity tab). You can select the **newest at the bottom** or **newest on top** to display the comments.

If you choose newest on top, the latest comment will appear on top in the Activity list.

### Disable keyboard shortcuts

If you use a screen reader or want to avoid accidentally triggering an action with a  shortcut, you can choose to disable default [keyboard shortcuts](../../keyboard-shortcuts-access-keys/) by selecting the respective option.

### Require double click to edit fields

By default, a single click on an editable field, for example the description of a work package, opens it for editing. This can get in the way when you only want to select and copy some text.

If you activate **Require double click to edit fields**, a single click no longer opens a field. Instead, you need to double click it to start editing. This applies to the work package details and full screen view, the work package table and to editable attributes on the project overview page. In the work package table, a single click on a field selects the work package instead.

You can still open a field with the keyboard by focusing it and pressing **Enter**.

This setting is disabled by default and only affects your own account.

## Alerts

Under **Alerts** section you can activate a **warning if you are leaving a work package with unsaved changes**.

Additionally, you can activate to **auto-hide success notifications** from the system. This (only) means that the green pop-up success notifications will be removed automatically after five seconds.
> [!TIP]
> Even if auto-hide is enabled, banners remain visible while you hover over them or move your mouse pointer over them. This gives you more time to read the message before it disappears.
![Alerts section under interface settings in OpenProject account settings](openproject_account_settings_interface_alerts.png)