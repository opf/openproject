---
sidebar_navigation:
  title: Nextcloud integration
  priority: 900
description: Using the Nextcloud integration to link/unlink files and folders to work packages, viewing and downloading files and troubleshooting common errors
keywords: integration, apps, Nextcloud, user
---

# Nextcloud integration

You can use [Nextcloud](https://nextcloud.com) as an integrated file storage in OpenProject.

This integration makes it possible for you to:

- Link files and folders stored in Nextcloud with work packages in OpenProject
- View, open and download files and folders linked to a work package via the **Files** tab
- View all work packages linked to a file
- Create work packages directly in Nextcloud

Additionally you can:

- View OpenProject notifications via the Nextcloud dashboard

- Pick and preview links to work packages in Nextcloud
- Search for work packages using Nextcloud's search bar

It is also possible to automatically create dedicated [project folders](../../projects/project-settings/files/#project-folders), which makes documentation structure clearer and makes navigation more intuitive.

> [!NOTE]
> To be able to use Nextcloud as a file storage in your project, the administrator of your instance should first have completed the [Nextcloud integration setup](../../../system-admin-guide/integrations/nextcloud). 

| Topic                                                                                               | Description                                                                               |
|-----------------------------------------------------------------------------------------------------|:------------------------------------------------------------------------------------------|
| [Connect your OpenProject and Nextcloud accounts](#connect-your-openproject-and-nextcloud-accounts) | How to connect your Nextcloud and OpenProject accounts to be able to use this integration |
| [Link files and folders to work packages](#link-files-and-folders-to-work-packages)                 | How to link files and folders to work packages and view and download linked files         |
| [Unlink files and folders](#remove-links)                                                           | How to remove the link between a work package and a Nextcloud file or folder              |
| [Nextcloud dashboard](#nextcloud-dashboard)                                                         | How to keep an eye on your OpenProject notifications                                      |
| [Navigation and search in Nextcloud](#navigation-and-search-in-nextcloud)                           | How to search OpenProject work packages via the universal search bar                      |
| [Work package link preview in Nextcloud](#work-package-link-preview-in-nextcloud)                   | How to use the smart picker and see previews of work packages in text fields              |
| [Permissions and access control](#permissions-and-access-control)                                   | Who has access to linked files and who doesn't                                            |
| [Possible errors and troubleshooting](#possible-errors-and-troubleshooting)                         | Common errors and how to troubleshoot them                                                |

This video will give you a complete overview of how to set-up and work with the Nextcloud integration (English only):

![Nextcloud integration complete user guide and admin guide](https://openproject-docs.s3.eu-central-1.amazonaws.com/videos/OpenProject-NextCloud-integration.mp4)

## Connect your OpenProject and Nextcloud accounts

To begin using this integration, you will need to first connect your OpenProject and Nextcloud accounts. To do this, open any work package in a project where a Nextcloud file storage has been added and enabled by an administrator and follow these steps:

1. Go to the Files tab and, under the "Nextcloud" header, click on **Nextcloud login**.
   ![Nextcloud login](1_0_01-Files_Tab-Log_in_error.png)

2. You will see a Nextcloud screen asking you to log in before granting OpenProject access to your Nextcloud account. You will also see a security warning, but since you are indeed trying to connect the two accounts, you can safely ignore it. Click on **Log in** and enter your Nextcloud credentials.

   ![Nextcloud login step 2](login_nc_step2-1.png)

   ![Nextcloud login step 3](login_nc_step2-2.png)

3. Once you are logged in to Nextcloud, click on **Grant access** to confirm you want to give OpenProject access to your Nextcloud account.

   ![Nextcloud login step 4](login_nc_step3.png)

4. You will now will be redirected back to OpenProject, where you will also be asked to grant Nextcloud read and write access to your OpenProject account via the API. This is necessary for the integration to function. Click on **Authorize**.

   ![Nextcloud login step 5](login_nc_step4.png)

5. The one-time process to connect your two accounts is complete. You will now be directed back to the original work package, where you can view and open any Nextcloud files that are already linked, or start linking new ones.

> [!NOTE]
> To disconnect the link between your OpenProject and Nextcloud accounts, head on over to Nextcloud and navigate to _Settings → OpenProject_. There, click *Disconnect from OpenProject* button. To re-link the two accounts, simply follow [the above instructions](#connect-your-openproject-and-nextcloud-accounts) again.

## Link files and folders to work packages

### In OpenProject

This video will give you an overview of how to link existing files and upload new files from OpenProject to Nextcloud (English only):

![Upload and link files to Nextcloud from OpenProject](https://openproject-docs.s3.eu-central-1.amazonaws.com/videos/OpenProject-Nextcloud-files-upload.mp4)

In addition to listing files directly attached to a work package, the **Files** tab shows your Nextcloud files that are linked to the current work package. Hovering on any linked file with your mouse will give you options to  **open or download the file, show the containing folder in Nextcloud or remove the link**.

#### Link existing files

To link a Nextcloud file to the current work package, you can either:

- select a file from your computer, which will be uploaded to Nextcloud and linked to this work package
- select an existing file in Nextcloud to link to

![Link existing file in Nextcloud](link_existing_files.png)

> [!TIP]
> The default project that opens in the location picker is set by the project administrators in the [File storages settings](../../projects/project-settings/files/).

![Select a file to be linked in Nextcloud](nc_select_file_to_link.png)

#### Upload and link new files

If the file you want to link has not yet been uploaded to Nextcloud, you can do so by clicking on the **Upload files** link.

![Upload new files to Nextcloud](NC_12.5-uploadFilesLink.png)

You will then be prompted to select a file (or multiple files) on your computer that you want to upload to Nextcloud.

![Pick a file from your computer](NC_12.5-selctFileToUpload.png)

Alternatively, you can also simply drag a file or folder from your computer to the drag zone that will appear under the name of your Nextcloud file storage.

Once you have selected or dropped the files you would like to upload, you will need to select a folder on Nextcloud to which they should be stored.

> [!TIP]
> The default project that opens in the location picker is defined by the project administrators in the [File storages settings](../../projects/project-settings/files/).

![Select the destination folder on Nextcloud](NC_12.5-selectLocationToUploadTo.png)

You can click on folders you see to navigate to them. A helpful breadcrumb shows you where you are in the folder hierarchy.

To navigate one level up or to go back to the root, simply click on the relevant parent in the breadcrumb.

> [!TIP]
> If you have navigated particularly deep (over 4 levels), intermediate levels might be collapsed to save space, but you'll always be able to navigate back to the immediate parent or the root to go backwards.

To save the files you uploaded to the currently open folder, click on the **Choose location** button.

The selected file is uploaded to your Nextcloud instance and linked to the current work package. It appears under the name of the file storage.

![List of linked files](NC_12.5-fileIsNowLinked.png)

If a file has been deleted from a Nextcloud storage, it will still be visible under the **Files** tab for better transparency. However it will not be selectable. If you hover over a deleted file you will see the message indicating that the file could not be found.

![A file has been deleted in a Nextcloud file storage](nc-deleted-file.png)

#### Download, open folders and remove links

If you wish to unlink any linked file or folder, hover to it in the list of linked Files and click on the **Unlink** icon.

![Unlinking linked file in OpenProject](op_unlink_download_openfolder.png)

Respectively in order to download a file, hover over the  **Download** icon in the list of the linked files.

If you click the  **Folder** icon, the Nextcloud folder containing this file will open in a separate tab.

### In Nextcloud

This video will give you an overview how to link files and folder from Nextcloud to OpenProject (English only).

![OpenProject Nextcloud integration video](https://openproject-docs.s3.eu-central-1.amazonaws.com/videos/OpenProject-Nextcloud-Integration-2.mp4)

#### Link work packages

On the file or folder that you want to link to a work package, click on the *three dots → **Details**.*

![Open files details in Nextcloud](Nextcloud_open_file_details.png)

In the **Details** side panel, click on the **OpenProject** tab. This tab lets you link work packages in OpenProject to the current file, and will list all linked work packages. When nothing is yet linked, the list will be empty.

![Nextcloud no file relation defined](NC_0_00-FileNoRelation.png)

To link this file to a work package in OpenProject for the first time, use the search bar to find the correct work package (you can search either using a word in the title of the work package, or simply enter the work package ID) and click on it.

![Search work package in Nextcloud](NC_0_01-FileRelationSearch_new.png)

This linked file will then appear underneath the search bar. Doing so will also automatically add the file to the Files tab of the corresponding work package(s) in OpenProject.

![Show linked work packages in Nextcloud](NC_1_00-FileWPRelation_new.png)

#### Link multiple files to a work packages

You can also **link multiple files** to a single OpenProject work package. To do that, select the files you want to link, click the *Actions* menu and select the respective option.
![Select multiple files in Nextcloud to link to a single work package in OpenProject](nc_select_multiple_files.png)

A dialogue will open, allowing you to search for and then select an OpenProject work package to add all of the files to. The newly added files will become visible under the **Files** tab in the work package.

![Select an OpenProject work package in Nextcloud](nc_select_wp_to_link.png)

#### Create a new work package

You can create a new OpenProject work package directly from Nextcloud file storage. To do this, select the file you want to link, choose the **OpenProject** tab and click on **+ Create and link a work package**.
![Create a new OpenProject work package from Nextcloud](nc_create_new_wp.png)

A pop-up dialogue will open allowing you to specify the project, work package name and further details. Once you click **Create**, the new work package will be created in the specified project and the file will be linked to it.

![Specify details of a new OpenProject work package created in Nextcloud](nc-new-work-package-created.png)

#### Remove links

Once a work package is linked to a file, you can always unlink it by clicking on the **unlink** icon.

![Unlink work packages in Nextcloud](NC_1_01-FileWPActions.png)

You will be asked to confirm that you want to unlink. Click on **Remove link** to do so.

> [!NOTE]
> Unlinking a file or folder simply removes the connection with this work package; the original file or folder will _not_ be deleted or affected in any way. The only change is it will no longer appear in the Files tab on OpenProject, and the work package will no longer be listed in the "OpenProject" tab for that file on Nextcloud.

## Nextcloud dashboard

In addition to actions related to individual files, you can also choose to display the OpenProject widget on your Nextcloud dashboard in order to keep an eye on your OpenProject notifications.
![Add widget in Nextcloud](nc_widget_choice.png)

![OpenProject widget in Nextcloud dashboard](nc_widgets.png)

## Navigation and search in Nextcloud

There are two additional features related to the integration that you can enable in Nextcloud. In your personal settings page, under **OpenProject**, you will find these options:

- **Enable navigation link** displays a link to your OpenProject instance in the Nextcloud header
- **Enable unified search for tickets** allows you to search OpenProject work packages via the universal search bar in Nextcloud

![Nextcloud settings for OpenProject](nextcloud_openproject_account.png)

![Nextcloud search for work packages](nc_global_search.png)

## Work package link preview in Nextcloud

Starting with **OpenProject Nextcloud Integration App 2.4** a work package link preview will be shown if you use Nextcloud Talk or Text apps. Please note that you will need Nextcloud 26 or higher to be able to use this feature.

You can [copy a work package link](../../work-packages/duplicate-move-delete/#copy-link-to-clipboard) and paste it into a text field, e.g in  Nextcloud Talk or Nextcloud Collectives. Whenever you paste a a URL to a work package in a text field, a card for previewing the work  package will get rendered.

Alternatively you can use **/** to activate the **smart picker** and find the work package by searching.

![activate smart picker in nextcloud](nc_smartpicker_start.png)

![smart picker search in nextcloud](nc_smartpicker_search.png)

Once you have selected a work package to share in the talk or text app, a preview of this work package will be displayed.

![work package preview in nextcloud](nc_smartpicker_preview.png)

## Permissions and access control

When a Nextcloud file or folder is linked to a work package, an OpenProject user who has access to that work package will be able to:

- See the name of the linked file or folder
- See when it was last modified (or created, if it has not yet been modified)
- See who last modified it (or who created it, if it has not yet been modified)

However, all available actions depend on permissions the OpenProject user (or more precisely, the Nextcloud account tied to that user) has in Nextcloud. In other words, a user who does not have the permission to access the file in Nextcloud will also *not* be able to open, download, modify or unlink the file in OpenProject.

## Possible errors and troubleshooting

### No permission to see this file

If you are unable to see the details of a file or are unable to open some of the files linked to a work package, it could be related to your Nextcloud account not having the necessary permissions. In such a case, you will be able to see the name, time of last modification and the name of the modifier but you will not be able to perform any further actions. To open or access these files, please contact your Nextcloud administrator or the creator of the file so that they can grant you the necessary permissions.

![Permissions missing error](1_1_01-Not_all_files_available.png)

### User not logged in to Nextcloud

If you see the words "Login to Nextcloud" where you would normally see a list of linked files in the Files tab in OpenProject, it is because you have logged out of (or have been automatically logged out of) Nextcloud. Alternatively, you could be logged in with a different account than the one you set up to use with OpenProject.

In this case, you will still be able to see the list of linked files, but not perform any actions. To restore full functionality, simply log back in to your Nextcloud account.

![Login error in OpenProject](1_0_01-Log_in_error.png)

### Connection error

If you see the words "No Nextcloud connection" in the Files tab in OpenProject, your OpenProject instance is having trouble connecting to your Nextcloud instance. This could be due to a number of different reasons. Your best course of action is to get in touch with the administrator of your OpenProject and Nextcloud instances to identify and to resolve the issue.

![OpenProject connection error](1_0_02-Connection_broken.png)

### File fetching error

In rare occasions, it is possible for the integration to not be able to fetch all the details of all linked files. A simple page refresh should solve the issue. Should the error persist, please contact administrator of your OpenProject and Nextcloud instances.

![OpenProject file fetching error](1_0_03-Fetching_error.png)

### Project notifications are not displayed in Nextcloud

If OpenProject notifications are not properly displayed in Nextcloud, navigate to *Administration settings → Basic settings → Background jobs* and ensure that _Cron_ is selected.

![Nextcloud notifications not displayed](Cron_job_settings.png)
