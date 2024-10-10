---
sidebar_navigation:
  title: Baseline comparison
  priority: 965
description: How to track changes in work packages over time.
keywords: baseline comparison, work package changes
---

# Baseline comparison

Baseline is a powerful feature that allows you to view changes to work package tables within a given period. This can be a saved view or a new filter query. Project managers can use baseline to get a quick overview of what has changed over time, making it easier to report on project progress and status.

> [!NOTE]
> Baseline comparison with yesterday is included in the Community version. Other comparison dates are Enterprise add-ons that are available with Enterprise cloud or Enterprise on-premises. An upgrade from the free Community edition is easily possible.

![Work package table list with Baseline enabled](13-0_Baseline_overview.png)

## Enable Baseline

Baseline comparison can be enabled on any work package table view:

1. Click on the **Baseline** button in the main toolbar.

2. Pick a comparison point by choosing one of the a preset options or inputting specific dates and times.

3. Click on **Apply** to enable Baseline.

![Clicking on the Baseline icon displays a dropdown that lets you pick a comparison point](13-0_Baseline_dropmodal.png)

## Show changes since yesterday (Community edition)

In the free of charge Community edition you will always be able to compare changes to work packages since yesterday.

![Compare changes in work packages since yesterday](13-0_Baseline_community_edition.png)

## Show changes for a preset period, a specific date or custom date range (Enterprise edition)

### Preset periods

Baseline offers these preset time ranges:

- _Yesterday_: Compare work packages to the previous day (also available in Community edition).

- _Last working day_: Compare work packages to the most recent working day.

- _Last week_: Compare work packages to seven working days ago.

- _Last month_: Compare work packages to thirty working days ago.

By default, Baseline will compare to 8 AM local time of the relevant day. You can change this to any other time of your choosing.

>[!NOTE]
>These are relative comparison points, which means that _Yesterday_ will always refer to the day before the current day, and not a specific date. You can use these to set up "running" baselines that show you all changes within the past day or week.

### A specific date

![You can compare the present state to a specific date in the past](13-0_Baseline_specificDate.png)

If you want to compare between now and a specific date in the past, you can select "a specific date" in the dropdown and select a particular date. With this option, the comparison will always be between the current state and that specific date in the past.

>[!NOTE]
>
>You can use this to "freeze" the baseline comparison point so that the view always shows changes in comparison to that specific date, regardless of when you access it.

### Between two specific dates

![You can see changes between two dates](13-0_Baseline_dateRange.png)

OpenProject also allows you to compare between two specific dates in the past. To select a custom date range, choose "between two specific dates" in the dropdown and select two dates in the date picker below.

>[!NOTE]
>
>This will create a fixed baseline view that will remain the same regardless of when you accesses it, since both points are fixed in the past.

## Understanding the comparison results

After selecting the comparison point, OpenProject presents the comparison results in table view using three icons to indicate the type of change for each work package.

![Baseline enabled showing changes to the work package table](13-0_Baseline_table.png)

When Baseline is enabled, you will see a legend at the top of the page which shows:

![A legend is visible on top of the table when Baseline is enabled](13-0_Baseline_legend.png)

- The comparison point or comparison period
- The number of work packages that now meet the filter criteria (and were thus added to view)
- The number of work packages that no longer meet the filter criteria (and were thus removed from view)
- The number of work packages that maintained but were modified

### Change icons

#### Now meets filter criteria

![Icon](13-0_Baseline_nowMeets.png)

Work packages that meet the filter criteria now but did not in the past are marked with an "Added" icon. These work packages were added to the current query after the selected comparison point, either because they were newly created since then or certain attributes changed such that they meet the filter criteria.

> [!NOTE]
>
> These do not necessarily represent _newly created_ work packages; simply those that are new to this particular view because they now meet the filter criteria.

#### No longer meets filter criteria

![Icon](13-0_Baseline_noLongerMeets.png)

Work packages that no longer meet the filter criteria now are marked with a "Removed" icon. These work packages were filtered out within the comparison period.

>[!NOTE]
>
>These do _not_ represent deleted work packages, which are not visible at all since no history of deleted work packages is maintained. Deleted work packages are simply ignored by Baseline.

#### Maintained with changes

![Icon](13-0_Baseline_maintainedChanges.png)

Work packages that meet the filter criteria now (and also did at the comparison point) but which have undergone changes in certain attributes are marked with a "Modified" icon.

#### No changes

When there are no changes to a work package in the comparison period, no icon is shown.

### Old values

When changes in the comparison period concern attributes that are visible as columns in the work package table, Baseline will show both old and current values. If the attribute you are interested in is not visible, you will need to [add it as a column](../work-package-table-configuration).

![Old values are visible in the work package table view](13-0_Baseline_oldNewValues.png)

Each attribute that has changed will have a grey background, with the old value crossed out visible on the top left corner of the cell, above the new value.

This allows you to have a complete view of what has changed in the comparison period.

>[!NOTE]
>
>Some attributes like _Spent time_ and _Progress_ are not tracked by Baseline and do not show the old values in the work package table. If any of the columns in your work package table are not tracked, a small warning icon in the column header will indicate this.
>
>![Unsupported columns have a warning icon next to them](13_0_Baseline_unsupportedColumn.png)

## Relation to active filters

Baseline always compares work packages between the two comparison points in relation to the current active filters. Changing the filters can change the results of the comparison.

It is not possible to compare between two different filter queries.

>[!NOTE]
>
>Some filter attributes are not tracked by Baseline and changes to them will not be taken into consideration. These include _Watcher_, _Attachment content_, _Attachment file name_ and _Comment_. These attributes are marked with a small warning icon next to them in the filter panel.
>
>![An icon and a message warning that certain filter criteria are not taken into account by Baseline](13-0_Baseline_activeFilters.png)

If you are interested in Baseline, please also take a look at this [blog article](https://www.openproject.org/blog/view-changes-on-project-baseline/).
