---
sidebar_navigation:
  title: Meetings
  priority: 760
description: Manage meetings with agenda and meeting minutes  in OpenProject.
robots: index, follow
keywords: meetings
---

# Meeting management

Meetings in OpenProject allow you to manage and document your project meetings at one central place, prepare a meeting agenda together with your team and document and share meeting minutes with your meeting attendees at one central place.

<div class="glossary">**Meetings** is defined as a module that allows the organization of meetings. The module has to be activated in the project settings in order to be displayed in the side navigation.</div>

| Feature                                                      | Documentation for                           |
| ------------------------------------------------------------ | ------------------------------------------- |
| [Meetings in OpenProject](#meetings-in-OpenProject)          | How to open meetings in OpenProject?        |
| [Create a new meeting](#create-a-new-meeting)                | How to create a new meeting in OpenProject? |
| [Edit a meeting](#edit-a-meeting)                            | How to edit an existing meeting?            |
| [Add meeting participants](#add-meeting-participants)        | How to add participants to a meeting?       |
| [Create or edit the meeting agenda](#create-or-edit-the-meeting-agenda) | How to create or edit the agenda?           |
| [Copy a meeting (recurring meetings)](#copy-a-meeting-(recurring meetings)) | How to create recurring meetings?           |

## Meetings in OpenProject

By selecting **Meetings** in the project menu on the left, you get an overview of all project meetings sorted by date. By clicking on a meeting name you can view further details of the meeting.

Note: in order to be able to use the meetings plugin, the Meetings module needs to be activated in the [Project Settings](../projects).

![meetings](1567598397931.png)

## Create a new meeting

To create a new meeting, click on Meetings in the project menu (Meetings needs to be activated in the Project settings to be displayed).

Click the green **+ Meeting** button.

![create-meeting](create-meeting.png)

Enter your meeting's Title, Location and Start and duration.

Select the meeting participants from the project members list.

Click the blue **Create** button to save your changes.

![create-new-meeting](1567430908286.png)

## Edit a meeting

If you want to change the details of a meeting, for example its time or location, open the meetings details view by clicking on the title in the overview list and click on **Edit** next to the meeting’s name.

![edit-meeting](edit-meeting.png)

An edit screen is displayed and the meeting information can be adjusted.

Do not forget to save the changes by clicking the blue **Save** button. Cancel will bring you back to the details view.

![edit-meeting](1567598762132.png)

## Add meeting participants

You can **add participants** (Invitees and Attendees) to a meeting while being in the [edit mode](#edit-a-meeting). The process is the same whether you are creating a new meeting or editing an existing one. Additionally you can record after the meeting who actually took part in it.

You can see the list of all the project members under **Participants**. This list varies from project to project. If you select the field in the columns Invitees or Attendees, the selected project members will be notified automatically when an agenda or a meeting protocol is created.

![participants](1567599156831.png)

By removing the check mark you can remove project members from the meetings.

Click on the **Save** button to secure the changes made by you.

## Create or edit the meeting agenda

After creating a meeting, you can set up a **meeting agenda**.

1. Prior to starting the meeting all participants can add their input to the agenda by simply clicking the Edit button.
2. With the toolbar you can make changes to the text format or edit macros, e.g. table of contents or work package tables (see [Wiki](#wiki) for details).
3. All changes made to the agenda are tracked. You can click the **History** button to get an overview of all the changes including the persons who made the changes.
4. Click the **Send for review** button to quickly notify participants about the meeting and send them a link to the meeting.
5. Press the **Send iCalendar** button to send a calendar entry to the participants. The users can then quickly add the meeting to their calendar by accepting the invitation / importing the iCal file attached to the email notification.
6. At the beginning of the meeting, **Close** the agenda to prevent any other changes and provide the same basis for all meeting participants. After closing the agenda, the meeting minutes are displayed to capture the results of the meeting.
7. ![meeting-agenda](meeting-agenda.png)

## Create or edit meeting minutes

The **meeting minutes** are automatically created when closing the agenda in the details view of the meeting and selecting the [Close](#create-or-edit-the-meeting-agenda) option.

The agenda is closed and copied to the meeting minutes page as a basis. You can start editing the minutes now. The same as in the [wiki](#wiki) pages, you can format the text, link minutes to work packages, documents, include work package lists or other macros.

Don’t forget to **Save** your data.

You will be directed to the meeting view, where you can

1. edit the minutes,

2. view the change history,

3. send the minutes for review to invitees and attendees (as well as watchers and the meeting’s author).

![meeting-agenda](meeting-agenda-1567601684299.png)

## Copy a meeting (recurring meetings)

If you have recurring meetings, such as a Jour Fixe, and want to simplify the process of creating meetings and agendas, you can **copy an existing meeting**. To do that select the meeting and open the detailed meeting view.

Select **Copy** in the top right side.

![copy-meeting](copy-meeting.png)

You can now edit the copied meeting and add the new details. Click the **Save** button to secure your changes.

<div class="alert alert-info" role="alert">
**Note**: all the settings will be copied, except for the minutes, participants and meeting history. So if you want to keep the minutes as well, you have to copy it separately.


</div>

