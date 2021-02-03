---
sidebar_navigation:
  title: FAQ
  priority: 001
description: Frequently asked questions regarding time, costs and tracking
robots: index, follow
keywords: time and costs FAQ, time tracking, time logging, booking costs
---

# Frequently asked questions (FAQ) for Time and costs

## Is there a way to prevent logging hours for Phases (or other work package types)? 

It is not possible to prevent time logging on phases or restrict it to certain work package types. You could deactivate the fields "Estimated time" and "Spent time" for type Phase (using the [work package form configuration](../../../system-admin-guide/manage-work-packages/work-package-types/#work-package-form-configuration)) but it would still be possible to log time for Phases.

## Can I log time for another user than myself?

Currently, that's not possible. However, there's already a [feature request](https://community.openproject.com/projects/openproject/work_packages/21754/activity) on our wish list.

Possible workarounds: 

- Log in as the other user.
- Set up a cost type (e.g."developer hours" or "John Smith") for unit costs and use this to log time (as unit cost) for others.
- Add a comment with the developer's name in the time logging modal. If you want to see the comment in the time and costs module you will have to remove all selections for columns and rows.
- Use the "Activity" drop down menu to choose a developer (you can add their names [in the system administration](../../../system-admin-guide/enumerations/)). Then you could use the time and costs module to filter for or sort by "Activity". 
- Create a work package as a dummy. It should have a special status so that it can be reliably excluded in time reporting. For this work package, each user for whom times are to be booked by others (e.g. project managers) creates several entries (time bookings) with sample values in advance. Subsequently, the project manager can assign these to another task if required and enter the actual effort.

## Is it possible to view all hours assigned to each member in total? If I work on various projects I'd like to know how many hours I accumulated for all tasks assigned to me.

Yes, it is possible to see all hours assigned to each user in total. In your cost report you would just need to [select](../reporting/#filter-cost-reports) all projects that you would want to look at.
Click on the **+** next to the project filter, select all projects or the ones that you would like to select (use Ctrl or shift key), choose all other filters and then click "apply" to generate the cost report.

