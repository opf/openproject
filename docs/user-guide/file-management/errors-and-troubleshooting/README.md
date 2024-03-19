---
sidebar_navigation:
  title: File management Troubleshooting
  priority: 002
description: Possible file management errors and troubleshooting in OpenProject.
keywords: files, attachment, Nextcloud, OneDrive, SharePoint, error, troubleshooting
---

# Possible errors and troubleshooting

## 

## Nextcloud specific errors and troubleshooting

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
