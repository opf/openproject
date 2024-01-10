---
sidebar_navigation:
  title: Implementing Scaled Agile Framework (SAFe) with OpenProject
  priority: 990
description: Understand the principles of the Scaled Agile Framework (SAFe) to manage and organise work in your organisation and see how you can practically implement them in OpenProject.
keywords: safe, scaled agile, release train, program increment, ART backlog, roadmap, portfolio backlog, solution train, script, scrum, roadmap
---

# Configuring SAFe in OpenProject

OpenProject is a powerful project management tool that can adapt to a number of different frameworks and methodologies. Larger organisations who choose to implement the Scaled Agile Framework (SAFe) methodology can leverage the wide range of features and customisability that OpenProject offers to define, plan, organise to deliver value to their end customers.

## Structure and terminology

Preparing OpenProject for SAFe involves configuration and access at two levels:

- **Individual projects** are self-contained and consist of a set of modules, members, work packages and project-level settings. Each can further contain sub-projects for additional hierarchy. They represent **Agile Release Trains** in SAFe.
- **Global modules** encompass content from all projects (and sub-projects) and instance-level settings that affect all modules for all users; these settings can sometimes be overridden at a project-level. The global level serves as a **Solution Train-level** view in SAFe.

Individual users will generally work within one or a set of different projects, using a set of modules to help deliver value. SAFe uses terminology that is different from OpenProject:

|     |     |
| --- | --- |
| **SAFe terminology** | **OpenProject terminology** |
| Agile Release Train | Project |
| Solution train | Project portfolio (in development) |
| Program increment (PI) | Version |
| Iteration | Version |
| Capability/Epic | Epic (work package type) |
| Feature | Feature (work package type) |
| Enabler | Enabler (custom work package type) |
| User Story | User story (work package type) |
| Kanban | Boards |
| Roadmap | Roadmap |
| Backlog | Backlog |

## Setting up Agile Release Trains

In OpenProject, each Agile Release Train (ART) is set up as an individual project.

A project consists of a number of different elements:

- **Members**: individual members can be created at an instance-level and then added to individual projects, or external users can directly be "invited" to a project. Each member can have different roles.
- **Modules** like Work packages, Wiki, Forums, Meetings...
- **Work packages** collectively include epics, features, enablers, user stories, and bugs.
- **Integrations** like external file storages.

Different members groups can also be created at an instance level, and these groups directly added to projects.

