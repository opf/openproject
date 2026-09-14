---
sidebar_navigation:
  title: Work package Atom export
  priority: 300
description: How to export a single work package in Atom format in OpenProject
keywords: work package exports, single work package, Atom
---

# Work package Atom export

If you select **Download Atom** in the work package dropdown menu, the extracted file will download automatically.

The Atom export contains one entry per activity of the work package. Every entry includes the work package title, composed of project, type, ID and subject, a link to the work package, the user who made the change, and the changed attributes together with the comment, if one was added.

## Limits

The Atom export of a single work package includes all activities you are allowed to see.

Work package lists additionally offer Atom feeds that a feed reader can subscribe to. These feeds are not part of the export dialog. They are limited by the **feed content limit** (15 items by default), which administrators can change in the [general settings](../../../../system-admin-guide/system-settings/general-settings/#general-system-settings) together with the **Enable feeds** option.

See [Export work packages](../#export-a-single-work-package) for how to trigger the export of a single work package.
