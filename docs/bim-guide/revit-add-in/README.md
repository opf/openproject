---
sidebar_navigation:
  title: Revit Add-in
  priority: 700
description: How to get started with the OpenProject BIM Revit Add-in.
robots: index, follow
keywords: BIM, Revit, BCF, IFC
---

# Revit Add-In (BIM feature)

The *OpenProject Revit Add-In* allows you to use the open source project management software *OpenProject BIM* directly within your Autodesk Revit environment. It lets you create, inspect and manage issues right in the moment when you can also solve them - when you have your Revit application fired up and the relevant BIM models open. Issues get stored as BCFs centrally and are available to every team member in real time - thanks to our browser based IFC viewer even to those team members without expensive Revit licenses. No BCF XML import/export is needed. However, you still can import and export BCF XML as you like and stay interoparable with any other BCF software.

To download the latest version of our OpenProject Revit AddIn click here: [DOWNLOAD](https://github.com/opf/openproject-revit-add-in/releases/download/v2.3.3/OpenProject.Revit.exe)



<div class="alert alert-info" role="alert">
**Note**: OpenProject BIM & BCF Management is a Premium Feature and can only be used with [Enterprise cloud](../../enterprise-guide/enterprise-cloud-guide/) or [Enterprise on-premises](../../enterprise-guide/enterprise-on-premises-guide/). An upgrade from the free Community Edition is easily possible.
</div>


| Topic                                   | Content                                   |
| --------------------------------------- | ----------------------------------------- |
| [How to install?](#how-to-install)      | How to install the Revit Add-In?          |
| [How to update?](#how-to-update)        | How to get the latest Version?            |
| [How to uninstall?](#how-to-uninstall?) | How to uninstall Revit Add-In?            |
| [Troubleshooting](#troubleshooting)     | Troubleshooting of Windows' Error Message |
| [Reporting Bugs](#reporting-bugs)       | How to report a bug.                      |



## How to login?

## How to select a Project

## How to Create a new BCF

## How to open a BCF

## How to Edit a BCF

## How to Edit a BCF

## Synchronize Revit with OpenProject

## How to export BCF XML

## How to import BCF XML







## How to install?

### System Requirements

The **OpenProject Revit AddIn** does not have any special system requirements. Autodesk Revit must be installed. The following versions of Revit are supported:

- 2019
- 2020
- 2021



### Download the Installer

To download the setup application for the **OpenProject Revit AddIn**, click here: [DOWNLOAD](https://github.com/opf/openproject-revit-add-in/releases/download/v2.3.3/OpenProject.Revit.exe)

You can find the latest version of our AddIn on [Github](https://github.com/opf/openproject-revit-add-in/releases/latest) as well.



### Installation 

After you have downloaded the file, please run it to start the installation process.

1. **Start Installation process**
   In the first screen, click *Next* to continue: 

<img src="https://github.com/opf/openproject-revit-add-in/raw/master/docs/images/installation-step-01.png" alt="Installation Step 01" style="zoom:80%;" />



2. **Select Revit Version**

   Next, select the Revit version you have installed locally and click *Next* to continue. You can select multiple versions:

![Installation Step 02](https://github.com/opf/openproject-revit-add-in/raw/master/docs/images/installation-step-02.png)



3. **Start Installation**

   Verify the installation steps are correct in the next screen and click on *Install* to install the **OpenProject Revit AddIn**:

![Installation Step 03](https://github.com/opf/openproject-revit-add-in/raw/master/docs/images/installation-step-03.png)



4. **Ready to use**

   Please wait a few moments for the installation to complete and then click *Finish* to finish the installation.



## How to update from an Earlier Version?

If you already have an earlier version installed, simply follow the same steps as for a new installation ([How to install?](#how-to-install)). The existing **OpenProject Revit AddIn** will be updated.



## How to uninstall the OpenProject Revit AddIn?

To remove the **OpenProject Revit AddIn** remove the AddIn like any other AddIn from Revit. First close any running instance of Revit. Then you'll have to enter the directory `C:\ProgramData\Autodesk\Revit\Addins\<REVIT_VERSION>`. There you must delete the file `OpenProject.Revit.addin` and the folder `OpenProject.Revit`. After a restart of Revit, the **OpenProject Revit AddIn** is no longer available.



## Troubleshooting

### 'Your computer was protected by Windows' Error Message

This is an internal Windows defense mechanism called *Windows SmartScreen*. When you run the installer, you might see a message similar to this:

<img src="https://github.com/opf/openproject-revit-add-in/raw/master/docs/images/installer-smart-screen-01.png" alt="Installer Windows SmartScreen 01" style="zoom:80%;" />



This can happen when a new release was not yet installed by many users, so internal Microsoft services do not yet know about the trustworthiness of the **OpenProject Revit AddIn** version.

To continue, please click on the highlighted part labeled *Additional Information*, then you should see a screen like the following:

<img src="https://github.com/opf/openproject-revit-add-in/raw/master/docs/images/installer-smart-screen-02.png" alt="Installer Windows SmartScreen 02" style="zoom:80%;" />



Ensure that publisher says *OpenProject GmbH*. That means the installer was correctly signed by OpenProject and is safe to use.

To proceed with the installation, click on *Run Anyway* and the installation will start.



## Reporting bugs

You found a bug? Please [report it](https://docs.openproject.org/development/report-a-bug) to our [OpenProject community](https://community.openproject.com/projects/revit-add-in). Thank you!
