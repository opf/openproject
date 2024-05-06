---
sidebar_navigation:
  title: Time and costs FAQ
  priority: 001
description: Frequently asked questions regarding time, costs and tracking
keywords: time and costs FAQ, time tracking, time logging, booking costs
---

# Frequently asked questions (FAQ) for Time and costs

## Is there a way to prevent logging hours for Phases (or other work package types)?

It is not possible to prevent time logging on phases or restrict it to certain work package types. You could deactivate the fields "Work (earlier called Estimated time)" and "Spent time" for type Phase (using the [work package form configuration](../../../system-admin-guide/manage-work-packages/work-package-types/#work-package-form-configuration-enterprise-add-on)) but it would still be possible to log time for Phases.

## Can I log time for another user than myself?

Since [12.2 release](../../../release-notes/12/12-2-0/) it is possible to log time for a user other than yourself. This right has to be granted by an admin to users with certain roles. You can find out more [here](../../../user-guide/time-and-costs/time-tracking/#log-and-edit-time-for-other-users).

## If I work on various projects I'd like to know how many hours I accumulated for all tasks assigned to me. Is it possible to view all hours assigned to each member in total?

Yes, it is possible to see all hours assigned to each user in total. In your cost report you would just need to [select](../reporting/#filter-cost-reports) all projects that you would want to look at.
Click on the **+** next to the project filter, select all projects or the ones that you would like to select (use Ctrl or Shift key), choose all other filters and then click **Apply** to generate the cost report.

## Can I show the columns I chose in the Time and costs module in the Excel export?

Unfortunately this is not possible at the moment. There's already a feature request for this on our wish list [here](https://community.openproject.org/work_packages/35042).

## Is there an overview over how much time I logged in one week?

Yes, you can use the "My spent time" widget on My Page and use the filters there.

## Can I log time in a different unit than hours, e.g. in days?

No, it is not (yet) possible to log time in days or any other units besides hours. However, you can use decimal places, like 0.25 hours.

## Does OpenProject offer resource management?

You can [set up budgets](../../budgets), [set an estimated time in the field **Work**](../../work-packages/edit-work-package/) for a work package and use the [Assignee board](../../agile-boards/#choose-between-board-types) to find out how many work packages are assigned to a person at the moment.
Additional resource management features will be added within the next years, as shown in the [roadmap for future releases](https://community.openproject.org/projects/openproject/roadmap).
More information regarding resource management in OpenProject can be found in the [Use Cases](../../../use-cases/resource-management) section.
