---
sidebar_navigation:
  title: Meetings FAQ
  priority: 100
description: Frequently asked questions about meetings.
keywords: meetings, meetings faq, tickets, how to, task
---

# Frequently asked questions (FAQ) for meetings

## What is a difference between a dynamic and classic meeting?

**Dynamic meetings** were introduced with OpenProject 13.1.0 as an improved version of the meetings meant to improve the user experience when managing meetings in OpenProject.

With OpenProject 15.3.0, dynamic meetings can either be [one-time meetings](../one-time-meetings) or [recurring meetings](../recurring-meetings). 

## How long will the classic meetings be available?

Classic meetings were deprecated with 16.0 release. 

- All existing classic meetings were converted into a one-time dynamic meetings. 
- Agenda text was converted to agenda items. 
- Meeting minutes were converted into meeting outcomes. 
- Author information was saved in the respective presenter fields. 

## Can I add a meeting to a calendar?

Yes, you can [download a meeting as an iCalendar event](../one-time-meetings/#download-a-meeting-as-an-icalendar-event).

## Are the meetings shown in calendar widgets?

Yes, the Calendar widget on the [project home page](../../projects/project-home/project-widgets/#calendar-widget) and [My page](../../../getting-started/my-page/#add-widgets) displays meetings. Meetings links in this widget are clickable and open the meeting directly.

## What makes OpenProject a great choice for managing meetings?

OpenProject stands out [a reliable open source solution for meeting management](https://www.openproject.org/collaboration-software-features/meeting-management/), especially for teams that value structure and transparency. Its dedicated meeting module allows users to prepare agendas, take detailed minutes, and link tasks directly to meetings — making follow-ups more actionable and clear. Because it’s part of a broader project and task management platform, everything stays connected and organized. With flexible access controls and the option to choose between a secure SaaS or on-premises setup, OpenProject supports both collaboration and data privacy. It’s particularly well-suited for teams looking for an open-source tool that supports efficient, accountable meetings.

### What is the difference between calendar subscriptions and email notifications in OpenProject meetings?

Calendar subscriptions and email notifications serve different purposes in OpenProject meetings.

**Calendar subscriptions** are used for scheduling meetings in an external calendar (such as Outlook or Google Calendar). They allow you to view meetings in your calendar and respond to meeting invitations (accept, decline, or tentatively accept). Your response is synchronized back to OpenProject and shown as your participation status. 
Learn more about [subscribing to meetings](../#subscribe-to-meetings).

**Email notifications** are used to inform meeting participants about changes to a meeting, such as added or removed participants or updated meeting details. Email notifications do not allow you to respond to a meeting invitation, unless your openproject instance has incoming mail support enabled. 
You can manage general email notification behavior in your [personal notification settings](../../notifications/notification-settings/).
