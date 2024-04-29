---
sidebar_navigation:
  title: Revit add-in
  priority: 100
description: How to use the OpenProject BIM - Revit add-in.
keywords: BIM, BCF, IFC, Viewer
---

# Revit add-in (BIM feature)

The *OpenProject Revit Add-In* allows you to use the open source project management software *OpenProject BIM* directly within your Autodesk Revit environment. It lets you create, inspect and manage issues right in the moment when you can also solve them - when you have your Revit application fired up and the relevant BIM models open. Issues get stored as BIM Issues centrally and are available to every team member in real time - thanks to our browser based IFC viewer even to those team members without expensive Revit licenses. No BCF XML import/export is needed. However, you still can import and export BCF XML as you like and stay interoperable with any other software for BIM Issue Management.

To download the latest version (v2.2.3) of our OpenProject Revit AddIn click here: [DOWNLOAD](https://github.com/opf/openproject-revit-add-in/releases/download/v2.3.3/OpenProject.Revit.exe)

> **Note**: OpenProject BIM Issue Management is an Enterprise add-on and can only be used with [Enterprise cloud](../../enterprise-guide/enterprise-cloud-guide/) or [Enterprise on-premises](../../enterprise-guide/enterprise-on-premises-guide/). An upgrade from the free Community edition is easily possible.

## Before usage

Please check the following steps before using the OpenProject BIM edition.

1. Does OpenProject BIM support your [Version of Revit](#system-requirements)?
2. Did you already install the latest Version of our OpenProject BIM Add-in?
3. Is the latest IFC Model uploaded to your Project in OpenProject BIM?

If you can answer all questions with "yes" you are ready to start using our Revit Add-in.

## How to install

### System requirements

The **OpenProject Revit AddIn** does not have any special system requirements. Autodesk Revit must be installed. The following versions of Revit are supported:

- 2019
- 2020
- 2021
- 2022

### Download the installer

To download the setup application for the **OpenProject Revit AddIn**, click here: [DOWNLOAD](https://github.com/opf/openproject-revit-add-in/releases/download/v2.3.3/OpenProject.Revit.exe)

You can find the latest version of our AddIn on [Github](https://github.com/opf/openproject-revit-add-in/releases/latest) as well.

### Installation

After you have downloaded the file, please run it to start the installation process.

1. **Start Installation process**
   In the first screen, click *Next* to continue:

![Installation Step 1](installation-step-01.png)

2. **Select Revit Version**

   Next, select the Revit version you have installed locally and click *Next* to continue. You can select multiple versions:

![Installation Step 02](installation-step-02.png)

3. **Start Installation**

   Verify the installation steps are correct in the next screen and click on *Install* to install the **OpenProject Revit AddIn**:

![Installation Step 03](installation-step-03.png)

4. **Ready to use**

   Please wait a few moments for the installation to complete and then click *Finish* to finish the installation.

## How to update from an earlier version

If you already have an earlier version installed, simply follow the same steps as for a new installation ([How to install](#how-to-install)). The existing **OpenProject Revit AddIn** will be updated.

## How to login

After Installing the OpenProject BIM AddIn you can find a new tab within the Revit taskbar named "OpenProject". To login you have to open the **settings** first.

![Revit AddIn Settings](RevitAddIn_Settings.png)

The settings will appear in a new tab. Within this tab you have to insert your own ***OpenProject BIM URL*** and confirm with "Go". Your OpenProject account is now linked to your Revit application and you can close the tab.

![OpenProject BIM Login](OpenProject_BIM_Login.png)

## How to select a project

After connecting your OpenProject BIM instance you are able to start working with your BCF Tasks within Revit. Firstly you have to open the **OpenProject Tab** in the taskbar and start the application.

![Start OpenProject BIM Add-in](OpenProject_BIM_Start.png)

After starting the application a new tab will be created and you are able to select the Project you want to work in.  

![OpenProject BIM - Select a Project](OpenProject_BIM_Projects.png)

## Working with BIM issues

To work with BIM Issues, please open our AddIn and navigate to our BCF Module.

![OpenProject BIM - BCF Module](OpenProject_BIM_BCF_Module.png)

Within this module all existing work packages are displayed. Within this demo project no work package exist yet. To create a new one, click on the "add new work package"-Button.  

![OpenProject BIM - Create BCF](OpenProject_BIM_Create_BCF.png)

An empty form for new work packages is now displayed. After adding a title and detailed information describing your issue, you have to add a viewpoint. This viewpoint saves your current view & selection of the building model (so check the rotation, selection and zoom of the model before).

And the most important thing: **don't forget to save** the work package.

![OpenProject BIM - Add Viewpoint](OpenProject_BIM_Add_Viewpoint.png)

To open a BIM Issue and restore the viewpoint you have to navigate to the BCF Module and just click on the BIM Issue you want to open. The behavior of working with the issues is almost the same like in OpenProject.

![OpenProject BIM - Issues](OpenProject_BIM_Issues.png)

The handling of BIM Issues within Revit is similar to OpenProject BIM. There are only a few changes to the browser based version:

- **Model Viewer**: To show a BIM Issue OpenProject BIM will use your Revit Model instead of the OpenProject BIM Model Viewer.
- **Reduced View**: OpenProject BIM is now used in a smaller window. That's why you are currently using a reduced view.
- **Missing Browser Toolbar**: The Browser Toolbar is missing, so you might miss some common user actions (e.g. jump to previous page)

## Synchronize tasks between Revit and OpenProject

OpenProject BIM and Revit automatically synchronize all BIM work packages. You don't have to pay attention to anything else and you can manage your entire project directly in OpenProject. Whatever you do, users of OpenProject BIM edition will see any changes in the browser as well.  

![OpenProject BIM - Synchronization](OpenProject_BIM_Synchronization.png)

## How to uninstall the OpenProject Revit add-in

To remove the **OpenProject Revit AddIn** remove the AddIn like any other AddIn from Revit. First close any running instance of Revit. Then you'll have to enter the directory `C:\ProgramData\Autodesk\Revit\Addins\<REVIT_VERSION>`. There you must delete the file `OpenProject.Revit.addin` and the folder `OpenProject.Revit`. After a restart of Revit, the **OpenProject Revit AddIn** is no longer available.

## Troubleshooting

### 'Your computer was protected by Windows' Error Message

This is an internal Windows defense mechanism called *Windows SmartScreen*. When you run the installer, you might see a message similar to this:

![Installer Windows SmartScreen 1](installer-smart-screen-01.png)

This can happen when a new release was not yet installed by many users, so internal Microsoft services do not yet know about the trustworthiness of the **OpenProject Revit AddIn** version.

To continue, please click on the highlighted part labeled *Additional Information*, then you should see a screen like the following:

![Installer Windows SmartScreen 2](installer-smart-screen-02.png)

Ensure that publisher says *OpenProject GmbH*. That means the installer was correctly signed by OpenProject and is safe to use.

To proceed with the installation, click on *Run Anyway* and the installation will start.

## Reporting bugs

You found a bug? Please [report it](../../development/report-a-bug) to our [OpenProject community](https://community.openproject.org/projects/revit-add-in). Thank you!
