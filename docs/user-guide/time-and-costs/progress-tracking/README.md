---
sidebar_navigation:
  title: Progress tracking
  priority: 800
description: How to use OpenProject to track and report progress of work packages in either work-based or status-based reporting modes. 
keywords: Progress tracking, estimated time, remaining time, work, % complete, percentage complete, remaining work
---

# Progress tracking


OpenProject lets you track and monitor progress on your work packages. 

> **Note:** Since OpenProject 14.0, the way progress is reported and calculated has changed significantly. Please read the documentation below to understand how OpenProject handles work and progress estimates.

## Terms

[OpenProject 13.2](https://www.openproject.org/docs/release-notes/13-2-0/) introduced some important changes in the names of three work package fields:

| **Old term**   	 | **New term**   	      |
|--------------------|------------------------|
| Progress       	 | %&nbsp;Complete	      |
| Estimated time 	 | Work           	      |
| Remaining time 	 | Remaining work 	      |

If you were used to an older version of OpenProject, please be aware of this change. 

>*Note*: You will still find the new attributes if you search using their older names (in the list of filters, for example).

## Progress reporting modes

OpenProject offers two modes for reporting progress:

- **Work-based progress reporting** enables you to automatically derive progress based on the values you enter for Work and Remaining work
- **Status-based progress reporting** allows you to assign fixed % Complete values to statuses, and automatically derive Remaining work based on the values for Work you can enter

### Work-based progress reporting

%&nbsp;Complete is an automatically calculated value that is a function of Work and Remaining work (unless %&nbsp;Complete is configured to be set by status, see below).

>**%&nbsp;Complete** is work done (**Work** - **Remaining work**) divided by **Work**, expressed as a percentage. For example, if Work is set at 50h and Remaining work is 30h, this means %&nbsp;Complete is _(50h-30h)/50h))_ = **40%**. Please note that these calculations are independent and unrelated to the value of **Spent time** (which is based on actual time logged). 

This means that for a work package to have a value for %&nbsp;Complete, both Work and Remaining work are required to be set. To make this link clear and transparent, clicking on any of the three values to modify them will display the following pop-over:

[IMG: Work-based progress reporting]

This allows you to edit Work or Remaining work and get a preview of the updated %&nbsp;Complete value before saving changes. 

>**Note:** If you enter a value for Remaining work that is higher than Work, you will see an error message telling you that this is not possible. You will have to enter a value lower than work to be able to save the new value.
>
>Additionally, the value for Remaining work cannot be removed if a value for Work exists. If you wish to unset Remaining work, you need to also unset Work. 

### Status-based progress reporting

Administrators can also switch to [status-based progress reporting mode](https://www.openproject.org/docs/user-guide/time-and-costs/progress-tracking/#status-based-progress-tracking) for their instance. 

In this mode, each status is associated with a fixed %&nbsp;Complete value, which can be freely updated by changing the status of a work package. This allows teams to report progress simply by changing status over time.

Unlike in work-based progress reporting mode, when %&nbsp;Complete is tied to a status, Remaining work is an automatically value that cannot be manually edited.

>**Remaining work** is **Work** times **(100% - %&nbsp;Complete)**, expressed in hours. For example, if the %&nbsp;Complete for a selected status is 25% and Work is 20h, Remaining work is automatically set to 15h.

In Status-based progress reporting mode, Work is not a required value. However, if Work is set, Remaining work is automatically calculated. To make this link clear and transparent, clicking on any of the three values to modify them will display the following pop-over:

[IMG: Status-based progress reporting]

This allows you to edit %&nbsp;Complete (by changing status) or Work and get a preview of the updated Remaining work before saving changes.

>**Note:** In the upcoming version, statuses cannot have an empty %&nbsp;Complete values in status-based progress reporting mode.When upgrading, all statuses that do not have a value will take the default value of 0%.


## Hierarchy totals

OpenProject will automatically show totals for Work, Remaining work and % Complete in a work package hierarchy (any parent with children). These appears in a work package table as a number with a Σ sign next to it, indicating that it is a sum of the values of the parent _and_ children.

> **Note**: The total %&nbsp;Complete value of a hierarchy is a weighted average tied to Work. For example, a feature with Work set to 50h that is 30% done will advance the sum of %&nbsp;Complete of the parent more than a feature with Work set to 5h that is 70% done. 


### Excluding certain work packages from totals


In some cases, you might want to exclude certain work packages (like those with status *rejected*) from sum calculations of the parent. When the mentioned changes will be released, you can go to the Administration settings for any status and check a new option called "Exclude from calculation of totals in hierarchy". All work packages with this status will then be excluded when calculating the sum value for the parent (for all fields: Work, Remaining work and %&nbsp;Complete).

A small info icon will appear next to excluded values to remind you of this fact:

[IMG: Excluded work packages warning]