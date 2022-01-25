---
sidebar_navigation:
  title: Custom fields for projects
  priority: 700
description: Custom fields for projects.
robots: index, follow
keywords: custom fields for projects, show custom fields
---
# Manage and display custom fields in the project list (Premium feature)

As a user of [OpenProject Enterprise on-premises](https://www.openproject.org/enterprise-edition/) or [OpenProject Enterprise cloud](https://www.openproject.org/hosting/) you can customize the work package list and show additional project information by adding custom fields to the project list, e.g. adding accountable, project due date, progress, and more.

## Creating a custom field for projects

To create a new custom field for projects, navigate to -> *Administration* -> *Custom fields* and select the tab **Project**. 
Click on the link **Create a new custom field** to create a project custom field.

![Sys-admin-create-custom-field-projects](Sys-admin-create-custom-field-projects.png)

1. In the newly opened create form provide a **name** to display in the project list (e.g. Project ID).
2. Choose a **format** for the custom field, e.g. List. Decide if you want to the custom field to allow multi-select.
3. **Enter the possible values** which can be selected (for a list). This is not relevant if you choose e.g. text format.
4. Define if the custom field should be **required**.
5. If you check **visible** it will also be visible for all users (non-admins) in the project overview and displayed in the project details widget on the [Project Overview](../../../user-guide/project-overview/).
6. Define if the custom field for projects should be **searchable**.
7. Click **Save** to create the custom field.

![project_custom_field_create](project_custom_field_create-1952858.png)

## Populating a project custom field

Once you created the custom field you can set a value for it in the [project settings](../../../user-guide/projects/project-settings/).

To do this navigate to a project and select *Project settings* from the side menu. The project custom field is visible under *Information*. As a project manager you can populate or edit the project custom field.

![Sys-admin-custom-fields-project-settings](Sys-admin-custom-fields-project-settings.png)



## Displaying project custom fields



If you selected *Visible* in the custom fields settings, the custom field for projects is also available in the [View all projects](../../../user-guide/projects/#global-projects-overview---view-all-projects) overview.

Navigate to this project list by selecting *View all projects* from the project selection menu on the top left side.

![Sys-admin-view-all-projects](Sys-admin-view-all-projects-1579704910470.png)

In the list of all projects you will see the project custom fields displayed as a columns in the project list. Therefore, you can easily communicate project information across multiple projects.

![Sys-admin-display-project-custom-field](Sys-admin-display-project-custom-field.png)

<div class="alert alert-info" role="alert">
**Please note**: The visibility settings of the project custom fields will be overruled by [these settings](../../system-settings/project-system-settings/#settings-for-the-projects-overview-list) for the projects overview list.
</div>

To change the **order of the project custom fields' columns**, change it in -> *Administration* -> *Custom fields* by using the sorting **arrows**.

![image-20201007163002544](image-20201007163002544.png)



Furthermore, the project custom fields will also be displayed in the Project details widget on the [project overview page](../../../user-guide/project-overview/).