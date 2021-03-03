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

## Is it possible to use a custom SSO provider (e.g. Keycloak) with the Enterprise cloud edition?

It is possible to use Keycloak, but you can't configure it yourself at the moment as there's no user interface (UI) for custom SSO providers. We can set up the custom provider for you. Then you can access and edit it in the administration. You will be able to enter client ID and client secret via the OpenProject UI.
For context: The connection of custom SSO providers is also described [here](../../../installation-and-operations/misc/custom-openid-connect-providers/#custom-openid-connect-providers) (however, we would enter this configuration for your Enterprise cloud environment).

## How do I set up OAuth / Google authentication in the Enterprise cloud?

The authentication via Google is already activated in the Enterprise cloud. Users who are invited to OpenProject, should be able to choose authentication via Google. There should be a Google button under the normal user name / password when you try to login. 

## Can we ensure that passwords are secure / have a high strength?

Password parameters for OpenProject can be configured on each OpenProject environment. Typically passwords require 10+ characters, as well as special characters. Please find the respective instruction [here]([../authentication-settings/#configure-password-settings.).

## I am an administrator of an on-premises installation of OpenProject. Our users can't login and when I send them a link to login they don't receive it. What can I do?

Probably it has something to do with the configuration of the email server if messages do not arrive. As a workaround, you can first [manually set a password](../../users-permissions/users/#manage-user-settings) for the users (then the users can log in in any case). 
In addition, we ask you to check if there are general difficulties with sending e-mails. There is a possibility to send a test email (you can see it quite well [here](../../email/#configure-email-header-and-email-footer) in the screenshot (under point 3). If the test email arrives, then the email dispatch from OpenProject works. Otherwise you would have to look in the [server logs](../../installation-and-operations/operation/monitoring), whether there is an error displayed when a user is invited again.

## How can a user change his/her authentication method?

Users who want to change their authentication method can just be re-invited. Go to *Administration -> Users* and click on the respective user. Then in the top there is a **Send invitation** button. This will allow the user to change their authentication method from password to Google and vice versa. They just have to click the link they will get via email and can choose to log in with the new method.

## I would like to assign work packages to users from different authentication sources (AD and OpenLDAP). Is this possible without the admin creating groups manually? 

OpenProject supports creating groups and staffing them with users based on information found in an LDAP (or AD). This is called [LDAP group synchronization](../ldap-authentication/ldap-group-synchronization/#synchronize-ldap-and-openproject-groups-premium-feature). The groups are created based on the name. So theoretically, it should be possible to have a single group that gets staffed by the information found in multiple LDAPs.  This scenario has not been tested yet. Therefore, we cannot promise that it will work for sure. There is currently no other option.

Assigning work packages to multiple assignees is expected to be implemented in 2021. Once it is implemented, the source the user is defined in is no longer relevant.