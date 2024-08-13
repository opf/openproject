---
sidebar_navigation:
  title: Project attributes
  priority: 300
description: Viewing, creating and modifying project attributes in OpenProject
keywords: project attributes, create, project settings
---

# Project attributes

Project attributes are custom fields that allow you to communicate key information relevant to a project in the [Project Overview](../../../user-guide/project-overview) page.

> [!NOTE]
> Prior to version 14.0, these were called "project custom fields" and described under the [Custom fields](../../custom-fields/custom-fields-projects/) page. Starting with 14.0, there is now a new entry in the administration section called 'Project attributes' under 'Projects'.

This page describes how to create, order and group project attributes and is directed at instance administrators. If you want know how to enable and set the values for project attributes at a project level, please refer to the [Project Overview](../../../user-guide/project-overview) page of the user guide.

## View project attributes

To view all existing project attributes, navigate to **Administration settings** → **Projects** → **Project attributes**.

![List of existing project attributes in OpenProject administration](open_project_system_admin_guide_project_attributes_list.png)

Each project attribute will be displayed in individual rows, which contain:

![OpenProject project attribute explained](open_project_system_guide_project_attribute_explained.png)

1. The drag handle
2. The project attribute name
3. Format
4. Number of projects using the attribute
5. More button

Attributes may also be contained in [sections](#sections).

## Create a project attribute

To create a new project attribute, click on the **+ Project attribute** button in the top right corner.

This will display the "New attribute" form with these options:

![Create a new attribute form in OpenProject administration](open_project_system_guide_project_attributes_new_attribute.png)

- **Name**: This is the name that will be visible in the [Project Overview](../../../user-guide/project-overview) page.

- **Section:** If there are sections, you can pick where this new project attribute should appear. [Learn about sections](#sections) for more information.

- **Format**: You can pick from nine different types of fields: text, long text, integer, float, list, date, boolean, user and version.

  > [!TIP]
  > You cannot change this once the project attribute is created.

- **Format options:** Depending on the type you choose, you might have additional options, such as minimum and maximum width, default value or regular expressions for validation.

- **Required for all projects**: Checking this makes this project attribute required for all projects. It cannot be deactivated at a project level.

- **Admin-only**: If you enable this, the project attribute will only be visible to administrators. All other users will not see it, even if it is activated in a project.

  > [!TIP]
  > This is enabled by default. Only disable this if you want this field to be invisible to non-admin users.

- **Searchable**: Checking this makes this project attribute (and its value) available as a filter in project lists.

## Modify project attributes

You can edit existing attributes under **Administration settings** → **Projects** → **Project attributes**.

![Edit or move a project attribute in the OpenProject administration](open_project_system_admin_guide_project_attributes_more_icon_menu.png)

Click on the  More icon to the right of each project attribute to edit, re-order or delete a project attribute.

>[!CAUTION]
>Deleting a project attribute will delete it and the corresponding values for it from all projects.

You can also use the drag handles to the left of each project attribute to drag and drop it to a new position.

>[!NOTE]
>
>Project admins can chose to enable or disable a project attribute from their project, but they cannot change the order. The order set in this page is the order in which they will appear in all projects.



## Enable project attributes

Under **Administration settings** → **Projects** → **Project attributes** select the *More* menu and select *Edit* or simply clicking on the name of the project attribute. This will open a detailed view of the project attribute you selected. 

The *Details* tab will allow you to edit the name, section and visibility. 

![OpenProject project attribute details editing](open_project_system_admin_guide_project_attributes_details.png)

The *Enabled in projects* tab will show a list of all the projects this project attributes was activated in. 

![Project attributes enabled in projects list in OpenProject administration](open_project_system_admin_guide_project_attributes_enabled_in_projects.png)

You can remove a project attribute from a specific project by selecting the **More** menu at the end of the line and clicking the *Deactivate for this project* option.

![Deactivate a project attribute for a project in OpenProject administration](open_project_system_admin_guide_project_attributes_deactivate_for_project.png)

To add this project attribute to a specific project click the **+Add projects** button. A modal will appear allowing you to search for projects to add this project attribute into. Please note, that the projects, in which the project attribute is already activated will be shown disabled in that selection. You can include subprojects. 

![ Configure which projects are activated for a project attribute in OpenProject administration](open_project_system_admin_guide_project_attributes_add.png)

> [!NOTE]
>
> It is not possible to add or remove a project attribute, if a project attribute is set to be required.

## Sections

You can group project attributes into sections to better organize them.

You can click on more icon to the right of each section to rename it, delete it or change its order.

> [!TIP]
>
> A section can only be deleted if no project attributes were assigned to it.

You can drag any existing project attribute into a section to move it there. You may also drag and drop entire sections up and down to re-order them.

>[!TIP]
>
>If a project attribute belongs to a section, it will be displayed within that section in _all_ projects.

![Edit project attribute sections in OpenProject administration](open_project_system_admin_guide_project_attributes_section_more_icon_menu.png)
