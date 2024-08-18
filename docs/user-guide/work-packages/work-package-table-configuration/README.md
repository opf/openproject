---
sidebar_navigation:
  title: Configure work package table
  priority: 950
description: How to configure the work package list in OpenProject.
keywords: work packages table configuration, work package table, columns, filter, group
---

# Work package table configuration

| Topic                                                        | Content                                                      |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [Add or remove columns](#add-or-remove-columns-in-the-work-package-table) | How to add or remove columns in the work package table.      |
| [Filter work packages](#filter-work-packages)                | How to filter in the work package table.                     |
| [Sort the work package table](#sort-the-work-package-table)  | How to sort within the work package table.                   |
| [Display settings](#flat-list-hierarchy-mode-and-group-by)   | Get to know the flat list, the hierarchy mode, the group by and the sum feature. |
| [Attribute highlighting (Enterprise add-on)](#attribute-highlighting-enterprise-add-on) | How to highlight certain attributes in the work package table. |
| [Save work package views](#save-work-package-views)          | How to save a new work package view and how to change existing ones. |

You can configure the work package table view in OpenProject to display the information that you need in the table.

You can change the header in the table and add or remove columns, filter and group work packages or sort them according to specific criteria. Also, you can change between a flat list view, a hierarchy view and a grouped view.

Save the view to have it available directly from your project menu. A work package view is the sum of all modifications you made to the default table (e.g. filters you set).

To open the work package table configuration, open the **Settings** icon with the three dots at the top right of the work package table.

![configure-work-package-table](configure-work-package-table.png)

## Add or remove columns in the work package table

To configure the view of the work package table and have different attributes displayed in the table you can add or remove columns in the work package table.

First, [open the work package table configuration](#work-package-table-configuration).

In the pop-up window, choose the tab **Columns**.

You can add columns by typing the name of the attribute which you would like to add.

You can remove columns by clicking the **x** icon.

You order the attributes via drag and drop.

![columns](1566395294543.png)

Clicking the **Apply** button will save your changes and adapt the table according to your configuration.

![columns](1566395078197.png)

## Filter work packages

To filter the work packages in the table, click on the **Filter** button on top of the work packages view. The number next to it tells you how many filter criteria you have applied to a table.

In this example one filter criterion is applied: Status = open.

![filter-work-packages](filter-work-packages.png)

To add a filter criterion, choose one from the drop-down list next to **+ Add filter** or start typing to search for a criterion.

![add-filter](add-filter.png)

You can add as many filter criteria as needed.
Also, you can filter by [custom fields](../../../system-admin-guide/custom-fields) if you set this in the custom field configuration.

> **Good to know**: Filtering a work package table will temporarily change the default work package type and default status to the values used in the filters to make newly created work packages visible in the table.

### Filter operators

Different attributes offer different filter criteria but most selection attributes like Assignee offer these:

- **is (OR)**: returns all work packages that match any one of the entered values
- **is not**: returns all work packages that do not match any of the entered values
- **is not empty**: returns all work packages for which the attribute has a value
- **is empty**: returns all work packages for which the attribute does not have a value

Multi-select attributes also have one extra options:

- **is (AND)**: returns all work packages that match _all_ of the entered values.

Other attributes like Status might offer additional criteria like _open_ or _closed_. Required attributes might only offer two options, _is (OR)_ and _is not_, since they cannot be empty.

### Filter by text

If you want to search for specific text in the subject, description or comments of a work package, type in the **Filter by text** the expression you want to filter for.

The results will be displayed accordingly in the work package table.

![filter-text](filter-text.png)

### Filter for a work package's children

If you want to only show work package with specific parents (e.g. all work packages belonging to a specific phase of your project) you can use the filter "Parent". Enter all required work packages and press Enter. This will show the selected work package(s) and its/their children.
If you only select work packages without children, no work packages will be shown at all.

![filter-for-parent-work-package](filter-for-parent-work-package.png)

### Include/exclude work packages from a specific project or subproject

It is possible to display the work packages from more than one project. To include, or exclude such work packages, use the **Include projects** button on top of the work package table view, where you can select/unselect the appropriate projects and sub-projects you want to add.
To automatically include all sub-projects for each project you chose to select, check the **Include all sub-projects** box at the bottom of the dialog.

![work-package-filter-include-projects](work-package-filter-include-projects.png)

To view all work packages across all projects you could select everything, or use the [global work package tables](../../projects/project-lists/#global-work-package-tables).

### Filter by ID or work package name

If you want to [create a work package view](#save-work-package-views) with only specific work packages you can use the filter "ID". By entering the ID or subject of work packages you can select them.
Another use case would be to *exclude* specific work packages (e.g. you want to display all milestones but one). Therefore, use the "is not" option next to the filter's name on the left.

![filtering-by-work-package-id](filtering-by-work-package-id.png)

### Filter for assignees or assigned groups

There are several options to filter for the assignee of a work package. You can choose one of these filters:

- Assignee: Filters for work packages where the specified user or group is set as Assignee
- Assignee or belonging group:
  - When filtering for a single user: Work packages assigned to this user, and any group it belongs to
  - When filtering for a group: Work packages assigned to this group, and any users within
- Assignee's group: Filters for work packages assigned to a user from this group
- Assignee's role: Filters for work packages assigned to users with the specified project role

![assignee-or-assignee-group-filter](assignee-or-assignee-group-filter.png)

### Filter for attachment file name and content

You can run a full text search and filter and search not only headings and text contents but also file names or file contents of attached documents to work packages.

Use the filter "Attachment content" or "Attachment file name" to filter attached documents in the work package table.

![advanced-filter-work-package-table](advanced-filter-work-package-table.png)

For both the file name and the content, you can then differentiate the filtering with the "contains" and "does not contain" options for selected keywords and text passages. To do this, please enter the corresponding text in the field next to it.

![advanced-filter-options](advanced-filter-options.png)

It will then display the corresponding work package with the attachment.

![openproject-search-work-package-attachments](openproject-search-work-package-attachments.png)

## Sort the work package table

### Automatic sorting of the work package table

By default, the work package table will be sorted by work package ID.

<div class="glossary">
The **ID** is unique for a work package within OpenProject. It will be set automatically from the system. With the ID you can reference a specific work package in OpenProject.
</div>
To sort the work package table view, open the [work package table configuration](#work-package-table-configuration) and select the tab **Sort by**. You can sort by up to three attributes, either ascending or descending.

![work-package-table-configuration](work-package-table-configuration-4874227.png)

Clicking the blue **Apply** button will save your changes and display the results accordingly in the table view.

![sort-work-packages](sort-work-packages.png)

> **Please note**:  If you have the hierarchy mode activated, all filtered table results will be augmented with their ancestors. Hierarchies can be expanded and collapsed.

Therefore, the results may differ if you sort in a flat list or in a hierarchy mode.

The same filter applied in the hierarchy mode.

![sort-hierarchy-mode](sort-hierarchy-mode.png)

### Manual sorting of the work package table

You can sort the work package table manually, using the icon with the 6 dots on the left of each work package to drag and drop it.

Moving a work package will change its attributes, depending on the kind of table displayed, e.g. hierarchy changes or priority.

To keep the sorting it is necessary to [save the work package view](#save-work-package-views).
Please note: This has no effect on the "All open" view; you have to save your sorting with another name.

## Flat list, Hierarchy mode and Group by

You have three different options to display results in the work package table.

* A **Flat list** (default), which contains all work packages in a list no matter how their parent-child-relation is.
* A **Hierarchy**, which will display the filtered results within the parent-child-relation.
* **Group by** will group the table according to a defined attribute.

To display the work package table you have to choose one of these options.

To switch between the different criteria, open the [work package table configuration](#work-package-table-configuration) and open the tab **Display settings**. Choose how to display the work packages in the table and click the blue **Apply** button.

![display-settings](image-20210426164224748.png)

When you group the work package table by an attribute or by project a **button to collapse groups** shows up:
![collapse-button](collapse-all-expand-all.png)

Use it to quickly collapse or expand all groups at the same time. Find out [here](../../gantt-chart/#aggregation-by-project) how to use this feature for a **quick overview of several projects** at once.

### Display sums in work package table

To display the sums of eligible work package attributes, go to the work package table configuration and click on the tab **Display settings** (see screenshot above). When you tick the box next to **Display sums** the sums of **Work** (earlier called Estimated time) and **Remaining work** (earlier called Remaining hours) as well as custom fields of the type Integer or Float will be displayed at the bottom of the work package table.
If you group the work package table, sums will be shown for each group.

## Attribute highlighting (Enterprise add-on)

You can highlight attributes in the work package table to emphasize the importance of certain attributes and have important topics at a glance.

The following attributes can be highlighted in the table:

* Priority
* Status
* Finish date

![attribute-highlighting](attribute-highlighting.png)

Furthermore, you can highlight the entire row by an attribute. The following attributes can be highlighted as a complete row:

* Priority
* Status

![highlight-priority](1566399038768.png)

You can configure the colors for attribute highlighting in the system administration. Find out how to set it for the color of the priority [here](../../../system-admin-guide/enumerations/#edit-or-remove-enumeration-value) and for the color of the status [here](../../../system-admin-guide/manage-work-packages/work-package-status/#edit-re-order-or-remove-a-work-package-status).

## Save work package views

When you have configured your work package table, you can save the views to access them again and share them with your team.

1. Press the **Settings icon** with the three dots on the top right corner of the work package table.
2. Choose **Save as...**

![Work-packages-save-view](Work-packages-save-view.png)

3. Enter a **Name** for your saved view (according to the criteria you have chosen in your work package table configuration).

   In this example, the table was filtered for work packages assigned to me which have a high priority.

   **Public views:** Check the public checkbox if you want to have this work package view accessible also for other users from this project.

   **Favored:** Check this favored checkbox if you want to have this work package as a menu item in your favorite views.

   Press the blue **Save** button to save your view.

![Enter-name for saved view](image-20191118172425655.png)

The view will then be saved in the work packages menu in your **Favorite views**:

![Work-packages-favorite-views](Work-packages-favorite-views.png)

If you check the public visibility, the view will be saved under your public views in the work package menu:

![Work-packages-public-views](Work-packages-public-views.png)

**Please note:** The collapse status (collapsed or expanded groups) can not be saved.

### Change saved work package views

If you make changes to a saved view, e.g. change a filter criteria, you have to save the new view once again. In order to apply the change to the actual saved view, click on the disk icon which appears next to the title of the saved view:

![Work-package-change-saved-views](Work-package-change-saved-views.png)

If you want to save a completely new work package view, again click on the settings and select **Save as...** as described [above](#save-work-package-views).

> **Please note**:  You can't change the default "All open" view. Therefore pressing the disc icon won't have any effect on the default view that is displayed when navigating to the work packages module. You always have to create a new view (filter, group, etc.), set a name and save it (private or public).
