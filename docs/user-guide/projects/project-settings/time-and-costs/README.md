---
sidebar_navigation:
  title: Time and costs
  priority: 400
description: Manage time tracking activities and cost types for a project.
keywords:  time tracking activities, cost types, time and costs, project settings, log time, log costs
---
# Time and costs

<div class="glossary">
**Time and costs** is defined as a module which allows users to log time and unit costs on work packages. Once the time and costs module is activated, time and costs can be logged via the action menu of a work package.
</div>

Project administrators can enable or disable **time tracking activities** and **cost types** for individual projects.

Before they can be enabled in a project, time tracking activities and cost types must first be configured by an administrator under **Administration → Time and costs**. For details, see the [Time and costs administration guide](../../../../system-admin-guide/time-and-costs/).

### Manage activities for time tracking

To enable time tracking activities for a project:

1. Navigate to **Project settings → Time and costs → Time tracking activities**.
2. Select the activities that should be available for time tracking in the project.
3. Click **Save**.

![Activate time tracking activities under the Time and costs section in Project settings](openproject_user_guide_project_settings_time_and_costs.png)

### Manage cost types

To enable cost types for a project:

1. Navigate to **Project settings → Time and costs → Cost types**.
2. Turn on the toggle next to each cost type that you want to make available in the project.

![Cost types under the Time and costs section in Project settings](openproject_user_guide_project_settings_enable_cost_types.png)

Enabled cost types are available for logging costs in the project.

![Enabled cost types under the Time and costs section in Project settings](openproject_user_guide_project_settings_cost_types_enabled.png)

> [!NOTE]
> A cost type is visible to a user only if:
> - the cost type is enabled in at least one project, and
> - the user has permission to log costs in that project.
