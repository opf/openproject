---
sidebar_navigation:
  title: Calendar FAQ
  priority: 001
description: Frequently asked questions regarding the calendar module
keywords: calendar FAQ, diary, planner, holiday
---

# Frequently asked questions (FAQ) for calendar

## What information can be displayed in the calendar?

The calendar automatically displays the start and end dates of work packages in the current project. Additionally, the start and end dates of versions are shown in the calendar.

## Where can I embed / activate the calendar?

To use the calendar in a project, you need to [activate the “Calendar” module in the project settings](../../projects/project-settings/modules). Afterwards you can access the calendar in the project menu, as well as add it in the [project overview](../../projects/project-lists/). You can also enable the calendar in your [“My page” view](../../../getting-started/my-page).

## Is there an option to export or sync my calendar (e.g. Outlook)?

You cannot synchronize a personal calendar in OpenProject. However, you can [subscribe to a calendar](../#subscribe-to-a-calendar) using an external client that supports the iCalendar format.

You can also use the meeting module in OpenProject to organize meetings and invite project members.  You can [export meetings as iCalendar file](../../meetings/dynamic-meetings/#create-or-edit-the-meeting-agenda) and import them to your external calendar. If you would like Microsoft Outlook to automatically import calendar invites, please check your Outlook settings and make sure to give permission from that side.

## Are holidays considered in the calendar?

Since the [12.3 release](../../../release-notes/12/12-3-0/) it is possible to specify working and non-working days on an overall instance-level and consequently define a global work week. The default value for non-working days is set to Saturday and Sunday, but can be adjusted to your specific needs. Read more [here](../../../user-guide/work-packages/set-change-dates/#working-days).

## Is there a limit for the number of work packages displayed in the calendar?

The limit is 100 and can't be changed at the moment. Find the respective feature request [here](https://community.openproject.org/wp/35062).
