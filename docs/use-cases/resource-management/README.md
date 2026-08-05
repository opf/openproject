---
sidebar_navigation:
  title: Resource management
  priority: 980
description: Learn how to plan capacity, allocate work and staff projects with resource management in OpenProject.
keywords: use-case, resource management, capacity planning, resource planner, staffing, resource allocation
---

# Resource management with OpenProject

Resource management helps you plan not only *what* needs to be done, but also *who* can do the work and *when*. With OpenProject 17.7, you can combine work packages with team members' working schedules, availability and skills to make realistic staffing decisions.

The dedicated **Resource management** module lets you create resource planners, allocate hours to specific users or requested profiles, identify capacity conflicts and fill open resource requests from within your project.

[feature: resource_management]

> [!NOTE]
> The Resource management module is an Enterprise add-on available with the Premium plan. Departments, user attributes, working schedules and availability are also useful independently of the module and are available in the Community edition.

## What you can achieve

Use resource management in OpenProject to:

- compare planned work with available capacity
- identify overloaded or available team members
- plan work for a known person
- reserve capacity based on required skills, roles or other user attributes before choosing a person
- find suitable project members for open resource requests
- review the same plan from a work package or user perspective

## Prepare your resource data

Capacity planning is most useful when the underlying project and user data is complete. Before creating a resource planner:

1. Activate **Resource management** under **Project settings → Modules**.
2. Add the relevant team members and work packages to the project.
3. Give work packages realistic dates and record their total work.
4. Configure each user's [working schedule, schedule changes and time off](../../user-guide/account-settings/schedule-and-availability/).
5. Organize users in [departments](../../system-admin-guide/users-permissions/organization/) and maintain [user attributes](../../system-admin-guide/users-permissions/user-attributes/), such as skills, languages or certifications, when these details should inform staffing decisions.

## Plan and balance capacity

### 1. Create a resource planner

Open **Resource management** from the project menu and create a resource planner. Define its name, planning period, visibility and first planner view.

You can create multiple planners for different teams, departments, project phases or planning scenarios.

### 2. Choose the right planning view

A resource planner can contain multiple views of the same planning data:

- **Work packages timeline** shows allocations alongside scheduled work packages.
- **Users timeline** shows each person's allocations and availability over time, including warnings for missing work schedules or overallocation.
- **Work packages list** provides a table-oriented view of work and allocations.
- **Users card list** combines capacity information with departments and selected user attributes to support staffing decisions.

Switch between these views depending on whether you want to start from the work, the people or the available capacity.

### 3. Allocate planned work

Create an allocation for a work package and enter the planned date range and hours. You can allocate work in two ways:

- **By user** when you already know which project member should perform the work.
- **By filter criteria** when you know which skills, role or other attributes are required but have not yet selected a person.

Allocations are separate from the work package assignee. This allows you to distribute planned hours across multiple people or reserve capacity before responsibility for the work package is finalized.

OpenProject warns you when allocation dates fall outside the work package dates or when a user is allocated beyond their available capacity.

### 4. Staff open resource requests

Allocations based on filter criteria appear as open requests in the **Staffing** view. Open a request to compare matching project members and their remaining capacity, then assign a suitable person.

This workflow lets project managers define the demand while resource managers or team leads complete the staffing decision.

### 5. Review and adjust the plan

Use the timeline views to spot scheduling gaps and overloads, and the user cards to compare availability and relevant attributes. Adjust allocation dates, hours or assigned users as project priorities and team availability change.

Keeping work package dates, work estimates and user schedules up to date ensures that the planner continues to reflect a realistic capacity picture.

## Complementary planning options

The Resource planner complements other OpenProject views:

- Use the [Team planner](../../user-guide/team-planner/) for a weekly or bi-weekly overview of work packages assigned to team members.
- Use configurable [work package tables](../../user-guide/work-packages/work-package-table-configuration/) to compare fields such as **Work**, **Remaining work** and **Spent time**, and to group results by assignee.

These views are useful for task coordination and lightweight workload overviews. For schedule-based capacity planning, skill-based resource requests and staffing, use the Resource management module.

For detailed instructions on creating planners, configuring views, allocating work and staffing requests, see the [Resource management user guide](../../user-guide/resource-management/).
