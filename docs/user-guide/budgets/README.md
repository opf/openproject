---
sidebar_navigation:
  title: Budgets
  priority: 780
description: Find out how to create and manage budgets for a project in OpenProject.
keywords: budgets, project budget, costs
---

# Budgets

You can create and manage a **project budget** in OpenProject to keep track of your available and spent costs in a project.

You can add planned **unit costs** as well as **labor costs** for the project.

Then, you will assign work packages to a budgets. If you log time or costs to this work package the costs will booked to this budget and show the percentage spent for a project budget.

| Topic                                                                   | Content                                                                  |
|-------------------------------------------------------------------------|--------------------------------------------------------------------------|
| [Create a project budget](#create-a-project-budget)                     | How to set up a project budget in OpenProject.                           |
| [Add planned unit costs](#add-planned-unit-costs)                       | How to add planned unit costs to a budget.                               |
| [Add planned labor costs](#add-planned-labor-costs)                     | How to add planned labor costs to a budget.                              |
| [Assign a work package to a budget](#assign-a-work-package-to-a-budget) | How to assign a work package to book time and costs to a project budget. |
| [View details and update budget](#view-details-and-update-budget)       | How to display the details, update, copy or delete a project budget.     |
| [Frequently asked questions (FAQ)](#frequently-asked-questions-faq)     | What are frequent questions regarding budgets?                           |

## Create a project budget

> [!TIP]
> In order to create a budget in your project, the **Budgets module** needs to be activated under [project settings](../projects/).

To create your first budget in OpenProject, navigate to _Budgets_ module and click the green **+ Budget** button in the top right corner.

![A button to create a new budget in OpenProject Budgets module](openproject_user_guide_budgets_create_budget_button.png)

In the form that opens, you can define the details of your project budget, including planned unit costs and planned labor costs.

1. **Subject** – Enter a clear subject for your budget so it can be identified easily.

2. **Description** – Add a detailed description with additional information such as the budget owner, status, or any other notes.

3. **Attachments** – Upload supporting files by dragging and dropping them into the upload field, or by clicking the field to select files from your computer.

4. **Fixed date** – Specify a fixed date. This date is used to calculate planned costs based on either:

   - the [configured hourly rate](../time-and-costs/cost-tracking) in the users profile, or
   - the [cost types](../../system-admin-guide) set by administrator.

   Since rates can be configured for different date ranges, the fixed date ensures the correct costs are calculated for the budget.

5. **Base amount** - Enter a lump-sum amount to allocate funds without planning materials or labor costs in detail. This is useful for high-level budgets where you simply assign an overall sum instead of tracking specific items.

![Add new budget details in OpenProject](openproject_user_guide_budgets_new_budget_details.png)

### Add planned unit costs

You can add planned unit costs to a budget in your project. These [unit costs first need to be configured in the system's administration](../../system-admin-guide/time-and-costs/#create-and-manage-cost-types).

Enter the number of **units** of the cost type to add to your project budgets.

Choose the **cost type** you would like to plan for your budget from the drop-down list.
The **unit name** will be set automatically according to the configuration of the cost types in your system administration.

Add a **comment** to specify the unit costs.

The **planned costs** for this cost type will be calculated automatically based on the configuration of the cost per unit for this cost type. The cost rate will be taken from the fixed date you have configured for your budget.
You can click the **edit icon** (small pen) if you want to manually overwrite the calculated costs for this cost type.

Click the **delete** icon if you want to drop the planned unit costs.

The **+ icon** will add a new unit cost type for this budget.

![Specify planned unit costs for a new budget in OpenProject](openproject_user_guide_budgets_new_budget_planned_unit_costs.png)

### Add planned labor costs

You can also add planned labor costs to a budget.

Set the **hours** that will be planned for a user on this budget.

Add a **user** from the drop-down list.

You can include a **comment** for your planned labor costs if needed.

The total amount of planned costs will be calculated based on the entered hours and the [hourly rate configured](../time-and-costs/time-tracking/#define-hourly-rate-for-labor-costs) for this user in the user profile.
You can manually overwrite the calculated planned labor costs by clicking the edit icon (pen) next to the calculated amount.
The costs will be calculated based on the hourly rate taken from the fixed date for your budget.

With the **delete** icon you can remove the planned labor costs from the budget.

Add more planned labor costs for different users to your budget with the **+ icon**.

Save and submit your changes by pressing the **Create** button.

![Specify planned unit costs for a new budget in OpenProject](openproject_user_guide_budgets_new_budget_planned_labor_costs.png)

## Assign a work package to a budget

To add a work package to a project budget to book time and costs to a budget, navigate to the respective work package detailed view.

In the Costs section, select the **budget** which you want to assign this work package to. You will see a [list of budgets configured](#create-a-project-budget) in your project in the drop-down list.

Now, all [time and costs booked to this work package](../time-and-costs) will be booked against the corresponding budget.

![Assign a work package to a budget in OpenProject](openproject_user_guide_budgets_assign_work_package.png)

## View details and update budget

You can view the details of a budget and make changes to your budget by selecting it from the list of budgets.

![A list of all existing project budgets for a specific project in OpenProject](openproject_user_guide_budgets_overview.png)

Click on the subject to open the details view of the budget.

You will get and overview of planned as well as spent costs and the available costs for your variable rate budget. Also, the total progress of the budget (ratio spent) is displayed. Furthermore the fixed rate is shown from which the costs for labor and unit costs are being calculated.

In the top right corner you can update, copy or delete a budget by clicking the respective button: 

- **Update** the budget and make changes to e.g. planned unit costs or planned labor costs.
- **Copy** the budget to use it to create a new budget based on the configurations for this budget.
- **Delete** the budget.

The detailed budget view will show the following:

- all **planned unit costs**.
- work packages assigned to this budget that have **actual unit costs** booked.
- **planned labor costs** are displayed for this budget.
- **actual labor costs** list all work packages that are [assigned to this budget](#assign-a-work-package-to-a-budget) and have logged time on it.

![A detailed view of a project budget in OpenProject](openproject_user_guide_budgets_detailed_budget_view.png)

> [!NOTE]
> The costs are calculated based on the [configuration for cost types](../../system-admin-guide) and the [configured hourly rate](../time-and-costs/time-tracking/#define-hourly-rate-for-labor-costs) in the user profile.

## Frequently asked questions (FAQ)

### How do I prepare a budget in OpenProject?

Budgets are currently limited to a single project. They cannot be shared across multiple projects.
This means that you would have to set up a separate budget for the different main and sub projects.
You can however use cost reports to analyze the time (and cost) spent across multiple projects. For details, you can take a look at our [time and cost reports user guide](../time-and-costs/reporting/).
