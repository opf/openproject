---
sidebar_navigation:
  title: Configure work package table
  priority: 700
description: How to configure the work package list in OpenProject?
robots: index, follow
keywords: work packages table configuration, work package list, columns, filter, group
---

# Work package table configuration

| Topic                                                        | Content                                                      |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [Add or remove columns](#add-or-remove-columns-in-the-work-package-table) | How to add or remove columns in the work package table?      |
| [Filter work packages](#filter-work-packages)                | How to filter in the work package list?                      |
| [Sort the work package list](#sort-the-work-package-list)    | How to sort within the work package list?                    |
| [Display settings](#flat-list,-hierarchy-mode-and-group-by)  | Get to know the flat list, the hierarchy mode and the group by feature. |
| [Aggregation by project](#aggregation-by-project)            | How to display an aggregated view of all milestones of multiple projects? |
| [Attribute highlighting (Premium Feature)](#attribute-highlighting-premium-feature) | How to highlight certain attributes in the work package list? |
| [Save work package views](#save-work-package-views)          | How to save a new work package view and how to change existing ones? |

You can configure the work package table view in OpenProject to display the information that you need in the list.

You can change the header in the table and add or remove columns, filter and group work packages or sort them according to a specific criteria. Also, you can change between a flat list view, a hierarchy view and a grouped view.

Save the view to have it available directly from your project menu. A work package view is the sum of all modifications you made to the default list (e.g. filters you set). 



To open the work package table configuration, open the **Settings** icon with the three dots at the top right of the work package table.

![configure-work-package-table](configure-work-package-table.png)


## Add or remove columns in the work package table

To configure the view of the work package table and have different attributes displayed in the list you can add or remove columns in the work package list.

First, [open the work package table configuration](#work-package-table-configuration).

In the pop-up window, choose the tab **Columns**.

You can add columns by typing the name of the attribute which you would like to add.

You can remove columns by clicking the **x** icon.

You order the attributes in the list with drag and drop.

![columns](1566395294543.png)

Clicking the **Apply** button will save your changes and adapt the table according to your configuration.

![columns](1566395078197.png)

## Filter work packages

In the work package list there will soon be quite a lot of work packages in a project. To filter the work packages in the list, click on the **Filter** button on top of the work packages view. The number next to it tells you how many filter criteria you have applied to a list.

In this example 1 filter criteria: Status = open.

![filter-work-packages](filter-work-packages.png)

To add a filter criteria, click the **+ Add filter:** button in the grey filter area. You can choose a filter criteria from the drop-down list or start typing to search for a criteria.

![add-filter](add-filter.png)

You can add as many filter criteria as needed. 
Also, you can filter by [custom fields](../../../system-admin-guide/custom-fields) if you set this in the custom field configuration.

If you want to search for specific text in the subject, description or comments of a work package, type in the **Filter by text** the expression you want to filter for.

The results will be displayed accordingly in the work package list.

![filter-text](filter-text.png)

## Sort the work package list

### Automatic sorting of the work package list
By default, the work package list will be sorted by work package ID. 

<div class="glossary">
The **ID** is unique for a work package within OpenProject. It will be set automatically from the system. With the ID you can reference a specific work package in OpenProject. 
</div>


To sort the work package list view, open the [work package table configuration](#work-package-table-configuration) and select the tab **Sort by**. You can sort by up to three attributes, either ascending or descending.

![1566396586476](1566396586476.png)

Clicking the blue **Apply** button will save your changes and display the results accordingly in the list view.

![sort-work-packages](sort-work-packages.png)

<div class="alert alert-info" role="alert">
**Please note**:  If you have the hierarchy mode activated, all filtered table results will be augmented with their ancestors. Hierarchies can be expanded and collapsed. 
</div>



Therefore, the results may differ if you sort in a flat list or in a hierarchy mode.

The same filter applied in the hierarchy mode.

![sort-hierarchy-mode](sort-hierarchy-mode.png)

### Manual sorting of the work package list

You can sort the work package list manually, using the icon with the 6 dots on the left of each work package to drag and drop it. 

Moving a work package will change its attributes, depending on the kind of list displayed, e.g. hierarchy changes or priority.

To keep the sorting it is necessary to [save the work package view](#save-work-package-views). 
Please note: This has no effect on the "All open" view; you have to save your sorting with another name.


## Flat list, Hierarchy mode and Group by

You have three different options to display results in the work package list.

* A **Flat list** (default), which contains all work packages in a list no matter how their parent-child-relation is.
* A **Hierarchy**, which will display the filtered results within the parent-child-relation.
* **Group by** will group the list according to a defined attribute.

You have to choose either option when displaying work packages in the list.

To switch between the different criteria, open the [work package table configuration](#work-package-table-configuration) and open the tab **Display settings**. Choose how to display the work packages in the list and click the blue **Apply** button.

![display-settings](1566397517070.png)

When choosing grouping the work package list by an attribute or by project a button to collapse groups shows up:
![collapse-button](image-20201211021022685.png)

Use it to quickly collapse or expand all groups at the same time.

## Aggregation by project

You can get a **quick overview of multiple projects** in the Gantt chart. Therefore navigate to the work package module of a project or the [project overarching work package list](../../projects/#project-overarching-reports).

**Group the list** by project by using the work package table configuration (as described above) or by clicking on the small triangle next to "Project" in the table header.
 ![group-by-project](image-20201211020614221.png)

**Display the [Gantt chart](../../gantt-chart)** by clicking on the button in the upper right corner.
![insert-gantt-chart-button](image-20201211020748715.png)

Use the minus next to the project's name or the **collapse button** in the upper right corner to collapse some or all projects.

This will give you an **aggregated view of the projects' milestones**.

**Please note**: If you want to make use of this feature, it is necessary to add milestones for the most important dates to your projects. At the moment this feature is not available for other [work package types](../../../getting-started/work-packages-introduction/#what-is-a-work-package). Which projects are shown depends on the [filters](#filter-work-packages) of the work package table you're in and your [permissions](../../../system-admin-guide/users-permissions/roles-permissions/).


## Attribute highlighting (Premium Feature)

You can highlight attributes in the work package list to emphasize the importance of certain attributes and have important topics at a glance.

The following attributes can be highlighted in the list:

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

1. Press the **Settings icon** with the three dots on the top right of the work packages list.
2. Choose **Save as...**

![Work-packages-save-view](Work-packages-save-view.png)

3. Enter a **Name** for your Saved view (according to the criteria you have chosen in your work package table configuration).

   In this example, the list was filtered for Work packages assigned to me which have a High Priority.

   **Public views:** Check the Public checkbox if you want to have this work package view accessible also for other users from this project.

   **Favored:** Check this Favored checkbox if you want to have this work package as a menu item in your Favorite views.

   Press the blue **Save** button to save your view.

![Enter-name for saved view](image-20191118172425655.png)

The view will then be saved in the work packages menu in your **Favorite views**:

![Work-packages-favorite-views](Work-packages-favorite-views.png)

If you check the Public visibility, the view will be saved under your Public views in the work package menu:

![Work-packages-public-views](Work-packages-public-views.png)

### Change saved work package views

If you make changes to a saved view, e.g. change a filter criteria, you have to save the new view once again. In order to apply the change to the actual saved view, click on the disk icon which appears next to the title of the saved view:

![Work-package-change-saved-views](Work-package-change-saved-views.png)

If you want to save a completely new work package view, again click on the Settings and select **Save as...** as described [above](#save-work-package-views). 

<div class="alert alert-info" role="alert">
**Please note**:  You can't change the default "All open" view. Therefore pressing the disc icon won't have any effect on the default view that is displayed when navigating to the work packages module. 
</div>