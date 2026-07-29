---
sidebar_navigation:
  title: Work package PDF export
  priority: 400
description: How to export a single work package in PDF format in OpenProject
keywords: work package exports, single work package, PDF, contract template
---

# Work package PDF export

If you select **Generate PDF** in the work package dropdown menu, a modal will open, where you can select a template and adjust its options.

![PDF generation modal for export of single work packages in OpenProject](openproject_user_guide_work_package_export_pdf_modal.png)

## Template

**Template** is a dropdown menu showing all of the options currently enabled. At moment possible template options include:

- _Attributes and description_ - this template lists all the work package attributes [configured in the work package form](../../../../system-admin-guide/manage-work-packages/work-package-types/#work-package-form-configuration-enterprise-add-on), regardless whether they are filled out or not.
- _Contract_ - this template includes work package details formatted to the standard German contract form.
- _PMflex Artefact_ - this template renders the work package details as a PMflex Artefact.

> [!TIP]
> You can define which templates are enabled for specific work package types in the [administration settings](../../../../system-admin-guide/manage-work-packages/work-package-types).

Which of the following options are offered depends on the selected template.

## Options for all templates

- **Hyphenation** - if selected, a break line will be included into the export between word for improved layout. This option is deactivated by default.

- **Language and hyphenation** - a dropdown menu showing languages to be used for hyphenation. Your current language is preselected if hyphenation is available for it. The selection does not change the language used in the PDF export.

## Options for _Attributes and description_

- **Footer text**, which is displayed in the PDF export. The project name will be suggested for the footer, and the text will be placed at the center of the footer. You can adjust the suggested footer text.

- **Page orientation**, which allows selecting _Portrait_ or _Landscape_ layout of the pages in the PDF.

## Options for _Contract_

- **Footer text**, which is displayed in the PDF export. The work package subject will be suggested as the footer text, and the text will be placed at the right corner of the footer. You can adjust the suggested footer text.

## Options for _PMflex Artefact_

- **Table of contents** - if selected, a table of contents page indexing the section headers is added to the export. This option is activated by default.

## Generate the export

Click the **Download** button to generate the PDF export.

> [!NOTE]
>
> Layout of the PDF export follows the [work package configuration form](../../../../system-admin-guide/manage-work-packages/work-package-types/#work-package-form-configuration-enterprise-add-on) defined for specific work package types.

![Example of a single work package PDF export in OpenProject](openproject-user-guide-single-pdf-export.png)

See [Export work packages](../#export-a-single-work-package) for how to trigger the export of a single work package.
