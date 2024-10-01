---

sidebar_navigation:
  title: Progress tracking
  priority: 965
description: Manage Work package progress tracking.
keywords: work package progress tracking, percentage complete, % complete
---

# Manage work package progress tracking

Progress tracking is a 

Administrators will see a new page under *Administration* → *Work packages* called **Progress tracking** with three settings:

![Progress tracking settings under OpenProject administration](openproject_system_guide_progress_tracking_settings.png)

- **Progress calculation mode** lets you select between *work-based* and *status-based* modes.

- Calculation of % Complete hierarchy totals

   lets you pick between: 

  - Weighted by work: The total *% Complete* will be weighted against the *Work* of each work package in the hierarchy. Work packages without *Work* will be ignored (current behaviour)
  - Simple average: *Work* is ignored and the total *% Complete* will be a simple average of *% Complete* values of work packages in the hierarchy

- % Complete when status is closed

   lets you chose what happens to 

  % Complete

   when you close a work package (even in work-based mode): 

  - No change, where the value of *% Complete* will not change even when a work package is closed
  - Automatically set to 100%, where a closed work package is considered complete.
