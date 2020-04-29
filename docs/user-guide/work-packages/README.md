---
sidebar_navigation:
  title: Work packages
  priority: 870
description: Find out about work packages in OpenProject
robots: index, follow
keywords: work packages
---

# Work Packages

<div class="glossary">
**Work packages** are items in a project (such as tasks, features, risks, user stories, bugs, change requests). A work package captures important information and can be assigned to project members for execution. 
</div>

Work packages have a **type**, an **ID**, a **subject** and may have various additional attributes, such as **status**, **assignee**, **priority**, **due date**.

<div class="glossary">**Work package ID** is defined as a unique integer assigned to a newly created work package. Work package IDs cannot be changed and are numbered across all projects of an OpenProject instance (therefore, the numbering within a project may not be sequential).</div>
<div class="glossary">
**Types** are the different items a work package can represent, such as task, feature, bug, phase, milestone. The work package types can be configured in the system administration.
</div>

Work packages can be displayed in a projects timeline, e.g. as a milestone or a phase. In order to use the work packages, the work package module has to be activated in the project settings.

## Overview

| Popular Topics                                               | Description                                                  |
| ------------------------------------------------------------ | :----------------------------------------------------------- |
| [Work packages views](work-package-views)                    | What is the difference between the work packages views: list view, split screen view, details view? |
| [Create a work package](#create-work-packages)               | How to create a new work package in OpenProject?             |
| [Edit work package](edit-work-package)                       | How to edit a work package in OpenProject?                   |
| [Copy, move, delete](copy-move-delete)                       | How to copy, move, delete a work package?                    |
| [Work package table configuration](work-package-table-configuration) | How to configure the work package table (columns, filters, group by, etc.)? |
| [Exporting](exporting)                                       | How to export work packages for other tools such as Microsoft Excel? |
| [Work package relations and hierarchies](work-package-relations-hierarchies) | How to create work package relations and hierarchies?        |

<iframe width="560" height="315" src="https://www.youtube.com/embed/R6-p8HgFmm8" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

## Frequently asked questions (FAQ)

### How to copy work package hierarchies with their relations?

You can create work package templates with hierarchies (parent and child work packages) and copy these templates, inkl. the relations.
First, navigate to the work package table. Highlight all work packages (in the hierarchy) which you want to copy. **To highlight and edit several work packages at once, keep Ctrl pressed** and select the ones to be copied.

**Press a RIGHT mouse click on the highlighted work packages**. This will open the in context menu to edit work packages.

Select **Bulk copy** in order to copy all selected work packages including their relations.

![image-20200331132513748](image-20200331132513748.png)

### Is it possible to adapt or rename the status list?

Yes, this is absolutely possible. To do this, you would first have to [create new statuses](https://docs.openproject.org/system-admin-guide/manage-work-packages/work-package-status/).
In the second step you can then [assign them to workflows](https://docs.openproject.org/system-admin-guide/manage-work-packages/work-package-workflows/).

### We like for each department to have their own custom "status" with different value options in OpenProject. How do we do this?

The status which can be selected by users (based on the workflow) is always determined based on the work package type and the role of the user. In order to use the same work package type (e.g. task) but display different status for each department, you would need to create a separate role for each department. You can then add the members of a department (ideally using a group) and assign them with the correct role. Please find the guide [here](../../system-admin-guide/manage-work-packages/work-package-workflows/#edit-workflows).
To work with different status, first create those status in “Administration” > “Work packages” > “Status”.
Next, go to “Administration” > “Work packages” > “Workflow” and select the combination of Type and Role for which you would like to set the allowed workflow transition.
You can e.g. create a role “Marketing – Member” and select it as well as the type (e.g. “Task”). Make sure to uncheck the option “Only display statuses that are used by this type” and click on “Edit”. Now, you can select the correct status transitions.
Repeat this step for the other (department) roles (e.g. “IT – Member”) and select the desired status transitions. This way, you can set different status for each department (only the default status is shared (i.e. “New” by default)). Please keep in mind that it may not be possible for a member of a different department to update the status of a work package if it has been updated before by another department (since the workflow may not support this status transition).

### Is it possible to create a PDF export for the overview of the work packages with Gantt chart?

The export is available via the browser print function (ideally Google Chrome).
