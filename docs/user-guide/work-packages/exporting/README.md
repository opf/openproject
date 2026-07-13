---
sidebar_navigation:
  title: Export work packages
  priority: 930
description: How to export work packages for other tools, such as Microsoft Excel
keywords: work package exports, CSV, Excel, XLS, PDF
---

# Export work packages

You can export [a single work package](#export-single-work-package) in PDF/Atom format or [multiple work packages](#export-multiple-work-packages) in PDF/XLS/CSV formats.

## Export multiple work packages

### How to trigger an export

To export work packages to another format, visit the **Work packages** module and select a default or saved work package view (table or card view) you want to export. Click on the settings icon in the top right corner. Trigger the **Export** dialog from the dropdown menu.

![Exporting from the table](openproject_export_wp.png)

This will open a dialog where you can select the desired format. Click on one of the possible formats to start the export. Below, we will detail how to adjust which data should be exported as well as what the various formats contain.

### Export options

All work packages included in the work package table in the currently selected view will be exported, unless a certain export limit has been defined by the instance administrator. The limit can be changed in the [work package settings](../../../system-admin-guide/system-settings/general-settings/#general-system-settings) in the system administration. Newly created instances have a maximum of 500 work packages set as a limit by default.

> [!NOTE]
> PDF export options include all of the work packages in the selected work package table, regardless of the limit. The possible export limit is relevant for XLS, CSV and Atom export options.

**Columns**

You can choose which columns will be displayed in the table (excluding long text fields) and change their order. The pre-selected columns are the ones in the work package table query. Learn how to [save the work package view](../work-package-table-configuration/#save-work-package-views).

Some formats such as PDF will limit the number of columns available due to limitations of the PDF rendering engine to avoid overflowing the available space.

#### Save export format

Export settings can be saved for custom (all non-default) work package queries. This allows you to easily share export settings with your team and save time in the future. 

To save export settings adjust the export to your liking and check the **Save setting** checkbox before triggering an export. Clicking the **Export** button will trigger the adjustments to a work package query. The checkbox will remain checked for the next export.

![Checkbox to save export settings in work packages export modal in OpenProject](openproject-user-guide-wp-export-settings-save-checkbox.png)

> [!TIP]
>
> If the query is public, other users can edit it and save the export settings. If you want to prevent other users from adjusting the export settings, you need to create a private work package query. 

### Export format options

OpenProject has multiple file format options for exporting work packages, including PDF, XLS and CSV. See below what each format entails.

### PDF export

OpenProject has multiple options for exporting work packages in PDF format. These include table, report and Gantt chart. 

> [!TIP]
>
> OpenProject PDF export supports commonly used character sets, including multilingual fonts with different alphabets, various symbols (mathematical, technical) and emojis.
>
![Example of a PDF export in OpenProject that includes lorem ipsum text in multiple languages and mathematical symbols](openproject-user-guide-wp-export-multilingual-symbols-example.png)

> [!NOTE]
>
> Rich text can be embedded using [Macros](../../wysiwyg/#attributes), such as descriptions of other work packages. This feature is supported as long as the embedding is not within table cells, or if it only contains basic text formatting.

#### PDF Table

PDF Table exports the work package table displaying work packages as single rows with the selected columns for the work package table. Work package IDs are linked to the respective work packages. Clicking on a work package ID will lead you directly to the work package in OpenProject.

![OpenProject PDF Table export](openproject_pdf_table_export.png)

> [!TIP]
> If ["display sums" is activated](../work-package-table-configuration/) in the work package table, then the sum table is included at the bottom of the exported work package table.

#### PDF Report

With PDF Reports, you can export detailed up-to-date work plans for your project in a clean and practical format. It includes a title page, a table of contents (listing all of the work packages), followed by the description of single work packages in a block form. The table of contents is clickable and is linked to the respective pages within the report, making navigation much easier.

![Define a PDF report for OpenProject work packages export](openproject_pdf_export_report_options.png)

For each work package, a table of attributes is included, where attributes correspond to the columns you specified for the export. For a [single work package export](#export-single-work-package), attributes are displayed according to the work package form configuration.

The table of attributes is followed by the work package description and, if necessary, custom long text fields, which support [embedded work package and project attributes](../../wysiwyg/#attributes).

##### Page breaks 

If you used page breaks in work package descriptions, contents will be split into separate pages accordingly. 

![OpenProject_pdf_report_export](openproject-pdf-export-work-plans.png)

##### Display sums 

If ["display sums" is activated](../work-package-table-configuration/) in the work package table, then the sum table is included between the table of contents and work packages description in an Overview section.

![A work package table in OpenProject, highlighting total sum under the work packages list](openproject_wp_table_total_sum.png)

![A PDF export in OpenProject, highlighting a dedicated section to values from _Total sum_ field in work packages table](openproject_wp_report_total_sum.png)

##### Display relations

If relations, such as _children_, _blocked by_, _followed by_, etc. are included in the report as columns, they will be included in dedicated blocks.

![A pdf export of OpenProject work packages, displaying dedicated sections to existing work package relations](openproject_pdf_report_relations.png)

#### PDF Report with images

If you select the **Include images** option, your PDF Report will include the images from the work package description. Supported formats include PNG, JPG, WebP. If an animated WebP or a GIF is used, the first frame will be included into the report.

![Include images in OpenProject work packages export](openproject_wp_report_include_images_checked.png)

> [!NOTE]
> Images attached or linked in the work package Files section or in the Activity comments are not included in the PDF Report with images.

![OpenProject_work_package_export](openproject_pdf_report_images.png)

#### Gantt chart PDF

[feature: gantt_pdf_export ]

You can export Gantt charts directly from the work packages module by selecting the respective option, or from the Gantt charts module by doing the same.

![Gantt chart PDF export in OpenProject](openproject_pdf_export_report_gantt_chart_options.png)

For more information on using the Gantt chart module and Gantt exports, please refer to the [Gantt chart PDF Export guide](../../gantt-chart/#gantt-chart-pdf-export-enterprise-add-on).

### XLS export (Excel)

**XLS** is a plain sheet that matches the OpenProject work packages table with its columns and work packages as rows matching the selected filter(s).

> [!TIP]
> To open XLS exported files in Microsoft Excel, ensure you set the encoding to UTF-8. Excel will not auto-detect the encoding or ask you to specify it, but simply open with the wrong encoding under Microsoft Windows.

OpenProject can export the table for Microsoft Excel with the following options:

![Work package export in Excel form in OpenProject](openproject_pdf_export_report_excel_options.png)

In **XLS** format export, you can manage and reorder columns that should be included, as well as decide if relations and descriptions should be included in the report.

![OpenProject_work_package_export_excel](openproject_export_excel.png)

#### XLS with descriptions

If you activate the **Include descriptions** option, an additional column will be included in the report, showing work package descriptions.

![OpenProject_work_package_export_excel_description](openproject_export_excel_with_descriptions.png)

#### XLS with relations

If you activate the **Include relations** option, additional columns to list each work package relation in a separate row will be included in the report. It will include the relation target and its ID and relation type.

![OpenProject_work_package_export_excel_relations](openproject_export_excel_with_relations.png)

#### Limitations

The OpenProject XLS export currently does not respect all options in the work package view being exported from:

- The hierarchy of work packages as displayed in the work package view. The exported XLS is always in "flat" mode.
- The description is exported in 'raw' format, so it may contain HTML tags.

### CSV export

OpenProject can export the table into a comma-separated CSV. This file will be UTF-8 encoded.

![Export work packages in CSV format in OpenProject](openproject_pdf_report_csv_options.png)

> [!TIP]
> To open CSV exported files in Microsoft Excel, ensure you set the encoding to UTF-8. Excel will not auto-detect the encoding or ask you to specify it, but simply open with the wrong encoding under Microsoft Windows.

![OpenProject work package CSV export](openproject_export_csv.png)

If you select the **Include descriptions** option, the work package description field will be included in the export.

![OpenProject work package CSV export with descriptions](openproject_export_csv_with_descriptions.png)

#### Limitations

The OpenProject CSV export currently does not respect all options in the work package view being exported from:

- The hierarchy of work packages as displayed in the work package view. The exported CSV is always in "flat" mode.
- The description is exported in 'raw' format, so it may contain HTML tags.

## Export single work package

It is also possible to export single work packages in PDF and Atom formats. To do that, click on the settings icon in the top right corner and select either the **Generate PDF** or the **Download Atom** option from the dropdown menu.

![Single work package export options in OpenProject](openproject_user_guide_work_package_export_options.png)

### Export single work package in PDF format

If you select **Generate PDF**, a modal will open, where you can adjust the following: 

- **Template** is a dropdown menu showing all of the options currently enabled. At moment possible template options include:

  - _Attributes and description_ - this template lists all the work package attributes [configured in the work package form](../../../system-admin-guide/manage-work-packages/work-package-types/#work-package-form-configuration-enterprise-add-on), regardless whether they are filled out or not.
  - _Contract_ - this template includes work package details formatted to the standard German contract form.
    
> [!TIP] 
> You can define which templates are enabled for specific work package types in the [administration settings](../../../system-admin-guide/manage-work-packages/work-package-types).

- **Hyphenation** - if selected, a break line will be included into the export between word for improved layout.

- **Language and hyphenation** - a dropdown menu showing languages to be used for hyphenation. The selection does not change the language used in the PDF export.

- **Footer text**, which is displayed in the PDF export. Footer position depends on the template. You can adjust the suggested footer text.

  - If _Attributes and description_ template is selected, the project name will be suggested for the footer. This text will be placed at the center of the footer. 
  - If _Contract_ template is selected, the work package subject will be suggested as the footer text. This text will be placed at the right corner of the footer.
  
- **Page orientation**, which allows selecting _Portrait_ or _Landscape_ layout of the pages in the PDF.  

![PDF generation modal for export of single work packages in OpenProject](openproject_user_guide_work_package_export_pdf_modal.png)

Click the **Download** button to generate the PDF export. 

> [!NOTE]
>
> Layout of the PDF export follows the [work package configuration form](../../../system-admin-guide/manage-work-packages/work-package-types/#work-package-form-configuration-enterprise-add-on) defined for specific work package types. 

![Example of a single work package PDF export in OpenProject](openproject-user-guide-single-pdf-export.png)

### Export single work package in Atom format

If you select **Download Atom** options, the extracted file will download automatically. Atom Export includes a work package Title, Author, a link to the work package and work package activities.
