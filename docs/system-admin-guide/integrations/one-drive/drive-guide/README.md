---
sidebar_navigation:
  title: Drive Guide
  priority: 600
description: Drive guide for OneDrive/SharePoint integration setup in OpenProject
keywords: OneDrive/SharePoint file storage integration, OneDrive, SharePoint, DriveID, Azure, Drive ID
---

# Drive Guide

## Configure drive for automatic management

If you need a OneDrive/SharePoint drive configured for using the "Automatically managed project folders" file storage
option, there are some preliminary steps to take. Otherwise, if the drive will to be used in a file storage with the
permission management still based within OneDrive/SharePoint, you should skip these steps and continue
with [obtaining the drive id](./#how-to-obtain-a-drive-id).

> [!IMPORTANT]
> **Disclaimer**: Some of the following descriptions are very tightly connected to the current (2024-02-13) state of
> SharePoint configuration. This may easily change in future, as we do not control nor foresee changes to the
> configuration UI developed by Microsoft.

### Break inheritance chain

The first step to take is to interrupt the inheritance chain of SharePoint for this drive. By doing this, your
OpenProject instance will be able to manage the permissions on the drive for the project folders, otherwise SharePoint
will consistently override those permissions.

To achieve that, you need to enter the *Library Settings* of the target drive. Those usually can get accessed by
selecting the *Settings gear icon* to the top right, selecting *Library Settings* and finally selecting *More Library
Settings*. In the category of *Permissions and Management*, there should be the option to select *Permissions for this
document library*. Within the new page, in the top menu, you need to select the option *Stop Inheriting Permissions*.

> [!TIP]
> If you are using OneDrive for Business instead of SharePoint, there will be no site overriding the
> permissions. Therefore, you can skip this step. You might still want to remove the previously set permissions, as
> described in the next section.

### Remove previously set permissions

Once the inheritance chain is interrupted, the last remaining step is to prepare the drive for remote permissions
management.

In the last screen of the drive configuration (the one after clicking on *Permissions for this document library*
in the *Library Settings*), you should be able to see a list of all currently set permissions. In a standard drive,
where no custom permissions were set, this is usually restricted to the *Members*, *Visitors* and *Owners* (SharePoint
groups that are linked to the parent site). Now, you need to remove all permissions except the ones for the group
*Owners*. Keeping these is important for still being able to reconfigure the drive at a later point in time.

Once this is done, there should be no permissions left assigned to the document library, except the *Owners* group.

## How to obtain a drive ID

To configure a OneDrive/SharePoint storage you will need the drive ID of the drive you want to connect to OpenProject.
Usually this will be a drive within a SharePoint site or a group.

The easiest way to get this ID is by using the Microsoft GRAPH API.

### Authentication and permission

To communicate with the GRAPH API you need to authenticate against it. This is done through an Azure application defined
in the [Azure portal](https://portal.azure.com/) for your Microsoft Entra ID. In addition, the Azure application needs
some API permissions. In general those permissions are given either of the `Delegated` type (in a user context) or of
the `Application` type (for the whole application). To achieve the task of getting the desired drive ID, you will need
an access token with the permission `Files.Read.All`.

### API endpoints

Once you have an access token with the correct permission, you need to fetch the site ID or the group ID, where your
drive is listed in. For a SharePoint site, this can be done with the following endpoint:

```shell
GET https://graph.microsoft.com/v1.0/sites/<HOSTNAME>:/<RELATIVE_PATH_TO_SITE>
```

This will result in a JSON response. The `ID` usually is a triple, of which the 2nd value is the site ID you need to
continue. With this site ID you can fetch the following endpoint:

```shell
GET https://graph.microsoft.com/v1.0/sites/<SITE_ID>/drives
```

This will result in a list of drives. You can select the correct drive by its `name` and take the value of the `ID`.
With this value you can fully configure the OneDrive/SharePoint integration in OpenProject.

## Step-by-step guide with examples

In this section we provide a few examples, in which we demonstrate how to go through the steps mentioned above with a
specific toolset.
> [!NOTE]
> Following examples are explicitly written for this toolset and other mentioned preconditions, hence deviating
> from the preconditions will cause the example to deviate.

### Example 1: Microsoft GRAPH explorer

Microsoft provides a web application, which can browse the GRAPH API. This tool can be
found [here](https://developer.microsoft.com/en-us/graph/graph-explorer). This method only works, if the drive is not
configured as described in the section
about [configuring a drive for automatic management](./#configure-drive-for-automatic-management), so the better
alternative is [example 2](./#example-2-terminal).

#### Preconditions

- Azure application has the API permission `Files.Read.All` of type `Delegated`
- Any browser

#### How to

- Click on the `Sign in` button in the top right corner.
- Log in with your Microsoft account.
  - Make sure to select the correct organization to log in, as the graph explorer will try to specifically log into the
    associated tenant.
  - After a successful login, the resolved tenant will be displayed for a sanity check.
- Fetch the hostname of the tenant (e.g. `example.sharepoint.com`)
- Go to the SharePoint website, where the drive you want to connect can be found.
  - Fetch the relative path from the browser's URL field (e.g. `/sites/mysharepointsite`)
- Copy the following endpoint to the GRAPH explorers query input field:

```shell
https://graph.microsoft.com/v1.0/sites/<HOSTNAME>:/<RELATIVE_PATH_TO_SITE>
```

- Replace the placeholders with the previously fetched values.
- Execute the query, the result should look like the following JSON:

```json
{
  "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#sites/$entity",
  "createdDateTime": "2023-09-26T13:22:00.053Z",
  "description": "This is my example SharePoint site.",
  "id": "example.sharepoint.com,1b4b6576-906d-4d94-8f19-6d00a2507f50,72fb59f8-8eed-4745-920a-8b36abb0d8e0",
  "lastModifiedDateTime": "2023-11-27T13:31:28Z",
  "name": "mysharepointsite",
  "webUrl": "https://example.sharepoint.com/sites/mysharepointsite",
  "displayName": "My SharePoint Site",
  "root": {},
  "siteCollection": {
    "hostname": "example.sharepoint.com"
  }
}
```

- Fetch the value from the `ID` property and copy the second value. In this example, it would
  be `1b4b6576-906d-4d94-8f19-6d00a2507f50`.
- Copy the following endpoint to the GRAPH explorers query input field:

```shell
https://graph.microsoft.com/v1.0/sites/<SITE_ID>/drives
```

- Replace the placeholder with the previously fetch site ID.
- Execute the query, the result should look like the following JSON:

```json
{
  "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#drives",
  "value": [
    {
      "createdDateTime": "2023-09-23T23:37:36Z",
      "description": "",
      "id": "b!dmVKM22QlE3PSW0AqVB7UOhZ8n7tjkVGkgqLNnzl2OBrIfd_KATARI8uVEeuopYk",
      "lastModifiedDateTime": "2023-11-02T15:56:46Z",
      "name": "Documents",
      "webUrl": "https://example.sharepoint.com/sites/mysharepointsite/Shared%20Documents",
      "driveType": "documentLibrary",
      "createdBy": {
        "user": {
          "displayName": "System Account"
        }
      },
      "lastModifiedBy": {
        "user": {
          "email": "darth.vader@outlook.com",
          "id": "0f01a8a9-e59b-4265-93fa-0d2cf727f17b",
          "displayName": "Darth Vader"
        }
      },
      "owner": {
        "group": {
          "email": "mysharepointsite@example.onmicrosoft.com",
          "id": "5854b8c6-773b-43a5-b7cd-1f12bd4bd830",
          "displayName": "my sharepoint site Owners"
        }
      },
      "quota": {
        "deleted": 1075256,
        "remaining": 27487779710490,
        "state": "normal",
        "total": 27487790694400,
        "used": 9908654
      }
    }
  ]
}
```

- The value in the `ID` property of the correct drive (check by name) is the desired drive ID.

### Example 2: Terminal

There is a way to get all necessary information by executing the web requests from the shell.

#### Preconditions

- Azure application has the API permission `Files.Read.All` of type `Application`
- `curl`
- `jq` (You do not have to use this tool, but if you don't, you will have to take the information from the JSON HTTP
  responses by hand.)

> **IMPORTANT, please read**: Setting the API permission `Sites.Read.All` to the `Application` level imposes an
> undeniable security risk.

If the client credentials would get leaked, any client can read sites and their content by just using those credentials.
It is highly recommended to remove that API permission after using this method to get the drive ID.

#### How to

- Navigate to `Overview` of the Azure application at [https://portal.azure.com/](https://portal.azure.com/).
- Copy the values of the `Directory (tenant) ID`, the `Application (client) ID`, and one valid client secret.
  - Those are the same values needed for configuring the OneDrive/SharePoint integration in OpenProject.
  - If the value of an already existing, valid secret is unknown, Azure allows to create multiple secrets for an
    application. Every secret value within Azure portal is only visible right after creation.
- Use the values to replace the placeholders in the following command:

```shell
curl -H "Content-Type: application/x-www-form-urlencoded" \
  -d "scope=https://graph.microsoft.com/.default&grant_type=client_credentials&client_id=<CLIENT_ID>&client_secret=<CLIENT_SECRET>" \
  'https://login.microsoftonline.com/<TENANT_ID>/oauth2/v2.0/token' | jq .access_token
```

- The result is a valid access that is needed in the following requests.
- Fetch the hostname of the tenant (e.g. `example.sharepoint.com`).
- Go to the SharePoint website, where the drive you want to connect can be found.
  - Fetch the relative path from the browser's URL field (e.g. `/sites/mysharepointsite`).
- Use the values to replace the placeholders in the following command:

```shell
curl -H "Authorization: Bearer <ACCESS_TOKEN>" \
  'https://graph.microsoft.com/v1.0/sites/<HOSTNAME>:/<RELATIVE_PATH_TO_SITE>' | jq .id
```

- The result will be something
  like `example.sharepoint.com,1b4b6576-906d-4d94-8f19-6d00a2507f50,72fb59f8-8eed-4745-920a-8b36abb0d8e0`. The site ID
  needed is the second value of the triple, in the example case it would be `1b4b6576-906d-4d94-8f19-6d00a2507f50`.
- Use the values to replace the placeholders in the following command

```shell
curl -H "Authorization: Bearer <ACCESS_TOKEN>" \
  'https://graph.microsoft.com/v1.0/sites/<SITE_ID>/drives' | jq '.value | map({name,id})'
```

- The result is a list with drive names and IDs. Choose the desired drive ID by the related name.
