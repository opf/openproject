---
sidebar_navigation:
  title: Notifications settings
  priority: 580
description: In-app notification settings in OpenProject
keywords: notifications settings
---
# Notification Settings

You can configure how and for what events you wish to be notified through Notification Center. To access these settings, you can either click on **_your avatar on the top right corner → My account → Notification settings_** or click on **Notification Settings** on the top right corner of Notification center.

>> IMG

## Participating

You participate in a work package by either being [mentioned](../../work-packages/edit-work-package/#-notification-mention), by watching it (being on the _Watchers_ list) or by being designated assignee or accountable. 

By default, you will be notified of all activities in work packages in which you participate. However, you can choose to disable these notifications for work packages for which you are assignee or accountable by unchecking these options:

>> IMG

You cannot disable notifications for when you are mentioned (since the goal of mentioning you is to get your attention) or for work packages that you are watching. For the latter, you may disable further notifications simply by unwatching those work package.

> Info: Modifying these settings might result in your missing updates and changes that are relevant to you. We do not recommend changing them unless you are absolutely certain of the consequences.

## Date alerts

Starting 12.4, Open Project offers notification for date alerts. Please note that this is an Enterprise feature.

> **Note**: Date alerts are a Premium Feature and can only be used with [Enterprise cloud](../../../enterprise-guide/enterprise-cloud-guide/) or  [Enterprise on-premises](../../../enterprise-on-premises-guide/). An upgrade from the free Community Edition is easy and helps support OpenProject.

Date alerts allow you to receive a notification when a start date or a finish date is approaching for a work package you are participating in (that is, for which you assignee, accountable or a watcher). 

>> IMG

For each date, you can choose to be alerted the same day, a day before, 3 days before or a week before.

You can also choose to receive a recurring notification (every day, every 3 days or every week) for work package that are overdue.

## Non-participating

You can also chose to get notifications for specific events concerning work packages in which you are not participating.

You can be notified of:

- New work package
- Status changes
- Date changes
- Priority changes
- New comment

> **Info:** Please note that these apply to _all_ work packages in _all_ of your projects. Enabling lots of these can result in your receiving too many irrelevant notifications. Please use this feature with parsimony. 

## Project-specific notifications

In some cases, you may wish to fine-tune your notification settings at a project-level. 

This might be because you are more active in certain projects than others, or because certain events (like new work packages or date alerts) might be more important to you than others (like priority changes).

To add project-specific notification settings, first click on **+ Add setting for project** and select a project. 

Once you do so, you will see a table with a column for your selected project, and a list of events for which you wish to be notified. You can now select and unselect from this list as you please.

>> IMG

> **Info**: These project-specific settings will override any global settings above. You can use these settings if you find you receive not enough or too many notifications for a particular project.

## Email reminders

You can supplement these in-app notifications with email reminders, either at specific times of the day or immediately when someone mentions you. For more information, please read our guide on **[Email reminders](../../../getting-started/my-account#email-reminders)**.
