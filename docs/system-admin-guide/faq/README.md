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

## Is it possible to only allow authentication via SSO (not via user name / password)?

Yes, for Enterprise on-premises and Community Edition there is a [configuration option](../installation-and-operations/configuration/#disable-password-login) to disable the password login.

## How do I set up OAuth / Google authentication in the Enterprise cloud?

The authentication via Google is already activated in the Enterprise cloud. Users who are invited to OpenProject, should be able to choose authentication via Google. There should be a Google button under the normal user name / password when you try to login. 

## Is it possible to set a custom field as "required" when it's already in use? What will hapen to the existing work packages for which the custom field is activated?

Yes, this is possible. When you edit existing work packages for which the custom field is activated but not populated you will receive the warning "[name of custom field] can't be blank" and you will have to populate the custom field.





## [FAQ for work package settings](../manage-work-packages/faq)



## [FAQ for incoming emails](../email/faq)

