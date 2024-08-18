---
sidebar_navigation:
  title: Attribute help texts
  priority: 950
description: Learn how to set attribute help texts in OpenProject
keywords: attribute help texts, help texts for projects and work packages

---

# Attribute help texts

<div class="glossary">
**Attribute help texts** provide additional information for attributes in work packages and projects. After setting them up they are displayed when users click on the question mark symbol next to custom fields in projects and work packages.
This way you will reduce wrong entries for attributes. This is especially relevant for company specific custom fields.
</div>

## Overview

| Topic                                                                       | Content                                                    |
|-----------------------------------------------------------------------------|:-----------------------------------------------------------|
| [Add Attribute help texts](#add-attribute-help-texts)                       | How to add and configure an Attribute help text.           |
| [Edit or delete Attribute help texts](#edit-or-delete-attribute-help-texts) | How to edit and how to delete an Attribute help text.      |
| [Work packages](#work-packages)                                             | Where will Attribute help texts for work packages be used? |
| [Projects](#projects)                                                       | Where will Attribute help texts for projects be used?      |
| [WYSIWYG editor](#wysiwyg-editor)                                           | Where can Attribute help texts be displayed?               |

Navigate to *Administration* -> *Attribute help texts* to set up help texts for attributes and custom fields in work packages and projects. Here you can add, edit and delete Attribute help texts.

![Attribute help texts in OpenProject administration](openproject_system_admin_guide_attribute_help_texts_overview.png)

## Add Attribute help texts

To add an Attribute help texts for custom fields click on the green **+ Attribute help text** button.

1. **Choose the attribute** you'd like to explain. Custom fields are also displayed here, which may require further explanation.
2. Add a **description**. You can add in-line pictures, links or videos, too. This **help text description** which will be shown in work package or project forms for the users.
3. Add **files**, e.g. excerpts from a process manual
4. **Save** your changes.

![Add a new attribute help text in OpenProject administration](openproject_system_admin_guide_attribute_help_texts_add.png)

> [!NOTE]
> Please be aware that the help text will be visible in all projects.

Once you configured the help text for an attribute, project members can see the explanation. The will see a question mark item next to the attribute.

When the users click on it, they see the description for this attribute.

![Attribute help text description example](openproject_system_admin_guide_attribute_help_texts_example.png)

## Edit or delete Attribute help texts

Navigate to *Administration* -> *Work packages* -> *Attribute help texts* in order to edit or remove an attribute help text.

1. Click on the **name** of the attribute to edit an existing attribute help text.
2. Click on the **delete icon** to delete an attribute help text.

![Edit or delete help attribute texts in OpenProject administration](openproject_system_admin_guide_attribute_help_texts_edit_delete.png)

## Work packages

The Attribute help texts for work packages will be displayed in the [details view](../../user-guide/work-packages/work-package-views/#split-screen-view) (as in the screenshot below) and in the [full screen view](../../user-guide/work-packages/work-package-views/#full-screen-view). They will help the users (e.g. the project managers) understand what kind of information to put in which fields.

![Example of attribute help text in a work package view in OpenProject](openproject_system_admin_guide_attribute_help_texts_example_wp.png)

## Projects

The Attribute help texts for projects will be displayed in the Project details widget in the [Project overview](../../user-guide/project-overview/) (as in the first screenshot below) and in the [Project settings](../../user-guide/projects/project-settings/project-information/) (as in the second screenshot below).

They will help the users (e.g. the project managers) understand what kind of information to put in which fields.

![Attribute help texts on a project overview page](openproject_system_admin_guide_attribute_help_texts_project_overview_page.png)

![Attribute help texts project information page](openproject_system_admin_guide_attribute_help_texts_project_settings_page.png)

## WYSIWYG editor

The Attribute help texts can also be displayed in the WYSIWYG text editor by using a certain syntax. Find out more [here](../../user-guide/wysiwyg/#embedding-of-work-package-attributes-and-project-attributes).
