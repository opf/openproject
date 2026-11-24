---
sidebar_navigation:
  title: Custom fields FAQ
  priority: 001
description: Frequently asked questions regarding custom fields in OpenProject.
keywords: custom field FAQ, project custom field, create own attribute, required custom fields, project-specific values
---

# Frequently asked questions (FAQ) for custom fields

## Where can I manage custom fields?

Starting with OpenProject 18.0, custom fields are managed directly within the relevant sections of the system administration rather than in a central Custom fields overview.

For an overview of the available custom field formats and configuration options, see [Manage custom fields](../).

For instructions on managing custom fields in different areas of OpenProject, see the following guides:

- [Work package custom fields](../../manage-work-packages/work-package-custom-fields/)
- [Version custom fields](../../manage-work-packages/version-custom-fields/)
- [Project attributes](../../projects/project-attributes/)
- [User attributes](../../users-permissions/user-attributes/)
- [Time and costs](../../time-and-costs/)
- [Groups](../../users-permissions/groups/)

## Is there a limit to how many values can be added to a work package custom field of the List format?

There is no hard limit. However, a large number of selectable values may affect performance, particularly on the custom field administration page where these values are maintained.

Large lists can also be difficult to maintain and navigate. When defining the available values, consider how easily users can find and select the information they need.

## Can I make an existing custom field required? What happens to existing work packages?

Yes. If you make an existing custom field required, users must provide a value when creating new work packages to which the custom field applies. Existing work packages that do not yet contain a value remain unchanged and can still be updated without filling in the field.

## Where do custom fields for document categories appear?

You can find them by opening an existing document category or creating a new one in the system administration.

## How do I make a work package custom field available in multiple projects?

Starting with OpenProject 18.0, work package custom fields are no longer activated or deactivated individually for each project. Instead, their availability is determined by the forms used by work package types and variants.

Navigate to *Administration → Work packages → Forms*, open the relevant form, and add the custom field to it. The custom field will then be available in all projects where the types or variants using that form are enabled.

To review where an existing custom field is used, navigate to *Administration → Work packages → Custom fields* and open the field. The **Forms**, **Types and variants**, and **Projects** tabs show the corresponding associations.

For more information, see [Make custom fields available in work packages](../../manage-work-packages/work-package-custom-fields/#make-custom-fields-available-in-work-packages).

## Can I make different custom field values available in different projects?

Yes. Starting with OpenProject 18.0, you can configure project-specific values for work package custom fields of the **List**, **Hierarchy**, and **Weighted item list** formats.

Using an allow filter or a block filter, you can choose which values to enable or disable for individual projects without having to create separate custom fields. To configure the available values for a particular project, open the custom field's **Projects** tab.

These settings control which values users can select, not whether the custom field itself is available in a project.

This functionality is an Enterprise add-on. For more information, see [Project-specific values](../../manage-work-packages/work-package-custom-fields/#project-specific-values-enterprise-add-on).

## How can I create custom fields for users?

Starting with OpenProject 17.7, user custom fields are managed as **user attributes** under *Administration → Users and permissions → User attributes*.

For more information, see [Manage user attributes](../../users-permissions/user-attributes/).