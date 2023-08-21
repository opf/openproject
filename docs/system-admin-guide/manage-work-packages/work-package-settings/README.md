---
sidebar_navigation:
  title: Settings
  priority: 999
description: Work package settings in OpenProject.
keywords: work package settings, workpackage configuration
---
# Work package settings

To change basic settings for work package tracking in OpenProject, navigate to **Administration -> Work packages -> Settings**.

You can adjust the following:

1. **Allow cross-project work package relations**, i.e. that work packages created in one project can have relations to work packages in another project, for example parent-children work packages.

2. **Display subprojects work packages in main projects** by default. This way the work packages of subprojects will always be visible in the main project if a user has the corresponding role in the subproject to see work packages.

3. **Use current date as start date for new work packages**. This way the current date will always be set as a start date if your create new work packages. Also, if you copy projects, the new work packages will get the current date as start date.

4. **Calculate the work package done ratio with** ... defines how the **Progress %** field is calculated for work packages. If you choose "disable", the field will not be shown. If you select "Use the work package field", the Progress % field can be manually set in 10% steps directly in the work package attribute. If you opt for „Use the work package status", the Progress % field is chosen based on the [status of a work package](../work-package-status). In this case a % done value is assigned to every status (for example, "tested" is assigned 80%), which is then adapted if the status changes.

5. **Default highlighting mode** (Enterprise add-on) defines which should be the default [attribute highlighting](../../../user-guide/work-packages/work-package-table-configuration/#attribute-highlighting-enterprise-add-on) mode, e.g. to highlight the following criteria in the work package table. This setting is only available for Enterprise on-premises and Enterprise cloud users.

   ![default highlighting mode](openproject_system_guide_default_highlighting_mode.png)

6. Customize the appearance of the work package tables to **define which work package attributes are displayed in the work package tables by default**.

Do not forget to save your changes with the blue **Save** button at the bottom.

![work-package-settings-administration](openproject_system_guide_work_package_settings.png)
