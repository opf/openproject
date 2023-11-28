---
sidebar_navigation:
  title: One Drive integration
  priority: 800
description: Using the OneDrive/Sharepoint integration to link/unlink files and folders to work packages, viewing and downloading files and troubleshooting common errors
keywords: integration, apps, OneDrive, Sharepoint, user
---

# OneDrive integration


Starting with OpenProject 13.1, you can use **Sharepoint** as an integrated file storage in OpenProject.

This integration makes it possible for you to:

- Link files and folders stored in Sharepoint with work packages in OpenProject
- View, open and download files and folders linked to a work package via the **Files** tab
- View all work packages linked to a file
- View OpenProject notifications via the Nextcloud dashboard



> **Important note**: To be able to use Sharepoint as a file storage in your project, the administrator of your instance should first have completed the [Nextcloud integration setup](../../system-admin-guide/integrations/nextcloud). Then a project administrator can activate Nextcloud in the  [**File storages**](../projects/project-settings/file-storages/) for a project.


| Topic                                                        | Description                                                  |
| ------------------------------------------------------------ | :----------------------------------------------------------- |
| [Connect your OpenProject and Nextcloud accounts](#connect-your-openproject-and-nextcloud-accounts) | How to connect your Nextcloud and OpenProject accounts to be able to use this integration |
| [Link files and folders to work packages](#link-files-and-folders-to-work-packages) | How to link files and folders to work packages and view and download linked files |
| [Unlink files and folders](#remove-links)                    | How to remove the link between a work package and a Nextcloud file or folder |
| [Permissions and access control](#permissions-and-access-control) | Who has access to linked files and who doesn't               |
| [Possible errors and troubleshooting](#possible-errors-and-troubleshooting) | Common errors and how to troubleshoot them     
