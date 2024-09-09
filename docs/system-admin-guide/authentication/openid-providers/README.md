---
sidebar_navigation:
  title: OpenID providers
  priority: 800
description: OpenID providers for OpenProject.
keywords: OpenID providers
---
# OpenID providers

| Topic                                                        | Content                                                      |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [Google Workspace](#google-workspace)                        | How to use Google Workspace as an SSO provider for OpenProject? |
| [Azure Active Directory](#azure-active-directory)            | How to use Microsoft Azure Active Directory as an SSO provider for OpenProject? |
| [Custom OpenID Connect Providers](#custom-openid-connect-providers) | Configuration of additional OpenID Connect providers.        |
| [Troubleshooting](#troubleshooting)                          | Common complications when using OpenID as SSO.               |

To activate and configure OpenID providers in OpenProject, navigate to *Administration* -> *Authentication* and choose -> *OpenID providers*.

## Add a new authentication application for oauth

To add a new OpenID provider, click the green **+ OpenID provider** button.

![OpenID providers in OpenProject administration](openproject_system-admin-guide_authentication_openid_provider.png)

You can configure the following options.

1. Choose **Google** or **Azure** to add as an OpenID provider to OpenProject.

2. Optionally enter a **display name**.

3. Enter the **Identifier**.

4. Enter the **Secret**.

5. Optionally, if you want to honor the system-wide self-registration setting, enable "Limit self registration".
  When checked, users will be created according to the [self-registration setting](../authentication-settings).

6. Set the **tenant** of your Azure endpoint. This will control who gets access to the OpenProject instance. For more information, please see [our user guide on Azure OpenID connect](#azure-active-directory)

7. Press the **create** button.

   ![Add a new OpenID provider in OpenProject administration](openproject_system-admin-guide_authentication_openid_provider_new.png)

## Google Workspace

### Step 1: Create the OAuth consent screen

1. Navigate to your GCP console.  (https://console.cloud.google.com/)
2. Go to **APIs & Services** > OAuth consent screen.

![g1-apis-and-services-oauth-consent-screen](g1-apis-and-services-oauth-consent-screen.png)

3. Create a new project and a new app or edit an existing project and an existing app, setting the following fields (shall be Internal):
   1. **App name** (e.g. EXAMPLE.COM SSO)
   2. **User support email** (e.g. user-support@example.com)
   3. **App domains** (at minimum, you must provide the Application home page - e.g. `https://example.openproject.com`)
   4. **Authorized domains** (e.g. openproject.com)
   5. **Developer Contact information** (e.g.  developer@example.com)
   6. Click **SAVE AND CONTINUE** to proceed.

![g2-edit-app-registration](g2-edit-app-registration.png)

4. **Scopes** - Press **SAVE AND CONTINUE**
5. **Summary** - Press **SAVE AND CONTINUE**

### Step 2: Create the OAuth Client

1. Under **APIs & Services**, go to **Credentials**.

![g3-apis-and-services-credentials](g3-apis-and-services-credentials.png)

2. Click **Create Credentials** and select **OAuth Client ID**.

   1. When prompted for your **Application type**, choose **Web Application**.

   2. Provide a **Name** for your application. (e.g. example-openproject-com)

   3. Under Authorized redirect URIs, click **Add URI**, and provide your URI (e.g. [example.openproject.com]/auth/google/callback).

   4. Click **CREATE** or **SAVE** .

![g4-create-credentials-oauth-client-id](g4-create-credentials-oauth-client-id.png)

After pressing **CREATE** you will get a pop-up window like the following

- Note **Client ID**
- Note **Client Secret**

![g5-oauth-client-created](g5-oauth-client-created.png)

### Step 3: Add Google as an OpenID Provider to OpenProject

1. Login as OpenProject Administrator
2. Navigate to *Administration* -> *Authentication* and choose -> *OpenID providers*.
   1. **Name** Choose Google
   2. **Display Name** (e.g. **EXAMPLE.COM SSO**)
   3. **Identifier** (**Client ID** from step 2)
   4. **Secret** (**Client Secret** from step 2)
   5. Enable **Limit self registration** option
3. Press **Create**

![Add a new OpenID Gogole provider in OpenProject administration](openproject_system-admin-guide_authentication_openid_provider_new_google.png)

4. The following green notification **Successful creation** should appear

![Successful OpenID creation message in OpenProject administration](openproject_system-admin-guide_authentication_openid_provider_new_google_successful_message.png)

## Azure Active Directory

### Step 1: Register an App in Azure Active Directory

If your organization currently has an Azure Active Directory to manage users, and you want to use that to log in to OpenProject, you will need to register a new *App*.

The steps are as follows:

Log into your Microsoft account, and go to the Azure Active Directory administration page.

![Azure Active Directory administration page](01-menu.png)

In the sidebar, click on "All services".

![Azure Active Directory All services](02-admin-dashboard.png)

Click on the link named "App registrations".

![Azure Active Directory App registrations](03-app-registrations.png)

Click on "New registration".

![Azure Active Directory New registration](04-register-app.png)

You are now asked for a few settings:

* For "Name", enter "OpenProject".
* For "Supported account types", select "Accounts in this organization directory only".
* For "Redirect URI", select the "Web" type, and enter the URL to your OpenProject installation, followed by "/auth/azure/callback". For instance: "https://myserver.com/auth/azure/callback".

When you are done, click on the "Register" button at the end of the page. You are redirected to your new App registration, be sure to save the "Application (client) ID" that is now displayed. You will need it later.

![Azure Active Directory Admin Dashboard](02-admin-dashboard-1580821056307.png)

You can now click on "Certificates & secret".

![Azure Active Directory Certificates](06-certificates.png)

Then click on "New client secret", set the description to "client_secret", and the expiration to "730 days (24 months)". Then click on "Add".

![Azure Active Directory New Client Secret](07-client-secret.png)

A secret should have been generated and is now displayed on the page. Be sure to save it somewhere because it will only be displayed once.

![Azure Active Directory Add Secret](08-add-secret.png)

At the end of this step, you should have a copy of the Application client ID as well as the client Secret you just generated.

### Step 2: Configure OpenProject

Now, head over to OpenProject > Administration > OpenID providers. Click on "New OpenID provider", select the Azure type, enter the client ID and client Secret.

By default, OpenProject will use the Microsoft Graph API endpoint to perform user info requests.
For that, you will need to enter the correct tenant identifier for your Azure instance.
To find the correct value for your instance, [please see this guide](https://learn.microsoft.com/en-us/azure/active-directory/develop/v2-protocols-oidc#find-your-apps-openid-configuration-document-uri).

Once you filled out the form, hit save and the Azure provider has been created.

You can now log out, and see that the login form displays a badge for authenticating with Azure. If you click on that badge, you will be redirected to Azure to enter your credentials and allow the App to access your Azure profile, and you should then be automatically logged in.

Congratulations, your users can now authenticate using your Azure Active Directory!

#### Tenant configuration

Sometimes you may need to configure the `tenant` option for the AzureAD connection.
Currently this is not possible through the user interface.

But you can do it via the console as described [here](../../../installation-and-operations/misc/custom-openid-connect-providers/#custom-openid-connect-providers) where you can add `tenant` next to the other options like `host`, `identifier` and `secret`.

## Custom OpenID Connect Providers

You  can still use an arbitrary provider. But for the time being there is no user interface yet for this. That means you will have to do it directly using the console on the server or via environment variables.

Please continue reading in the [Miscellaneous section of the Installation and Operations Guide](../../../installation-and-operations/misc/custom-openid-connect-providers/).

## Troubleshooting

Q: After clicking on a provider badge, I am redirected to a signup form that says a user already exists with that login.

A: This can happen if you previously created user accounts in OpenProject with the same email than what is stored in the OpenID provider. In this case, if you want to allow existing users to be automatically remapped to the OpenID provider, you should do the following:

Spawn an interactive console in OpenProject. The following example shows the command for the packaged installation.
See [our process control guide](../../../installation-and-operations/operation/control/) for information on other installation types.

```shell
sudo openproject run console
# or if using docker:
# docker-compose run --rm web bundle exec rails console
```

Once in the console you can then enter the following to enable the setting and leave the console.

```shell
Setting.oauth_allow_remapping_of_existing_users = true
exit
```

Then, existing users should be able to log in using their Azure identity. Note that this works only if the user is using password-based authentication, and is not linked to any other authentication source (e.g. LDAP) or OpenID provider.

Note that this setting is set to true by default for new installations already.
