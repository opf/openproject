---
sidebar_navigation:
  title: One-time meetings
  priority: 900
description: Manage meetings with agenda and meeting minutes in OpenProject.
keywords: meetings, dynamic meetings, agenda, minutes, one-time meeting, draft mode, presentation mode, meeting draft, meeting presentation
---

# One-time meetings

For information on setting up recurring meeting series and templates, please refer to [this page](../recurring-meetings). Note that individual occurrences of a recurring meeting series are one-time meetings and have the same features as described here.

> [!NOTE]
> The **Meetings module needs to be activated** in the [Project settings](../../projects/project-settings/modules/) to be able to create and edit meetings.

| Topic                                                        | Content                                                    |
| ------------------------------------------------------------ | ---------------------------------------------------------- |
| [Create a new meeting](#create-a-new-meeting)                | How to create a new meeting in OpenProject.                |
| [Meeting templates](#meeting-templates-enterprise-add-on)    | How to use meeting templates (Enterprise add-on).          |
| [Meetings draft mode](#meeting-draft-mode)                   | How to prepare a new meeting behind the scenes.            |
| [Edit a meeting](#edit-a-meeting)                            | How to edit an existing meeting.                           |
| [Add a work package to the agenda](#add-a-work-package-to-the-agenda) | How to add a work package to a meeting agenda.             |
| [Create or edit the meeting agenda](#create-or-edit-the-meeting-agenda) | How to create or edit the agenda.                          |
| [Agenda backlog](#agenda-backlogs)                           | How to use an agenda backlog.                              |
| [Add meeting participants](#add-meeting-participants)        | How to invite people to a meeting.                         |
| [Add meeting attachments](#meeting-attachments)              | How to add attachments to a meeting.                       |
| [Send email to all participants](#send-email-to-all-participants) | How to send an email to all meeting participants.          |
| [Download a meeting as an iCalendar event](#download-a-meeting-as-an-icalendar-event) | How to download a meeting as an iCalendar event.           |
| [Present a meeting](#present-a-meeting)                      | How to use presentation mode for meetings in OpenProject.  |
| [Close a meeting](#close-a-meeting)                          | How to close a meeting in OpenProject.                     |
| [Re-open a meeting](#re-open-a-meeting)                      | How to re-open a meeting in OpenProject.                   |
| [Export a meeting](#export-a-meeting)                        | How to export a meeting as a PDF in OpenProject.           |
| [Copy a meeting](#copy-a-meeting)                            | How to copy a meeting in OpenProject (recurring meetings). |
| [Delete a meeting](#delete-a-meeting)                        | How to delete a meeting in OpenProject.                    |

## Create and edit one-time meetings

### Meeting templates (Enterprise add-on)

[feature: meeting_templates ]

Meeting templates allow you to reuse a predefined meeting structure when creating one-time meetings. They make it easy to start meetings with a proven structure instead of creating the agenda from scratch each time. 

Meeting templates are always associated with a specific project, but they can be created either from within a project or from the global **Meetings** page. To access them, open the **Meetings** module and select **Templates** from the left-hand menu. In the **Templates** view you can see all templates you have access to. When viewing templates globally, an additional **Project** column indicates which project each template belongs to. 

![Reusable meeting templates in OpenProject](openproject_userguide_meetings_templates.png)

Use the **More** menu (⋯) next to a template to edit or delete the template. 

![Edit or delete a meeting template in OpenProject](openproject_userguide_meetings_templates_edit_delete.png)

Click the green **+ Template** button to create a new template. When creating a template from the global view, you first need to select the project the template should belong to. Click the **Create template** button to proceed.

![Create new meeting template in OpenProject](openproject_userguide_meetings_create_new_template.png)

In the template that opens, enter and save a title. Define the agenda structure and add attachments to the template the same way as you would when creating a one-time meeting. You can also define whether this template should be kept within the project, shared with subprojects, or all other projects in this instance. If the template is to be shared, the agenda items and attachments will be copied to sub- or other projects when the template is used.

![Name and define a new meeting template in OpenProject](openproject_userguide_meetings_templates_name_save.png)

You can edit, delete, or view the history through the **More (three dots)** menu in the top right corner and selecting the respective option.

![Edit, delete or view a meeting template history](openproject_userguide_meetings_templates_edit_delete_history.png)

When creating a new **one-time meeting**, you can optionally select a **Meeting template**. The template field is empty by default. After selecting a template, the agenda and attachments are copied to the new meeting.

![Select a template when creating a new one-time meeting in OpenProject](openproject_userguide_meetings_templates_new_meeting.png)

> [!NOTE]
> Changes made to the template later will not affect meetings that were already created from it.

You can also open a template and click the **+ Meeting** button to create a new meeting in the same project.

![Create a new one-time meeting from a meeting template view in OpenProject meeting template](openproject_userguide_meetings_templates_create_new_meeting.png)


### Create a new meeting

You can either create a meeting from within a project or from the global **Meetings** module.

To create a new meeting, click the green **+ Meeting** button in the upper right corner and select what type of meeting you want to create. You can choose between **one-time and recurring meetings**. 

![Create new meeting in OpenProject](openproject_userguide_meetings_create_meeting_button.png)

For steps on setting up recurring meetings please consult [this page](../recurring-meetings).

If you choose the **one-time** option, enter your meeting's title, location, start date and time, and duration. 

If you are creating a meeting from a global module you will first need to select a project to which the meeting is attributed. 

If you are using (reusable meeting templates)(#meeting-templates-enterprise-add-on), you can also select a template. 

![Create a new one-time meeting in OpenProject](openproject_userguide_meetings_new_onetime_meeting_form.png)

> [!TIP] 
> Duration can be entered both in hours and minutes. For example for a meeting that should last for 1.5 hours, you can enter:
>
> - 1.5h
> - 90m
> - 90min
> - 1:30

Click the **Create meeting** button to save your changes. A new meeting will be created. It will initially be in **draft mode**, as indicated by the status message and the corresponding  banner. You can then proceed to add more details to the meeting.

### Meeting draft mode 

**Draft mode** allows you to prepare the meeting in advance. You can structure or refine agenda items and work on the material without initiating the meeting. This mode enables internal meeting preparation and allows freely adjusting meeting participants without them being notified at this stage.

In draft mode, the meeting status indicator does not have drop-down options. No email notifications or invites are sent out in draft mode.

After creating a meeting, you can set up a **meeting agenda** in draft mode. You can also edit the agenda at any time after opening the meeting.

![A newly created meeting in draft mode in OpenProject, highlighting draft status and banner](openproject_userguide_meetings_draft_mode_banner.png)

Once you are done editing the draft, click the **Open meeting** button in the top right corner. 

![A button to end the draft mode and mark a meeting as open in OpenProject](openproject_userguide_meetings_open_meeting_button.png)

This will open a dialog, in which you can choose whether an invite and updates should be sent out to meeting participants or not. Depending on your choice, a banner will explain what action will follow. 

![A dialogue opened after exiting a meetings draft mode in OpenProject showing options to notify meeting participants or not](openproject_userguide_meetings_open_meeting_button_invite_options_dialogue.png)

> [!IMPORTANT]
> Once you exit draft mode (by opening a meeting), you can no longer return to it.

Exiting the draft mode will change the meeting status to Open.

### Create or edit the meeting agenda

You can edit a meeting agenda by adding sections, agenda items or existing work packages by selecting the desired option under the green **+ Add** button. You can then add notes to each agenda item.

![The add button in OpenProject meetings module with three choices: section, agenda item or work package](openproject_userguide_meetings_add_agenda_item_button.png)

#### Add an agenda section 

Sections allow you to group agenda items into blocks for better organization.

To add a section, click on the **+ Add** button at the bottom of the agenda items and select the **Section** option. 

![Add a new section to a meeting agenda in OpenProject](openproject_userguide_meetings_add_section.png)

If, prior to creating your first section, your meeting already had existing [agenda items](#add-an-agenda-item), they will automatically be contained in a section called **Untitled section**. You can rename this section if you wish. 

> [!NOTE]
> If you use sections, all agenda items must have sections.

![Untitled section in OpenProject meeting](openproject_userguide_meetings_untitled_section.png)

After adding a section, you can specify it further by [adding agenda items](#add-an-agenda-item) or [work packages](#link-a-work-package-to-a-meeting) to it. 

You can also add agenda items to specific sections by either dragging and dropping items into each section, or by clicking on the **More** button (⋯) and choosing your desired action.

![Edit or delete a section in an OpenProject meeting](openproject_userguide_meetings_section_more_menu.png)

This menu also lets you rename a section, move it or delete the entire section by selecting the respective option from the dropdown menu behind the **More** (⋯) icon on the right side. If a section is moved, the agenda items will move along with it. 

> [!TIP]
> You can also re-arrange sections by dragging and dropping sections up and down.

> [!IMPORTANT]
> Deleting a section will delete all containing agenda items. If a section contains agenda items, you will be asked for confirmation before deletion.

#### Add an agenda item

If you select the **Agenda item** option, you can name that item, add notes, set the anticipated duration in minutes and select a user to be displayed next to the agenda item.  This could for example be a meeting or a project member that is accountable for the item or someone who will present that particular topic. 

![Add an agenda item to a meeting section](openproject_userguide_meetings_add_section_items.png)

By default, when creating an agenda item, this will be pre-filled with the name of the user adding the agenda item, but it can either be removed or replaced by one of the other meeting participants.

![Form for adding agenda items to meetings sections in OpenProject](openproject_userguide_meetings_add_section_items_form.png)

Sections will show the sum of all the durations of all containing items (or at least, those that have a duration specified).

![Duration of a section in OpenProject meeting](openproject_userguide_meetings_section_duration_sum.png)

> [!TIP]
> If you need to store the agenda outside of OpenProject, you can generate an optimized PDF using the print function (Ctrl/Cmd + P).

#### Convert agenda items to work packages

You can convert an agenda item into a work package to turn a discussion topic into an actionable task within your project.

To do so, open the **More** menu (three dots) of an agenda item and select **Convert to work package**.

![Menu option to convert an agenda item into a work package](openproject_userguide_meetings_convert_agenda_item_to_wp.png)

A **Convert to work package** dialog will open. The agenda item title is used as the work package subject, and the agenda item notes are added as the work package description. You can review and adjust these values before creating the work package.

![Form to convert an agenda item into a work package](openproject_userguide_meetings_convert_to_wp_form.png)

Click **Create** to create the work package in the same project as the meeting. 

After creation, the agenda item is converted into a work package agenda item and becomes the newly created work package within the meeting agenda. The original agenda item notes are preserved in the work package description.

![Converted work package agenda item](openproject_userguide_meetings_converted_work_package.png)

#### Link a work package to a meeting

To link a work package to a meeting, click the **+ Add** button and select the **Work package** option. Enter a work package ID, type, status or a keyword, this will open a list of work packages for you to choose from.

![Add work package](openproject_userguide_meetings_add_work_package.png)

The meeting will appear under the *Meetings* tab of the linked work package. 

You can also include work packages into the description section of other agenda items, by using # mention, same as in the CKEditor. In this case the meeting will not be linked to the work package and will not be displayed under the *Meetings* tab of mentioned work packages.

#### Edit a meeting agenda

After you have finalized the agenda, you can always edit the agenda, items, add notes, move an item up or down or delete it. Clicking on the **More** (three dots) menu icon on the right edge of each agenda item will display a menu of available options, including editing, copying link to clipboard, moving the agenda item within the agenda or to the backlog, or deleting it.

![Edit, copy, move or delete an agenda item in OpenProject meetings module](openproject_userguide_meetings_agenda_item_more_icon_opened.png)

You may also re-order agenda items by clicking on the drag handle (the icon with six dots) on the left edge of each agenda item and dragging that item above or below.

![Drag handle next to an agenda item in OpenProject meetings](openproject_userguide_meetings_agenda_item_drag_handle.png)

The durations of each agenda item are automatically summed up. If that sum exceeds the planned duration entered in *Meeting Details*, the duration of those agenda times that exceed the planned duration will appear in red to warn you of the fact.

![Meeting agenda items duration sum is greater than the meeting duration set in OpenProject](openproject_userguide_meetings_agenda_too_long.png)

### Agenda backlogs

An **agenda backlog** is a special pre-existing section below the actual meeting agenda where additional agenda items can be listed before being added to that particular meeting. This allows users to propose topics that are then picked up by the meeting organizer either before or during the actual meeting. 

The backlog can be expanded or collapsed by clicking on the title.

> [!TIP]
> By default, the backlog is expanded when the meeting status is *open*, collapsed if the meeting status is *in progress*, and hidden if the meeting is *closed*.

![Agenda backlog section title collapsed, in OpenProject one-time meeting](openproject_userguide_meetings_agenda_backlog_title.png)

#### Add and edit items to agenda backlogs

You can add agenda items and link work packages in the same way as you would within the meeting agenda, by dragging and dropping agenda items elsewhere in the meeting or by using the dropdown options of the More (three dots) icon on the right. 

![Agenda backlog in a single meeting in OpenProject](openproject_userguide_meetings_agenda_backlog.png)

That same *More* menu also allows editing, reordering, adding notes or deleting an item in the agenda backlog. 

![Move agenda items from the agenda backlog to the agenda in OpenProject Meetings](openproject_userguide_meetings_move_agenda_backlog_items.png)

#### Clear agenda backlogs

You can either remove single items from an agenda backlog or clear an entire backlog by clicking the *Clear backlog* option under More (three dots) menu next to the backlog name. Use this option with caution, as the action cannot be undone.

![An option to clear an agenda backlog in OpenProject meetings](openproject_userguide_meetings_clear_agenda_backlog.png)

### Add a work package to the agenda

There are two ways to add a work package to a meeting agenda.

- **From the Meetings module**: using the **+ Add** button [add a work package agenda item](#link-a-work-package-to-a-meeting) or
- **From a particular work package**: using the **+ Add to meeting** button on the [Meetings tab](../../work-packages/add-work-packages-to-meetings)

You can add a work package to both upcoming or past meetings as long as the work package is marked **open**.

![Button to add a work package to a meeting under Meetings tab in a work package in OpenProject](openproject_userguide_meetings_add_wp_to_meeting_agenda.png)

> [!TIP]
> The upcoming meetings are displayed in chronological order, from the nearest meeting to the most distant. 
> The past meetings are displayed in reverse chronological order, from the most recent meeting to the oldest.


### Edit a meeting

If you want to change the details of a meeting, for example its time or location, open the meetings details view by clicking the cogwheel icon next to the **Meeting details**.

![A cogwheel icon to edit a meeting in OpenProject](openproject_userguide_meetings_cogwheel_icon.png)

An edit screen will be displayed, where you can adjust the date, time, duration and location of the meeting. Depending on whether email calendar updates are enabled or disabled, a corresponding banner in the form will indicate whether an update will be sent after the changes are saved.

![A form to edit an existing meeting in OpenProject](openproject_userguide_meetings_edit_meeting_form.png)

Do not forget to save the changes by clicking the **Save** button. Cancel will bring you back to the details view.

> [!TIP]
> If someone else edits or updates the current meeting page at the same time and saves their changes, you and all other users on the same page will be notified of this with a small banner at the top of the page. Click the **Reload** button to load the updated version of the page. 
>
> If you are in the [presentation mode](#present-a-meeting), changes will load automatically, without the banner being displayed.

![Banner notifying that a meeting has been updated while a user is editing it in OpenProject meetings module](openproject_userguide_meetings_page_update_reload_button.png)

In order to edit the title of the meeting select the dropdown menu behind the three dots and select the **Edit meeting title**.

![Edit a meeting title in OpenProject](openproject_userguide_meetings_edit_meeting_title.png)

## Meeting participants

### Add meeting participants

You will see the list of all the invited project members under **Participants**. You can add participants (Invitees and Attendees) to a meeting in [edit mode](#edit-a-meeting). The process is the same whether you are creating a new meeting or editing an existing one. You can either click the cogwheel icon next to **Participants** section or click the **Manage participants** link under the list of existing participants.

![Add meeting participants in OpenProject](openproject_userguide_meetings_add_participants.png)

The participants list will show everyone invited to the meeting so far. Initially, it only contains the meeting creator. To add participants, use the search bar to find one or more project members, then click **Add**. Depending on whether email calendar updates are enabled or disabled, a corresponding banner in the form will indicate whether an update will be sent after the changes are saved.

![A form showing invited and attending meeting participants in OpenProject](openproject_userguide_meetings_add_new_participants_form.png)

To remove a participant, click the *x* icon on the far right of their name. 

Once participants are added, their **participation status** is shown in the meeting view.

If participants are subscribed to meetings via an external calendar, they can respond to the meeting invitation directly from their calendar (Accepted, Tentative, or Declined). Their response is synchronized back to OpenProject and visible to meeting organizers and other participants.

![Meeting participants with their status highlighted in an OpenProject meeting](openproject_userguide_meetings_participants_status.png)

Once the meeting has started (status set to *In progress*), you can record attendance by selecting the **Mark as attended** button.

![Button to mark meeting participants as attended in OpenProject meetings module](openproject_userguide_meetings_mark_participants_attendance_button.png)

### Send email to all participants

You can send an email reminder to all the meeting participants. Select the dropdown by clicking on the **More** (three dots) icon in the top right corner and select **Send email invite to participants**. An email reminder with the meeting details (including a link to the meeting) is immediately sent to all invitees and attendees.

![Option to send email invite to meeting participants in an OpenProject meeting](openproject_userguide_meetings_send_email_invite.png)

### Email calendar updates

**Email calendar updates** section on the right side shows whether the setting to notify participants of any meeting changes via email is activated. To enable it click the **Enable** button, to disable it click the **Disable** icon. Here is an example of disabling the calendar updates. 

![Icon to disable email calendar updates for one-time meetings in OpenProject](openproject_userguide_meetings_disable_calendar_updates.png)

You will then see a warning message informing you of the consequences. You can either cancel or confirm disabling the email updates at this point. 

![A warning banner to cancel or confirm disabling meeting email calendar updates](openproject_userguide_meetings_disable_calendar_updates_warning.png)

You can always re-activate it by clicking the **Enable** icon. 

![Icon to enable calendar updates for meeting changes in OpenProject one-time meetings](openproject_userguide_meetings_enable_calendar_updates.png)

> [!NOTE]
> Enabling or disabling email calendar updates does not affect calendar subscriptions. 
> If you are unsure whether a meeting change will trigger an email or update your calendar subscription, see the [Meetings FAQ](../meetings-faq/#what-is-the-difference-between-calendar-subscriptions-and-email-notifications-in-openproject-meetings).

## Meeting outcomes

Meeting outcomes help you document what was discussed and decided during a meeting. You can capture outcomes as written notes (e.g. decisions or summaries) or as work packages to create follow-up tasks that stay connected to the meeting agenda.

### Add agenda item outcomes

During a meeting, stakeholders will often make relevant decisions, add useful information, or specify follow-up steps. In OpenProject, these can be added as outcomes to each agenda item. To note outcomes, the meeting status has to first be set to [in progress](#mark-meeting-in-progress). 

> [!TIP]
> To be able to add *Agenda meeting outcomes*, **Manage outcomes** permission needs to be granted under [Roles and permissions](../../../system-admin-guide/users-permissions/roles-permissions/) in system administration.

Once a meeting is in progress, there will be a **+ Outcome** button at the end of each agenda item. Click **+ Outcome** and choose one of the following options:

- [Write outcome](#write-outcome)
- [Existing work package](#existing-work-package)
- [New work package](#new-work-package)

![Button to add an agenda outcome in OpenProject meetings](openproject_userguide_meetings_agenda_outcome_button.png)

#### Write outcome

Use this option to add a written outcome, such as a decision, a short summary, or meeting notes.

An editor will appear, allowing you to enter and format text, similar to editing an agenda item.

![Editor to enter or edit agenda item outcomes in OpenProject meetings](openproject_userguide_meetings_agenda_outcome_form.png)

Click **Save** to add the agenda item outcome.

> [!TIP]
>
> You can save multiple outcomes per agenda item in OpenProject.

After saving a written outcome, you can still edit it. Click the **More** (three dots) menu on the right edge of each outcome item and select *Edit outcome*.

![Edit an agenda item outcome in OpenProject meetings](openproject_userguide_meetings_agenda_outcome_more_menu.png)

This menu also allows you to *Copy link to clipboard* and to *Remove the outcome*.

#### Existing work package

Use this option to add an already existing work package as a meeting outcome. This is helpful if the follow-up task already exists and you want to document that it was discussed during the meeting.

You can use the search bar to search for a work package name or ID.

![Add an existing work package as a meeting agenda item outcome in OpenProject](openproject_userguide_meetings_agenda_outcome_existing_wp_form.png)

Once added, the work package will appear as an outcome under the agenda item. Work package outcomes can be removed again if needed. From the **More** (three dots) menu, you can copy the work package URL or remove the outcome.

![Copy link or remove a work package outcome from an OpenProject meeting](openproject_userguide_meetings_agenda_outcome_existing_wp_edit.png)

#### New work package

Use this option to create a new work package directly from the meeting and add it as an outcome. This is useful for quickly creating follow-up tasks during the meeting while keeping them linked to the agenda item and meeting minutes.

When you select **New work package**, a work package creation dialog will open. 

![Form to create a new work package as an agenda outcome in an OpenProject meeting](openproject_userguide_meetings_agenda_outcome_new_wp_form.png)

After creating it, the new work package will be shown as an outcome under the agenda item.

> [!TIP]
> Creating work packages as meeting outcomes requires users to have both **Manage outcomes** and **Create work packages** permissions.

### Agenda outcomes in work packages

Meeting agenda outcomes are also displayed in the **Meetings** tab of the linked work package in a read-only format. They are marked with an **Added as outcome** label so that it is clear how the work package is connected to the meeting.

![Agenda item outcomes displayed in Meetings tab in a work package in OpenProject](openproject_userguide_meetings_agenda_outcome_in_work_package.png)

## Meeting attachments

You can add attachments in the meetings in the **Attachments** section in the bottom right corner. You can either use the **+Attach files** link to select files from your computer or drag and drop them.

Added attachments can be added to the Notes section of agenda packages by dragging and dropping them from the Attachments section.

![Attachments in OpenProject meetings](openproject_userguide_meetings_attachments.png)


## Meeting history

You can track what changes were made to a meeting and by which user. Select the dropdown by clicking on the **More** (three dots) icon in the top right corner and select **Meeting history**.

![Select Meeting history option in OpenProject meetings](openproject_userguide_meetings_select_meeting_history.png)

This will display meeting history details.

![Meeting history in OpenProject](openproject_userguide_meetings_history_shown.png)

## Download a meeting as an iCalendar event

You can download a meeting as an iCalendar event. Select the dropdown by clicking on the **More** (three dots) menu in the top right corner and select the **Download iCalendar event**. 

Read more about [subscribing to a calendar](../../calendar/#subscribe-to-a-calendar).

![An icon to download a meeting as an iCalendar event in OpenProject meetings module](openproject_userguide_meetings_download_ical.png)

Please keep in mind that downloading a meeting as an iCalendar event adds it to your calendar, but it does not keep the meeting synchronized automatically.

> [!TIP]
> If you want to respond to meeting invitations directly from your calendar and have your participation status synchronized back to OpenProject, you can [subscribe to meetings](../#subscribe-to-meetings) instead of downloading individual iCal events.

## Change meeting status
You can change the status of a meeting depending on whether you are preparing it, running it, or finalizing it.

[**Draft mode**](#meeting-draft-mode) is used while preparing a meeting before it is opened. In this mode you can outline the agenda, add or adjust items, work on the content, and adjust participants without running the meeting yet. Draft mode is intended for internal preparation and does not represent the start of the meeting.

Once the preparation stage is finalized, meetings in OpenProject transition to an active phase and can have three different statuses: Open, In Progress, and Closed. Depending on the meeting status, different options are available, such as editing the agenda, adding outcomes, or finalizing the meeting. You can transition between these statuses using the meeting status button  with a drop-down menu under the meeting name or in the right-hand pane.

![Meeting status in OpenProject](openproject_userguide_meetings_meeting_status.png)

Clicking on this button will show following status options:

**Open**: reverts the meeting to an editable state, but existing outcomes remain read-only.

**In progress**: enables outcome documentation for agenda items.

**Closed**: locks the meeting and prevents further edits.

### Open meeting status 

When a meeting is *Open*, you can prepare the agenda by adding or removing agenda items. Once the agenda is ready, the meeting can be started.  

> [!TIP]
>
> In an open meeting state in addition to the status menu, you will directly see the **Start a meeting** link on the right.

![Link to start a meeting in OpenProject](openproject_userguide_meetings_meeting_mark_in_progress.png)

### Mark meeting in progress

Once the agenda is ready, the meeting can be started. To mark a meeting in progress you can use the dropdown status menu and select *In progress* or click the *Start meeting* link on the right side.

Setting a meeting *In progress* allows adding [**Agenda item outcomes**](#add-agenda-item-outcomes) by using the **+ Outcome** buttons.

Once all outcomes are documented, you can close the meeting. To do that use the dropdown status menu on the right side or under the meeting name. 

### Close a meeting

Once all outcomes are documented, you can close the meeting. To do that use the dropdown status menu on the right side or under the meeting name. 

> [!TIP]
> In a meeting marked *in progress* in addition to the status menu, you will directly see the **Close meeting** link on the right. 

Closing a meeting locks the current state and makes it read-only.

![Close a meeting in OpenProject](openproject_userguide_meetings_close_meeting.png)

When a meeting is closed, you can still copy a link to a specific agenda item or outcome. Click the More (three dots) icon on the right and select *Copy to clipboard*.

![Copy a link to a meeting agenda item in OpenProject meeting](openproject_userguide_meetings_copy_link.png)

### Re-open a meeting

Once a meeting has been closed, it can no longer be edited. Project  members with the permission to edit and close meetings will, however,  see a **Re-open meeting** option. Clicking on this re-opens a meeting and allows further editing.

![Re-open a meeting in OpenProject](openproject_userguide_meetings_reopen_meeting.png)

## Present a meeting


**Presentation mode** is available when you want to show the meeting content in a clean, non-editable view. This mode is intended for presenting the agenda or meeting material to participants during or before the meeting without distractions. However, agenda items can be edited in presentation mode if needed.

Presentation mode can be used regardless of the meeting status (open, in progress or closed). However, a presentation mode is not available in a draft mode or for a meeting template (recurring meetings).

> [!TIP]
> Presentation mode generally does not change the meeting status, with one exception. If a meeting has the status *Open*, clicking the *Present* button will automatically change the meeting status to *In progress*. 

To initiate a presentation mode click the present button in the top right corner. 

![Button to start the presentation mode in OpenProject meetings module](openproject_userguide_meetings_present_button.png)

Presentation mode will be activated. It will show the following: 

1. The meeting title 
2. Exit presentation button
3. Current section (if any)
4. Current item of the selected section
5. Button to add outcomes directly during the presentation 
6. Footer with agenda progress, a running timer, and Previous / Next navigation buttons showing item titles and section titles when applicable

![An example of a meeting in an active presentation mode in OpenProject](openproject_userguide_meetings_presentation_mode_activated.png)

You can navigate through the meeting presentation by either clicking the *Previous/Next* navigation buttons, or by using arrow keys of your keyboard.

Meeting changes made during the presentation are updated automatically unless an item is actively being edited.

To exit the presentation mode click the Exit presentation button in the header. 

>  [!NOTE]
>
> Some browsers may block automatic full-screen mode. In this case you can manually enable full-screen using the browser controls.

## Export a meeting

You can export a meeting in OpenProject in a PDF format. A meeting can be exported regardless of the meeting state (open, in progress or closed). 

To export a meeting select the dropdown by clicking on the **More** (three dots) icon in the top right corner and select **Export PDF**. 

![Option to export a meeting in PDF format in OpenProject](openproject_userguide_meetings_export_pdf.png)

The **Export PDF** dialogue will open. Here you can specify what elements should be included into the PDF and specify the footer text. Options include: 

- Include list of participants: a list of participants will be preset above the meeting agenda (**this option is selected by default**)
- Include list of attachments: a list containing the filenames of attachments will be appended at the end
- Include backlog: includes list of backlog elements
- Include agenda outcomes: includes agenda outcomes (**if your agenda outcomes contain confidential information, you can choose to not include them in the export**).

You can also specify the **Footer text**, which will appear on the bottom of every page. The default text for the PDF export footer is the project name.

![A dialogue to specify the PDF export of a meeting in OpenProject](openproject_userguide_meetings_pdf_export_dialogue.png)

Click the **Download** button to generate a PDF. First page of the PDF is the title page. The generated PDF will include all the meeting details and agenda. Meeting participants, agenda outcomes, a list of attachments and backlog items will only be included if selected for the export. 

> [!NOTE]
> Macros from the editor macros dropdown are not supported in the PDF.

![An example of a meeting exported as a PDF file in OpenProject meetings module](openproject_userguide_meetings_pdf_export_file.png)

## Copy a meeting

You can copy an existing meeting. This is useful if you have recurring meetings. To copy a meeting, click on the three dots in the top right corner and select **Duplicate**.

![Copy a meeting in OpenProject](openproject_userguide_meetings_copy_meeting.png)

A modal will open, which will allow you adjust the title, time, location and further details of the copied meeting. By default, the date for the copied meeting will be set to the next day. You also have an option of copying the agenda, attachments and the list of participants. 

If you copy a closed meeting, the new meeting status will automatically be set to open. Don't forget to **save** the copied meeting by clicking the **Create meeting** button.

![Edit details of a copied meeting in OpenProject](openproject_userguide_meetings_copy_form.png)

## Delete a meeting

You can delete a meeting. To do so, click on the three dots in the top right corner, select **Delete meeting** and confirm your choice.

![Deleting a meeting in OpenProject](openproject_userguide_meetings_delete_meeting.png)
