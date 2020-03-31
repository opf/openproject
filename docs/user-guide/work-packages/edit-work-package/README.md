---
sidebar_navigation:
  title: Edit Work packages
  priority: 900
description: How to edit work packages in OpenProject?
robots: index, follow
keywords: edit work packages
---

# Edit work packages

| Feature                                             | Documentation for                                  |
| --------------------------------------------------- | -------------------------------------------------- |
| [Update a work package](#update-a-work-package)     | How to make a change to an existing work package?  |
| [Watchers](#watchers)                               | How to add or remove watchers from a work package? |
| [Export work packages](#export-work-packages)       | How to export work packages?                       |
| [Bulk edit work packages](#bulk-edit-work-packages) | How to edit several work packages as once?         |

## Update a work package

To edit a work package, double-click in the row of a work package in the [list view](#work-package-list-view) or open the [split screen view](#work-package-split-screen-view) to see the details.

In the work package details, you can click in any field to update it, e.g. change the description, status, priority, assignee, or add a comment. 

To save changes in the description, click the **checkmark** icon.

Other input fields can be saved with **Enter**.

![edit-work-package](edit-work-package-1566546727784.png)

The green message on top of the work package indicates a successful update.

![successful-update](1566546959027.png)

All changes of a work package are documented in the work package [Activity](#activity).

<div class="alert alert-info" role="alert">
**Note**: There is no possibility to undo changes to work packages (Ctrl+Z).
</div>


### How to update the status of a work package?

To update the status of a work package, click on the current status in the work package details and select the new status in the drop-down list.

![update-status](1566375642243.png)

Please note, the status may differ from work package type. They can be configured in the [system administration](../../../system-admin-guide).

### How to add comments to a work package?

To add a comment to a work package, open the [details view](#work-package-full-screen-view) or the [split screen view](#work-package-split-screen-view) of a work package. On the tab [Activity](#activity) tab you have a comment field at the bottom (or on top depending on your [My account settings](#my-account)).

**Split screen view:**

![comment-work-packages1](comment-work-packages1.png)

### @ notification

You can add a comment or notify team members via [@notification](#notification). They will receive an email about the updates (according to their [email preferences](#email-notification) in the **My account** settings).

**Full-screen view**:

![comment-work-packages](comment-work-packages.png)

## Watchers

### How to add watchers to a work package?

<div class="glossary">
**Watchers** can be added to a work package in order to notify members about changes . They will receive emails according to their notification settings if changes are made to the respective work package.

</div>

To add watchers, open the work package [details view](#work-package-full-screen-view), select the tab watchers on the right hand side and choose the members you want to add with the drop-down menu or by starting to type their name.

![watchers](watchers.png)

### How to remove watchers from a work package?

To remove watchers, navigate to the work package [details view](#work-package-full-screen-view) and select the tab Watchers. Click the cross icon next to a watcher to remove the watcher from a a work package. The user will no longer get email notifications about changes to this work package according to the email notification settings.

![remove-watchers](remove-watchers.png)

## Export work packages

To export the work packages, choose **Export ...** in the settings menu on the top right of the work package list (or Gantt chart) view.

Please see [this separate guide](../exporting) for more information on exporting work packages.

## Bulk edit work packages

To make a bulk update and edit several work packages at once, nagivate to the work packages list view.
Highlight all work packages which you want to edit.
Tip: **keep the Ctrl. button pressed** in order to select and edit several work packages at once.

To open the quick context menu, **press the RIGHT mouse button**.

You have then the possibility to:

* Open details view of all selected work packages.
* Open the fullscreen view of all selected work packages.
* Bulk edit all selected work packages.
* Bulk change of the project of all selected work packages.
* Bulk copy all selected work packages, incl. the hierarchy relations (parent-child relations).
* Bulk delete all selected work packages.

![bulk edit right mouse click](image-20200331133245192.png)