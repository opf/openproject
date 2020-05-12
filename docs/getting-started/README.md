---
sidebar_navigation:
  title: Getting started
  priority: 999
description: OpenProject getting started guide.
robots: index, follow
keywords: getting started guide
---

# Getting started guide

Welcome to the OpenProject **Getting started guide**.

Here you will learn about the **first steps with OpenProject**. If you need more detailed explanations of all features, please visit the respective section in our [user guide](../user-guide/).

## Overview

| Popular Topics                                          | Description                                                  |
| ------------------------------------------------------- | :----------------------------------------------------------- |
| [Introduction to OpenProject](openproject-introduction) | Get an introduction about project management with OpenProject. |
| [Sign in and registration](sign-in-registration)        | Find out how you can register and sign in to OpenProject.    |
| [Create a project](projects)                            | How to create and set up a new project?                      |
| [Invite team members](invite-members)                   | How to invite new members?                                   |
| [Work packages](work-packages-introduction)             | Learn how to create and edit work packages.                  |
| [Gantt chart](gantt-chart-introduction)                 | Find out how to create a project plan.                       |
| [Boards](boards-introduction)                           | How to work with Agile Boards?                               |
| [My account](my-account)                                | How to configure My Account?                                 |
| [My page](my-page)                                      | Find out more about a personal My page dashboard.            |

## 5 steps to get started

Watch a short 3-minute introduction video to get started with OpenProject in 5 easy steps:

1. Create a project
2. Add team members
3. Create work packages
4. Create a project plan
5. Filter, group and create reports

<iframe width="560" height="315" src="https://www.youtube.com/embed/Fk4papnAzMw" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
## OpenProject product demo video

Watch a **comprehensive OpenProject product introduction** video to learn how to work with OpenProject using traditional and agile project management. 

<iframe width="560" height="315" src="https://www.youtube.com/embed/ebc3lcSmncA" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>



## Frequently asked questions - FAQ

### Is OpenProject free of charge?

We offer three different versions of OpenProject. Please get an overview of the different OpenProject Editions [here](https://www.openproject.org/pricing/). The (on-premise) OpenProject Community Edition is completely free. The Cloud and Enterprise Edition offer premium features, hosting and support and thus we are charging for it. Nevertheless, we offer free 14 days trials for the Enterprise and Cloud versions so that you can get to know their benefits. If you prefer to use the free OpenProject Community Edition, you can follow these [installation instructions](https://www.openproject.org/download-and-installation/), please note that you need a Linux server to install the Community Edition. It is always possible to upgrade from the Community to the Cloud and Enterprise Edition – check out the premium features [here](https://www.openproject.org/enterprise-edition/).

### How do I get access to the OpenProject premium features?

We offer the premium functions of OpenProject (incl. boards) for two different OpenProject variants:
* For the OpenProject Cloud Edition (hosted by us),
* For the self-hosted (on-premise) OpenProject Enterprise Edition

If you want to run OpenProject on your own server the OpenProject Enterprise Edition is the right option.
Have you already installed the [OpenProject Community Edition](https://www.openproject.org/download-and-installation/)? If yes, you can request a trial license for the OpenProject Enterprise Edition by clicking on the button ["Free trial license"](https://www.openproject.org/de/enterprise-edition/) and test the Enterprise Edition for 14 days for free.


### Is it possible that we can have a board over all OpenProject tasks and Users?

Yes, to achieve the desired result you can navigate to the main project and on the Kanban view add the filter "subproject" "all". This will display the work packages in the main project and all subprojects.



### **Are there extra fees to pay, in terms of installing the** **OpenProject** **software?****Is it possible to adapt or rename the status list?

Yes, this is absolutely possible. To do this, you would first have to create new statuses: https://docs.openproject.org/system-admin-guide/manage-work-packages/work-package-status/In the second step you can then assign them to workflows:[ https://docs.openproject.org/system-admin-guide/manage-work-packages/work-package-workflows/](https://docs.openproject.org/system-admin-guide/manage-work-packages/work-package-workflows/) 



### How can I migrate MySQL to PostgreSQL in OpenProject?

We have prepared a guide for the migration of MySQL to PostgreSQL:https://docs.openproject.org/installation-and-operations/misc/packaged-postgresql-migration/If you are experiencing difficulties in following this guide, we could use a temporary remote SSH access to your servers to perform the migration for you, or you provide us with the dump of the MySQL database and will be returned a migrated PostgreSQL dump. 



### How can I activate Boards in OpenProject?

**The boards module is a feature of the enterprise edition. You can upgrade your installation by entering a valid subscription token in the application administration. You can purchase the token on our website:-> [openproject.org/enterprise-edition](https://www.openproject.org/enterprise-edition)

Additionally you need to activate the boards module in the project settings. 



### What is the best way to maintain an overview of multiple projects in** **OpenProject****? Is it possible to create a dashboard that shows all the projects you are responsible for at once?

You can click on "Select a project" on the upper left side and then choose "View all projects" to get an overview of all projects. You can also apply filters to filter e.g. by projects for which you are set as the responsible. If you want to see the individual work packages in the projects, you can click on the module icon (the icon with the 9 squares) in the upper right side and choose "Work packages" from the dropdown menu. This shows all work packages across all projects you have access to. You can then click on the "Project" column header and select "Group by" to group by project. Additionally, you can then filter based on the project and e.g. only display certain projects. 



### How do I prepare a budget in** **OpenProject****?

**Budgets are currently limited to a single project. They cannot be shared across multiple projects.This means that you would have to set up a separate budget for the different main and sub projects.You can however use cost reports to analyze the time (and cost) spent across multiple projects. For details, you can take a look at our user guide: https://www.openproject.org/help/time-costs/time-costs-reports-cost-report-plugin/. 



### Is it possible to create a PDF export for the overview of the work packages with Gantt chart?

The export is available via the browser print function (ideally Google Chrome). 



### We like for each Department to have their own custom "Status" with different values options in OpenProject. How do we do this?**

The status which can be selected by users (based on the workflow) is always determined based on the work package type and the role of the user. In order to use the same work package type (e.g. Task) but display different status for each department, you would need to create a separate role for each department. You can then add the members of a department (ideally using a group) and assign them with the correct role.https://docs.openproject.org/system-admin-guide/manage-work-packages/work-package-workflows/#edit-workflowsTo work with different status, first create those status in “Administration” > “Work packages” > “Status”.

Next, go to “Administration” > “Work packages” > “Workflow” and select the combination of Type and Role for which you would like to set the allowed workflow transition.You can e.g. create a role “Marketing – Member” and select it as well as the type (e.g. “Task”). Make sure to uncheck the option “Only display statuses that are used by this type” and click on “Edit”. Now, you can select the correct status transitions.Repeat this step for the other (department) roles (e.g. “IT – Member”) and select the desired status transitions. This way, you can set different status for each department (only the default status is shared (i.e. “New” by default)). Please keep in mind that it may not be possible for a member of a different department to update the status of a work package if it has been updated before by another department (since the workflow may not support this status transition).