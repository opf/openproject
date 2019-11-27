---
sidebar_navigation:
  title: Time and cost reporting
  priority: 797
description: Time and cost reporting
robots: index, follow
keywords: time and cost reporting
---

# Time and cost reporting

You can easily report spent time and costs in OpenProject and filter, group and save the reports according to your needs.

<div class="alert alert-info" role="alert">
**Note**: If you want to use the reporting functionality,, the **Cost reports module** needs to be activated in the project settings.
</div>

| Feature                                                      | Documentation for                                            |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [Time and costs report](#time-and-costs-reports)             | How to open time and costs reports in OpenProject?           |
| [Change time and costs reports](#change-time-and-costs-reports) | How to change the view of the reports, e.g. to filter, group by and select units to be displayed? |
| [Filter cost reports](#filter-cost-reports)                  | How to filter time and cost reports?                         |
| [Group by criteria for cost reports](#group-by-criteria-for-cost-reports) | How to group time and cost reports?                          |
| [Select units to display](#select-units-to-display)          | How to choose the unit to be displayed in a report?          |

## Time and costs reports

To open the time and costs reports in OpenProject, navigate to the **Cost reports** module in the project navigation.

![Time-costs-reports](Time-costs-reports.png)

## Change time and costs reports

You can change the view of a cost reports and adapt it to your needs.

### Filter cost reports

You can select and apply various filters, such as work package, author, start date or target version.

Multiple projects can be selected with the **Projects** filter. Depending on your rights in the project, multiple users can also be selected. This way you can filter the time and cost entries exactly to your need, depending on the time, work or user you want to see.

The results will the be displayed in the time and cost report below.

![Time-costs-filter](Time-costs-filter.png)

### Group by criteria for cost reports

The time and cost reports can be grouped by selected criteria, such as dates, work packages, assignee, or any other field, incl. custom fields.

To add grouping criteria to the columns or rows of the report, select the drop-down field on the right to **add grouping field**.

![Time-cots-group-by](Time-cots-group-by.png)

The grouping criteria will then be added to the Column or Row of the report. 

Click the blue **Apply button** in order to display your changes.

![Time-costs-reports-columns-rows](Time-costs-reports-columns-rows.png)

The report will then be displayed according to the selected criteria in the columns and rows.

You can make changes to the order of the grouping criteria in the columns or rows with drag and drop.

### Select units to display

In the time and cost reports you can select the **units** which you want to display.

You can either select **Labor** which will display the logged time to the work packages according the filter and group by criteria above.

![Time-costs-units](Time-costs-units-1574773348146.png)

The **Cash value** will display the costs logged according to the filter and grouping criteria above. This includes labor costs (calculated based on the logged time and the [hourly rate](#/cost-tracking/#hourly-rate)) as well as the unit costs.

![Time-costs-cash-value](Time-costs-cash-value.png)

## Report unit costs

If you just want to report on spent **unit costs**, choose the respective unit costs in the cost report under Units. Only the logged unit costs will then be displayed in the report according to your filter and grouping criteria.

![Time-costs-unit-costs](Time-costs-unit-costs.png)