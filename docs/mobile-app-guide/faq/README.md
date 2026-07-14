---
sidebar_navigation:
  title: Mobile app FAQ
  priority: 800
description: FAQ of the OpenProject Mobile app.
keywords: Mobile app FAQ, faq, mobile app questions, OpenProject mobile app
---

# Mobile app FAQ

## Why is the OpenProject Mobile App being released in a Beta state?

The app is released in **Beta** state to provide early access to users while the core functionality is still under development. This allows the OpenProject team to gather **feedback from real users**, identify issues, and make improvements before the full public release. The Beta release ensures that users can start using the app for essential tasks while the remaining advanced features and refinements are being implemented.

## What is the OpenProject Mobile App?

The OpenProject Mobile App is a companion to the OpenProject desktop and web applications. It allows users to **stay informed, manage work packages, track time, and collaborate** while on the go. The app is currently in **Beta**, meaning core features are available, but some advanced functionalities are still under development.

## What platforms are supported?

- **iOS 17 or later**
- **Android 12 or later**

The app requires an **active internet connection** to sync data with your OpenProject instance.

## How can I log into the app?

You can log in using your OpenProject Cloud account or your username and password for your On-Premises instance. Please ensure:

- Your instance has a **valid HTTPS certificate**.
- **Built-in OAuth applications are enabled** in your instance administration settings (`{BASE_URL}/admin/oauth/applications`).
- Your instance is on **OpenProject version 17.0.0 or higher**, or the “OAuth Authentication” feature flag is enabled under **Administration → Experimental** for older instances.

## What can I do in the Home Dashboard?

The Home Dashboard provides a **personalized overview** of your work and includes the following widgets:

- **Notifications**: See recent mentions, comments, and updates.
- **Time Tracker**: Start or resume focus-mode timers.
- **Favorite Projects**: Quick access to starred projects.
- **Week Time Tracking**: Overview of logged hours for the current week.
- **Portfolios**: Snapshot of portfolio-level progress.
- **Assigned to Me**: List of work packages assigned to you.
- **Recently Viewed**: Quick access to recently opened items.

[Learn more about Home Dashboard in the OpenProject mobile app](../core-features/home-dashboard/).

## How does the Projects module work?

The Projects module provides an **index of all portfolios, programs, and projects**. Users can:

- Navigate the **hierarchy** between portfolios, programs, and projects.
- Filter the list to show only **favorites**.
- Open any item to see:
  - **Overview tab**: Description, status, and attributes
  - **Work Packages tab**: List of associated tasks
  - **Child Projects/Programs tab**: Projects or programs under the selected item

[Learn more about Projects module in the OpenProject mobile app](../core-features/projects/).

## What can I do in Work Packages?

The Work Packages module supports:

- Viewing and filtering all open work packages
- Searching by keywords
- Editing work package details and custom fields
- Creating new work packages (quick creation or full attribute entry)
- Adding comments, mentions, and images in the **Activity** tab
- Uploading files or photos directly from the camera
- Managing **relations** and **watchers**
- Logging time or starting a timer for focused work
- Setting reminders
- **Sharing work packages** using the device’s native sharing options

[Learn more about Work Packages module in the OpenProject mobile app](../core-features/work-packages/).

## How does Time Tracking work?

The Time Tracking module allows you to monitor and log your work efficiently:

- **Time Entries Index**: View current and past weeks and their logged time entries.
- **Timer Focus Mode**: Track work in real time with a background timer.
- **Log Time**: Record time spent on specific work packages manually.

[Learn more about Time Tracking in OpenProject mobile app](../core-features/time-tracking/).

## How do notifications work?

The Notification Center collects updates from your projects. Users can:

- View all new notifications from OpenProject.
- Open a notification to see the associated work package in the **Activity tab**.
- Mark individual notifications or all notifications as read.
- Switch between notification queries to filter by participation, mentions, or other custom inboxes.
- Toggle between viewing only unread or all notifications.

[Learn more about Notifications in OpenProject mobile app](../core-features/notification-center/).

## What settings can I configure in the app?

Through the **User Settings** module, users can:

- Change the **default launch page**
- Switch **color mode** (light, dark, system default)
- Change the app **language**
- Enable or disable specific **features** (e.g., hide Time Tracking module)
- Update **personal details** (name, email, etc.)
- Configure **notification settings** and deactivate OS-level notifications
- Provide **feedback** directly to the OpenProject Community project

[Learn more about configuring user settings in OpenProject mobile app](../core-features/user-settings/).

## Are all OpenProject features available in the mobile app?

No. The mobile app is a **companion app** and is currently in Beta status. Some advanced features of the web or desktop versions are not yet available, including:

- Deep-linking to On-Premises instances
- Multi-device UI synchronization
- Real-time push notifications
- Writing internal comments across multiple work packages
- Viewing meeting agendas in the app

These features are planned for future releases.

## What should I do if I experience login issues?

Check the following:

- Your instance supports **HTTPS** and is reachable from your device.
- Built-in OAuth applications are **enabled** in your instance administration.
- Your instance meets the **minimum version** requirement (17.0.0), or the OAuth feature flag is enabled.
- Ensure your credentials are correct, and you have **API access** enabled on On-Premises instances.

If none of the above solves the problem, check the [Login Troubleshooting Guide](../first-steps/login-troubleshooting/).

## How can I provide feedback on the Beta app?

Feedback can be submitted directly through the **User Settings → Feedback** section. Submitted feedback is sent to the OpenProject Mobile App team, allowing us to review and incorporate user suggestions.

## Can I use the app offline?

The app requires an **active internet connection** to sync data with your OpenProject instance. Some previously loaded data may be viewable offline, but creating work packages, logging time, or updating tasks requires connectivity.
