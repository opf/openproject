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

@Valentin: hier wäre der Hinweis gut, dass BIM Issue kein spezifischer Workpackagetyp ist, sondern, dass einbeliebiges Workpackage zu einem BIM Issue wird, indem per Viewer ein Viewpoint gesetzt wird. (generell ist die unterscheidung wichtig: BIM issue, BCF, viewpoint ==> evtl. mit grafik erklären wie beim ifc viewer)   

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

@Valentin: Hinweis, dass auch mehrere Viewpoint erstellt werden können 

*Within the viewpoint the current status of your building model is saved. So please check the view before - is there everything shown within the model viewer?*

![Add a viewpoint](add_a_viewpoint.png)





### Add a viewpoint to an existing work package

The workflow of adding a viewpoint to an existing work package is similar to creating a new BIM Issue. To switch an existing work package to a BIM Issue just follow the steps:



Open the **BCF-Module** to see the building Model.
 ![BCF Module](bcf_module.png)



Make sure the "Model Viewer & Maps" - View or "Model Viewer & Table" - View is selected within the **OpenProject-Toolbar**.

![Model and workpackage view](model_maps_view.png)



Now open the **work package Details** by double click on the work package ("my first work-package"). Now you are able to add a viewpoint like it is described above.


## BIM Issue Handling (Details View)

@Valentin: anhand des erstellen Issues: Handling eines BIM Issues

* Detailsansicht
* Jump to Viewpoint
* Hinweis auf Konfiguration+ Hinweis, dass ansonsten alles wie bei der Core Anwendung ist, bspw. auch Konfiguration von Attributen


### Details




### Jump to Viewpoint in the viewer



If the Model viewer isn't shown yet, open the Detail - view of the BIM Issue and follow the Cube symol of the preview. Now the model viewer opens and the viewpoint of the BIM Issue will be displayed.

![Display BIM Issue](display_bim_issue.png)



@Valentin: zeigen, wie man zwischen denen viewpoints wechselt



### @Valentin: Hinweis auf Konfiguration

@Valentin: unter dieser Überschrift nochmal aufgreifen, dass BIM Issue kein WP typ ist. Die konfiguration hängt am WP Typ. (und damit auch die Konfiguration) ==> ansonsten erfolgt alles wie bei der core anwendung




## View and Find BIM Issues (Cards and List View)

### Overview

@Valentin ==> zeigen wie man oben rechts zwischen den ansichten wechseln kann






### Viewer and Cards

@Valentin: wichtig ist in jeder ansicht:

* wie komme ich zu den details? (doppelklick, klick auf # oder i)
* wie zeige ich den viewpoint an? (klick aufs bild)



### Cards

@Valentin: wichtig ist in jeder ansicht:

* wie komme ich zu den details? (doppelklick, klick auf # oder i)
* wie zeige ich den viewpoint an? (detailansicht ==> dann cube)




### Viewer and Table

@Valentin: wichtig ist in jeder ansicht:

* wie komme ich zu den details? (doppelklick, klick auf #)
* wie zeige ich den viewpoint an? (wechselt automatisch)




### Table

@Valentin: wichtig ist in jeder ansicht:

* wie komme ich zu den details? (doppelklick, klick auf # oder i)
* wie zeige ich den viewpoint an? (detailansicht ==> dann cube)






## Filter BIM Issues

@Valentin: erwähnen, dass in jeder View ähnlich (auch verweis auf Core anwendung) ==> würde es am beispiel viewer + card view zeigen




## BIM Issues in Workpackage Module

@Valentin: hier gehts darum, dass die BIM issues auch im workpackage module auftauchen können ==> wie unterscheidet man sie (fltern nach BCF snapshot)




## Import and Export BCF Issues using BCF

Within the BCF module you are able to upload BIM Issues (BCF) which are created within other software and download already existing files to manage them within other BIM project management solutions. Just Click on the ***"Import"-Button*** or ***"Export"-Button*** within the OpenProject Toolbar. 

@valentin: wichtig ist vor allem übersicht: welche attribute werden synchronisiert?

* Personen (autor, verantwortlich)
* comments
* status
* wieland fragen was noch alles

@Valentin: hier dann mal wirklich ein beispiel durchmachen (vor allem import, da es dabei auch zu mapping themen kommt) ==> hast du solibri? wenn nein, besorgs dir mal und generier darin ein paar bcfs :)

@Valentin: dasselbe gilt für den export (nur eben schmalen)

==> am besten schön mit teilüberschriften






