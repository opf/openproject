---
sidebar_navigation:
  title: Create work packages
  priority: 990
description: How to create Work packages in OpenProject.
keywords: create work packages
---

# Create Work packages

| Topic                                                                  | Content                                        |
|------------------------------------------------------------------------|------------------------------------------------|
| [Create Work packages](#create-work-packages)                          | How to create a new Work package in a project. |
| [Add attachments to a Work package](#add-attachments-to-work-packages) | How to add attachments to a Work package.      |

## Create Work packages

There are two ways to create new Work packages:

- Work packages can be [created in-line in the Work package table](#create-a-work-package-in-the-table-view) (just like Excel) to quickly create multiple Work packages.
- Work packages can be [created in a split screen](#create-a-work-package-in-the-split-screen-view) which allows you to specify detailed information from the start.

Work packages always belong to a project. Therefore, you first need to [select a project](../../../getting-started/projects/#open-an-existing-project).

Then, navigate to the Work package module in the project navigation.

![work packages module](1566302949658.png)

### Create a Work package in the table view

To create new Work packages directly in line in the table view, click on the **+ Create new Work package** link below the table.

![create split screen](create-split-screen.png)

The new Work package appears in a green row. Type in the subject of the Work package, change attributes, such as Type or Status directly in the table and hit Enter to save the changes.

![create work package list](1566303144875.png)

This way, you can quickly and easily create new Work packages in the table, just like Excel.

### Create a Work package in the split screen view

In order to enter detailed information to the Work package from the start, you can create a Work package in the split screen view. In the Work package module, click the green **+ Create** button and select the type of Work package you want to create.

![Select work package type](1566303633018.png)

The new Work package form will open in the split screen view. Enter all information, such as description, assignee, status, priority, due date and more.

Click the green **Save** button.

![create a work package in the split screen view](1566303947314.png)

Starting with OpenProject 13.0 you can add emojis to all text editors, including the work package description. Type a colon and a letter, e.g. **:a** into the text editor and get a suggested list of emojis you can use.

![work package description emojis](openproject_user_guide_wp_description_emojis.png)

To find out **how to create a child Work package** please click [here](../work-package-relations-hierarchies/#add-a-child-work-package).

## Add attachments to Work packages

You can directly add images, e.g. via copy and paste to the **Work package description**. You can also use the toolbar above the Work package description and click the Insert image icon:

![insert-image](1566304978459.png)

Also, at the bottom of the Work package form you can add files via drag and drop or select the file from a folder to upload it to the Work package.

![add-file](1566305040178.png)

> Note: it is also possible for users that are not members of the project to add attachments to work packages if they have been granted the permission by an administrator. This can be useful for example for confirming bug reports.

Find out how to [edit existing Work packages](../edit-work-package).

> Note: you can also use [Nextcloud integration](../../file-management/nextcloud-integration/#link-files-and-folders-to-work-packages) to upload files to Nextcloud or link already existing files or folders to a work package under the tab **Files**.
