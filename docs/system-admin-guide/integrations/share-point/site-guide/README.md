---
sidebar_navigation:
  title: SharePoint Site setup guide
  priority: 600
description: Site permission guide for SharePoint integration setup in OpenProject
keywords: SharePoint file storage integration, SharePoint, Sites.Selected, Sites Permission, share point, sharepoint
---

# SharePoint Site setup guide

## Configure the Integration permissions on the SharePoint Site

You will need to grant the `manage` permission to the Azure Application so that the integration can work.

> [!IMPORTANT]
> Some of the following descriptions are very tightly connected to the current (2025-10-29) state of SharePoint
> configuration. This may easily change in future, as we neither control nor foresee changes to the configuration UI
> developed by Microsoft.

### Authentication and permission

To communicate with the GRAPH API you need to authenticate against it. This is done through an Azure application defined
in the [Azure portal](https://portal.azure.com/) for your Microsoft Entra ID or by using
the [Microsoft Graph Explorer](https://developer.microsoft.com/en-us/graph/graph-explorer). The authenticated user must
have the `owner` role for the required site and the access token must have the delegated permission
`Sites.FullControl.All`.

### API Endpoints

Once you have an access token, you will be able to check the site permissions using the following endpoints:

> [!IMPORTANT]
> The current documentation for setting permissions on a SharePoint site can also be found at
>
the [Microsoft Graph API documentation](https://learn.microsoft.com/en-us/graph/api/site-post-permissions?view=graph-rest-1.0&tabs=http)

```shell
GET https://graph.microsoft.com/v1.0/sites/<SHAREPOINT HOSTNAME>:/sites/<SITE NAME>:/permissions
```

Then you will need to grant access to the Azure Application by sending the following JSON:

```json
{
  "roles": ["manage"],
  "grantedToIdentities": [{
    "application": {
      "id": "<AZURE APPLICATION ID>",
      "displayName": "<AZURE APPLICATION NAME>"
    }
  }]
}
```

To the same URL above but as a POST request

```shell
POST https://graph.microsoft.com/v1.0/sites/<SHAREPOINT HOSTNAME>:/sites/<SITE NAME>:/permissions
```
