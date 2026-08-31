---
sidebar_navigation:
  title: Get started
  priority: 890
description: Follow these steps to install, log in, and start using the OpenProject Mobile app (Beta).
keywords: mobile app first steps, getting started, log in, log-in, login, mobile log in, openproject mobile app, download, access, install, mobile installation
---

# Get started

This section helps you install the OpenProject Mobile app (Beta) and log in to your OpenProject instance.

## Start here

| Feature | Description |
| --- | --- |
|[ **Install and log in**](install-login) | Download the app for iOS or Android, check the requirements, and sign in with your OpenProject credentials. |
|[**Login troubleshooting**](login-troubleshooting) | If login fails, follow a step-by-step checklist to verify OpenProject version, HTTPS/certificates, and OAuth settings. |

## Quick requirements overview

To use the OpenProject Mobile app (Beta), you need:

- **OpenProject 17.0.0 or above**
- An **OpenProject Cloud** workspace or **on-premises** installation (with API access enabled)
- **HTTPS with a signed certificate** (http is not supported)
- **Built-in OAuth applications enabled**: `{BASE_URL}/admin/oauth/applications`
- **iOS 17+** or **Android 12+**
- Internet access for syncing

> [!NOTE]
> If you have an earlier OpenProject version, an administrator may need to enable the **Built in OAuth applications** flag under `{BASE_URL}/admin/settings/experimental`.