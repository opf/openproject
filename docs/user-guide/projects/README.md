---
sidebar_navigation:
  title: Projects
  priority: 600
description: Manage projects in OpenProject
keywords: manage projects
---
# Manage projects

In OpenProject you can create projects to collaborate with your team members, track issues, document and share information with stakeholders, organize things. A project is a way to structure and organize your work in OpenProject.

Your projects can be available publicly or internally. OpenProject does not limit the number of projects, neither in the Community edition nor in the Enterprise cloud or in Enterprise on-premises edition.

| Topic                                                                        | Content                                                                                                                  |
|------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------|
| [Select a project](../../getting-started/projects/)                          | Open a project which you want to work at.                                                                                |
| [Create a new project](../../getting-started/projects/#create-a-new-project) | Find out how to create a new project in OpenProject.                                                                     |
| [Create a subproject](#create-a-subproject)                                  | Create a subproject of an existing project.                                                                              |
| [Project structure](#project-structure)                                      | Find out how to set up a project structure.                                                                              |
| [Project settings](#project-settings)                                        | Configure further settings for your projects, such as description, project hierarchy structure, or setting it to public. |
| [Change the project hierarchy](#change-the-project-hierarchy)                | You can change the hierarchy by selecting the parent project ("subproject of").                                          |
| [Set a project to public](#set-a-project-to-public)                          | Make a project accessible for (at least) all users within your instance.                                                 |
| [Create a project template](./project-templates/#create-a-project-template)  | Configure a project and set it as template to copy it for future projects.                                               |
| [Use a project template](./project-templates/#use-a-project-template)        | Create a new project based on an existing template project.                                                              |
| [Copy a project](#copy-a-project)                                            | Copy an existing project.                                                                                                |
| [Archive a project](#archive-a-project)                                      | Find out how to archive completed projects.                                                                              |
| [Delete a project](#delete-a-project)                                        | How to delete a project.                                                                                                 |
| [Projects list](#projects-list)                                              | Get an overview of all your projects in the projects list.                                                               |
| [Export project list](#export-projects)                                      | You can export the project list to XLS or CSV.                                                                           |
| [Project overarching reports](#project-overarching-reports)                  | How to create project overarching reports across multiple projects.                                                      |

![](https://openproject-docs.s3.eu-central-1.amazonaws.com/videos/OpenProject-Projects-Introduction.mp4)

## Select a project

Find out in our Getting started guide [how to open an existing project](../../getting-started/projects/) in OpenProject.

## Create a new project

Find out in our Getting started guide how to [create a new project](../../getting-started/projects/#create-a-new-project) in OpenProject.

## Create a subproject

To create a subproject for an existing project, navigate to [*Project settings*](#project-settings) -> *Information* and click on the green **+ Subproject** button.

Then follow the instructions to [create a new project](../../getting-started/projects/#create-a-new-project).

![project settings subproject](project-settings-subproject.png)



## Project structure

Projects build a structure in OpenProject. You can have parent projects and sub-projects. A project can represent an organizational unit of a company, e.g. to have issues separated:

* Company (Parent project)
  * Marketing (Sub-project)
  * Sales
  * HR
  * IT
  * ...

Also, projects can be for overarching teams working on one topic:

* Launch a new product
  * Design
  * Development
  * ...

Or, a project can be to separate products or customers.

* Product A
  * Customer A
  * Customer B
  * Customer C

OpenProject, for example, uses the projects to structure the different modules/plugin development:

![project hierarchy select project](image-20220728200830893.png)

**Note**: You have to be a [member](../members/#add-members) of a project in order to see the project and to work in a project.

## Project Settings

You can specify further advanced settings for your project. Navigate to your project settings by [selecting a project](../../getting-started/projects/#open-an-existing-project), and click -> *Project settings* -> *Information*.

- You can define whether the project should have a parent by selecting **Subproject of**. This way, you can [change the project hierarchy](#change-the-project-hierarchy).

- Enter a detailed description for your project.

- You see the default project **Identifier**. The identifier will be shown in the URL. 

**Note**: Changing the project identifier while the project is already being worked on can have major effects and is therefore not recommended. For example, repositories may not be loaded correctly and deep links may no longer work (since the project URL changes when the project identifier is changed).

- You can set a project to **Public**. This means it can be accessed without signing in to OpenProject.
- Click the blue **Save** button to save your changes.
- If you like, use the autocompleter to fill in the project attributes.

![project information description status](project-information-description-status.png)

Find out more detailed information about the Project settings [here](project-settings).

### Change the project hierarchy

To change the project's hierarchy, navigate to the [project settings](project-settings) -> *Information* and change the **Subproject of** field.

Press the blue **Save** button to apply your changes.

![project settings information change hierarchy](project-settings-information-change-hierarchy-3912542.png)



### Set a project to public

If you want to set a project to public, you can do so by ticking the box next to "Public" in the [project settings](project-settings) *->Information*.

Setting a project to public will make it accessible to all people within your OpenProject instance. 

(Should your instance be [accessible without authentication](../../system-admin-guide/authentication/authentication-settings) this option will make the project visible to the general public outside your registered users, too)

### Copy a project

You can copy an existing project by navigating to the [project settings](project-settings) and clicking **Copy project** in the upper right of the project settings.

![project information copy project](project-information-copy-project.png)

Give the new project a name. Select which modules and settings you want to copy and whether or not you want to notify users via email during copying. 
You can copy existing [boards](../agile-boards) (apart from the Subproject board) and the [Project overview](../project-overview/#project-overview) dashboards along with your project, too.

![project settings information copy project copy options](project-settings-information-copy-project-copy-options.png)

**!!Attention!!** - **Budgets** cannot be copied, so they must be removed from the work package table beforehand. Alternatively, you can delete them in the Budget module and thus delete them from the work packages as well.

For further configuration open the **Advanced settings**. Here you can specify (among other things) the project's URL (identifier), its visibility and status. Furthermore you can set values for custom fields (not shown in the screenshot).

![copy project advanced settings](copy-project-advanced-settings-3914305.png)

Then click the blue **Copy** button.

### Archive a project

In order to archive a project, navigate to the [project settings](project-settings), and click the **Archive project** button.

> **Note**: This option is always available to instance and project administrators. It can also be activated for specific roles by enabling the _Archive project_ permission for that role via the [Roles and permissions](../../system-admin-guide/users-permissions/roles-permissions/) page in the administrator settings.

![project settings archive project](project-settings-archive-project.png)

Then, the project cannot be selected from the project selection anymore. It is still available in the **View all projects** dashboard if you set the "Active" filter to "off" (move slider to the left). You can un-archive it there, too, using the three dots at the right end of a row.

![project list filter](project-list-filter.png)


### Delete a project

If you want to delete a project, navigate to the [Project settings](project-settings). Click the button **Delete project** on the top right of the page. 

![delete a project](delete-a-project.png)

Also, you can delete a project via the [projects overview](#projects-list).

**Note**: Deleting projects is only available for System administrators.


## Projects list

To get an overview of all your projects, press the **Projects lists** button at the bottom of the **Select a project** menu in the top left header navigation. 

![projects list button](image-20220728201226907.png)

You will then get a list of all your projects in OpenProject. You can use this projects overview to **create a multi project status dashboard** if you include your own [project custom fields](../../system-admin-guide/custom-fields/custom-fields-projects/), e.g. custom status options, Accountable, Project duration, and more.

**Please note:** Project custom fields are an Enterprise add-on and will only be displayed here for Enterprise on-premises and Enterprise cloud.

With the **arrow** on the right you can display the **project description**.

With the horizontal **three dots** icon on the right side of the list you can open **further features**, such as [creating a new subproject](#create-a-subproject), [project settings](project-settings), [archiving a project](#archive-a-project), [copying](#copy-a-project) and [deleting a project](#delete-a-project). Please note that you have to be a System Administrator in OpenProject to access these features. Find out how to un-archive projects [here](#archive-a-project).

![new subproject project list](new-subproject-project-list.png)

You can choose the **columns displayed by default** in the [System settings](../../system-admin-guide/system-settings/project-system-settings) in the Administration. To access it quickly use the **vertical three dots** icon on the upper right.

![configure project list](configure-project-list.png)

To change the order of the displayed [custom fields](../../system-admin-guide/custom-fields) (columns) follow the instructions here: [Displaying a project custom field](../../system-admin-guide/custom-fields/custom-fields-projects/#display-project-custom-fields).



To **display the work packages** of all your projects **in a Gantt chart** click on the **Open as Gantt view** icon on the upper right. This is a shortcut to quickly get to the report described in the [chapter below](#project-overarching-reports). 
The Gantt chart view can be configured in the [System settings](../../system-admin-guide/system-settings/project-system-settings) in the Administration.

![display all wprkpackages](display-all-workpackages.png)

### Overall activity

Besides the Gantt-chart view and the filter function for the project list, you can also access the activity of all users in all projects. 

![overall activity button](overall-activity-button-3922893.png)

By clicking on the Overall activity button you can open a view in which all the latest global project activities are documented. In the menu on the left side you can filter the activity by different areas to control e.g. the activity of work packages, wiki pages or meetings.

![overall activity meeting filter](overall-activity-meeting-filter.png)


## Export projects

You can export the project list by selecting the **View all projects** list from the drop-down.
To export the project list, click on the three dots in the upper right hand corner and select > **Export**.

![Export projects](export-projects.png)

Next, you can select the format in which you want to export the project list.

It can be exported as .xls or .csv.

![Export project list formats](export-project-list-formats.png)


## Project overarching reports

Often you need to see information about more than one project at once and want to create project overarching reports.

Click on the **Modules** icon with the nine squares in the header navigation. These are the project overarching modules in OpenProject.

![navigation bar modules](navigation-bar-modules-3923134.png)

Here you will find

- The [global projects list](#projects-list)
- The global work package tables (see below)
- The global news overview
- The global time and costs module

### Global work package tables

Select **Work packages** from the drop down menu **Modules** in the upper right (nine squares). Now, you will see all work packages in the projects for which you have the required [permissions](../..//system-admin-guide/users-permissions/roles-permissions/).

In this project overarching list, you can search, filter, group by, sort, highlight and save views the same way as in the [work package table](../work-packages/work-package-table-configuration) in each project.

You can group by projects by clicking in the header of the work package table next to PROJECT and select **Group by**. Collapsing the groups will allow you an **overview of the projects' aggregated milestones** as described [here](../../user-guide/work-packages/work-package-table-configuration/#flat-list-hierarchy-mode-and-group-by).

![project overarching report](project-overarching-report.gif)
