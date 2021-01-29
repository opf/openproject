---
sidebar_navigation:
  title: FAQ
  priority: 001
description: Frequently asked questions regarding authentication
robots: index, follow
keywords: authentication FAQ, LDAP, SAML, SSO
---

# Frequently asked questions (FAQ) for authentication

## Is there an option to mass-create users in OpenProject via the LDAP?

There's no such option at the moment. However, you can activate the on-the-fly user creation for LDAP authentification. This means: An OpenProject user account will be created automatically when a user logs in to OpenProject via LDAP the first time.

## Is it possible to only allow authentication via SSO (not via user name / password)?

Yes, for Enterprise on-premises and Community Edition there is a [configuration option](../installation-and-operations/configuration/#disable-password-login) to disable the password login.

## How do I set up OAuth / Google authentication in the Enterprise cloud?

The authentication via Google is already activated in the Enterprise cloud. Users who are invited to OpenProject, should be able to choose authentication via Google. There should be a Google button under the normal user name / password when you try to login. 

## Can we ensure that passwords are secure / have a high strength?

Password parameters for OpenProject can be configured on each OpenProject environment. Typically passwords require 10+ characters, as well as special characters. Please find the respective instruction [here]([../authentication-settings/#configure-password-settings.).