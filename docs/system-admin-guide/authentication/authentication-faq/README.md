---
sidebar_navigation:
  title: Authentication FAQ
  priority: 001
description: Frequently asked questions regarding authentication
keywords: authentication FAQ, LDAP, SAML, SSO
---

# Frequently asked questions (FAQ) for authentication

Additional information regarding the use of LDAP from a user management perspective can be found [in this FAQ section](../../users-permissions/users-permissions-faq).

## How do I set up OAuth / Google authentication in the Enterprise cloud?

The authentication via Google is already activated in the Enterprise cloud. Users who are invited to OpenProject, should be able to choose authentication via Google. There should be a Google button under the normal user name / password when you try to login.

## How can I disable the Google authentication?

Disabling the Google based authentication currently requires you to reach to [support[at]openproject.com](mailto:support@openproject.com). We will disable the Google login option for you.

For on premises installations the functionality can be deactivated the same way it was activated.

## Can we ensure that passwords are secure / have a high strength?

Password parameters for OpenProject can be configured on each OpenProject environment. Typically passwords require 10+ characters, as well as special characters. Please find the respective instruction [here](../authentication-settings/#configure-password-settings).

## How can a user change his/her authentication method?

Users who want to change their authentication method can just be re-invited. Go to *Administration -> Users* and click on the respective user. Then in the top there is a **Send invitation** button. This will allow the user to change their authentication method from password to Google and vice versa. They just have to click the link they will get via email and can choose to log in with the new method.

## I am an administrator of an on-premises installation of OpenProject. Our users can't login and when I send them a link to login they don't receive it. What can I do?

Probably it has something to do with the configuration of the email server if messages do not arrive. As a workaround, you can first [manually set a password](../../users-permissions/users/#manage-user-settings) for the users and send it to them by protected channels (then the users can log in in any case).
In addition, we ask you to check if there are general difficulties with sending emails. There is a possibility to send a [test email](../../../installation-and-operations/configuration/outbound-emails). If the test email arrives, then the email dispatch from OpenProject works. Otherwise you would have to look in the [server logs](../../../installation-and-operations/operation/monitoring), whether there is an error displayed when a user is invited again.

## Is it possible to only allow authentication via SSO (not via user name / password)?

Yes, for Enterprise on-premises and Community edition there is a [configuration option](../../../installation-and-operations/configuration/#disable-password-login) to disable the password login.

## Which authentication providers are supported for single sign-on?

We support all authentication providers that support the SAML and  OpenID Connect (OIDC) standards, such as Microsoft Entra  ID, ADFS, CAS  (with the OpenID connect overlay), Azure, Keycloak, Okta. 

> [Note]
> Please note  that single sign-on is an Enterprise add-on and can only be activated  for Enterprise cloud and Enterprise on-premises.

## Is it possible to use a custom SSO provider (e.g. Keycloak) with the Enterprise cloud edition?

It is possible to use Keycloak, but you can't configure it yourself at the moment as there's no user interface (UI) for custom SSO providers. We can set up the custom provider for you. Then you can access and edit it in the administration. You will be able to enter client ID and client secret via the OpenProject UI.
For context: The connection of custom SSO providers is also described [here](../../../installation-and-operations/misc/custom-openid-connect-providers/#custom-openid-connect-providers) (however, we would enter this configuration for your Enterprise cloud environment).

## I want to connect AD and LDAP to OpenProject. Which attribute for authentication sources does OpenProject use?

You can freely define the attributes that are taken from LDAP sources [in the LDAP auth source configuration screen](../ldap-authentication/).
For group synchronization, OpenProject supports the AD/LDAP standard for groups via "member / memberOf". The attribute cannot be configured at this time.

## Is there an option to mass-create users in OpenProject via the LDAP?

There's no such option at the moment. However, you can activate the on-the-fly user creation for LDAP authentication. This means: An OpenProject user account will be created automatically when a user logs in to OpenProject via LDAP the first time.

## I would like to assign work packages to users from different authentication sources (AD and OpenLDAP). Is this possible without the admin creating groups manually?

OpenProject supports creating groups and staffing them with users based on information found in an LDAP (or AD). This is called [LDAP group synchronization](../ldap-authentication/ldap-group-synchronization/#synchronize-ldap-and-openproject-groups-enterprise-add-on). The groups are created based on the name. So theoretically, it should be possible to have a single group that gets staffed by the information found in multiple LDAPs.  This scenario has not been tested yet. Therefore, we cannot promise that it will work for sure. There is currently no other option.

Assigning work packages to multiple assignees is expected to be implemented in 2021. Once it is implemented, the source the user is defined in is no longer relevant.
