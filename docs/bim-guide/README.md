---
sidebar_navigation:
  title: BIM Guide
  priority: 975
description: User guide for the OpenProject BIM Edition.
robots: index, follow
keywords: BIM user guide
---
# BIM user guide

Welcome to the OpenProject user guide for Building Information Modeling (BIM) with OpenProject.

On top of the general project management functionalities, OpenProject BIM enables construction teams to better plan, communicate and collaborate in their building projects. OpenProject BIM includes a 3D model viewer (IFC viewer), support of the BIM collaboration format (BCF) for BIM issue management, and much more powerful features, e.g. a [Revit integration](revit-add-in).

<div class="alert alert-info" role="alert">

**Note**: This guide only covers the specific [BIM features and functionalities of OpenProject](https://www.openproject.org/bim-project-management/). To learn more about the core features for project management of OpenProject (which are included in the BIM Edition as well), please visit our [User Guide](../user-guide/).

</div>

![BIM Project Management](demo_project_teaser_bim.jpg)



## Overview of all topics regarding the OpenProject BIM Edition

OpenProject BIM Edition provides powerful features particular designed for the needs of construction industry. Please choose the topic you want to learn more about.

## IFC Viewer

Upload your IFC building models and show them directly in the internet browser, without any additional software.

Details: [IFC-Viewer](ifc-viewer)



## BIM Issue Management

Create tasks directly connected to your building model, import tasks or export tasks from any other BIM application.

Deails: [BIM Issue Management](bim-issue-management)



## Revit Addin

Stay always connected to OpenProject in realtime, show and create tasks while you're working in the Revit, using the Revit Addin.

Details: [Revit Add-in](revit-add-in)



## How to get a free trial?

You easily can start a new BIM trial on our [OpenProject BIM website](https://www.openproject.org/bim-project-management/). The have a look at the full description of how to start a new trial installation just follow the Link: [Create trial installation](../enterprise-guide/enterprise-cloud-guide/create-cloud-trial/).



## How to enable the BCF module?

The BCF Module and the included IFC viewer can be enabled for every single project. Here you can find the description how to [enable a module](../user-guide/projects/project-settings/modules/) within your ***project settings***.



## Reporting bugs

You found a bug? Please [report it](../development/report-a-bug) to our [OpenProject community](https://community.openproject.com/projects/revit-add-in). Thank you!



## BIM FAQs



### Can OpenProject features be used within the OpenProject BIM Edition?

Yes, you are able to use all known features. Within our BIM Edition you get the full functionality and additionally some features only for the building industry.



### Is it possible to switch my existing OpenProject Installation to the BIM Edition?

Yes, an existing OpenProject on-premises (self-hosted) installation can easily be switched to the BIM Edition without losing your settings and projects.

In our [Installation & Upgrade Guide](../installation-and-operations/changing-to-bim-edition) you can find a description how to switch.



### Is OpenProject BIM compatible to other BIM Software?

Yes of course. We are of the opinion that the full potential of the BIM method only works through collaboration and the exchange of information (openBIM). For this reason we support the open BCF XML Standard. You are able to import and export all created BCF and stay interoparable with any other BCF software.



### Why do I need a Revit Add-In?

You don't need it, but it makes your BIM Issue Management much easier. The *OpenProject Revit Add-In* allows you to use the open source project management software *OpenProject BIM* directly within your Autodesk Revit environment. It lets you create, inspect and manage issues right in the moment when you can also solve them - when you have your Revit application fired up and the relevant BIM models open. Issues get stored as BIM Issues centrally and are available to every team member in real time - thanks to our browser based IFC viewer even to those team members without expensive Revit licenses. No BCF XML import/export is needed. However, you still can import and export BCF XML as you like and stay interoparable with any other BCF software.



### Are there any System Requirements for the Revit Add-In?

The OpenProject Revit Add-In does not have any special system requirements. Only a supported [version of Autodesk Revit](./revit-add-in/#system-requirements) must be installed. 



### Which versions of Revit are supported?

The OpenProject BIM Addin for Revit supports the following versions:

- REVIT 2019 
- REVIT 2020 
- REVIT 2021



### Is it possible to use OpenProject BIM without REVIT?

Yes! The Revit Add-In is just additional to the OpenProject BIM core functionality. It's still possible to import and export BCF XML as you like and stay interoparable with any other Software for BIM Issue Management.



### Are integrations with other BIM software planned?

Yes, we want to develop some other integrations to stay interoparable with other BIM software and make BIM Issue Management with OpenProject BIM much easier.



### How to enable the BCF module?

The BCF Module and the included IFC viewer can be enabled or disabled for every single project. Here you can find the description how to [enable a module](../user-guide/projects/project-settings/modules/) within the project settings. 

*The BCF Module is an OpenProject BIM Premium function. Please make sure, that you are already using the OpenProject BIM Edition ([switch to the BIM Edition](../installation-and-operations/changing-to-bim-edition))*

 

### Why can't I see a building model?

There are many potential reasons why you can't see your building model. Please check out the most common reasons and their solution:

- BCF Module could be disabled ([How to enable a module](../user-guide/projects/project-settings/modules/))
- Building model is hidden in Model hierarchy (check within the [IFC Model Tree](ifc-viewer/#show-or-hide-models-or-elements-via-model-tree))
- Building model is completely sliced ([clear all slices](ifc-viewer/#how-to-slice-the-building-model) within the model viewer toolbar)
- IFC file isn't uploaded yet or is invalid (please check the status of the uploaded file within the [IFC Model management area](ifc-viewer/#import-and-export-ifc-models)).
- IFC file does not have any geometry (please check if your IFC file has some geometry)



### Where to find the Version of my Revit AddIn?

To see which version of the Revit AddIn you are currently using, navigate to the OpenProject tab in the Revit taskbar and open the settings. Here you can see which version you are currently using.

