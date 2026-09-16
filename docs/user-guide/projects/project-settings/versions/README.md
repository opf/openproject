---
sidebar_navigation:
  title: Versions
  priority: 500
description: Manage versions in OpenProject.
keywords: manage versions
---
# Manage versions

Versions help you structure and track work towards releases, milestones, or other delivery goals. Assign work packages to a version to plan and monitor their progress in the [Roadmap](../../../roadmap).

## Create a new version

Navigate to _Project settings → Versions_ in the project menu. You will see an overview of all existing versions. Per default, the existing versions will be sorted by the _Name_, which is indicated by an arrow next to the column header. To change the sorting order, click the name of any column you wish to use for sorting instead. 

 To create a new version for your project, click the green **+ Version** button. 

![Versions in project settings in OpenProject](openproject_user_guide_project_settings_work_packages_versions.png)

![Create new version under project settings in OpenProject](openproject_user_guide_project_settings_work_packages_versions_new.png)

You can configure the following details:

- **Name**: Set a name for the version.
- **Description**: Add a description to clarify the purpose of the version.
- **Status**: Choose the status of the version. The default status is open.
- **Wiki page**: Select a wiki page to link directly from the version in the Roadmap.
- **Start and finish date**: Set the planned start and finish dates.
- **Sharing**: Choose which projects the version should be shared with. Depending on the selected option, the version can be available only in the current project or also in related projects.

For example, let's consider the following project hierarchy:

```text
Parent project
├── Project A
│   ├── Project A1
│   │   └── Project A1a
│   └── Project A2
└── Project B
    ├── Project B1  ← current project
    │   ├── Project B1a
    │   │   └── Project B1a-i
    │   └── Project B1b
    └── Project B2
```

Assuming the version are are creating or editing belongs to **Project B1**:
  - **Not shared**: The version is available only in the current project.

  ```text
  Project B1  ✓  ← current project
  ```
  - **With subprojects**: The version is available in the current project and all of its subprojects, including subprojects nested at lower levels.

  ```text
  Project B1          ✓  ← current project
  ├── Project B1a     ✓
  │   └── Project B1a-i ✓
  └── Project B1b     ✓
  ```
  - **With project hierarchy**: The version is available in the current project, all of its parent projects, and all of its subprojects. Other projects under the same parent are not included.

  ```text
  Parent project      ✓
  └── Project B       ✓
      ├── Project B1  ✓  ← current project
      │   ├── B1a     ✓
      │   └── B1b     ✓
      └── Project B2  ✗
  ```
  -  **With project tree**: The version is available in all projects that belong to the same project tree. This includes the current project, its parent projects and subprojects, as well as other projects under the same top-level parent and their subprojects.

In this example, **Project A** and **Project B** have the same top-level parent, **Parent project**, so they and their subprojects are part of the same project tree.

  ```text
  Parent project          ✓  ← common parent
  ├── Project A           ✓
  │   ├── Project A1      ✓
  │   │   └── Project A1a ✓
  │   └── Project A2      ✓
  └── Project B           ✓
      ├── Project B1      ✓  ← current project
      │   ├── Project B1a ✓
      │   └── Project B1b ✓
      └── Project B2      ✓
  ```

  - **With all projects**: The version is available in all projects across the entire OpenProject instance, regardless of their position in the project hierarchy.


Click the Create button to save your changes.


## Edit a version

Click on the **edit** icon at the right of the row to edit the version.

> [!NOTE]
> You can only edit versions in the project they were originally created in. In projects where a version is shared, the edit option won’t be available.

![Edit or close version under project settings in OpenProject](openproject_user_guide_project_settings_work_packages_versions_edit.png)

## Close a version

To close a version, open its details and set the **Status** to _Closed_.

![Close a version under project settings in OpenProject](openproject_user_guide_project_settings_work_packages_versions_closed.png)

## Close completed versions

To close all completed versions at once, click the **More (three dots**) icon in the top right corner and click **Close completed versions**.

![Close completed versions in OpenProject project settings](openproject_user_guide_project_settings_work_packages_versions_close_completed.png)

## Delete a version

To remove a version, press the respective **delete** button at the end of the corresponding line in the Versions overview.

![Delete a version under project settings in OpenProject](openproject_user_guide_project_settings_work_packages_versions_delete.png)

## Differences between open, locked and closed versions

There are a few differences between open, locked and closed versions:

- **Open version**:
Versions in this state can be used throughout the system. Work packages can be added or removed. The version is visible in both the Backlogs and Roadmap modules.
- **Locked version**:
Work packages cannot be added or removed. The version is **not** visible in the Backlogs module but is still shown in the Roadmap module.
_Use case:_ You’ve finalized the scope of a sprint or release and want to prevent changes while it's being worked on.
- **Closed version**:
Work packages cannot be added or removed. The version is no longer shown in the Backlogs or Roadmap modules, unless you explicitly filter for closed versions.
_Use case:_ The release or sprint is complete, and you’ve moved on to the next one.
