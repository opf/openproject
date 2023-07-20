# Baseline comparison (work in progress)

Baseline is a powerful tool that allows you to view changes to a list of work packages within a given period. This list can be a saved view or a new filter query.  Project managers can use baseline to get a quick overview of what has changed over time, making it easier to report on project progress and status.

## Enabling Baseline

Baseline mode can be enabled on any work package list view:

1. Navigate to a saved view or create a new one with a new set of filter criteria.

2. Click on the **Baseline** button in the main toolbar.

3. Pick a comparison point by choosing one of the a preset options or specifying specific dates.

4. Click on **Apply** to enable Baseline.

## Selecting the Comparison Point

You have the flexibility to choose to which point in time you would like to compare the current list of work packages. OpenProject offers a number of options under the "Show changes since" drop-down.

### Preset Periods

Baseline offers these preset time ranges:

- Yesterday: Compare work packages to the previous day.

- Last working day: Compare work packages to the most recent working day.

- Last week: Compare work packages to seven working days ago.

- Last month: Compare work packages to thirty working days ago.

>**Note:** These are relative comparison points, which means that _Yesterday_ will always refer to the day the current day, and not a specific day. You can use these to set up, for example, "running" baselines that show you all the things that have happened within the past week.

### Specific Date

If you want to compare between now and a specific date in the past, you can select "a specific date" from the dropdown and select a particular date. With this option, the comparison will always be between the current state and that specific date in the past.

>**Note:** You can use this to "freeze" a baseline point, so the view always shows changes in comparison to that particular time. 

### Custom Date Range

OpenProject also allows you to compare work packages between two specific dates in the past. To select a custom date range:

1. Click on the "Baseline" button/icon in the toolbar.

2. From the dropdown menu, choose "between two specific dates".

3. Two date pickers will appear, representing the start and end dates of the desired range. Click on the dates to choose them accordingly.

>**Note**: This is will create a fixed baseline view that will remain the same regardless of when a user accesses it, since both points are in the past.

## Understanding the Comparison Results

After selecting the comparison point, OpenProject performs the analysis and presents the comparison results in the list view using three icons to indicate the type of change for each work package:

### Now meet filter criteria

Work packages that meet the filter criteria now but did not exist at the comparison point are marked with a "New" icon. These work packages were effectively added to the view after the selected comparison point.

### No longer meet filter criteria

Work packages that no longer meet the filter criteria now are marked with a "Removed" icon. These work packages but have been filtered out since the comparison point.

### Maintained with changes

Work packages that meet the filter criteria now (and also did at the comparison point) but which have undergone changes in certain attributes are marked with a "Modified" icon. 

### No changes

When there are no changes to a work package in the comparison period, no icon is shown.