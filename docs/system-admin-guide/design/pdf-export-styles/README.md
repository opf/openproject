---
sidebar_navigation:
  title:  PDF Export Styling
keywords: pdf export styling
---
# PDF Export Styling

These documents describe the style settings format for **PDF Export styling files**.

The described files are YAML files used by the export to apply the styles.

| YAML file                                                               | PDF Export                                                 |
|-------------------------------------------------------------------------|------------------------------------------------------------|
| [attributes-and-description/standard.yml](./attributes-and-description) | Single PDF Export template "Attributes and description"    |
| [report/standard.yml](./report)                                                      | PDF Export template "Report", "Overview table" and "Gantt" |
| [timesheet/standard.yml](./timesheet)                                                | PDF Export of timesheets of the Cost module                |

> [!IMPORTANT]
> These files are included in your OpenProject installation. Please create a backup before and after changing them, as they might be overwritten during an OpenProject update.
> An admin section is planned, please follow this [ticket](https://community.openproject.org/projects/14/work_packages/61743/) for updates.

After changing the styles, you need to restart the OpenProject server to apply the changes. 
There is a utility script available you can run to see if the changes are valid or not.

```shell
bundle exec script/pdf_export/validate_styles
```

An example of a style:

```yml
border:
  color: d3dee3
  height: 1px
```

Where the color is a hexadecimal color code and the height is the height of the border in pixels.
