---
sidebar_navigation:
  title: Projects
  priority: 900
description: Introduction to projects in OpenProject.
keywords: open project, create project, projects introduction
---
# Projects introduction

Get an introduction how to work with projects in OpenProject. To start collaboration in OpenProject, you first have to set up a new project.

<div class="glossary">

A **project** is defined as a temporary, goal-driven effort to create a unique output. A project has clearly defined phases, a start and an end date, and its success is measured by whether it meets its stated objectives.
A project in OpenProject can be understood as a project as defined above. Also, it can be set up as a "workspace" for teams to collaborate on one common topic, e.g. to organize a department.

</div>

>  [!NOTE]
>
> In order to see a project and work in it, you have to be a [member of the project](../invite-members).

| Topic                                                   | Content                                                      |
| ------------------------------------------------------- | ------------------------------------------------------------ |
| [Open a project](#open-an-existing-project)             | Select and open an existing project.                         |
| [Create a new project](#create-a-new-project)           | Create a project from scratch or use existing project templates. |
| [View all projects](#view-all-projects)                 | Get an overview about all your projects.                     |
| [Advanced project settings](#advanced-project-settings) | Configure further advanced settings for your project.        |

<video src="https://openproject-docs.s3.eu-central-1.amazonaws.com/videos/OpenProject-Projects-Introduction.mp4"></video>

## Open an existing project

In order to open an existing project, click the **All projects** dropdown menu in the upper left corner of the header and select the project you want to open.

You can also start typing in a project name to filter by the project's title or filter for favorite projects. 

![Project selection dropdown menu called "all projects" in the header navigation of OpenProject, opened and showing a list of existing projects](openproject_getting_started_all_projects_menu.png)

Projects and subprojects are displayed according to their hierarchy in the drop-down menu.

<div class="glossary">

**Subproject** is defined as a child project of another project. Subprojects can be used to display a hierarchy of projects. Several filter options (e.g. in work package table and timeline) can be applied only to the current project and its subprojects.

</div>

![Project hierarchy displayed in "all projects" dropdown menu in OpenProject](openproject_getting_started_project_hierarchy.png)

Alternatively, you can open the list of all existing projects using the [**Global modules**](../../user-guide/home/global-modules/#projects) menu.

Also, you will see your newest and favorited projects on the application landing page in the **Projects** section. Here you can simply click on one of the projects to open it. Alternatively, select favorite projects from the **All projects** dropdown menu by using the respective switch.

![Favorite projects displayed on OpenProject overview page](openproject_getting_started_favorite_projects.png)

## Create a new project

There are several ways to create a new project in OpenProject. Keep in mind that the ability to create a new project is tied to correct [permissions](../../system-admin-guide/users-permissions/roles-permissions/).

1. Click the green button **+ Project** directly on the system's home screen in the **Project** section.

   ![Button to create a new project on the OpenProject homepage](openproject_getting_started_project_new_project_button.png)

2. You can also use the **+ (Plus)** button in the top right corner of the header navigation. 

![+ Button in the top right corner of the OpenProject head navigation, opened, showing an option to add a new project](openproject_getting_started_project_plust_button_add_project.png)

![+ Button in the top right corner of the OpenProject head navigation, opened, showing an option to add a new project](openproject_getting_started_project_plust_button_add_project.png)

3. In addition, you can also create a new project on the [project lists](../../user-guide/projects/project-lists/) overview page. 

4. If the project you are creating is subproject, navigate to the [project settings](../../user-guide/projects/project-settings/) and use the *+ Subproject* button.

### Choose how to create your project
You can create either:

- a **blank project** (a completely new and empty project), 
- a project **based on a template**,
- a project **based on [project initiation request (Enterprise add-on)](../../user-guide/projects/project-initiation-request)** process

The **Blank project** option is selected by default.

>  [!TIP]
> If you do not see any template options, this may be because no projects have been set as [project templates](../../user-guide/projects/project-templates/#create-a-project-template) yet, or because you do not have access to any template projects. Only templates that are public or where you are a project member are shown, allowing different user groups to see only the templates relevant to them.

Click **Continue** to proceed.

![Select a template for creating a new project in OpenProject](openproject_getting_started_create_new_project_select_template.png)

### Define project details

Next, enter the **name**  for your project. 

Based on the project name, OpenProject automatically suggests an **identifier**. You can edit the suggested identifier manually if needed. The identifier is validated automatically to ensure it follows the required rules.

> [!NOTE]
> The identifier suggestion updates automatically when you change the project name.
> If you manually edit the identifier and later go back to change the project name again, OpenProject updates the identifier suggestion once more.

You can also optionally enter a **description** for your project.  You can also integrate the project into your existing project hierarchy by selecting a **parent project**, which will make the new project a **subproject**.

Click **Complete** to finish the setup.

![Name and create a new project in OpenProject](openproject_getting_started_create_new_project_name.png)

> [!TIP]
> If you started creating a new project (project B) from within any other project (project A), project B is considered a subproject of project A. 
> In this case, the **Subproject of** field is not shown, but the parent project appears in the breadcrumb navigation.
> If this was not your intention, you can change or remove the parent project later in the project settings of project B.


![Name and create a new subproject in OpenProject](openproject_getting_started_create_new_sub_project_name.png)

> [!TIP]
> If there are project attributes configured as **required**, an additional step will appear during project creation. You must fill in these attributes before you can complete the setup.

![Fill out a required project attribute during new project creation in OpenProject](openproject_getting_started_create_new_project_attributes.png)

### Project initiation request (Enterprise add-on)

If a project initiation request was configured for the template you are using, after project creation you will be guided through additional pre-defined steps. 

Read more about [project initiation request (Enterprise add-on)](../../user-guide/projects/project-initiation-request).

### Project members

The project members of a newly created project depend on how the project was created:

- **Blank project**: The user creating the project will be added automatically as a member, project role is based on the [corresponding setting in administration](../../system-admin-guide/projects/new-project/). 
- **From a template**: The project inherits the same members and roles as defined in the template.
- **Copied from another project**: The project inherits the members and roles from the original project. See here [how to copy a project](../../user-guide/projects/project-settings/project-information/#copy-a-project).

To continue configuring your project, see the documentation on [project settings](../../user-guide/projects/project-settings/project-information/).

## View all projects

To view all your projects in which you are a member, use the [**Global modules menu**](../../user-guide/home/global-modules/#projects) on the left or select *Projects* using the grid icon in the top left corner.

![*Global modules* grid icon in OpenProject header navigation, opened, Projects module selected](openproject_getting_started_global_modules_icon_projects.png)

![Projects global module selected from the left-side menu on OpenProject overview page](openproject_getting_started_global_modules_projects.png)

You will see a list with all your projects and their details.

![Projects overview list in OpenProject](openproject_getting_started_project_lists_overview.png)

## Advanced project settings

In our detailed user guide you can find out how to configure further [advanced project settings](../../user-guide/projects/) for your projects, e.g. description, project hierarchy or setting it to public.
