---
title: OpenProject 10.4.1
sidebar_navigation:
    title: 10.4.1
release_version: 10.4.1
release_date: 2020-02-20
---
# Release notes OpenProject 10.4.0

| Release notes                                                | Description                                                  |
| ------------------------------------------------------------ | :----------------------------------------------------------- |
| [OpenProject 10.4.0](#openproject-10-4-0)                    | What is new for OpenProject 10.4.0?                          |
| [OpenProject 10.4 BIM Edition for construction project management](#openproject-10-4-bim-edition-for-construction-project-management) | What is new for the construction project management for the building industry in OpenProject 10.4.0? |

## OpenProject 10.4.0

We released OpenProject 10.4. The new release of the open source project management software contains a new time tracking widget for the My page which facilitates visualizing and logging time spent on your tasks. Additionally, cost reports can now be exported to Excel.

Cloud and Enterprise Edition users can now choose between the default OpenProject theme, a light theme and a dark theme. This provides a good starting point for further customization.

Read below to get a detailed overview of what is new in OpenProject 10.4.

### Spent time widget on My page

Tracking your own time is a lot easier with OpenProject 10.4. The release replaces the existing Spent time widget on your personal My page with a modern time tracking overview. You can now easily see your logged time in a comprehensive weekly calendar view.

The tasks you worked on are color-coded. Therefore, you see right away which tasks you spent the most time on in the current week. Viewing or changing your logged hours is also a lot easier - simply drag and drop the time block to the correct day to make a change.

![Spent time widget on My Page](https://www.openproject.org/wp-content/uploads/2020/02/Spent-time_My-page-1024x628.png)

### Export cost reports to Excel

Having the ability to export cost reports was one of the most requested features. With OpenProject 10.4 you can just that. From your cost report set the appropriate filters and export it as an Excel document.

The Excel spreadsheet lists the tracked time, cost, as well as the different cost types. This makes it very easy to perform further computations or to forward the data to someone else, e.g. your accounting department.

![Export cost report to Excel](https://www.openproject.org/wp-content/uploads/2020/02/Export-cost-report-1024x710.png)

### Light and dark theme for OpenProject (Premium feature)

Cloud and Enterprise Edition users can now easily customize the look and feel of their OpenProject environment by using a custom logo and adjusting the color theme. With OpenProject 10.4 this gets a lot easier - thanks to default themes. Simply choose between the OpenProject theme, the light theme and the dark theme.

These themes are optimized and fulfill accessibility requirements. You can further customize them by starting with one of the default themes and adjusting individual colors based on your needs.

![Light and dark theme](https://www.openproject.org/wp-content/uploads/2020/02/Default_theme-1024x722.png)

### Updated menus for project and system administration

The menus in the project and system administration are updated with OpenProject 10.4. Wherever possible the tab navigation has been replaced with sub menus.

The other tabs menus have been updated to a modern layout. Additionally, the email settings have moved out into their own menu item in the system administration.

![Layout project admin settings](https://www.openproject.org/wp-content/uploads/2020/02/Layout_Project-admin-settings-1024x483.png)

## OpenProject 10.4 BIM Edition for construction project management

What is new for the digital construction project management for the building industry in OpenProject?

OpenProject contains a new IFC file model viewer to integrate 3D models in the IFC format in OpenProject. You can now upload IFC files and display the building models directly in your browser in OpenProject - withIFC model upload and viewer

Import of 3D building models directly in your OpenProject application. The supported format is IFC files.

![OpenProject BIM upload IFC files](https://www.openproject.org/wp-content/uploads/2020/02/OpenProject-BIM_upload-IFC-model.png)

### Manage multiple IFC models in OpenProject

In OpenProject you can now manage multiple building models in IFC format in parallel. **Browse through multiple models at the same time** and selectively activate models such as architecture and heating, ventilation and air conditioning (HVAC). Set "default" models to be displayed.

![manage IFC models](https://www.openproject.org/wp-content/uploads/2020/02/OpenProject-BIM-manage-IFC-models.png)

![OpenProject BIM structural](https://www.openproject.org/wp-content/uploads/2020/02/OPenPoject-BIM_structural.png)

### IFC viewer integrated in OpenProject

OpenProject 10.4 supports to open 3D **models** **and** **visualize** **building** **models** directly in your browser. With this new integrated functionality for construction project management you can now easily **share** **multiple IFC** **files** with your team directly in OpenProject - integrated with all OpenProject functionalities for the project management along the entire building project life-cycle, i.e. BCF management, issue tracking, project planning, documentation.

View full 3D objects in OpenProject in IFC format. Select and display the model in total, for objects, classes and storeys for the building.

![IFC 3D viewer](https://www.openproject.org/wp-content/uploads/2020/02/OpenProject-BIM_IFC-viewer.png)

### **Switch between 3D and 2D view** for your building model in OpenProject.

You can change between a 3D view or 2D view of the building model in OpenProject.

![2D view IFC viewer](https://www.openproject.org/wp-content/uploads/2020/02/OPenPoject-BIM_2D.png)

### Slice objects to get exact view

You can slice 3D objects in all dimensions to get a view on the exact thing you need.

![OpenProject BIM - IFC slice objects](https://www.openproject.org/wp-content/uploads/2020/02/OpenProject-BIM_slice-objects.gif)



## Further improvements and bug fixes

Update bug fixes



## How to try the OpenProject BIM Edition?

Try out OpenProject BIM 10.4. right away, create a free trial instance for the [OpenProject BIM Edition.](https://start.openproject.com/go/bim)

 

## What is on the Roadmap?

We are continuously developing new features for OpenProject. For the upcoming BIM specific release we are focusing on more building industry specific features and integrations, i.e.

- Revit integration to OpenProject.
- Further advanced BCF management.



## Installation and Updates

To use OpenProject 10.4 right away, create an instance on [OpenProject.org.](https://start.openproject.com/)

Prefer to run OpenProject 10.4 in your own infrastructure?
Here you can find the [Installation guidelines](https://docs.openproject.org/installation-and-operations) for OpenProject.

Want to upgrade from a Community version to try out the light or dark theme? [Get a 14 days free trial token.](https://www.openproject.org/enterprise-edition/)

## Migrating to OpenProject 10.4

Follow the [upgrade guide for the packaged installation or Docker installation](https://docs.openproject.org/installation-and-operations/operation/upgrading/) to update your OpenProject installation to OpenProject 10.4.

We update hosted OpenProject environments (Cloud Edition) automatically.

## Support

You will find useful information in the OpenProject [FAQ]() or you can post your questions in the [Forum](https://community.openproject.org/projects/openproject/boards).

## Credits

Special thanks go to all OpenProject contributors without whom this release would not have been possible:

- All the developers, designers, project managers who have contributed to OpenProject.
- DBI AG for sponsoring the IFC module.
- Lindsay Kay with the integration of his open source 3D model viewer, [xeokit](https://xeokit.io/).
- [Georg Dangl](https://blog.dangl.me/categories/BIM) who contributes regarding BCF management.
- Every dedicated user who has [reported bugs](https://docs.openproject.org/development/report-a-bug/) and supported the community by asking and answering questions in the [forum](https://community.openproject.org/projects/openproject/boards).
- All the engaged users who provided translations on [CrowdIn](https://crowdin.com/projects/opf).