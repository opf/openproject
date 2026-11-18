---
sidebar_navigation:
  title: Meeting types
  priority: 900
description: The difference between one-time meetings and recurring meetings in OpenProject.
keywords: meetings, meeting types, one-time meeting, recurring meeting, meeting series
---

# Meeting types

There are two types of meetings in OpenProject: **one-time meetings** and **recurring meetings**. Both types share the same [meeting features](../meeting-features/), such as agendas, participants, outcomes and presentation mode. They differ in how they are scheduled and set up.

| Topic | Content |
| --- | --- |
| [One-time meetings](one-time-meetings/) | Single meetings scheduled for a specific date and time. |
| [Recurring meetings](recurring-meetings/) | A series of meetings with the same structure that repeat regularly. |

## Which meeting type should I use?

- Use a **one-time meeting** for a meeting that happens only once, for example a kick-off, a workshop or an ad-hoc discussion.
- Use a **recurring meeting** for meetings that take place regularly and follow the same structure, for example a weekly team meeting or a monthly steering committee.

## Differences at a glance

|  | One-time meeting | Recurring meeting |
| --- | --- | --- |
| Scheduling | One date and time | Frequency and interval, with an optional end date or number of occurrences |
| Template | Optional [meeting template](../meeting-features/meeting-templates/) (Enterprise add-on) | [Series template](recurring-meetings/#edit-recurring-meetings-template) that is the basis for every occurrence |
| Backlog | [Agenda backlog](../meeting-features/meeting-agenda/#agenda-backlogs) for this meeting | [Series backlog](recurring-meetings/#meeting-backlogs-for-recurring-meetings) shared by all occurrences |
| Moving agenda items | To another section or the backlog | Also to the [next meeting](recurring-meetings/#move-an-agenda-item-to-next-meeting) in the series |
| Copying | [Copy the meeting](../meeting-features/meeting-creation/#copy-a-meeting) | [Duplicate an occurrence as a one-time meeting](recurring-meetings/#edit-a-recurring-meeting-occurrence) |
| Removing | [Delete the meeting](../meeting-features/meeting-creation/#delete-a-meeting) | Cancel a single occurrence, end the series or delete the whole series |

> [!NOTE]
> Each occurrence of a recurring meeting is a meeting in its own right. Everything described under [meeting features](../meeting-features/) also applies to individual occurrences.
