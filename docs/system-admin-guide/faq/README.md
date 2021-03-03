---
sidebar_navigation:
  title: FAQ
  priority: 001
description: Frequently asked questions regarding system administration
robots: index, follow
keywords: system admin FAQ, global admin, administration, system settings
---

# Frequently asked questions (FAQ) for system administration

## How do I know if I have system admin permissions?

If you can choose *Administration* when clicking on your avatar you have system admin permissions.

## How can I use the Slack plugin?

The slack plugin is deactivated per default in the Enterprise cloud. Please contact support to have it activated. For the Enterprise on-premises edition please have a look at [this instruction](../../user-guide/integrations/#slack).

## Can I use a self-developed plugin in my Enterprise cloud?

No, that's not possible, as all tenants (customers) use the same code on the shard. But you can do this in Enterprise on-premises.

## I want to delete a user but it fails.

If you are using the Enterprise cloud and the user you are trying to delete is the user that initially set up OpenProject, you will need to contact us to delete this project member. For other users please make sure the box "User accounts deletable by admins" in *Administration ->users & Permissions ->Settings* is checked.

## We use LDAP. How do we release a license should someone leave our team and no longer need access?

There are two possibilities:

- You can block the user in the user list under "Administration". The LDAP sync does not change the status and the user does not count into the active users anymore.
- The user can be released through an attribute in the LDAP or through an OpenProject LDAP group. Then the permission for this user can be removed in the LDAP and the user cannot use the LDAP authentication for OpenProject anymore. In this case the user still needs to be blocked or deleted in OpenProject.

## How can I access the log files or increase the log level?

Please have a look at [these instructions](../../installation-and-operations/operation/monitoring).

## [FAQ for authentication](../authentication/faq)



## [FAQ for work package settings](../manage-work-packages/faq)



## [FAQ for incoming emails](../email/faq)



## [FAQ for custom fields](../custom-fields/faq)



