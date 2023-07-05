---
sidebar_navigation:
  title: Exporting
  priority: 600
description: How to export work packages for other tools, such as Microsoft Excel
keywords: work package exports, CSV, Excel, XLS, PDF
---

# Exporting work packages

You can export work packages from your OpenProject instance to other formats using the export functionality. 



## How to trigger an export

To export a work package list or card view to another format, visit the *Work packages* module or a saved view and click on the settings icon in the top right corner. Trigger the **Export** dialog from the dropdown menu that opens.

![Exporting from the table](openproject_export_wp.png)

This will open a dialog where you can select the desired format. Below, we will detail how to adjust which data should be exported as well as what the various formats contain.



![The export dialog](openproject_wp_export_options.png)



## Export contents

All work packages that are included in the work package table in the currently selected view will be exported, unless a certain export limit has been defined by the instance administrator. The limit can be changed in the [work package settings](../../../system-admin-guide/system-settings/general-settings/#general-system-settings) in the system administration.

> **Note**: PDF export options includes all of the work packages in the selected work package table, regardless of the limit. The possible export limit is relevant for XLS, CSV and Atom export options.

**Columns**

The exported file will display the columns that are activated for the work package table. By adding or removing specific columns you can control the columns that will be included into the exported file. Please make sure to [save](../work-package-table-configuration/#save-work-package-views) the work package view you configured for the changes to be included into the report.

Some formats such as PDF will limit the number of columns available due to limitations of the PDF rendering engine to avoid overflowing the available space. 



## Export format options
### PDF export

OpenProject has multiple options of exporting work packages in PDF format:

- **PDF Table** exports the work package table displaying work packages as single rows.

![OpenProject PDF Table export](openproject_pdf_table_export.png)

- **PDF Report** includes a table of contents (listing all of the work packages), followed by the description of single work packages in a block form. For each work package a table of attributes is included (attributes correspond to the columns in the work package table). 

  ![OpenProject_pdf_report_export](openproject_pdf_report.png)
 > **Note**: If "display sums" is activated in the work package table, then the sum table is included between table of contents and work packages description in an Overview section.

![OpenProject_work_package_table_sum](openproject_wp_table_total_sum.png)

![OpenProject_pdf_report_sum](openproject_wp_report_total_sum.png)

- **PDF Report with images** is the same as PDF Report, but also includes the images from the work package description. 

   > **Note**: images from the work package comments section are not included into exported report.

   ![OpenProject_work_package_export](openproject_pdf_report_images.png)


### Excel (XLS) export

> **Note**: To open XLS exported files into Microsoft Excel, ensure you set the encoding to UTF-8. Excel will not auto-detect the encoding or ask you to specify it, but simply open with a wrong encoding under Microsoft Windows.

OpenProject can export the table for Microsoft Excel with the following options:

- **XLS** is a plain sheet that matches the OpenProject work packages table with its columns and work packages as rows matching the selected filter(s).

![OpenProject_work_package_export_excel](openproject_export_excel.png)

- **XLS with descriptions** same as above, but with an additional column for work package descriptions, which cannot be selected in the table.

![OpenProject_work_package_export_excel_description](openproject_pdf_table_export_description.png)

- **XLS with relations** same as **XLS**, but with additional columns to list each work package relation in a separate row with the relation target and its ID and relation type included in the export.

![OpenProject_work_package_export_excel_relations](openproject_pdf_table_export_relations.png)

### CSV export

OpenProject can export the table into a comma-separated CSV. This file will be UTF-8 encoded.

> **Note**: To open CSV exported files into Microsoft Excel, ensure you set the encoding to UTF-8. Excel will not auto-detect the encoding or ask you to specify it, but simply open with a wrong encoding under Microsoft Windows.

![OpenProject_work_package_export_csv](openproject_export_csv.png)


### Atom (XML) export

OpenProject can export the table into a XML-based atom format. This file will be UTF-8 encoded.

![OpenProject_work_package_export_atom](openproject_export_atom.png)
