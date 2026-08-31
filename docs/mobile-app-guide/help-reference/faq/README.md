---
sidebar_navigation:
  title: Mobile app FAQ
  priority: 790
description: FAQ of the OpenProject Mobile app.
keywords: Mobile app FAQ, faq, mobile app questions, OpenProject mobile app
---

# Mobile app FAQ

## Why is the OpenProject Mobile App being released in a Beta state?

The app is released in **Beta** to provide early access while core functionality is still under development. This allows the OpenProject team to gather **feedback from real users**, identify issues, and improve the experience before a full public release.

## What is the OpenProject Mobile app?

The OpenProject Mobile app is a companion to the OpenProject web and desktop applications. It helps you **stay informed, manage work packages, track time, and collaborate** while on the go. As the app is currently in **Beta**, some advanced features are still under development.

## What platforms are supported?

- **iOS 17 or later**
- **Android 12 or later**

The app requires an **active internet connection** to sync data with your OpenProject instance.

## How can I log in to the app?

The app requires an **active internet connection** at login to sync data with your OpenProject instance. You can log in using your username and password. Please ensure:

- Your instance has a **valid HTTPS certificate**.
- **Built-in OAuth applications are enabled** in your instance administration settings (`{BASE_URL}/admin/oauth/applications`).
- Your instance is on **OpenProject version 17.0.0 or higher**, or the “OAuth Authentication” feature flag is enabled under **Administration → Experimental** for older instances.

## What can I do in the Home Dashboard?

The Home dashboard provides a **personalized overview** of your work and includes widgets such as:

- **Notifications**
- **Time tracker**
- **Favorite projects/spaces**
- **Week time tracking**
- **Portfolios** (if configured)
- **Assigned to me**
- **Recently viewed**

Depending on your device, many of these widgets may also be available as **OS widgets** on your phone’s home screen.

[Learn more about Home Dashboard in the OpenProject mobile app](../../core-features/home-dashboard/).

## How does the Spaces module work?

The **Spaces** module (formerly Projects) provides an index of the spaces/projects you can access. Depending on your setup, it can also display a hierarchy (for example, portfolios → programs → projects). You can:

- Browse the list and navigate hierarchies (if enabled)
- Filter (e.g., by type)
- Switch between **All** and **Favorites**
- Open a space to view its overview and work packages

[Learn more about Spaces in the OpenProject mobile app](../../core-features/projects/).

## What can I do in Work Packages?

The Work packages module supports:

- Viewing and filtering work packages
- Searching by keywords
- Viewing details (Overview, Activity, Files, Relations, Watchers)
- Editing fields supported by the mobile app (depending on configuration and permissions)
- Creating new work packages from the list (via **+**)
- Collaboration via the **Activity** tab and watchers
- More actions such as sharing, time tracking, adding to device calendar, and reminders (depending on platform/version)

[Learn more about the Work Packages module in the OpenProject mobile app](../../core-features/work-packages/).

## How does Time Tracking work?

The Time tracking module helps you review and log time from the mobile app. It includes tabbed views:

- **Day**: review logged time by day
- **Work week**: weekly overview and totals
- **Time tracker**: run a timer and link it to a work package

You can also log time for **other users** (and even **multiple users at once**) if you have permission.

> [!IMPORTANT]
> The time entries displayed in the app are **personal only**. Entries for other users are not shown in the app even if you logged them.

[Learn more about Time Tracking in the OpenProject mobile app](../../core-features/time-tracking/).

## How do notifications work?

The **Notifications** module collects updates from your projects/spaces. You can:

- View notifications in different **queries** (selected from the top header), such as Inbox, Mentioned, Assignee, Watcher, Date alert, etc.
- Toggle between **Unread** and **All**
- Open a notification to view it in context (usually in the work package’s **Activity** tab)
- Mark notifications as read

You can also adjust:

- what you receive notifications for (**Account and settings → Notification settings**)
- when activity is marked as read (e.g., on opening Activity, on commenting, or on quote reply—depending on your available options)

[Learn more about Notifications in OpenProject mobile app](../../core-features/notification-center/).

## What can I do in Meetings?

The **Meetings** module lets you manage both **one-time meetings** and **recurring meeting series**. In the mobile app, you can:

- See all meetings (individual meetings and meeting series)
- Browse **upcoming** and **past** meetings within a series
- Search and filter meetings (e.g., by project or query)
- Open meeting details, including:
    - **Agenda**
    - **Backlog**
    - **Details**
    - **Participants**
    - **Attachments**
- Update the meeting status
- Prepare and manage the agenda:
    - add/edit/move/delete agenda sections and items
    - link work packages to agenda items
- Add and edit outcomes while a meeting is in progress
- Create new meetings (one-time) or new recurring meeting series
- Delete or cancel meetings (depending on permissions and configuration)
- View linked meetings from a work package via the **Meetings** tab

[Learn more about Meetings in the OpenProject mobile app](../../core-features/meetings/).

## What settings can I configure in the app?

In **Account and settings**, you can manage:

- Basic account information (avatar, username, name, email — depending on what is editable)
- Personalization (launch page, enabled modules, language, theme)
- Notification settings
- Work package settings (Activity “mark as read”, creation defaults, default list page)
- Crash reports (opt-in)
- Give feedback (bug/feedback/feature request, attachments, follow-up email)
- What’s new
- Link to mobile app documentation
- Switch instance
- Sign out

[Learn more about configuring user settings in the OpenProject mobile app](../../core-features/user-settings/).

## Are all OpenProject features available in the mobile app?

No. The app is a **companion app** and is currently in Beta. Some web/desktop capabilities are not available yet and will be added over time.

## What should I do if I experience login issues?

Check the following:

- Your instance supports **HTTPS** and is reachable from your device.
- Built-in OAuth applications are **enabled** in your instance administration.
- Your instance meets the **minimum version** requirement (17.0.0), or the OAuth feature flag is enabled.
- Ensure your credentials are correct and that you have **API access** enabled on On-Premises instances.

If none of the above solve the problem, check the [Login Troubleshooting Guide](../../first-steps/login-troubleshooting/).

## How can I provide feedback on the Beta app?

Use **Settings and support → Give feedback** to submit bug reports, feedback, or feature requests (including attachments). This goes directly to the mobile app team.

## Can I use the app offline?

The app requires an **active internet connection** to sync. Some previously loaded content may remain visible, but creating and updating items generally requires connectivity. We are currently working on bringing offline capabilities to the app, and we hope we will be able to offer these soon.

## How can I switch between multiple OpenProject instances?

Use **Settings and support → Switch instance** to switch between instance URLs without signing out each time.

## Why can’t I find a project/space, work package, meeting, or user?

The app only shows content you are allowed to access. If something is missing, it is usually due to:

- missing permissions in that project/space,
- the item being outside the currently selected filters (e.g., “All open”),
- or the feature not being supported in the current mobile version.

## Why don’t I see time entries for other users in the app?

Even if you logged time for other users, the Time tracking views show **only your personal time entries**. Other users’ time entries are not displayed.

## Can I search across my whole instance?

Yes. Use **Global search** to search across supported types (currently **Work packages** and **Spaces/Projects**). Meetings are planned to be added in a future update.

## Is there a dedicated desktop app?

Not yet. On macOS, a scaled-up iPad version may be available via the App Store, but it’s not designed for desktop usage and should be used with caution. Desktop support improvements are planned.

## Why do I receive too many notifications (or miss some)?

Check **Settings and support → Notification settings** to configure:

- Which notification types you receive (participation, date alerts, etc.)
- how Activity items are marked as read (so notifications aren’t cleared too early—or aren’t left unread longer than you want).