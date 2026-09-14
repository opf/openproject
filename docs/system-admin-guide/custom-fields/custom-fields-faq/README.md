---
sidebar_navigation:
  title: Custom fields FAQ
  priority: 001
description: Frequently asked questions regarding custom fields
keywords: custom field FAQ, project custom field, create own attribute
---

# Frequently asked questions (FAQ) for custom fields

## Is there a limit to how many values can be added to a work package custom field of the type **List**?

There is no hard limit. However, the following factors may affect usability:

- **Performance:** Currently, all allowed values are loaded into the work package form before it is displayed. Rendering the values in the frontend should generally not be a problem because an autocomplete field is used. However, performance on the custom field administration page, where the list of allowed values is maintained, may be affected.
- **Usability:** Managing a very large number of values can become difficult. For example, there is currently no way to sort values automatically. If you need to enter and manually sort thousands of values (for example, 4,000), maintaining the list can become time-consuming.

## Is it possible to set a custom field as required after it is already in use? What happens to existing work packages where the custom field is enabled?

Yes. If you make an existing custom field required, existing work packages that do not yet have a value remain unchanged. However, when users edit one of these work packages, they will receive the validation message **"[Custom field name] can't be blank"** and must populate the field before they can save their changes.

## Where do custom fields for document categories appear?

You can find them under **Administration → Enumerations** by opening an existing document category or creating a new one.

## Can I activate a custom field for multiple projects at the same time?

Yes. Open the custom field and use the **Add projects** button to assign it to multiple projects at once.

## How can I create custom fields for users?

Starting with OpenProject 17.7, user custom fields have became **user attributes**.

In versions prior to 17.7, user custom fields were managed under **Administration → Custom fields**. Since 17.7, they are managed under **Administration → Users and permissions → User attributes**.

## What happened to project custom fields?

Starting with OpenProject 14.0, **project custom fields** were renamed to **project attributes**.

If you are looking for information about configuring project custom fields, refer to the documentation on project attributes:

- **User guide:** [Project attributes](../../../user-guide/projects/project-home/project-attributes)
- **Administrator guide:** [Project attributes](../../projects/project-attributes)