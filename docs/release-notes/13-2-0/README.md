---
title: OpenProject 13.2.0
sidebar_navigation:
    title: 13.2.0
release_version: 13.2.0
release_date: 2024-01-17
---

# OpenProject 13.2.0

Release date: 2024-01-17

We released [OpenProject 13.2.0](https://community.openproject.org/versions/1979).

Among other features, it brings improvements for the **OneDrive/SharePoint integration**, now also allowing **manual project folders**. In addition to that, both OneDrive/SharePoint and Nextcloud integrations were improved by **showing deleted files in OpenProject work packages**.

We also added the option to **filter the project member list**, allowing project administrators to easily filter through the project member lists based on various roles, groups and shares. Instance administrators can now also allow for users to **change work package status without the rights to edit a work package**.

Furthermore, it is now **possible to set users with whom a work package has been shared as assignee or responsible**. The **quick content menu** in the Gantt view has now offers an additional option to show work package relations.

Finally, **several fields were renamed**:

- **Estimated time** is now called Work (calculation of **Work** has also been updated)
- **Remaining hours** is now called Remaining work (calculation of **Remaining work** has also been updated)
- **Progress (%)** is now called **% Complete**

As always, this release contains several bug fixes and we recommend updating to the newest version.

## Manual project folders for OneDrive/SharePoint storages (Enterprise add-on)

With OpenProject 13.2, manual project folders have become available for OneDrive/SharePoint storage, further improving access to essential project files.

When project folders are configured, all project-related files are automatically uploaded and organized within the specified folder. To activate project folders, administrators are required to designate the desired folder as the project folder and manually configure the associated permissions. This feature enhances user convenience and file organization within the OpenProject environment.

![Manual project folders for OneDrive/SharePoint storages in OpenProject](onedrive-storage-add-folders.png)

See our user guide to learn more about this Enterprise add-on and how to [use the SharePoint integration](../../user-guide/file-management/one-drive-integration/).

## Show file links of files that are not available to the user in the cloud storage

In 13.2 we improved the functionality of file storages. Even if a file has been deleted on a file storage, it will still be displayed under the Files tab in OpenProject work packages, allowing users to better keep track of project files.

![Deleted file storage file in OpenProject](deleted-file.png)

This new feature is available for [both file storage integrations](../../user-guide/file-management).

## Filter for roles, groups, and shares in the project members list

With OpenProject 13.2, users can filter the list of project member based on user roles, groups, and shared work packages. This enables project members to promptly identify others with specific roles or individuals outside the project team who have gained access through the newly introduced Sharing feature.

![Project members filter in OpenProject](project-members.png)

Read more about filtering the project members list in our [user guide](../../user-guide/members/#project-members-overview).

## Allow assignee and accountable for shared work packages (Enterprise add-on)

In OpenProject 13.1, we introduced the work package sharing feature with external users. In the 13.2 release, these shared users can now be designated as assignee and accountable for the work packages that have been shared with them. This is useful for teams collaborating with external partners who cannot access sensitive project data but still require access to specific tasks within the project.

Learn more about our [Sharing work packages (Enterprise add-on)](../../user-guide/work-packages/share-work-packages/).

## Status change without rights to edit a work package

In OpenProject 13.2, the ability to modify the status of a work package is now separated from the broader "Edit work package" permission. This separation means that a user can be granted the right to change the status without having the permission to edit the entire work package.

Read more about [roles and permissions for users of OpenProject](../../system-admin-guide/users-permissions/roles-permissions/).

## Quick context menu in Gantt view: Show relations

Quick context menu in the Gantt view now includes "Show relations" option. It displays all existing relations for the selected work package.

Please note that this option is only available if you have selected a Gantt view (i.e. not a table or cards view).

![Quick context menu in Gantt charts in OpenProject](gantt-relations.png)

Read more about [Gantt charts in OpenProject](../../user-guide/gantt-chart/)

## New field names and calculation of work and remaining work

Several field names were changed in OpenProject 13.2.

- Estimated time is now called **Work**
- Remaining hours is now called **Remaining work**
- Progress (%) is now called **% Complete**

Furthermore, the calculation of **Work** and **Remaining work** has been modified, now featuring a sum value (∑) displayed in the "Work" and "Remaining work" fields. This sum shows the total value of all child elements within the work package, including the work package itself.

Please note that **% Complete** does not adjust automatically when the values of **Work** or **Remaining work** are changed.

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Bugfix: "Spent time" is not translated on overview page \[[#42646](https://community.openproject.org/wp/42646)\]
- Bugfix: Notifications view is cut off on Samsung Galaxy S21 \[[#44221](https://community.openproject.org/wp/44221)\]
- Bugfix: Project "Members" list names groups that are irrelevant for the project \[[#47613](https://community.openproject.org/wp/47613)\]
- Bugfix: Dismiss action of the primer banner is not translated \[[#51360](https://community.openproject.org/wp/51360)\]
- Bugfix: In mobile view, the primer banner does not take the full width \[[#51370](https://community.openproject.org/wp/51370)\]
- Bugfix: Can not add invited users to existing groups \[[#51679](https://community.openproject.org/wp/51679)\]
- Bugfix: Project.visible scope slower than it should be \[[#51706](https://community.openproject.org/wp/51706)\]
- Bugfix: Ongoing meetings are not visible via the Meetings tab in work packages \[[#51715](https://community.openproject.org/wp/51715)\]
- Bugfix: The Access Token expiry date not updated on refresh for FileStorage tokens \[[#51749](https://community.openproject.org/wp/51749)\]
- Bugfix: Work package share permissions not in Work package permission group \[[#52086](https://community.openproject.org/wp/52086)\]
- Bugfix: lockVersion missing in payload for API WP form when only having change_work_package_status permission \[[#52089](https://community.openproject.org/wp/52089)\]
- Bugfix: Status cannot be changed in backlogs when only having change_work_package_status permission \[[#52090](https://community.openproject.org/wp/52090)\]
- Bugfix: Primer tooltips are cut off in OpenProject \[[#52099](https://community.openproject.org/wp/52099)\]
- Bugfix: Remaining hours field not renamed in backlogs forms \[[#52107](https://community.openproject.org/wp/52107)\]
- Bugfix: Estimated time is not updated when a sub-WP is delete. \[[#52125](https://community.openproject.org/wp/52125)\]
- Feature: Shared with users can become assignee of the work package \[[#49527](https://community.openproject.org/wp/49527)\]
- Feature: Allow status change without Edit WP rights \[[#50849](https://community.openproject.org/wp/50849)\]
- Feature: Change calculation and name of Work and Remaining work \[[#50953](https://community.openproject.org/wp/50953)\]
- Feature: Gantt: shorten menu and add "Show relations" action \[[#51170](https://community.openproject.org/wp/51170)\]
- Feature: Enable manual project folders for OneDrive/SharePoint storages \[[#51362](https://community.openproject.org/wp/51362)\]
- Feature: Filter project member list \[[#51484](https://community.openproject.org/wp/51484)\]
- Feature: Use the new defaults on the project index page for page header and sidebar \[[#51678](https://community.openproject.org/wp/51678)\]
- Feature: Teaser the share feature in the Community edition \[[#51704](https://community.openproject.org/wp/51704)\]
- Feature: Show file links of files that are not available to the user in the cloud storage \[[#52013](https://community.openproject.org/wp/52013)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->

## Contributions

A very special thank you goes to our sponsors for features and improvements of this release:

- **AMG** - for the advanced filters for project members lists
- **Deutsche Bahn** - for the manual project folders for OneDrive/SharePoint integration
- **German Federal Ministry of the Interior and Home Affairs (BMI)** - for the improvements to progress reporting

A big thanks to Community members for reporting bugs and helping us identifying and providing fixes, especially to Arun M, Patrick Massé and Richard Richter.

A big thank you to every other dedicated user who has [reported bugs](../../development/report-a-bug), supported the community by asking and answering questions in the [forum](https://community.openproject.org/projects/openproject/boards) and provided translations on [CrowdIn](https://crowdin.com/projects/opf).
