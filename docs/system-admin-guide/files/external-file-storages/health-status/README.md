---
sidebar_navigation:
  title: Health status / Troubleshooting
  priority: 999
description: Health status checks and troubleshooting for file storages in OpenProject.
keywords: file storages, health, health status, error, troubleshooting, Nextcloud, OneDrive, SharePoint, Connection validation, Connection test
---

# Health status checks and troubleshooting

If a file storage is not working as expected, you can find additional information about possible errors in the details
view of the file storage. You can access this view by clicking on the file storage's name in the list under *Administration* -> *Files* -> *External file
storages*.  In addition, administrator can manually trigger a connection validation. 

## Connection validation

### Connection validation for OneDrive/SharePoint 

Every file storage for OneDrive/SharePoint has the ability to run a connection test. This test is triggered manually by
clicking on **Recheck connection** in the sidebar on the right side of the file storage's details view. This check is
available after the file storage is fully configured.

![Recheck connection for OneDrive/SharePoint in OpenProject administration](openproject_file_storages_recheck_connection.png)

There are several possible errors that can occur during the connection test. The following table lists the error codes with a description of the possible reasons and suggested solutions.

| Error code             | Error description                                            | Possible reasons                                             | Next steps and solutions                                     |
| ---------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| WRN_NOT_CONFIGURED     | The file storage is not fully configured.                    | Important data is missing, so that the file storage is labelled incomplete. | Check the input fields and fill in the missing data.         |
| ERR_TENANT_INVALID     | The configured directory (tenant) id is invalid.             | There might be a typo or the tenant name or ID has changed recently. | Go to the correct Microsoft Entra ID overview in the [Azure Portal](https://portal.azure.com/) and copy the correct tenant id to the input field. |
| ERR_CLIENT_INVALID     | The configured client credentials are invalid.               | Either the client id or the client secret are invalid. The error descriptions should help you finding the culprit. | Go to the correct application overview in the [Azure Portal](https://portal.azure.com/). Copy the correct client ID to the input field, or check whether the client secret is still valid. Attention: secrets might have an expiration date. If a secret is expired, you will have to generate a new one. |
| ERR_DRIVE_INVALID      | The configured drive cannot be found.                        | The request for the drive ID failed without finding the drive ID. The drive might be deleted, or your application has no permissions to see it. | Consult the [drive guide](../../../integrations/one-drive/drive-guide/) and fetch the desired drive ID again, to fill out the input field. |
| WRN_UNEXPECTED_CONTENT | The connection request was successful, but unexpected content was found in the drive. | This warning is only shown, if the file storage is configured to automatically managed project folder permissions. There was data found in the drive, that is not a project folder created by OpenProject. | Go to your drive and migrate or delete the data from the drive root, that was not created by OpenProject. Further information about the unexpected data is found in the server logs. A drive configured for usage with the *Automatically managed project folders* option has a disrupted inheritance chain. Any data in here can only be seen by site owner. It is discouraged to use this drive for other purposes than the OpenProject integration. |
| ERR_UNKNOWN            | An unknown error occurred.                                   | There can be multiple reasons and the error source was not foreseen. | Errors of this kind are logged to the server logs. Look for a log entry starting with `Connection validation failed with unknown error:` |

### Connection validation for Nextcloud

Same as OneDrive/SharePoint, every file storage for Nextcloud has the ability to run a connection test. This test is
triggered manually by clicking on **Recheck connection** in the sidebar on the right side of the file storage's details
view. This check is available after the file storage is fully configured.

![Recheck connection for Nextcloud in OpenProject administration](openproject_file_storages_recheck_connection_nextcloud.png)

There are several possible errors that can occur during the connection test. The following table lists the error codes
with a description of the possible reasons and suggested solutions.

| Error code               | Error description                                            | Possible reasons                                             | Next steps and solutions                                     |
| ------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| ERR_HOST_NOT_FOUND       | No Nextcloud server was found at the configured host URL.    | There might be a typo or the URL has changed.                | Please check the configuration.                              |
| ERR_MISSING_DEPENDENCIES | A required dependency is missing on the file storage.        | Either the Integration OpenProject app or the Group Folders app is not enabled in Nextcloud. | Please add the following dependency: %{dependency}.          |
| ERR_UNEXPECTED_VERSION   | The Integration OpenProject app version or the Group Folders app version is not supported. | Either the Integration OpenProject app or the Group Folders app is outdated or was not updated to the officially minimal supported version. | Please update your apps to the latest version. It might be necessary to update your Nextcloud server to the latest version in order to be able to install the latest app versions. |
| ERR_UNKNOWN              | An unknown error occurred.                                   | There can be multiple reasons and the error source was not foreseen. | Errors of this kind are logged to the server logs. Look for a log entry starting with `Connection validation failed with unknown error:` |
| WRN_UNEXPECTED_CONTENT   | The connection request was successful, but unexpected content was found in the drive. | This warning is only shown, if the file storage is configured to automatically managed project folder permissions. There was data found in the drive, that is not a project folder created by OpenProject. | Go to your storage and migrate or delete the data in the OpenProject folder, that was not created by OpenProject. Further information about the unexpected data is found in the server logs. |

The officially minimal supported app versions are listed in
the [system admin guide](../../../../system-admin-guide/integrations/nextcloud/#required-system-versions).

## Health checks for automatically managed project folders

File storages with the *Automatically managed project folders* option will have reoccurring synchronization
runs, that update the user permissions on the external system and report possible errors. An additional section is
displayed for those file storages in the side bar.

![Health check for automatically managed folders in file storage integrations in OpenProject](openproject_file_storages_health_message.png)

If a problem has been detected, the OpenProject administrators will be notified of the detected error via email.
Administrators will be notified of the faulty integration once a day, including the specific error description and
solution suggestions (see the table below).

Once the error has been resolved, the administrators will also receive an email informing them of this.

You can choose to subscribe or unsubscribe to these email notifications by clicking the respective button under the
error message.

### File storage errors description

Please consult the following table for possible reasons behind the errors and suggested solutions.

| Error name   | Error description                       | Possible reasons                                                                                                                                                                                                                                                                                                                                                                 | Next steps and solutions                                                                                                                                                                                                                                              |
|--------------|-----------------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Error        | No group specified                      | The name may not be specified for the storage.<br/>A glitch during setup or manual changes to the DB could cause this problem. The group name is saved in the database in the Storages Table in the providers field (JSON).                                                                                                                                                      | Setup the entire storage again.                                                                                                                                                                                                                                       |
| Error        | Group does not exist                    | The app was activated on Nextcloud and the OpenProject group was removed afterwards.<br/>Changes on Nextcloud: OpenProject group was removed.                                                                                                                                                                                                                                    | Manually add the group in the Nextcloud setup and call it OpenProject. Add the user OpenProject to the group OpenProject.                                                                                                                                             |
| Error        | User does not exist                     | After the app was activated on Nextcloud and the user was removed afterwards.<br /> Changes on Nextcloud: OpenProject user was removed.                                                                                                                                                                                                                                          | Manually add the user in the Nextcloud setup and call that user OpenProject. Add the user OpenProject to the group OpenProject.  <br />Alternatively reinstall the OpenProject integration app on Nextcloud. You will also need to reconfigure the Nextcloud storage. |
| Error        | Insufficient privileges                 | OpenProject can not change the user permissions for folders or add folders to the OpenProject folder, because the OpenProject user no longer has access to the folder.                                                                                                                                                                                                           | Reinstall the OpenProject integration app on Nextcloud. You will need to reconfigure the Nextcloud storage.   Make sure the OpenProject user is the admin of the OpenProject group and also the admin of the OpenProject folder.                                      |
| Error        | Failed to remove or add user from group | A user does not exist in the file storage.  <br />A user can not be removed from the OpenProject group due to admin rights.  <br />This may occur when running the sync job and further information can be found in the server logs.                                                                                                                                             | Ensure that the user exists in the file storage platform. <br />Remove admin rights for that user on the OpenProject group.  <br />If the user is also an admin in the files storage group, he/she/they need to be removed by a file storage platform admin.          |
| Not allowed  | Outbound request method not allowed     | OpenProject sent wrong requests to the storage.  <br />This error can occur both in Nextcloud and OneDrive/Sharepoint integration.                                                                                                                                                                                                                                               | Report this to [OpenProject community](https://community.openproject.org/projects/openproject/forums) or [support team](https://www.openproject.org/contact/).                                                                                                        |
| Not found    | Outbound request destination not found  | OpenProject can not reach file storage platform.  <br />This could be due to Storage provider being down:<br />- DNS problems <br />- Network problems (flaky network) <br />- Local networks (Nextcloud specific setting that needs to enabled)                                                                                                                                 | See if you can access the file storage platform from your browser.  <br />For Nextcloud, see if Nextcloud settings are active if in local network.                                                                                                                    |
| Unauthorized | Outbound request not authorized         | - Authentication is failing<br /> - Application password was changed and not updated in OpenProject (Nextcloud OAuth settings are wrong or OneDrive/SharePoint client secret or ID is wrong).<br />- User has no access, can not login, no token can be negotiated.<br />  Server to server: the client secret might be wrong <br /> OpenProject User credentials might be wrong | Check the storages setup.<br />Check if the client secret (OneDrive/SharePoint) or the OAuth setup is correct (Nextcloud).<br />Check if the application password is correct.                                                                                         |
| Conflict     | *error_text_from_response*              | A folder or a file was created, which already exists on the storage platform, e.g. a folder with the same name exists. <br /> Can happen if for example a user manually created something on the storage platform.                                                                                                                                                               | Check in the storage platform if the folder already exists.                                                                                                                                                                                                           |
| Error        | Outbound request failed                 | An unexpected 500 error, e.g. TOS (Terms of Service) app was activated and OpenProject can not access storage anymore. <br /> Password configuration plugin may have caused problems.                                                                                                                                                                                            | See if file storage is working correctly. If it does, collect as much information as possible and contact [OpenProject community](https://community.openproject.org/projects/openproject/forums) or [support team](https://www.openproject.org/contact/).             |

If the suggested troubleshooting solutions did not resolve your issue, please reach out to
the [OpenProject community](https://community.openproject.org/projects/openproject/forums)
or [support team](https://www.openproject.org/contact/) for further assistance.
