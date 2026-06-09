---
sidebar_navigation:
  title: Recurring meetings
  priority: 800
description: Manage meetings with agenda and meeting minutes in OpenProject.
keywords: meetings, dynamic meetings, agenda, minutes, recurring meeting
---

# Recurring meetings management

With OpenProject 15.3, meetings were enhanced by introducing a clear distinction between **one-time meetings** and **recurring meetings**. This page covers the features and functionalities of recurring meetings. For information on one-time meetings, please refer to [this page](../one-time-meetings). 

Recurring meetings are helpful to schedule and organize meetings that happen regularly and which have the same structure. They consist of individual occurrences that repeat with a defined frequency and interval, and are all based on a meeting template consisting of predefined sections, agenda items and participants. 

> [!NOTE]
> The **Meetings module needs to be activated** in the [Project settings](../../projects/project-settings/modules/) to be able to create and edit meetings.

| Topic                                                        | Content                                                      |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [Create and edit recurring meetings](#create-and-edit-recurring-meetings) | How to create and edit recurring meetings in OpenProject.    |
| [Edit recurring meetings template](#edit-recurring-meetings-template) | How to edit a template for recurring meeting series.         |
| [Edit recurring meeting series](#edit-recurring-meeting-series) | How to edit  recurring meeting series in OpenProject.        |
| [Edit a recurring meeting occurrence](#edit-a-recurring-meeting-occurrence) | How to edit a single meeting within recurring meeting series. |
| [Meeting backlogs for recurring meetings](#meeting-backlogs-for-recurring-meetings) | How to edit backlogs for recurring meetings in OpenProject.  |

## Create and edit recurring meetings

You can either create a recurring meeting from within a project or from the global **Meetings** module. For steps on setting up one-time meetings, please consult [this page](../one-time-meetings).

To create a new recurring meeting, click the green **+ Meeting** button in the upper right corner and select **Recurring**. 

![A button to create recurring meetings in OpenProject](openproject_userguide_meetings_recurring_meeting_button.png)

Enter your meeting's title, location, start and end date and time, duration, frequency and interval. Note that if you are creating a meeting from a global module you will first need to select a project to which the meeting belongs.

![Form to create recurring meetings in OpenProject](openproject_userguide_meetings_recurring_meeting_default_form.png)

> [!TIP] 
> Duration can be entered both in hours and minutes. For example for a meeting that should last for 1.5 hours, you can enter: 
> - 1.5h
> - 90m
> - 90min
> - 1:30

**Frequency** offers the following options: 

- Every day 
- Every working day 
- Every week 
- Day of month: This option allows you to schedule meetings to recur on the same calendar date every month
- Monthly on a weekday: This option allows you to choose an ordinal position and a weekday 

Depending on the selected frequency, one or more of the following additional fields may appear:

**Interval** is a **required** integer field that defines the recurrence pattern of a meeting series. It specifies how often a meeting should repeat within the selected recurrence scheme. For example:

- Daily, Interval = 2 → The meeting occurs every two days.
- Weekly, Interval = 4 → The meeting occurs every four weeks.

> [!TIP]
> For **working day-based recurrence**, the **Interval** field is hidden and always set to 1, meaning the meeting occurs on every working day without customization.

**Day of month**  is a **required** field indicating the date of the month, on which meetings will recur. For example, if you enter 4, the meeting will be scheduled on the 4th of every month.

**Position** is a **required** ordinal indicator field ranging from first, second, third, fourth to last. For example: Every first Monday of the month.

**Weekday** is a **required** field used to select a day of the week, from Monday through Sunday.

**Meeting series ends** field is a dropdown field that defines when a recurring meeting series should come to an end. The following options are available:

- **Never** - the meeting series runs indefinitely
- **After a specific date** – lets you specify an **end date** (the final occurrence will be scheduled on or before this date, depending on the recurrence pattern)
- **After a number of occurrences** – lets you specify the number of individual **occurrences** after which the series will end

> [!NOTE]
> If the scheduled start time does not match the actual first occurrence, the caption is extended to state: "The first occurrence of this series will be on (date/time)".

Click the **Create meeting series** button to save your changes. This will create the recurring meeting series and redirect you to the meeting template page. 

## Edit recurring meetings template

After creating a meeting series, you are redirected to the recurring meeting template, which will open in the [draft mode](../one-time-meetings/#meeting-draft-mode) by default. At this point, no meeting within the recurring meeting series has yet been set up. You need to first define a template that will be the basis of all upcoming meetings. In other words, all new iterations of meetings in the series will be a copy of this template.

![Template meeting for recurring meetings in OpenProject](openproject_userguide_meetings_recurring_meeting_initial_template.png)

You can define the template the same way that you would a [one-time meeting](../one-time-meetings): you can add sections, agenda items, work packages and even a set of participants. Keep in mind that every new occurrence of a meeting in the series will use this template. After you are done editing the meeting template, you can create the first meeting by clicking **Open first meeting** button, which will direct you to the first open meeting occurrence in the new series.

> [!IMPORTANT]
> Once you leave the draft mode, you can no longer return, i.e. you can still edit your template, but the changes may be visible (depending on the e-mail notification status).

You will be asked to decide whether or not meeting series participants should receive calendar invites and updates. Depending on your choice, a corresponding banner will inform you of the consequent actions.

![A dialogue to select meeting related notification preferences when exiting a meeting draft mode in OpenProject](openproject_userguide_meetings_recurring_meeting_open_button_dialogue.png)

> [!NOTE]
> Multiple meeting updates made within a short period of time are combined into a single notification email. Participants will receive one email showing all changes, including participant updates and changes to meeting details.
>
> Exception: Meeting deletion notifications are sent immediately and separately.

You can always adjust the template at a later date by selecting the meeting series from the left hand menu and clicking **Edit template** on the meeting series index page. These changes will not affect past or already created (opened) meetings. 

![Edit template button for recurring meetings in OpenProject](openproject_userguide_meetings_recurring_meeting_edit_template_button.png)

## Edit recurring meetings

### Edit recurring meeting series

The left side menu displays all existing meeting series. Click on one will open the index page for this particular series, displaying all meeting occurrences planned for this series, and are grouped into:

- **Open**: lists all meetings within the series that have been opened and can be edited. All open meetings will also be displayed under *My Meetings* section. 
- **Planned**: lists all meetings within the selected meeting series that are scheduled, but not yet open.  Every time a planned meeting starts, the next one will open automatically. You can also open any of the planned  meetings manually to import the template and start editing the agenda.

> [!TIP]
> Once a meeting is open, changes to the template do not affect it. 

To edit the meeting series, select the **More** (three dots) icon on the far right side of the meeting series name and select *Edit meeting series*.

![Button to edit recurring meeting series in OpenProject](openproject_userguide_meetings_edit_meeting_series_button.png)

Within the same menu you also have the following options:

- Download meeting series as iCalendar event

- Send email to all participants

- End meeting series (this option is only displayed if the series has not been ended before)

- Delete meeting series

  

### Edit a recurring meeting occurrence

To edit a single meeting within recurring meeting series you have to open it first by clicking the **Open** button next to the meeting. It will then be displayed under *Agenda opened* section on the recurring meeting index page, where you can click the meeting date and time. 

![Select a meeting occurrence on a recurring meetings series index page](openproject_userguide_meetings_edit_meeting_occurence_link.png)

This will open the specific meeting page. You can then edit the meeting by using same functions as for [editing one-time meetings](../one-time-meetings), including adding sections and agenda points, documenting agenda item outcomes, inviting participants and adding attachments.

Additionally you can copy a specific meeting series occurrence as a one-time meeting. To do that click the **More** (three dots) icon and select **Duplicate as one-time meeting**.

![Copy a recurring meeting occurrence as a one-time meeting](openproject_userguide_meetings_copy_recurring_meeting_as_onetime.png)

Within the same menu you also have the following options:

- Download iCalendar event
- Send email invite to participants
- Export PDF
- History
- Cancel this occurrence

### Move an agenda item to next meeting

In addition to all the options available when clicking on the three-dot **More** (⋯) menu for an agenda item in when [editing one-time meetings](../one-time-meetings), you will see one additional option to move the agenda item to the next meeting occurrence in the series.

![Move an agenda item to next meeting in OpenProject recurring meetings](openproject_userguide_meetings_recurring_move_agenda_item.png)

Clicking this option will display a confirmation dialog. From there, choose where to move the item: a section of the agenda or the backlog.

![A confirmation dialogue for moving an agenda item into the the next meeting occurrence in OpenProject](openproject_userguide_meetings_recurring_move_agenda_item_confirmation_dialog.png)

Confirming will move the agenda item and outcomes (if any exist) into the next immediate meeting occurrence. 

### Duplicate an agenda item to next meeting

If you don’t want to move an agenda item to the next meeting (and remove it from the current one), but instead keep it in the current meeting protocol and still discuss it again next time, you can duplicate it to the next occurrence.

This can be useful, for example, if an item was discussed but needs a follow-up in the next meeting, while the current meeting minutes should remain complete.

To do duplicate an agenda item into the next meeting, open the **More (⋯)** menu of an agenda item and select Duplicate → Duplicate in next meeting. 

![Duplicate an agenda item to next meeting in OpenProject recurring meetings](openproject_userguide_meetings_recurring_duplicate_agenda_item2.png)

Clicking this option will display a confirmation dialog. You will then need to select a destination from the dropdown menu: either a section of the agenda or the backlog.

![A confirmation dialogue for duplicating an agenda item into the the next meeting occurrence in OpenProject](openproject_userguide_meetings_recurring_duplicate_agenda_item_confirmation_dialog.png)

Confirming will create a copy of the agenda item in the next immediate meeting occurrence. The original agenda item will remain in the current meeting, keeping the protocol intact.

> [!NOTE]
> Meeting outcomes will not be duplicated if a meeting agenda item is duplicated. The outcomes will only be copied if a meeting agenda item is moved.

## Meeting backlogs for recurring meetings

### Series backlogs

A **series backlog** is a special pre-existing section below the actual agenda items of that occurrence where additional agenda items maybe be listed for consideration. These items may then be added to a particular occurrence by the meeting organizer either before or during a meeting. 

The backlog can be collapsed or expanded by clicking on the the title. Agenda backlog for recurring meetings will be visible for all meetings in the series. 

> [!TIP]
> By default, the backlog is expanded when the meeting status is *open*, collapsed if the meeting status is *in progress*, and hidden if the meeting is *closed*.

![Agenda backlog section title collapsed, in OpenProject recurring meetings](openproject_userguide_meetings_series_backlog_title.png)

#### Add and edit items to series backlogs

You can add agenda items and link work packages in the same way as you would within the meeting agenda: either by dragging and dropping via the handle on the left or by using the **Add** button. 

![Agenda backlog in recurring meetings in OpenProject](openproject_userguide_meetings_series_backlog.png)

The dropdown More (three dots) icon on the right opens a menu allowing editing, reordering or deleting an item in the series backlog.  Here you can also  add notes and move a backlog item to a current meeting. If there are multiple sections in the current meeting, you will be asked to select a section first. 

![Move agenda items from the series backlog to the agenda in OpenProject Meetings](openproject_userguide_meetings_move_series_backlog_items.png)

#### Clear agenda backlogs

You can either remove single items from a series backlog or clear an entire backlog by clicking the *Clear backlog* option under More (three dots) menu next to the backlog name. Use this option with caution, as the action cannot be undone.

![An option to clear a series backlog in OpenProject recurring meetings](openproject_userguide_meetings_clear_series_backlog.png)
