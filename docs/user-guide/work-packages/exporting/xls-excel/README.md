---
sidebar_navigation:
  title: XLS export (Excel)
  priority: 600
description: How to export work packages in XLS format for Microsoft Excel
keywords: work package exports, XLS, Excel, spreadsheet
---

# XLS export (Excel)

**XLS** is a plain sheet that matches the OpenProject work packages table with its columns and work packages as rows matching the selected filter(s).

> [!TIP]
> To open XLS exported files in Microsoft Excel, ensure you set the encoding to UTF-8. Excel will not auto-detect the encoding or ask you to specify it, but simply open with the wrong encoding under Microsoft Windows.

OpenProject can export the table for Microsoft Excel with the following options:

![Work package export in Excel form in OpenProject](openproject_pdf_export_report_excel_options.png)

In **XLS** format export, you can manage and reorder columns that should be included, as well as decide if relations and descriptions should be included in the report.

![OpenProject_work_package_export_excel](openproject_export_excel.png)

## XLS with descriptions

If you activate the **Include descriptions** option, an additional column will be included in the report, showing work package descriptions.

![OpenProject_work_package_export_excel_description](openproject_export_excel_with_descriptions.png)

## XLS with relations

If you activate the **Include relations** option, additional columns to list each work package relation in a separate row will be included in the report. It will include the relation target and its ID and relation type.

![OpenProject_work_package_export_excel_relations](openproject_export_excel_with_relations.png)

## Limitations

The OpenProject XLS export currently does not respect all options in the work package view being exported from:

- The hierarchy of work packages as displayed in the work package view. The exported XLS is always in "flat" mode.
- The description is exported in 'raw' format, so it may contain HTML tags.

See [Export work packages](../) for how to trigger an export and adjust the general export options.