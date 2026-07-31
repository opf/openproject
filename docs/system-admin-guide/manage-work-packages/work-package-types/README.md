---
sidebar_navigation:
  title: Types
  priority: 800
description: Configure work package types in OpenProject.
keywords: work package types, work package form, related work package, work package table, relations, pdf export, automatic subject
---

# Manage work package types

In OpenProject, you can create and manage as many work package types as needed, such as Tasks, Bugs, Ideas, Risks, and Features.

To add or modify work package types, navigate to _Administration → Work packages → Types_.

Here, you will see a list of all existing work package types.

1. Click on a work package type name to **edit an existing type**.
2. Use the up and down arrows to **reorder work package types**. The type at the top of the list becomes the default and is automatically selected when creating a new work package.
3. Click the delete icon to **remove a work package type**.

![System-admin-work-packages-types](openproject_system_guide_work_package_types.png)

## Create new work package type

Click the green **+ Type** button to add a new work package type in the system, e.g. Risk.

1. Give the new work package type a **name** that easily identifies what kind of work should be tracked.
2. Choose a **color** from the drop-down list which should be used for this work package type in the Gantt chart. You can configure new colors [here](../../design/#set-a-new-color).
3. You can **copy a [workflow](../work-package-workflows)** from an existing type.
4. You can enter **default text for the work package description field**, which always be shown when creating new work package from this type. This way, you can easily create work package templates, e.g. for risk management or bug tracking, that already contain certain required information in the description.
5. Choose whether the type should be a **milestone**, e.g. displayed as a milestone in the Gantt chart with the same start and finish date.
6. Choose whether the type should be displayed in the [roadmap](../../../user-guide/roadmap/) by default.
7. Select if the work package type should be **active in new projects by default**. This way work package types will not need to be [activated in the project settings](../../../user-guide/projects/project-settings/work-packages/#work-package-types) but will be available for every project.
8. Click the **Save** button to add the new type.

![Create a new work package type in OpenProject administration](openproject_system_guide_new_work_package_typ.png)

## Work package form configuration (Enterprise add-on)

You can customize the work package form for each work package type to display the attributes most relevant to your team's workflow. Attributes can be added, removed, and arranged within the form as needed.

In the Enterprise edition, you can also create and rename sections and add a related work packages table.

[feature: edit_attribute_groups ]

To configure the work package form for a type, navigate to **Administration → Work packages → Types**, select a type, and open the **Form configuration** tab.

The form preview on the right shows the attributes that are currently displayed when creating or editing work packages of this type. Attributes are organized into sections.

On the left side are all available attributes and [custom fields](../../custom-fields) that are not currently used in the form. You can filter them using the search field.

To customize the form:

- Add attributes and custom fields by dragging them from the left side into the desired section.
- Remove attributes from the form using the **(...)** menu next to the attribute.
- Reorder attributes and sections using drag and drop or the available move options from the **(...)** menu.
- Rename sections using the **(...)** menu.

> [!NOTE]
> If you use custom fields, remember that they must also be activated for the relevant projects before they can be used.

![Sys-admin-type-form-configuration](openproject_system_guide_wp_form_configuration.png)

To add a new section, click **+ Add** and select **Section**. Enter a name for the section and then drag attributes into it.

To add a related work packages table, click **+ Add** and select **Related work packages table**.

If you want to restore the default form layout for this type, click **Reset form**. This resets the entire form configuration, including all sections and attribute assignments.

![Add button for attribute group](openproject_system_guide_wp_add_section.png)

Changes are saved automatically. Users creating or editing a work package of this type will see the form exactly as configured.

Watch the following video to see how you can customize your work packages with custom fields and configure the work package forms:

<video src="https://openproject-docs.s3.eu-central-1.amazonaws.com/videos/OpenProject-Forms-and-Custom-Fields-1.mp4"></video>

## Add table of related work packages to a work package form (Enterprise add-on)

You can add a related work packages table to your work package form. Click the **+ Add** button and select **Related work packages table**.

[feature: work_package_query_relation_columns ]

![Sys-admin-table-of-related-work-packages](openproject_system_guide_table_of_related_wp.png)

You can configure which related work packages should be displayed in the table, for example child work packages or work packages with a specific relation type. You can also define how the table is filtered, grouped, sorted, and displayed. Configure the table in the same way as a regular [work package table](../../../user-guide/work-packages/work-package-table-configuration/).

When you have finished configuring the table, click **Apply** to add it to the form.

![Work package table configuration for work package form in OpenProject administration](openproject_system_admin_guide_filter_wp.png)

The related work packages table is then displayed directly in the work package form. It automatically shows work packages that match the configured relation and filters. Users can also create new related work packages directly from the table.

![A work package in OpenProject displaying related work packages table](open_project_admin_related_wp_table.png)

## Display project attributes in work package forms

You can display **[project attributes](../../projects/project-attributes/)** in a dedicated tab within work packages. This allows users with necessary permissions to view and edit project-level information directly from a work package.

To configure this, go to **Administration → Work packages → Types**, open the **Project attributes** tab, and select which project attributes should be displayed for each work package type.

![Work package settings in OpenProject administration, showing "project attributes" tab](openproject_system_guide_work_package_types_project_attributes.png)

The tab lists all available project attribute sections and their attributes.

Use the On/Off toggle next to each project attribute to show or hide it in the **Project attributes** tab for the selected work package type.

You can also use the **Enable all** and **Disable all** buttons displayed next to each section title to show or hide all project attributes within that section at once.

If your instance contains many project attributes, use the search field to quickly find a specific attribute.

> [!NOTE]
> This setting only controls which project attributes are displayed in the **Project attributes** tab of a work package for the selected work package type. It does **not** affect which project attributes are displayed on the project's overview page. The project overview uses its own display configuration.
>
> Read more about configuring project attributes for the [project overview page](../../../user-guide/projects/project-settings/project-attributes/).

The same project attributes are used in both the project overview and work packages. Any changes made to a project attribute from within a work package are reflected everywhere the attribute is displayed.

Displaying project attributes in work packages is particularly useful for **PDF exports**, as the project attributes shown in the work package are also included in the exported document.

## Work package automatic subject configuration (Enterprise add-on)

[feature: work_package_subject_generation ]

Please refer to [this guide](automatic-subjects) for a detailed description of automatically generated work package subjects in OpenProject. 

## Activate work package types for projects

Under **Administration → Work packages → Types**, open the **Projects** tab to select for which projects a work package type should be activated.

The **Enabled for new projects by default** setting (which can be selected when creating or editing a work package type) only activates the type for newly created projects. It does not activate the type for existing projects.

For existing projects, work package types can also be activated manually in the [project settings](../../../user-guide/projects/project-settings). There, work package types can be enabled or disabled on a per-project basis.

To activate a work package type for all projects, enable the **Enable for all projects** switch.

If **Enable for all projects** is disabled, a list of projects is displayed. Select the projects for which the work package type should be available and click **Save**.

![activate projects for work package types in OpenProject administration](openproject_system_guide_wp_type_activate_projects.png)

## Generate PDF

Under the **Generate PDF** tab of **Administration -> Work packages -> Types** you configure how a single work package of this type is exported as a PDF. The tab contains two sections: the available export templates and the automatic artefact export.

### Activate templates for PDF exports

Here you can select which PDF export templates are available for this work package type.

The template determines the design and attributes visible in the exported PDF of a work package using this type. The first  template on the list is selected by default.

![Generate PDF tab under work package types settings in OpenProject administration](openproject_system_guide_work_package_types_pdf_tab.png)

Use the toggle next to a template to enable or disable it, or use **Enable all** and **Disable all** to switch every template at once. Changes are saved immediately.

Drag a template by its handle to change the order of the list. The order determines the sequence in the **Template** dropdown menu of the export dialog, and the first enabled template is preselected there.

If no template is enabled, users of this type cannot generate a PDF: the export dialog states that no template has been enabled and the download button stays disabled.

> [!TIP]
> See [Work package PDF export](../../../user-guide/work-packages/exporting/work-package-pdf/) in the user guide for what each of the templates contains.

### Automatic artefact export

In addition to exporting on demand, OpenProject can generate a PMflex Artefact PDF automatically whenever the status of a work package of this type changes. Select one of the following options:

- **Off** - no PDF is generated automatically. This is the default.

- **Save as work package file attachment** - the generated PDF is saved as a file attachment on the work package. The new attachment is also recorded in the work package Activity.

- **Upload file to external file storage and add file link to work package** - the generated PDF is uploaded to the project's automatically-managed Nextcloud storage and linked from the work package. Work packages in projects without such a storage are skipped. This option can only be selected if an [automatically-managed Nextcloud storage](../../files/external-file-storages/) is configured for the instance.

The selection is saved immediately.

> [!NOTE]
> The automatic export always uses the PMflex Artefact template, regardless of which templates are enabled for manual exports above.