To learn how to use the Work packages module to configure epics, features and user stories, see: [Working with epics, features and stories](#working-with-epics-features-and-stories)

> **Demo:** View an [overview of an ART set up as a project](https://safe.openproject.com/projects/art-0-test-release-train/work_packages?query_id=40 "https://safe.openproject.com/projects/art-0-test-release-train/").
> 
> **Note:** You can also use [project templates](https://www.openproject.org/docs/user-guide/projects/project-templates/) and to make it easier to create news ARTs with the same structure, set of enabled modules, project structure or work package templates. Once a new ART is created using a template, it can then be modified in any way.

Agile teams *within* an ART can also be organised using the Team planner or Assignee-based Kanban boards. To learn more, read [Backlogs, Kanban and Team planner](#backlogs-kanban-and-team-planner) below.

## Solution Trains

Project portfolios allow you to view, organise, sort and filter through all projects. Since each project can be an ART, it can also be used to access information at a **Solution train**-level.

> In a near future release, OpenProject will have dedicated project portfolio features. [View mockups.](#add-URL)
> 
> For the moment, **global modules** give you an overview of content from all projects, including the ability to view and filter though a **project list**, and view, sort and filter **work packages at a global level**.

> **Demo:** [Solution train (project list)](https://safe.openproject.com/projects)
> 
> **Demo:** [Global work package view (epics, features and stories from all ARTs)](https://safe.openproject.com/work_packages?query_id=74)

## Using versions to program increments (PIs) and iterations

In OpenProject, a program increment (PI) or iteration corresponds to a version.

Like most things in OpenProject, a version is technically contained within a project. As such, a PI or iteration can be contained with in an ART. However, it is possible to *share* versions with sub-projects, other projects or even with the entire instance.

Versions shared with the entire instance are useful when you need PIs to be shared between multiple ARTs.

> **Demo:** [Versions set up as PIs shared with all ARTs](https://safe.openproject.com/projects/art-0-test-release-train/settings/versions)

Versions are also tied to the Backlog module. To learn more, read [Backlogs, Kanban and Team planner](#backlogs-kanban-and-team-planner) below.

## Working with epics, features and stories

Once the instance, individual ARTs and versions are set up, you are ready to move on to the configuration of individual work initiatives or functionalities.

In OpenProject, all work is expressed as work packages of various types. In the context of SAFe, it already comes with **Epic**, **Feature**, **User story** and **Milestone** types out of the box. Depending on your needs, **Capability** and **Enabler** types can be easier created and configured.

Apart from milestone (which has the particularity of having a single date), all types can be freely configured and new ones freely created.

A work package type is a set of configurations:

- A set of fields (including custom fields)
- Workflows (statuses and available status transitions)
- Settings (which projects/ARTs have access to the type)

In the context of SAFe, it's best to pre-configure the set of types that are required for your project. Since types can be shared between projects, a type can share the same structure between different ARTs if needed.

### Type template

A [type template (or default text for description)](/Applications/Joplin.app/Contents/Resources/app.asar/type%20template%20%28or%20default%20text%20for%20description%29) can defined for each type. For example a **Feature** can be pre-configured to include:

- A short description
- Capability
- Hypothesis
- Acceptance criteria

> **Demo**: Defining a [type template for features](https://safe.openproject.com/types/4/edit/settings).

Similarly, a template can be defined for **User stories** so that they can be expressed in a SAFe-compatible manner, like so:

> **As a** *{role}*, 
> **I want to** *{activity} *
> **so that** *{business or user value}*
> 
> **Demo**: Defining a [type template for user stories](https://safe.openproject.com/types/6/edit/settings).

### Custom fields

[Custom fields](https://www.openproject.org/docs/system-admin-guide/custom-fields/) can be added to each type (or even to multiple types) to add additional structured information. The benefit of a custom field over a heading in that custom fields can be used to later filter, search or group work packages. This can be immensely useful to create dashboards or highly-specific queries.

For a Feature, **Benefit hypothesis** can be expressed as a custom fields.

For an Epic, **Business outcome hypothesis**, **Non-functional requirements** and **Target KPIs** can be expressed as custom fields.

> **Demo:** [Defining custom fields for different work unit types](https://safe.openproject.com/custom_fields)

Or if you are using Kanban class of service, you can create a "**Class of service**" custom field of type multi-select with these options:

- Standard
- Fixed
- Expedite

> **Demo**: [Class of service custom field](https://safe.openproject.com/custom_fields/5/edit)

### Story points

**Story points** can be added to **User Stories** (or even to **Features**).

> **Demo:** [Adding story points as a field in a Feature](https://safe.openproject.com/types/4/edit/form_configuration).

Story points are particularly powerful as they are also visible in the Backlog. To learn more, read [Backlogs, Kanban and Team planner](#backlogs-kanban-and-team-planner) below.

### Progress

OpenProject allows you to track the progress of each work package (or a set of work packages in a parent-child relationship) using the **Progress** field.

Progress can either be manually entered or based on set values tied to statuses. For more information, read the [documentation on progress tracking](https://www.openproject.org/docs/user-guide/time-and-costs/progress-tracking/).

Progress can be viewed at a team label, at an ART-level or at a solution train level by creating filtered views showing only the information you need.

> **Demo:** [Progress overview at a PI level](https://safe.openproject.com/projects/art-0-test-release-train/work_packages?query_id=40)

## Backlogs, Kanban and Team planner

The Backlog and Kanban are key tools in a scaled agile environment, not only during PI Planning but during the course of the entire project.

### Backlog

The Backlog module displays all versions available to a particular project or ART in a two-column format. For each version (representing a Product increment, Iteration or a Feature or Story backlog), the module displays:

- Version name
- Start and end date
- Total story points

It also displays the id, name, status and story points for each work package contained in a version.

We recommend organising all relevant sprints on the left column and the backlog on the right column. Any epic, feature, story, enabler or capability can easier be dragged and dropped between versions or to and from the backlog.

> **Demo**: [Backlog of an ART showing planned Sprints and a feature backlog](https://safe.openproject.com/projects/art-0-test-release-train/backlogs)

### Kanban

Kanban boards allow you to clearly visualise work items in a number of different ways. In OpenProject, dynamic boards can easily be created for a number of different fields.

For each ART, we recommend creating these dynamic Kanban boards:

- Sprints (or PIs, [see demo](https://safe.openproject.com/projects/art-0-test-release-train/boards/9))
- Assignees ([see demo](https://safe.openproject.com/projects/art-0-test-release-train/boards/10))
- Status ([see demo](https://safe.openproject.com/projects/art-0-test-release-train/boards/11))

OpenProject boards are powerful and can be filtered for more control over what is displayed.

> **Note**: Swimlanes are already in our roadmap will soon be added to OpenProject.

### Team planner

Team planners allow you to visualise work packages assigned to particular team members in a weekly or two-week calendar view. It is a powerful tool to monitor work on an on-going and day-to-day level.

If you have multiple agile teams under a single ART, it allows you create custom planners for each team.

> **Demo**: [Team planner for an agile team within an ART](https://safe.openproject.com/projects/art-0-test-release-train/team_planners/75?cdate=2024-01-07&cview=resourceTimelineWorkWeek)

At a solution train level, it allows you to view the work of members across multiple ARTS.

## Organising work using table view, Gantt view

OpenProject is a very powerful tool that allows you to view work packages in a number of different ways.

### Work package table view

The work package table view lets you view work packages of all types (Epic,Capability, Feature, Enabler, User Story) in any number of ways.

It allows you to **sort** or **group** by certain fields, use **filters** to create a highly precise query, and even show nested parent-children relations in **hierarchy view**.

> **Demo**: [An table view of all epics, features and stories in an ART](https://safe.openproject.com/projects/art-0-test-release-train/work_packages?query_id=29)

You can [**configure work package table views**](https://www.openproject.org/docs/user-guide/work-packages/work-package-table-configuration/) using filter queries and save them as views to easily access them later and share them with other team members.

The [**Baseline** **comparison**](https://www.openproject.org/docs/user-guide/work-packages/baseline-comparison/) feature allow lets you view changes to a certain view over a certain period of time, allowing yet another way to monitor progress and changes in your agile team.

**Gantt view**

The Gantt allows you to quickly visualise planning at any level (Solution, ART or agile team) in a calendar view that also displays [work package relations](https://www.openproject.org/docs/user-guide/work-packages/work-package-relations-hierarchies/). Like table view, it can be filtered to create custom views that can be saved.

> **Demo:** [A Gantt view of a sprint within a PI](https://safe.openproject.com/projects/art-0-test-release-train/work_packages?query_id=39)

## Here for you

OpenProject is a powerful and highly-configurable tool that can be customised to fit the needs of your scaled agile implementation. Should you have questions about how to use OpenProject for a particular use case, please get in touch. Our custom success are happy to help you figure it out.