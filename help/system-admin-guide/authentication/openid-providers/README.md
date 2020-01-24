---
sidebar_navigation:
  title: OpenID providers
  priority: 800
description: OpenID providers for OpenProject.
robots: index, follow
keywords: OpenID providers
---
# OpenID providers

<div class="alert alert-info" role="alert">
**Note**: For the OpenID configuration view our docs in Github:  https://github.com/opf/openproject/blob/dev/docs/configuration/openid.md  (Todo: needs to be moved to documentation).
</div>

To activate and configure OpenID providers in OpenProject, navigate to -> *Administration* -> *Authentication* and choose -> *OpenID providers*.

## Add a new authentication application for oauth

To add a new OpenID provider, click the green **+ OpenID provider** button.

![Sys-admin-authentication-openid-provider](Sys-admin-authentication-openid-provider.png)

You can configure the following options.

1. Choose **Google** or **Azure** to add as an OpenID provider to OpenProject.
2. Optionally enter a **display name**.
3. Enter the **Identifier**.
4. Enter the **Secret**.
5. Press the blue **create** button.

![Sys-admin-authentication-add-openid-provider](Sys-admin-authentication-add-openid-provider.png)