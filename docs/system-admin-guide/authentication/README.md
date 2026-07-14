---
sidebar_navigation:
  title: Authentication
  priority: 890	
description: Overview of authentication options in OpenProject and guidance on which solution fits which need.
keywords: authentication, SSO, single sign-on, LDAP, SAML, OpenID Connect, OAuth, SCIM
---
# Authentication

OpenProject offers several ways to authenticate users and to connect OpenProject with the other systems in your IT landscape. This page gives you an overview of the available options and helps you decide which one fits your needs.

To configure these settings, go to **Administration → Authentication**.


## How authentication works in OpenProject

There are two considerations for authentication between OpenProject and other systems:

- **How users sign in to OpenProject.** Users can either log in with an account managed inside OpenProject, or OpenProject can delegate authentication to a central system you already operate (a directory or an SSO identity provider). This is one of the first decisions administrators should make before inviting users.
- **How other systems connect to OpenProject.** OpenProject itself can act as an identity and authorization source for other applications such as OAuth, and can receive automated user provisioning from your identity provider through SCIM.

The sections below walk through both directions and point you to the detailed configuration guides.

## Which sign-in solution fits my needs?

Use the following table to determine how your users should sign in. You can also combine several methods or authentication providers. For example, using SSO for employees while maintaining internal OpenProject accounts for external collaborators or emergency administrator access.

| Your environment                                             | Recommended approach                                         | Edition    |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ---------- |
| Small or medium organization with **no central directory or identity provider** | [Internal accounts](login-registration-settings) (username and password) | Community  |
| You run a **central directory service** such as Active Directory or OpenLDAP | [LDAP authentication](ldap-connections)                      | Community  |
| You use an **OpenID Connect identity provider** (Microsoft Entra ID, Keycloak, Google Workspace, Okta, ...) | [OpenID Connect single sign-on](openid-providers)            | Enterprise |
| Your identity provider is **SAML-based** (e.g. ADFS, Shibboleth) | [SAML single sign-on](saml)                                  | Enterprise |
| You want **integrated network sign-on** on Windows/desktop clients through a local Apache setup. | [Kerberos](kerberos)                                         | Community  |

Not sure which one applies to you? The [Authentication FAQ](authentication-faq) answers common questions around LDAP, SAML and SSO.

## Signing users in

These options determine who can access your instance and how they prove their identity.

| Topic                                                        | What it does                                                 |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [Login and registration settings](login-registration-settings) | General authentication settings: self-registration, password rules, session behavior and the global SSO options. Start here for internal logins, even if they are only meant for additional administrative access. |
| [LDAP authentication](ldap-connections)                      | Authenticate users against an existing directory (Active Directory, OpenLDAP) using their directory credentials. You can also [synchronize groups and departments](ldap-connections/ldap-group-synchronization) into OpenProject (Enterprise add-on). |
| [OpenID Connect providers](openid-providers)                 | Set up Single Sign-On (SSO) using an OpenID Connect identity provider (Enterprise add-on). |
| [SAML single sign-on](saml)                                  | Set up Single Sign-On (SSO) using a SAML 2.0 identity provider  (Enterprise add-on). |
| [Kerberos](kerberos)                                         | Delegated login for users in a Kerberos network, configured through the Apache web server. OpenProject then trusts a header value set up by this server to identify logged in users. |

## Securing sign-in

These options add extra protection on top of your chosen sign-in method.

| Topic                                                    | What it does                                                                                              |
| ------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| [Two-factor authentication](two-factor-authentication)  | Require a second factor (TOTP app or WebAuthn/security key) in addition to the password.                  |
| [reCAPTCHA](recaptcha)                                  | Add a CAPTCHA challenge on login to protect against automated attacks and bots.                          |

## Connecting other systems to OpenProject

Use these options when OpenProject should act as an identity or authorization source for other applications, or when user accounts should be managed automatically from your identity provider.

| Topic                                                        | What it does                                                 |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [OAuth applications](oauth-applications)                     | Let external applications authenticate users against OpenProject and access the API on their behalf (OpenProject acts as OAuth server). |
| [SCIM provisioning](scim)                                    | Automatically provision and de-provision users and groups from your identity provider (Enterprise add-on). |
| [LDAP group synchronization](ldap-connections/ldap-group-synchronization) | Keep OpenProject group memberships in sync with your LDAP directory (Enterprise add-on). |
