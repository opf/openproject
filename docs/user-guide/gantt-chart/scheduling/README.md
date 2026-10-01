---
sidebar_navigation:
  title: Automatic and manual scheduling
  priority: 999
description: Use manual or automatic scheduling mode in OpenProject
keywords: Gantt chart, automatic scheduling, manual scheduling, start date, finish date, relations


---

# Automatic and manual scheduling modes

<div class="glossary">

To schedule work packages in the Gantt chart, there is an **automatic scheduling mode** and a **manual scheduling mode (default)** (new in [release 15.4](../../../release-notes/15/15-4-0)). To add dependencies between work packages, you can set them as predecessor or successor in the Gantt chart. The automatic and manual scheduling modes determine how work packages behave when the dates of related work packages change.

</div>

Since the scheduling mode only affects individual work packages, you can combine manual scheduling (top-down planning) and automatic scheduling (bottom-up planning) within the same project.

| Topic                                                   | Content                                                      |
| ------------------------------------------------------- | ------------------------------------------------------------ |
| [Manual scheduling](#manual-scheduling)       | How work packages behave in manual scheduling mode |
| [Automatic scheduling](#automatic-scheduling) | How to use automatic scheduling to automatically derive dates |
| [Changing modes](#changing-mode)                         | How can I change between manual and automatic scheduling mode? |

## Manual scheduling

By default, all work packages in OpenProject are manually scheduled. 

In this mode you can select dates at your discretion. Project managers can set timelines based on specific needs, deadlines, or external factors. Manually-scheduled work packages can still have predecessor, successor, parent or child relations, but these relations will not affect the manually input dates.

Manual scheduling is useful because no _other_ work package can affect the dates that are set. For example, a manually scheduled work package can have a predecessor, but even if the predecessor moves forwards in time, the manually scheduled work package will remain unchanged.

The **manual scheduling mode** can makes sense if:

- you want to plan your project top-down without knowing all tasks yet, or
- you want to set a parent work package’s date independently from the dates of its children, or
- you don't want the start date of a successor be automatically updated when you change the predecessor's finish date.

Moving a child work package in the manual scheduling mode will not move the dates of the parent work package. The scheduling differences will be indicated by a black or red bracket underneath (e.g. when a child is shorter or longer than the parent phase). See [this explanation](../#understanding-the-colors-and-lines-in-the-gantt-chart) to find out more about the lines and colors in the Gantt chart.

<video src="https://openproject-docs.s3.eu-central-1.amazonaws.com/videos/OpenProject-Top-down-Scheduling.mp4"></video>

## Automatic scheduling

In [automatic scheduling mode](../../work-packages/set-change-dates/#automatic-scheduling), it is not possible to manually enter a start date. This means that when a task is scheduled, the date picker will automatically calculate the appropriate dates.

> [!TIP]
> A work package can only be in automatic mode if it has predecessors or children.

An automatically-scheduled work package with predecessors will automatically start one working day after the finish date of the nearest predecessor. You can still enter a duration (and effectively change the finish date). This temporal relationship is maintained even if you the dates of the predecessor are changed. For example, if the predecessor is moved forwards or backwards in time (either because the finish date or duration changed), the automatically-scheduled work package will also change its start date so it starts the day after the new date. This makes it possible to create a dependable chain of automatically scheduled work packages that adjust to planning changes. 

> [!NOTE]
> If you would like to change the lag (or the gap) between when the predecessor ends and the successor starts, you can do so by editing lag in the Relations tab of a work package.

For automatically-scheduled work packages with children, the start and finish dates are determined by the earliest-starting and latest-ending children respectively.

## Changing mode

You can **activate manual or automatic scheduling mode** by clicking on the date of a work package and selecting the respective option in the _Scheduling mode_ toggle in the date picker. This will activate the chosen scheduling mode only for the respective work package. 

While switching to manual mode is always possible, a work package can only be set to automatic mode if it has predecessors or children.

![The scheduling mode switch in the OpenProject date picker with the choice of manual and automatic scheduling](openproject_user_guide_gantt_chart_scheduling_mode_switch.png)

The auto-date symbol next to the date indicates that a work package is in automatic scheduling mode.

![Auto-date icon next to the start date indicating that a work package is in automatic scheduling mode](openproject_user_guide_gantt_chart_scheduling_auto_icon.png)

> [!NOTE]
> Switching from manual scheduling to automatic scheduling might cause dates to change. When they do, a helpful banner will explain where the derived dates are coming from. Clicking on the "Show relations" button will show all directly-related work packages. 
