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

## Is there a limit to how many values can be added to a work package custom field of the type list?

A hard limit does not exist. Nevertheless, there are factors that can represent a restriction in usability: 

- Performance: So far, the allowed field values are all entered into the work package form retrieved before processing a work package. It is only a guess, but  no problems should arise when rendering in the frontend (displaying in the select field), as an autocompleter is already used here. The performance on the administration page of the user-defined field, where the possible values are maintained, could also be a factor. 
- On the same administration page, editing could be difficult from a UI point of view. Especially if the user wants to sort. For example, there is currently no way to sort the values automatically. If 4000 values have to be entered and sorted, it could be a lengthy process.

## Can I use a self-developed plugin in my Enterprise cloud?

No, that's not possible, as all tenants (customers) use the same code on the shard. But you can do this in Enterprise on-premises.

## Is it possible to set a custom field as "required" when it's already in use? What will happen to the existing work packages for which the custom field is activated?

Yes, this is possible. When you edit existing work packages for which the custom field is activated but not populated you will receive the warning "[name of custom field] can't be blank" and you will have to populate the custom field.

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

