---
sidebar_navigation:
  title: Work packages FAQ
  priority: 001
description: Frequently asked questions regarding work package settings in the administration.
keywords: manage work packages FAQ, admin settings for work packages, type variants, forms, workflows
---

# Frequently asked questions (FAQ) for work package settings

> [!NOTE]
> OpenProject 18.0 introduced changes to work package types and variants, reusable workflows and forms, and status configuration. For an overview of these changes and important information about upgrading, see the [OpenProject 18.0 release notes](../../../release-notes/18-0-0/).

## Why can I not see my new work package status in the workflow settings?

Make sure the status has been added to the workflow you are configuring.

Workflows can be assigned to multiple work package types and variants. Adding a new status in the administration does not automatically make it available in every workflow.

Open the relevant [workflow](../work-package-workflows/) and add the status to its configuration.

## What happens to existing values of work package attributes if I remove the attribute from the work package form? Will they be deleted?

Removing an attribute from a work package form or hiding it for a specific type or variant does not delete its existing values. The attribute is no longer displayed in the corresponding work package form.

If the attribute is added or made visible again, its existing values are displayed.

Hiding an attribute does not create an entry in the work package activity.

> [!NOTE]
> If you *delete* a custom field in the custom field administration, its stored values will also be deleted.

## How can I change the default type for work packages?

The work package type at the top of the [types list](../work-package-types/) is the default type.

To change it, use the arrows on the right to move another type to the top of the list.

## What is the difference between a work package type and a type variant?

A work package type defines a category of work, such as Task, Bug, or Feature.

A type variant allows you to use different configurations of the same work package type in different projects. For example, two projects can use the Bug type with different workflows and forms.

Variants retain the name of their parent type, so work packages can still be grouped and filtered by type across projects.

Each project uses either the original type or one of its variants.

For more information, see [Manage work package types](../work-package-types/).

## Can project administrators create their own type variants?

Yes, if an instance administrator has enabled this option for the relevant work package type.

Project administrators can then create project-specific variants that are available only in their project.

Instance administrators can manage variants across projects and make project-specific variants available to other projects.

## What happens when I change a shared workflow or form?

Workflows and forms can be reused across multiple work package types and variants.

If you edit a shared workflow or form, the changes affect all types and variants that use it.

If you need a different configuration for a particular type or variant, create a separate workflow or form instead.

See [Workflows](../work-package-workflows/) and [Forms](../work-package-forms/) for more information.

## What happens to existing work package configurations when upgrading to OpenProject 18.0?

Existing work package types continue to work after upgrading to OpenProject 18.0.

If projects previously used different project-specific custom field configurations, OpenProject automatically creates type variants where necessary to preserve these differences.

These variants are marked as **Migrated** in the work package type administration.

Administrators should review migrated variants after upgrading. A migrated variant can be deleted once no project uses it anymore.

## Why can I not find the option to set a progress percentage for a work package status?

You have to activate progress calculation by status first. Find out [here](../work-package-settings/) how to do it.

## Can I switch back to numerical work package identifiers later?

Yes. If you switch from numerical identifiers to project-based identifiers, you can switch back at any time. Changing the identifier mode requires administrator permissions.

## Will existing work package links continue to work after switching identifier modes?

Yes. Existing numerical identifiers remain associated with their original work packages and continue to resolve correctly.

## What happens if a project identifier changes?

Historical references remain functional. OpenProject continues to resolve references that use previously assigned project identifiers.

## Are project-based work package identifiers available everywhere in OpenProject?

Project-based identifiers are supported in many areas of OpenProject. Some areas of the application may still display numerical identifiers; in these cases, numerical identifiers remain fully functional and continue to resolve to the same work packages.

## Do integrations support project-based work package identifiers?

Yes. Project-based work package identifiers are supported by GitHub and GitLab integrations. References to work packages continue to resolve correctly when using project-based identifiers.

Support for project-based identifiers is also available in other key areas of OpenProject, including work package URLs, notifications, searches, exports, and the API.