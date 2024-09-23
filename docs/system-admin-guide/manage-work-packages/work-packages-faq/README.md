---
sidebar_navigation:
  title: Work packages FAQ
  priority: 001
description: Frequently asked questions regarding work package settings in the administration
keywords: manage work packages FAQ, admin settings for work packages
---

# Frequently asked questions (FAQ) for work package settings

## Why can I not see my new work package status in the workflow settings?

Make sure to un-check the option "Only display statuses that are used by this type".

## What happens to existing values of work package attributes if I remove the attribute from the work package form? Will they be deleted?

If work package attributes are removed from the form configuration of a work package type, the values are no longer displayed. However, if the attribute is later added to the form configuration again, then this attribute is displayed again. No change is displayed in the activity of the work package if changes are made to the displayed attributes in the administration (the attribute is therefore purely hidden / values are not removed).
Please note: If you *delete* a custom field (in the custom field configuration) its values will be deleted, too.

## How can I change the default type for work packages?

The work package type that is at the top of the [list](../work-package-types) is the default type. To change it, use the arrows on the right to move another type to the top of the list.

## Why can I not find the option to set a progress percentage for a work package status?

You have to activate the progress calculation by status first. Find out [here](../work-package-settings) how to do it.
