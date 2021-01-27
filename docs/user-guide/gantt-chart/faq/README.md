---
sidebar_navigation:
  title: FAQ
  priority: 001
description: Frequently asked questions regarding Gantt chart
robots: index, follow
keywords: Gantt chart FAQ, time line, scheduling
---

# Frequently asked questions (FAQ) for Gantt chart

## Is there a critical path feature?

Unfortunately, we don't have the critical path feature yet. We have a feature request for it though and will check how to integrate it into our road map. A workaround could be to [create predecessor-successor relations](../../work-packages/work-package-relations-hierarchies/#work-package-relations) for only the work packages that are in the critical path. 

## How can I move the milestones in the Gantt chart to a specific date, independently from the other work packages?

Make sure that you remove the relations of the milestone to other work packages. Then its date won't change when you change the timings of other work packages. For releases from 11.0.0 onwards (October 2020) you can use the [manual scheduling mode](../scheduling) for this.



## When I am working in the Gantt chart, every change seems to take quite long. 

We understand that the loading time when working in Gantt Chart is too long for you. The reason for this is that every single action is saved. So everything is fine with your installation. We have already taken up the point with us and already have first ideas for a technical solution. The respective feature request can be found [here](https://community.openproject.com/projects/openproject/work_packages/34176/activity). 