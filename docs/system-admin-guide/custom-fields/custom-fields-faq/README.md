---
sidebar_navigation:
  title: Custom fields FAQ
  priority: 001
description: Frequently asked questions regarding custom fields
keywords: custom field FAQ, project custom field, create own attribute
---

# Frequently asked questions (FAQ) for custom fields

## Is there a limit to how many values can be added to a work package custom field of the type list?

A hard limit does not exist. Nevertheless, there are factors that can represent a restriction in usability:

- Performance: So far, the allowed field values are all entered into the work package form retrieved before processing a work package. It is only a guess, but  no problems should arise when rendering in the frontend (displaying in the select field), as an autocompleter is already used here. The performance on the administration page of the user-defined field, where the possible values are maintained, could also be a factor.
- On the same administration page, editing could be difficult from a UI point of view. Especially if the user wants to sort. For example, there is currently no way to sort the values automatically. If 4000 values have to be entered and sorted, it could be a lengthy process.

## Is it possible to set a custom field as "required" when it's already in use? What will happen to the existing work packages for which the custom field is activated?

Yes, this is possible. When you edit existing work packages for which the custom field is activated but not populated you will receive the warning "[name of custom field] can't be blank" and you will have to populate the custom field.

## Where do custom fields for document categories show up?

You can find them when navigating to *Administration -> Enumerations* and clicking on an existing document category (or creating a new one).

## Can I activate custom fields for multiple projects at the same time?

Yes, you can. Select the custom field and use the **Add projects** button to add it to multiple projects at the same time.


