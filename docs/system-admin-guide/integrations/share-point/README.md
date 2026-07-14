---
sidebar_navigation:
  title: SharePoint integration setup
  priority: 601
description: Set up SharePoint as a file storage in your OpenProject instance
keywords: SharePoint, file storage, integration
---

# SharePoint (Enterprise add-on) integration setup

| Topic                                                        | Description                                                  |
| ------------------------------------------------------------ | :----------------------------------------------------------- |
| [Minimum requirements](#minimum-requirements)                | Minimum version requirements to enable the integration       |
| [Set up the integration](#set-up-the-integration)            | Connect OpenProject and SharePoint instances as an administrator |
| [Sharepoint site setup guide](./site-guide)                                   | How to set the necessary permission on your SharePoint site  |
| [Using the integration](#using-the-integration)              | How to use the SharePoint integration                        |
| [Edit a SharePoint file storage](#edit-a-sharepoint-file-storage) | Edit a SharePoint file storage                               |
| [Delete an SharePoint file storage](#delete-a-sharepoint-file-storage) | Delete a SharePoint file storage                             |

[feature: one_drive_sharepoint_file_storage]

> [!NOTE]
> This feature includes using both OneDrive and SharePoint integrations.

OpenProject offers an integration with SharePoint to allow users to:

- Link files and folders stored in SharePoint with OpenProject work packages
- View, open and download files and folders linked to a work package via the Files tab

The goal here is to provide access to all the _Document Libraries_ in a SharePoint site, as a file storage system for OpenProject.

> [!NOTE]
> This guide only covers the integration setup. Please go to our [SharePoint integration user guide](../../../user-guide/file-management/one-drive-integration/) to learn more about how to work with the SharePoint integration.

## Minimum requirements

Please note these minimum version requirements for the integration to work with a minimal feature set:

- OpenProject version 17.0 (or above)
- Access to a SharePoint site

We recommend using the latest version of OpenProject to be able to use the latest features.

## Set up the integration

> [!IMPORTANT]
> You need administrator privileges in the Azure portal for your Microsoft Entra ID and in your OpenProject instance to set up this integration.
>
> Please make sure that you configure your Azure application to have the following **API permissions**:
>
> - Files.ReadWrite.All - Type: Delegated
> - Sites.Selected - Type: Application
> - offline_access - Type: Delegated
> - User.Read - Type: Delegated

Navigate to **System administration -> File storages**. You will see the list of all storages that have already been set up. If no files storages have been set up yet, a banner will tell you that there are no storages yet set up.

Click the green **+Storage** button and select the SharePoint option.

![Add a new SharePoint storage to OpenProject](openproject_system_guide_new_sharepoint_storage.png)

A screen will open, in which you will first need to add the **Name**, **Directory (tenant) ID** and the **Host** details for your new SharePoint storage. Please consult your Azure administrator and the [Site guide](./site-guide) to obtain respective information. Be aware, that the last step includes copying generated information to the Azure portal. Enter your data and click the green _Save and continue_ button.

![Setting up a new SharePoint storage](openproject_system_guide_new_sharepoint_storage_details_new.png)

Continue by filling out the information for the _Azure OAuth_ and once again click the green _Save and continue_ button.

![OAuth applications details in SharePoint file storages setup in OpenProject](openproject_system_guide_new_sharepoint_storage_OAuth.png)

Finally, copy the _Redirect URl_ and click the green _Finish setup_ button.

![Redirect URI details in SharePoint file storage setup in OpenProject](openproject_system_guide_new_sharepoint_storage_redirect_URL.png)

You will see the following message confirming the successful setup on top of the page.

![System message on successful SharePoint file storages setup in OpenProject](openproject_system_guide_new_sharepoint_message_successful_setup.png)

You can now configure user access management. Click the _edit_ icon next to the relevant section. 

![Configure folder and user access settings for SharePoint file storage in OpenProject administration](openproject_system_guide_new_sharepoint_folder_access_setup.png)

OpenProject can automatically create and manage project folders when a file storage is added. This helps keep folder structures organized and ensures correct access for all project members. You can choose between the following options:

- **Enable automatically-managed access and folders** 
  Projects can decide whether to use automatic or manual folder and access management when adding the storage.
- **Only allow manually-managed access and folders** 
  Projects must manage folders and access manually. Automatic management is not available.

![Folder and access management settings for SharePoint integration in OpenProject administration](openproject_system_guide_new_sharepoint_message_folder_setup.png)

> [!IMPORTANT]
> In SharePoint you can add (custom) columns in addition to the ones shown by default (_Modified_ and _Modified by_). Please keep in mind if these custom columns are added, OpenProject integration can no longer copy the automatically-managed project folders. The columns will have to be de-activated, or ideally not be created in the first place.

## Enable SharePoint file storage in projects

Now that the integration is set up, the next step is to make the SharePoint file storage you just created available to individual projects. This can be either done by you directly in the system administration under **Projects** tab of a specific file storage, or on a project level under **Project settings**.

To add a SharePoint to a specific project on a project level, navigate to any existing project in your OpenProject instance and click on **Project settings** -> **Files** and follow the instructions in the [Project settings user guide](../../../user-guide/projects/project-settings/files/).

To add a SharePoint storage to one or multiple projects on an instance level, click on a file storage under _Administration -> Files -> External file storages_ and select **Projects** tab. You will see the list of all projects, for which the file storage was already activated. Click the **+Add projects** button.

![Add SharePoint file storage to projects in OpenProject administration](openproject_system_guide_file_storages_add_projects_button_sharepoint.png)

You can use the search bar to select one or multiple projects and optionally include subprojects. Select the type of project folder for file uploads. Depending on whether automatically-managed access and folders are enabled, the available folder options may vary. Options include:

- **No specific folder**: By default, each user will start in their own home folder when uploading a file or when browsing for existent files to create file links in the file picker.
- **New folder with automatically-managed permissions** (only visible if automatically-managed access and folders are enabled): A root folder is automatically created for the project, and access permissions are managed for each project member.
- **Existing folder with manually-managed permissions**: You can designate an existing folder as the root folder for the project. Permissions are not managed automatically; the administrator must ensure that relevant users have access. The selected folder can be used by multiple projects.

Click **Add** to save your changes.

![Select projects to activate SharePoint storage in OpenProject administration](openproject_system_guide_sharepoint_add_multiple_projects.png)

You can always edit or remove file storages from projects by clicking the **More (three dots)** icon next to the file storage name and selecting the respective option. 

![Remove SharePoint file storage from a project in OpenProject administration](openproject_system_guide_sharepoint_storage_remove_projects.png)

## Using the integration

Once the [file storage is added and enabled for projects](../../../user-guide/projects/project-settings/files/), your instance users are able to take full advantage of the integration between SharePoint and OpenProject. For more information on how to link SharePoint files to work packages in OpenProject, please refer to the [SharePoint integration user guide](../../../user-guide/file-management/sharepoint-integration).

## Edit a SharePoint file storage

To edit an existing SharePoint file storage hover over the name of the storage you want to edit and click it.

![Select SharePoint file storage in OpenProject system administration](openproject_system_guide_select_sharepoint_storage.png)

To update the general storage information, select the **Details** tab, click the **Edit** icon next to the storage provider. To replace the Azure authentication information, click on the **Sync** icon next to the OAuth application. With changing the authentication information the redirect URI will get generated again and thus needs to be copied again. The redirect URI can be copied by clicking the **Copy-to-Clipboard** icon next to the information text, or by entering the form by clicking the **View** icon.

> [!TIP]
> If you have selected automatically-managed access and folders you will also see the _Health status_ message on the
> right side. If the file storage set-up is incomplete or faulty, an error message will be displayed in that section. Read
> more about errors and troubleshooting [here](../../files/external-file-storages/health-status/).

![Edit SharePoint in OpenProject](openproject_system_guide_edit_icon_sharepoint_storage.png)

Here you will be able to edit all the information you have specified when creating the SharePoint connection initially.

## Delete a SharePoint file storage

You can delete a SharePoint file storage either at a project level or at an instance level.

Deleting a file storage at a project level simply makes it unavailable to that particular project, without affecting the integration for other projects. Project admins can do so by navigating to _Project settings -> Files_ and clicking the **Delete** icon next to the file storage you would like to remove.

![Delete a SharePoint storage from an OpenProject project](openproject_system_guide_delete_sharepoint_storage_in_a_project.png)

> [!WARNING]
> Deleting a file storage at an instance level deletes the SharePoint integration completely, making it inaccessible to all projects in that instance. 

Should an instance administrator nevertheless want to do so, they can navigate to _Administration -> File storages_, hover over the name of the file storage they want to remove and click it to enter the next page. Then they need to click the **Delete** button in the top right corner.

![Delete icon for SharePoint integration in OpenProject system settings](openproject_system_guide_delete_icon_sharepoint_storage.png)

You will be asked to confirm the exact file storage name.

![Delete a SharePoint integration from OpenProject system settings](openproject_system_guide_delete_sharepoint_storage.png)

> [!IMPORTANT]
> Deleting a file storage as an instance administrator will also delete all settings and links between work packages and SharePoint files/folders. This means that should you want to reconnect your SharePoint instance with OpenProject, you will need to complete the entire setup process once again.

## Getting support

If you run into any issues, or you cannot set up your integration yourself, please use our [Support Installation & Updates forum](https://community.openproject.org/projects/openproject/forums/9) or if you have an Enterprise subscription, please contact us at Enterprise Support.
