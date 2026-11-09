---
sidebar_navigation:
  title: Notification settings
  priority: 580
description: Configure in-app notification settings in OpenProject.
keywords: notification settings, email reminders, date alerts
---
# Notification settings

You can choose which work package events trigger in-app notifications. To access these settings, you can either click on your avatar on the top right corner > _Account settings_ > _Notification settings_ or click on **Settings** on the top right corner of the notifications inbox.

![A screenshot of Notification center with the Notification settings button highlighted](Notification-settings-12.4-fromNotificationCenter.png)

Notification settings are divided into four sections:

| Topic                                               | Description                                                                                                                          |
|-----------------------------------------------------|:-------------------------------------------------------------------------------------------------------------------------------------|
| [Participating](#participating)                     | Be notified of activities on some or all of the work packages in which you are participating (as assignee, accountable or watcher).  |
| [Date alerts](#date-alerts-enterprise-add-on)       | Be notified of approaching start or end dates, and when things are overdue.                                                          |
| [Non-participating](#non-participating)             | Be notified of activities on work packages in which you are not participating.                                                       |
| [Project-specific](#project-specific-notifications) | Fine-tune your notification settings at the level of individual projects.                                                            |

![A screenshot of the notification settings page](Notification-settings-12.4-overall.png)

## Participating

You participate in a work package by either being [mentioned](../../work-packages/edit-work-package/#-notification-mention), by watching it (being on the _Watchers_ list) or by being designated assignee or accountable.

By default, you will be notified of all activities in work packages in which you participate. However, you can choose to change these settings for work packages for which you are an assignee or accountable by checking or unchecking these options:

![A screenshot of options for participating work packages](Notification-settings-12.4-Participating.png)

You cannot disable notifications for when you are mentioned since the goal of mentioning you is to get your attention. If you no longer wish to receive notifications for certain work packages you are watching, you can simply unwatch them.

> [!NOTE]
> Modifying these settings may cause you to miss updates and changes that are relevant to you. We do not recommend changing them unless you are absolutely certain of the consequences.

## Date alerts (Enterprise add-on)

[feature: date_alerts]

Date alerts allow you to receive a notification when a start date or a finish date is approaching for a work package you are participating in (that is, for which you are assignee, accountable or a watcher).

![A screenshot of options for date alerts](Notification-settings-12.4-dateAlerts.png)

For **start** and **finish dates**, you can choose to be alerted the same day, 1 day before, 3 days before or a week before.

> [!NOTE]
> Date alerts use calendar days, not working days. For a work package starting on a Monday, "3 days before" is Friday.
> Date alerts are generated once a day at 1:00 a.m. local time.
> When you activate a date alert, work packages that are due sooner than the selected interval do not generate that alert. For example, choosing "3 days before" does not create an alert for a work package that is already due in 2 days.

For **overdue dates**, you can also choose to receive a recurring notification (every day, every 3 days or every week).

> [!NOTE]
> A previously unread notification for an overdue date alert is marked as read and replaced by a new one with the updated due date (for example, if you choose to be alerted every day for an overdue work package, and ignore that alert for a week, you will still see only one notification for this work package). You can stop receiving these alerts by either unchecking this option, or changing or removing the dates of the work package.

Date alerts notifications appear in [Notification center](../#access-in-app-notifications), both in the _Inbox_ and the separate _Date alerts_ sections on the left menu.

## Non-participating

You can also choose to receive additional notifications for specific events in all projects concerning work packages in which you are not participating.

You can be notified of:

- New work packages
- Status changes
- Date changes
- Priority changes
- New comments

![A screenshot of options for non-participating work packages](Notification-settings-12.4-nonPartipating.png)

> [!NOTE]
> Please note that these apply to _all_ work packages in _all_ of your projects. If you enable many of them, you may receive too many irrelevant notifications. Enable only the events that are relevant to you.

## Project-specific notifications

In some cases, you may wish to fine-tune your notification settings at the project level.

This might be because you are more active in certain projects than others or because certain activities (like date alerts or the creation of new work packages) might be more important to you than others.

To add project-specific notification settings, first click on **+ Add project-specific notifications**.

![A button to add project-specific notifications for OpenProject](openproject_user_guide_project_specific_settings_button.png)

Then select a project from the overlay form that will appear and specify notification settings.

![A form to specify project-specific notifications for OpenProject](openproject_user_guide_project_specific_settings_overlay.png)

Once you do so, you will see a list of projects, for which project-specific notification settings were defined. You can modify these settings at any later point.

![A list of projects with project-specific notification settings](Notification-settings-12.4-projectSpecific.png)

> [!NOTE]
> These project-specific settings will override any global settings above. You can use these settings if you find that you receive too many or not enough notifications for a particular project.

## Email reminders

You can supplement these in-app notifications with email reminders, either at specific times of the day or immediately when someone mentions you. For more information, please read our guide on [Email reminders](../../account-settings/notification-and-email/#email-reminders).
