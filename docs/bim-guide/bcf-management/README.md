---
sidebar_navigation:
  title: Revit Add-in
  priority: 800
description: How to use OpenProject BIM Issue Management (BCF).
robots: index, follow
keywords: BIM, BCF, IFC, BCF-Management
---

# BIM Issue - Management (BIM feature)

Within the *BCF-Module* you are able to manage *BIM Issues (BCF)*. All BIM Iccues get stored as BCFs centrally and are available to every team member in real time. Below you find the most important features how to use the BCF Module to create, inspect and manage issues. 



| Topic                                                        | Content                                                   |
| ------------------------------------------------------------ | --------------------------------------------------------- |
| [What is a BIM Issue?](#what-is-a-bim-issue?)                | Find out what a BIM Issue in OpenProject BIM is.          |
| [Create a BIM Issue](#Create-a-bim-issue)                    | How to create a new BIM Issue in a project?               |
| [Open and edit a BIM Issue](#open-and-edit-a-bim-issue)      | How to open and make changes to an existing work package? |
| [Import and Export BIM Issues](#import-and-export-bim-issues) | How to Import and Export BIM Issues?                      |



## What is a BIM Issue?

A BIM Issue (BCF) is a special kind of work package to communicate directly wihtin the building model. It supports you to solve problems and coordinate the planning phase in a building project.

The BCF is not only a description of a problem, the view of the building model is stored within the issue as well. This includes the current selection, view , rotation & zoom of the model.

OpenProject BIM supports the standard of the ***BIM Collaboration Format (BCF)***. All Issues which are created within another *Open BIM* Software can be imported to work with this issue within our project management solution. 



## Create a BIM Issue

There are two ways to create new BIM Issue:

- [Create a new BIM Issue](#create-a-new-bim-issue) within the building model
- Add a viewpoint to an existing work package

BCF-Issues always belong to a project and a building model. Therefore, you first need to [select a project](https://www.openproject.org/docs/getting-started/projects/#open-an-existing-project) and upload an IFC file to see the building .

Then, navigate to the BCF module in the project navigation.



![BCF-Module](OpenProject_BCF_Module.png)



### Create a new BIM Issue

To create new BIM Issues, you have to open the Model - Viewer first and create the view you want to save within the BIM Issue (e.g. zoom, [rotate](...\ifc-viewer\#how-to-rotate-the-building-model?), [slice](...\ifc-viewer\#how-to-slice-the-building-model?), [select](...\ifc-viewer\#how-to-select-elements?), [hide](...\ifc-viewer\#show-or-hide-elements-or-models), ... ). 

Click on the **+ Create new work package** and select the type of workpackage you want. 

![Create a new BIM Issue](create-a-new-BIM-issue.png)



Now you can see a detail view of the new BIM Issue. Describe all necessary information to work on that task and add a viewpoint by clicking on the **"+ Viewpoint"**-Button. Now the current Viewpoint of the Building Model is added to the BIM Issue (BCF). After saveing your new BIM issue is created.

*Within the viewpoint the current status of your building model is saved. So please check the view before - is there everything shown within the model viewer?*

![Add a viewpoint](add_a_viewpoint.png)





### Add a viewpoint to an existing work package

The workflow of adding a viewpoint to an existing work package is similar to creating a new BIM Issue. To switch an existing work package to a BIM Issue just follow the steps:



Open the **BCF-Module** to see the building Model.
 ![BCF Module](bcf_module.png)



Make sure the "Model Viewer & Maps" - View or "Model Viewer & Table" - View is selected within the **OpenProject-Toolbar**.

![Model and workpackage view](model_maps_view.png)



Now open the **work package Details** by double click on the work package ("my first work-package"). Now you are able to add a viewpoint like it is described aboce.





## Open and edit a BIM Issue

To open and edit a BIM issue, you are able to ***double click on the BCF*** if the model viewer is already shown (e.g. "Model Viewer & Cards" - View).

If the Model viewer isn't shown yet, open the Detail - view of the BIM Issue and follow the Cube symol of the preview. Now the model viewer opens and the viewpoint of the BIM Issue will be displayed.

![Display BIM Issue](display_bim_issue.png)





## Import and Export BCF Issues

Within the BCF module you are able to upload BIM Issues (BCF) which are created within other software and download already existing files to manage them within other BIM project management solutions. Just Click on the ***"Import"-Button*** or ***"Export"-Button*** within the OpenProject Toolbar. 

