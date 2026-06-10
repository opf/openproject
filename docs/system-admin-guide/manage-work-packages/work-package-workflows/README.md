---

sidebar_navigation:
  title: Workflows
  priority: 300
description: Manage Work package workflows.
keywords: work package workflows
---

# Manage work package workflows

A **workflow** in OpenProject is defined as the allowed transitions between work package status for a role and a type, i.e. which status changes can a certain role implement depending on the work package type.

This means, a certain type of work package, e.g. a Task, can have the following workflows: News → In Progress → Closed → On Hold → Rejected → Closed. This workflow can be different depending on the [role in a project](../../users-permissions/roles-permissions).

## Edit workflows

To edit a workflow, navigate to *Administration → Work packages → Workflows*. You will see an overview of all available work package types.

![List of work packages types under Workflows editing in OpenProject administration](openproject_system_guide_wp_workflows_menu.png)

Select the type of work package for which you want to edit the workflow, e.g. *Task*. 

Once opened, you can configure workflows for this type:

1. Choose whether you want to edit default transitions, or transitions when a user is the **author** or **assignee** using the tabs at the top of the page.

   ![Menu list of work packages types under Workflows editing in OpenProject administration](openproject_system_guide_wp_workflows_menu_edit.png)

   

![Tabs to select between default transitions, when the user is the author or when the user is the assignee](openproject_system_guide_wp_workflows_role_list.png)

2. Select the **role** or **roles** for which you want to configure the workflow from the select panel. The workflow table will update automatically when switching roles. The role panel will also update to reflect the selected number of roles. When multiple roles are selected, the checkboxes of the workflow table assign transitions for all. When only some of the selected roles have the transition, the checkboxes are marked as partial.

   ![Panel to select roles for a work package type in default transitions](openproject_system_guide_wp_workflows_select_role.png)

3. Define which **statuses** are available for this type:
   - Click **+ Status** to add or remove statuses.
   - Select the statuses you want to associate with this type and apply your changes.
   - Removing a status will make it unavailable for this type and delete existing workflow transitions for it.
   - Newly added statuses will appear in the workflow table immediately and can be configured before saving.

> [!NOTE]
> If a status has no transitions configured, it will be removed automatically when saving.

4. Configure the allowed status transitions in the workflow table:
   - The matrix shows the **current status in the rows** and the **new status in the columns**.
   - Read transitions from rows to columns, e.g. if the cell at the intersection of **NEW (row)** and **IN PROGRESS (column)** is checked, a transition from **NEW → IN PROGRESS** is allowed.
   - To allow transitions in both directions, ensure both corresponding cells are checked.

   ![Edit work package workflows in OpenProject administration](System-admin-guide-work-package-workflows_edit.png)
   
5. Optionally, define additional transitions:
   - When the user is the **author** of the work package.
   - When the user is the **assignee** of the work package.

6. Click **Save** to apply your changes. The Save button is always visible at the bottom of the page. If you try to switch roles or leave the page with unsaved changes, you will be asked to save or discard them.

![Overlay message with choices to ignore or save changes and continue in OpenProject workflows administration](openproject_system_guide_wp_workflows_save_message.png)

If no statuses are configured for a role yet, an empty state is shown asking that you add statuses.

![A work package type with unconfigured status transitions workflow in OpenProject administration](openproject_system_guide_wp_workflows_not_configured.png)
## Copy an existing workflow

You can copy an existing workflow by clicking **Copy** in the workflow overview.

![Copy work package workflow in OpenProject administration](System-admin-guide-work-package-workflows_copy.png)

You will then be able to select which existing workflow should be copied to selected types. Here, you can select as many target types as you wish.



![Example for copying a work package workflow from one type to another in OpenProject administration](System-admin-guide-work-package-workflows_copy_type.png)

You can also copy to other roles by selecting a role or multiple target roles from the drop-down list.

![Example for copying a work package workflow to other roles in OpenProject administration](System-admin-guide-work-package-workflows_copy_to_roles.png)

![Example for copying a work package workflow in OpenProject administration,copy button highlighted](
System-admin-guide-work-package-workflows_copy_to_roles_save.png)

You can also choose to use the workflows for the source type and role as the blueprint for multiple target types at the same time.

The copy of a workflow can later on be altered to better reflect the desired transitions between statuses for the edit role. You can also create the desired workflows from scratch.

## View the workflow summary

You can get a summary of the allowed status transitions of a work package type for a role by clicking on **Summary** in the workflow overview.

![Summary of work package workflows in OpenProject administration](System-admin-guide-work-package-workflows_overview.png)

You will then view a summary of all the workflows. The number of possible status transitions for each type and role are shown in a matrix.

![Overview of work package workflow summary in OpenProject administration](System-admin-guide-work-package-workflows_summary.png)

> [!TIP]
> For more examples on using workflows in OpenProject take a look at [this blog article](https://www.openproject.org/blog/status-and-workflows/).
