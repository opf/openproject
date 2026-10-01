---
sidebar_navigation:
  title: Projects FAQ
  priority: 001
description: Frequently asked questions regarding projects
keywords: projects FAQ, project questions
---

# Frequently asked questions (FAQ) for projects

## How can I get an overview over multiple projects at the same time?

There are several possibilities:

1. To see only the projects without their work packages go to [Projects](../project-lists/) ("View all projects"). Here you can also display the Project list in a Gantt chart view with all important milestones of all Projects. Therefore you have to click on "Open as Gantt view".
2. For work packages of all projects click on _Modules -> Work packages_ in the upper right hand corner (9 squares) in the navigation bar, to access the [global work packages list](../project-lists/#global-work-package-tables). Use the view configuration to group the work packages by project.
3. Select a project with subprojects, go to the Project overview, add the widget "Work package table" and set the filter "Including subproject". Find more information on this topic [here](../../projects/project-home/project-widgets/). Additionally you could add the column "Progress" to compare your different Project progress.
4. Add the widget "Work package table" to your My page and set the filter mentioned above. Find more information on this topic [here](../../../getting-started/my-page/#configure-the-my-page). Additionally you could add the column "Progress".

We will introduce further similar functions in the course of implementing multi-project management.

## What is the difference between creating a project from a template and copying the template project?

Creating a project from a template and copying projects serve slightly different purposes: Project templates provide an easy way to create a new project while copying all the data (as far as supported) of the source project.
Copying projects provides more flexibility: You can choose which data to copy from the source project. Please note that choosing not to copy certain project data may lead to errors (e.g. when work packages are assigned to users who are not copied along with the project).

### We have different departments in our company and need projects by departments. Can I use sub-projects for the departments?

Yes, that is in most cases the best solution.

## How are the Backlogs module, boards and versions related? Can I use boards with versions?

In OpenProject, you can work agilely according to Scrum ([backlogs](../../backlogs-scrum)) or Kanban ([boards](../../agile-boards)). Versions in OpenProject represent a "container" that contains the work packages to be processed.
Versions serve a double function: On the one hand, you can use them to plan your product releases, and on the other hand, you can use them to map the product backlog(s) and sprints required for Scrum.
As soon as you have created at least one version in a project, the module "[Roadmap](../../roadmap)" is displayed on the left side in your project, which you can use to get an overview of the versions (intended primarily for releases).
The [Backlogs module](../../backlogs-scrum) uses versions to map the product backlog or sprints. By using the backlog, however, some special rules occur: For example, tasks must be assigned to the same version as the associated (parent) work packages.
If you do not work according to Scrum we would recommend to deactivate the Backlogs module and use the [Boards module](../../agile-boards) instead. If you have activated the boards module you can create a version board. You can find an example [here](https://community.openproject.org/projects/openproject/boards/2077).

## Can I assign work packages in subprojects to versions of the parent project?

Yes, it is possible; [set](../project-settings/versions/) the sharing option for the version to "with sub project".

## Is it possible to hide or remove fields in the project settings (like status, status description)?

You can't remove fields/attributes that are no custom fields. However, you can hide them in the [projects overview](../project-lists/).

## Can I create a custom project status?

There are six project status to choose from: on track, at risk, off track, not started, finished and discontinued. These cannot be changed. However, if you want to add additional information, you can do so in the status description or you can create an additional [project custom field](../../../system-admin-guide/custom-fields/#add-a-custom-field-to-one-or-multiple-projects). Both, status description and the project custom field can be displayed in the **project list**.

## How do I reopen an archived project?

Go to the projects overview ("View all projects") and change the filter to not only include active projects. Then choose the archived project you want to reopen and click on the three dots at the right end of its row. Click on **Unarchive** there.

## How can I un-archive subprojects?

Please navigate to the global projects overview and change the filter to include non-active projects. If you take a look at the project name on the left side (in front of "ARCHIVED project name") there should be an arrow. It is not possible to directly unarchive subprojects (without their parent project) since then it would be unclear in which hierarchy they should be located.
However, you should be able to unarchive the parent project. Once you have done this, the "unarchive" option should be shown for the project and you can unarchive it.
Afterwards, you could adjust the hierarchy of the child project (which you originally wanted to unarchive). This way you can archive / unarchive it independently of its parent project.

## Does OpenProject offer portfolio management?

For portfolio management or custom reporting, you can use either the project list, or the global work package table. Both views can be used to create optimal reports via filtering, sorting and other configuration options.

For more information on portfolio management options in OpenProject please refer to this [Use Case](../../../use-cases/portfolio-management/).

## When I set up the overview page for a project, work packages can be arranged as a Gantt chart. I would also need this for the subprojects. How does it work?

If you have selected the "Work package table" widget on the under the _Dashboard_ tab of the home page, you can open the _more (three dots)_ menu at the top right corner of the widget and click **Configure view**. In the configuration, you can select subprojects under _Filter_. You can choose all subprojects, a single subproject, or several subprojects.  

In the _Gantt chart_ tab of the Work package table configuration, tick the box next to "Show Gantt chart". All work packages of the selected subprojects will then be displayed in a combined Gantt chart view.  

If you want to see the individual Gantt charts of the subprojects separately, you need to add a Work package table widget for each subproject.

## Can I change or re-arrange the widget on the project home page?

The layout of widgets on the **Overview** tab of the project home page is pre-set and **cannot** be changed.  

You **can**, however, add, edit, and re-arrange all widgets on the **Dashboard** tab of the project home page.
