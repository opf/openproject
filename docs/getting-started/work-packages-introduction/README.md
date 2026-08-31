---
sidebar_navigation:
  title: Work packages introduction
  priority: 700
description: Introduction to work packages in OpenProject.
keywords: work packages introduction, attributes, values, task
---

# Introduction to Work Packages

In this document you will get a first introduction to work packages. You will find out how to create and update work packages in a project.

For further documentation, please visit our [user guide for work packages](../../user-guide/work-packages).

| Topic                                                         | Content                                                   |
|---------------------------------------------------------------|-----------------------------------------------------------|
| [What is a work package?](#what-is-a-work-package)            | Find out what a work package in OpenProject is.           |
| [Create a new work package](#create-a-new-work-package)       | How to create a new work package in a project.            |
| [Open and edit a work package](#open-and-edit-a-work-package) | How to open and make changes to an existing work package. |
| [Activity of work packages](#activity-of-work-packages)       | See all changes in a work package.                        |

<video src="https://openproject-docs.s3.eu-central-1.amazonaws.com/videos/OpenProject-Work-Packages.mp4"></video>

## What is a work package?

A work package in OpenProject can basically be everything you need to keep track of within your projects. It can be e.g. a task, a feature, a bug, a risk, a milestone or a project phase. These different kinds of work packages are called **work package types**.

## Create a new work package

To get started, create a new work package in your project, [open the project](../projects/#open-an-existing-project) with the project dropdown menu and navigate to the **work packages module** in the project menu.

Within the work packages module, click the + Create button to create a new work package. In the drop down menu, choose which type of work package you want to create, e.g. a task or a milestone. 

![Create button to create a new work package in OpenProject](openproject_getting_started_work_packages_create_new_work_package_button.png)

A split screen view is opened with the new work package form on the right and the table listing already existing work packages on the left.

If there are not yet any work packages in the project, you will see a message that there are no work packages to be displayed in the table.

In the empty form on the right, you can enter all relevant information for this work package, e.g. the subject and a description, set an assignee, a due date or any other field. The fields you can populate are called **work package attributes**. Also, you can add attachments with copy & paste or with drag and drop.

Click the **Save** button to create the work package.

![Split screen view showing a list of existing work packages on the left and the form to create a new work package on the right side](openproject_getting_started_work_packages_create_new_work_package_form.png)

The work package will then be displayed in the table on the left:

 ![Newly created work package is displayed in the work packages list in OpenProject](openproject_getting_started_work_packages_create_new_work_package_created_displayed.png)

Another option to create a work package is to do it from the header navigation. The [work package types](../../user-guide/projects/project-settings/work-packages/#work-package-types) that are activated, will be shown and you can select the relevant work package type to be created. Click the **+ (plus)** icon in the upper right corner and select the work package type.

![Plus icon in the header navigation of OpenProject, opened and showing work package types to create a new work package](openproject_getting_started_work_packages_create_new_work_package_header_navigation.png)

Once you click on the work package type that you want to create, the work package detail view will open, where you can **select the project** that you want to create the work package for.

![Create and name a new work package in OpenProject](openproject_getting_started_work_packages_create_new_work_package_header_navigation_form_opened.png)

Fill out work package attributes and click **Save** button to create a new work package.

## Open and edit a work package

To open and edit an existing work package from the table, select the work package which you want to edit and click on the **open details view** icon in the work package table or on top of it to open the split screen view. Other ways to open it would be to double-click on the work package or to click on the work package ID.

!["I" icon to open a detailed view of a work package in OpenProject](openproject_getting_started_work_packages_information_icon.png)

By clicking through the list on the left hand side you will see the details of each work package on the right in the split screen.

Click any of the fields to **update a work package**, e.g. description. Click the checkmark at the bottom of the input field to save changes.

![Update a work package in a split screen view in OpenProject](openproject_getting_started_work_packages_wp_detailed_view_edit.png)

To **update the status**, click on the highlighted displayed status on top of the form and select the new status from the dropdown.

![Work package status dropdown menu opened in a detailed work package view in OpenProject](openproject_getting_started_work_packages_update_status.png)

## Activity of work packages

To keep informed about all changes to a work package, open the _Activity_ tab in the details view.

Here you will see all changes which have been made to this work package.

You can also insert a comment at the end of the Activity list.

![Activity tab in a detailed view of a work package in OpenProject](openproject_getting_started_work_packages_activity_tab.png)

To notify other people about changes in your work packages activities, you can comment and type an **@** in front of the username you want to inform. When you publish your message, the person you have tagged will get a notification. The aggregation of changes in the Activity list can be configured in the [system administration](../../system-admin-guide/calendars-and-dates/#date-format).

To find out more about the work package functionalities, please visit our detailed [user guide for work packages](../../user-guide/work-packages).
