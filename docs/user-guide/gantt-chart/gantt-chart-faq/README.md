---
sidebar_navigation:
  title: Gantt chart FAQ
  priority: 001
description: Frequently asked questions regarding Gantt chart
keywords: Gantt chart FAQ, time line, scheduling
---

# Frequently asked questions (FAQ) for Gantt chart

## How can I move the milestones in the Gantt chart to a specific date, independently from the other work packages?

Make sure that you remove the relations of the milestone to other work packages. Then its date won't change when you change the timings of other work packages. For releases from 11.0.0 onwards (October 2020) you can use the [manual scheduling mode](../scheduling) for this.

## When I am working in the Gantt chart, every change seems to take quite long. What can I do?

We understand that the loading time when working in Gantt Chart is too long for you. The reason for this is that every single action is saved. So everything is fine with your installation. We have already taken up the point with us and already have first ideas for a technical solution. The respective feature request can be found [here](https://community.openproject.org/wp/34176).

## Can I export the Gantt?

At the moment that's not possible, but you can use the print feature of your browser to print it as PDF (we optimized this for Google Chrome). Please find out more [here](../#how-to-print-a-gantt-chart).
The respective feature request can be found [here](https://community.openproject.org/wp/15444).

## I can no longer see my Gantt chart filters, what can I do?

Gantt charts became a separate module in OpenProject 13.3. To see the filters you created and saved earlier please select the **Gantt charts** module either from the global modules menu or from the project menu on the left.

## How can I build in a "buffer" (e.g. two weeks gap) between two consecutive work packages, so that even if the first one is postponed the second one always starts e.g. two weeks later?

Adding a buffer directly is currently not possible in OpenProject. When you create a follows-precedes relationship between a preceding and a following work package and leave a gap between the finish date of the preceding and the start date of the following work package, and then postpone the preceding work package, the "buffer" will be used up. Only when the finish date of the preceding work package is moved past the start date of the following work package, will the following work package be postponed.
As a workaround you could create a separate work package (type) which acts as a buffer. You can then create a precedes-follows relationship between the first item and the "buffer work package" and the "buffer work package" and the second item. To avoid cluttering up your view you could use the filter to not display the buffer work packages.

## Is there a critical path feature?

Unfortunately, we don't have the critical path feature yet. We have a feature request for it though and will check how to integrate it into our road map. A workaround could be to [create predecessor-successor relations](../../work-packages/work-package-relations-hierarchies/#work-package-relations) for only the work packages that are in the critical path.
