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

For an overview of the available custom field formats, configuration options, and where to manage custom fields, see [Manage custom fields](../).

For instructions on managing custom fields in different areas of OpenProject, see the following guides:

- [Work package custom fields](../manage-work-packages/work-package-custom-fields/)
- [Version custom fields](../manage-work-packages/version-custom-fields/)
- [Project attributes](../projects/project-attributes/)
- [User attributes](../users-permissions/user-attributes/)
- [Time and costs](../time-and-costs/)
- [Groups](../users-permissions/groups/)

## Is there a limit to how many values can be added to a work package custom field of the type List?

There is no hard limit. However, the following factors may affect usability:

- **Performance:** Large numbers of selectable values may affect performance, particularly on the custom field administration page where these values are maintained.
- **Usability:** Managing a very large number of values can become difficult. For example, there is currently no way to sort values automatically. If you need to enter and manually sort thousands of values (for example, 4,000), maintaining the list can become time-consuming.

## Is it possible to set a custom field as required after it is already in use? What happens to existing work packages where the custom field is enabled?

Yes. If you make an existing custom field required, users must provide a value when creating new work packages to which the custom field applies. Existing work packages that do not yet contain a value remain unchanged and can still be updated without filling in the field.

## Where do custom fields for document categories appear?

You can find them by opening an existing document category or creating a new one in the system administration.

## Can I activate a custom field for multiple projects at the same time?

Yes. Navigate to *Administration → Work packages → Custom fields*, open the relevant custom field, and select the **Projects** tab. Click **Add projects** to activate the custom field for multiple projects at once.

For more information, see [Activate a custom field for projects](../../manage-work-packages/work-package-custom-fields/#activate-a-custom-field-for-projects).

## Can I make different custom field values available in different projects?

Yes. Starting with OpenProject 18.0, you can configure project-specific values for work package custom fields of the **List**, **Hierarchy**, and **Weighted item list** formats.

Using an allow filter or a block filter, you can control which values are available in individual projects without having to create separate custom fields for each project.

This functionality is an Enterprise add-on. For more information, see [Project-specific values](../../manage-work-packages/work-package-custom-fields/#project-specific-values-enterprise-add-on).

## How can I create custom fields for users?

Starting with OpenProject 17.7, user custom fields are managed as **user attributes** under *Administration → Users and permissions → User attributes*.

For more information, see [Manage user attributes](../../users-permissions/user-attributes/).