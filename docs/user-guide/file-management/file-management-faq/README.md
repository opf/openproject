---
sidebar_navigation:
  title: File management FAQs
  priority: 001
description: FAQs on file management in OpenProject.
keywords: files, attachment, Nextcloud, OneDrive, SharePoint, FAQ
---

# File Management FAQs

## Why am I not allowed to see/read a certain file in OneDrive/SharePoint or Nextcloud?

It is possible that you lack the necessary permissions to view a certain file. In this case please contact your administrator.

Another explanation may be that you have been removed from a project in OpenProject, which will also mean that you lost your viewing or reading privileges in OneDrive/SharePoint or Nextcloud project folders.

It can also be that case, that a project admin revoked your permission to view files on file storages within a project in OpenProject.

## Can I rename a project with an established file storage (Nextcloud or OneDrive/SharePoint) connection?

Yes, that is possible. If you work with automatically managed folders, the corresponding project folder will also be renamed automatically after a few minutes.

## Can I copy a project, including the OneDrive/SharePoint file storage?

Yes, you can. If the OneDrive/SharePoint file storage in your project had the automatically managed folders selected during the set-up, the folder with all files will be copied. If the file storage was added with manual managed folders, the new copy of the project will have the same file storage setup and reference the original folder without copying it. Read more about copying projects [here](../../projects/#copy-a-project).

> [!IMPORTANT]
> In Sharepoint you can add (custom) columns in addition to the ones shown by default (*Modified* and *Modified by*). Please keep in mind if these custom columns are added, OpenProject integration can no longer copy the automatically managed project folders. The columns will have to be de-activated, or ideally not be created in the first place.


## Is there a virus scanner for the files attachments in OpenProject?

Yes, there is a virus scanner for attachments in OpenProject. At the moment it is only available for on-premises installations and is an Enterprise add-on. Your system administrator will need to [configure it first](../../../system-admin-guide/files/attachments/virus-scanning/).
