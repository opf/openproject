---
sidebar_navigation:
  title: Import work packages
  priority: 920
description: How to create many work packages at once from a CSV file
keywords: work package import, CSV import, import work packages, bulk create
---

> [!IMPORTANT]
> This import functionality is available on our Dev branch.

# Import work packages from a CSV file

You can create many work packages at once by uploading a CSV file. Existing work packages are never changed by an import, and no notifications are sent for the work packages it creates.

## Overview

| Topic                                         | Content                                                            |
|-----------------------------------------------|:-------------------------------------------------------------------|
| [Before you start](#before-you-start)         | The permission you need and the template to start from.            |
| [Import a file](#import-a-file)               | How to check a file first and then import it.                      |
| [Column reference](#column-reference)         | Every column that can be imported, and how its values are matched. |
| [Limits](#limits)                             | How large a file can be.                                           |
| [What is not imported](#what-is-not-imported) | What the CSV import currently does not cover.                      |

## Before you start

> [!NOTE]
> You need the **Import work packages** permission in order to import work packages into a project. It can be assigned to a role in the [roles and permissions](../../../system-admin-guide/users-permissions/roles-permissions/) administration, together with the **Add work packages** permission it requires.

To open the import page, go to the **Work packages** module in your project, click the green **+ Create** button above the work packages table and select **Import from CSV**.

Start from the template. The **Download the template** link on the import page gives you a CSV file with the exact column headers this project accepts and two example lines. Replace the examples with your own, keep the header line, and save the file as **CSV UTF-8**.

The file must be a UTF-8 or UTF-16 encoded `.csv` file. Comma, semicolon and tab are all accepted as separators, and the separator is detected from the header line, so a file exported by a spreadsheet application in any locale can be uploaded as it is. A value that contains the separator, a line break or a quotation mark has to be quoted, which spreadsheet applications do for you.

## Import a file

1. Select the file under **CSV file**.
2. Leave **Check the file first, without importing** selected. Every line is then validated and reported, but nothing is created.
3. Select **Check file**.
4. Read the report. If the file has problems, each one is listed with the line it is on, the column, the value and what is wrong with it. A file with a many problems shows the first 500 on the page; the CSV download beside the list always contains all of them, so you can work through them in your spreadsheet application.”
5. Correct the file and check it again, until the report shows no problems.
6. Select the **Import** button, which names how many work packages will be created, to create them.

The summary shown after a successful check tells you how many lines were read, how many accounts the file named in its `Assignee`, `Accountable` and `Author` columns, and which types, statuses, priorities and categories the lines use, so you can see that the file was understood the way you meant it before anything is created.

Once the import has run, the report links to the work packages it created. The link opens a view named **CSV import on** the date and time of the run, saved privately for you, which also appears under your own views in the sidebar of the work packages module. Delete it as you would any other view once you no longer need it.

**Clear** puts the report away and gives you the empty form back. It is offered beside the button in every state, so a report you have finished with, or a file that was refused, never has to be left on the page.

> [!TIP]
> The checked file is kept for a few hours, so you do not need to upload it again when importing. If you come back to the report later and the file has expired, upload it again. It is checked once more before anything is created.

You can clear the **Check the file first, without importing** checkbox to import straight away. The button then reads **Import file**, so it always names what will happen.

An import is all or nothing. If any line cannot be created, nothing is created, and the report lists every problem in the file rather than stopping at the first one. You are recorded as the author of every work package the import creates, unless the file names someone else in the `Author` column.

## Column reference

The header line decides what is imported. Column order is free, and you only need the columns you want to fill in. A header that is not in the table below stops the import before any line is read, as does the same attribute appearing twice.

| Column           | Content                           | Required | Format and matching                                                                                                                                       |
|------------------|-----------------------------------|----------|-----------------------------------------------------------------------------------------------------------------------------------------------------------|
| `Subject`        | The name of the work package      | Yes      | Text                                                                                                                                                      |
| `Description`    | The description                   | No       | Text. A value containing line breaks has to be quoted.                                                                                                    |
| `Type`           | Task, Milestone, Phase and so on  | No       | Matched by name, upper and lower case ignored. The type must be enabled in this project.                                                                  |
| `Status`         | The status                        | No       | Matched by name, upper and lower case ignored. The status must exist.                                                                                     |
| `Priority`       | The priority                      | No       | Matched by name, upper and lower case ignored. The priority must exist and be active.                                                                     |
| `Category`       | The category                      | No       | Matched by name, upper and lower case ignored. The category must exist in this project.                                                                   |
| `Version`        | The version                       | No       | Matched by name, upper and lower case ignored. The version must be open and available in this project. Only one version is supported in the cell.         |
| `Assignee`       | The assignee                      | No       | Matched by the email address the user signs in with, upper and lower case ignored. The user must be allowed to be assigned work packages in this project. |
| `Accountable`    | The accountable                   | No       | Matched the same way as `Assignee`.                                                                                                                       |
| `Author`         | Who created the work package      | No       | Matched by email address. Leave it empty, or leave the column out, and you are recorded as the author.                                                    |
| `Start date`     | The start date                    | No       | `YYYY-MM-DD`, for example `2026-03-17`.                                                                                                                   |
| `Finish date`    | The finish date                   | No       | `YYYY-MM-DD`.                                                                                                                                             |
| `Work`           | The estimated work                | No       | Hours as a number, for example `8` or `7.5`, or a duration such as `1h 30m`.                                                                              |
| `Remaining work` | The work still to do              | No       | Written like `Work`. Not available while progress is calculated from the status.                                                                          |
| `% Complete`     | The progress                      | No       | A whole number from 0 to 100, with or without a percent sign. Not available while progress is calculated from the status.                                 |
| `Created on`     | When the work package was created | No       | `YYYY-MM-DDTHH:MM:SSZ`, for example `2025-11-04T09:30:00Z`. Not in the future.                                                                            |
| `Updated on`     | When it was last updated          | No       | `YYYY-MM-DDTHH:MM:SSZ`. Not in the future, and not earlier than `Created on`.                                                                             |

A value that cannot be matched is reported with the line it is on, and the report lists the values that would have been accepted, so a misspelled type or status is quick to correct.

`Created on` and `Updated on` are there for work packages that come from another system and should keep their dates.
`Created on` also moves the creation entry in the work package's activity, so a [baseline comparison](../baseline-comparison/) over a period before the import behaves as it would have at the time.

> [!NOTE]
> The column headers are also accepted in the language you are using OpenProject in.
> A file written with German headers such as `Thema` and `Zugewiesen an` imports while your language is German.
> The translations are not guaranteed to be stable, however, so a file that is imported in one version of OpenProject may not be accepted in another.
> The English headers in the table above always work, whichever language is set, which is why the downloadable template uses them.

Everything the work package form would refuse is refused here as well, line by line: a subject that is missing,
a finish date before the start date, a type that has no such status in its workflow.

An empty cell means "not given", and the work package is created with whatever the project and the type would give it.
There is no way to say "explicitly empty" in a CSV file, so a value that is set by default cannot be cleared by leaving its cell blank.

## Limits

A file can hold up to 5000 lines and can be up to 5 MB by default.
Split a larger import across several files. The import page states the limits that apply to your instance.

Both limits are configurable. The file size limit is the one that applies to every attachment,
so an administrator can change it under [Administration, Files, Attachments](../../../system-admin-guide/files/attachments/).
The line limit is not in the administration: it is set for the instance with the `OPENPROJECT_WORK__PACKAGE__IMPORT__MAX__ROWS` [environment variable](../../../installation-and-operations/configuration/environment/),
which needs access to the server the instance runs on.

## What is not imported

A CSV import creates work packages. It currently does not do any of the following.

- **Change existing work packages**: Every line creates a new work package. There is no way to address one that already exists.
- **Create hierarchies**: Parents and children have to be set after the import.
- **Create relations**: Predecessors, successors and the other relation types are not read.
- **Fill custom fields**: Only the columns listed above are accepted.
- **Set watchers or attachments**:
- **Read spreadsheet files**: Save an `.xlsx` or `.ods` file as CSV first.
