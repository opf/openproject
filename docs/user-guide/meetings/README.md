---
sidebar_navigation:
  title: Meetings
  priority: 760
description: Manage meetings with agenda and meeting outcomes in OpenProject.
keywords: meetings, meeting, meeting series, recurring meetings, meetings agenda
---

# Meeting management

Meetings in OpenProject allow you to manage and document your project meetings, prepare a meeting agenda together with your team, and share minutes with attendees - all in one central place.

<div class="glossary">

**Meetings** is defined as a module that allows the organization of meetings.
**Note:** In order to be able to use the meetings plugin, the **Meetings module needs to be activated** in the [Project Settings](../projects/project-settings/modules/).

</div>

| Topic                                               | Content                                                   |
| --------------------------------------------------- | --------------------------------------------------------- |
| [Meetings in OpenProject](#meetings-in-openproject) | How to open meetings in OpenProject.                      |
| [Meeting types](meeting-types/)                     | The difference between one-time and recurring meetings.   |
| [Meeting features](meeting-features/)               | Features that apply to all meetings.                      |
| [Meetings FAQs](meetings-faq/)                      | Frequently asked questions about meetings in OpenProject. |

### Common tasks

| Task | Where to find it |
| --- | --- |
| Create a one-time meeting | [Create a new meeting](meeting-features/meeting-setup/#create-a-new-meeting) |
| Create a meeting series | [Recurring meetings](meeting-types/recurring-meetings/#create-and-edit-recurring-meetings) |
| Use a meeting template | [Meeting templates](meeting-features/meeting-templates/) |
| Add participants | [Add meeting participants](meeting-features/meeting-participants/#add-meeting-participants) |
| Prepare the agenda | [Meeting agenda](meeting-features/meeting-agenda/) |
| Vote on agenda items | [Sort agenda items and vote](meeting-features/meeting-agenda/#sort-agenda-items-and-vote) |
| Start or close a meeting | [Change meeting status](meeting-features/meeting-modes/#change-meeting-status) |
| Present a meeting | [Present a meeting](meeting-features/meeting-modes/#present-a-meeting) |
| Document outcomes | [Meeting outcomes](meeting-features/meeting-outcomes/) |
| Export a meeting as PDF | [Export a meeting](meeting-features/meeting-follow-up/#export-a-meeting) |

## Meetings in OpenProject

Meetings in OpenProject help teams organize discussions, track meeting agendas, and document decisions efficiently. There are two [types of meetings](meeting-types/): **one-time meetings** and **recurring meetings**. [One-time meetings](meeting-types/one-time-meetings/) are standalone events scheduled for a specific date and time. [Recurring meetings](meeting-types/recurring-meetings/) introduce a structured way to define a series of related meetings, ensuring consistency and reducing manual setup.

Both meeting types share the same [meeting features](meeting-features/), such as agendas, participants, outcomes and presentation mode. Meeting agendas can be sorted manually or by votes. With [vote-based sorting](meeting-features/meeting-agenda/#sort-agenda-items-and-vote), participants can upvote or downvote agenda items to prioritize topics within each section.

### Meetings overview

By selecting **Meetings** in the project menu on the left, you get an overview of all the meetings you have been invited to within a specific project sorted by date. By clicking on a meeting name you can view further details of the meeting.

To get an overview of the meetings across multiple projects, you can select **Meetings** in the [global modules menu](../../user-guide/home/global-modules/).

![Select meetings module from openproject global modules ](openproject_userguide_meetings_module_select.png)

Meetings will be grouped based on the meeting start time into the following groups:

- **Today** lists open meetings scheduled for the same day

- **Tomorrow** lists open meetings scheduled for the day after

- **Later this week** lists all open meetings scheduled between two days from now till the end of the week 

- **Next week and later** lists all open meetings scheduled the next week and later

![Meetings overview in openproject global modules](openproject_userguide_meetings_overview.png)

![](openproject_userguide_meetings_overview_continued.png)

### Meetings filters

The menu on the left will allow you to filter meetings based on following:

- **My meetings** lists all meetings you participate in
- **Recurring meetings** lists all recurring meetings visible to you
- **All meetings** lists all meetings visible to you
- **Templates** lists the [meeting templates](meeting-features/meeting-templates/) you have access to (Enterprise add-on, only shown if you have the permission to create meetings)

Under **Meeting series**, all recurring meeting series visible to you are listed. Click a series to see its occurrences.

Under **Involvement**, you can find:

- **Attended** lists all past meetings in which you were marked as having attended
- **Created by me** lists all meetings created by you

The buttons next to _Filters_ will allow you to filter for upcoming or past meetings.

![Meetings module side menu in OpenProject](openproject_userguide_meetings_side_menu.png)

You can also use the meetings filters to refine the list of meetings based on the following criteria: 

- **Attended user** - shows meetings that a specific user attended

- **Author** - shows meetings that a specific user created

- **Invited user** - shows meetings that a specific user was invited to

- **Meeting status** - shows meetings that are in draft mode, Open, In progress or Closed

- **Part of a meeting series** - shows meetings that are part of specific meeting series

- **Project** - shows meetings for a specific project (this will only be displayed in the global module view, i.e. not within a specific project)

- **Start time** - shows meetings that are upcoming or past

- **Title** - shows meetings that contain or do not contain certain letters or keywords

  ![Filter the list of dynamic meetings in OpenProject](openproject_userguide_meetings_filters.png)

### Subscribe to meetings

You can subscribe to all your OpenProject meetings in an external calendar application (such as Outlook, Apple Calendar, or Open-Xchange). This provides a single, read-only calendar that stays up to date automatically, without relying on individual .ics email invites.

A calendar subscription is read-only: it shows your meetings, but you cannot respond to meeting invitations through it. To respond to a meeting invitation, use the invitation you receive by email. Learn more about [participation status](meeting-features/meeting-participants/#add-meeting-participants).

#### Create a subscription

You can subscribe to OpenProject meetings either within the _Meetings_ module, or from your [Account settings page](../account-settings/access-tokens/#icalendar). 

On the meetings overview page (either global or project specific) click the **More (three dots)** icon and select **Subscribe to calendar**. 

![Button to subscribe to meetings calendar on OpenProject meetings overview page](openproject_userguide_meetings_subscribe_button.png)

You will be guided through creating an iCal subscription token:

1. Name the token and click **Create subscription**.

![New calendar subscription form opened in OpenProject](openproject_userguide_meetings_subscribtion_form_name.png)

2. Copy the generated iCal meeting subscription URL. This URL is shown only once and allows anyone with it to view your meetings.

![iCal meeting subscription URL shown when subscribing to a meetings calendar in OpenProject](openproject_userguide_meetings_subscription_token.png)

3. Add this URL to your external calendar to subscribe to your OpenProject meetings.

Once subscribed, meeting dates and updates are synchronized automatically.

If you are only interested in a specific meeting, you can [download that specific meeting as an iCal event](meeting-features/meeting-participants/#download-a-meeting-as-an-icalendar-event) instead. 

> [!TIP]
> If you are interested in how the Meetings module is used by the OpenProject team, please take a look at [this blog article](https://www.openproject.org/blog/meeting-management-example/) and this [use case](../../use-cases/meeting-management/).
>
> Find out more about OpenProject as [open source meeting management software](https://www.openproject.org/collaboration-software-features/meeting-management/).
