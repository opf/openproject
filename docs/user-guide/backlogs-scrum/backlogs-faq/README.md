---
sidebar_navigation:
  title: Backlogs FAQ
  priority: 001
description: Frequently asked questions regarding the backlogs module
keywords: backlogs FAQ, backlogs, backlog, task board, taskboard, version, sprint, scrum
---

# Frequently asked questions (FAQ) for Backlog and sprints

> [!NOTE]
> With the release of OpenProject 17.3, the **Backlogs** module has undergone significant changes, including the introduction of redesigned sprint handling and updated functionality. As a result, this FAQ page has been revised to reflect the current behavior and concepts.
>
> Please note that further improvements are implemented in OpenProject 17.4 and beyond. We will continue to update this page to keep it aligned with the latest product changes.

## If I previously had sprints defined using versions, how does the change from sprint to version affect migration and existing data?

Before the OpenProject 17.3 release, the backlog module allowed defining versions that could be used in the left or right columns of the backlog module. There wasn't a designated column for the sprint, but rather the user could decide whether the version should be displayed in the left or right column.

All the versions that have been defined to appear in either the left or right columns are now migrated into a sprint. All the work packages associated with the version will also appear on the sprint.

## Can I define if sprints should be on the left or right-hand side?

We have chosen a view which is the same in all projects to maintain consistency. Each project you visit now shows backlog on the left-hand side and the sprints on the right-hand side. Usually the life-cycle of a work package starts in the backlog and then the work package moves to the sprint. This is why we decided to place the backlog as the first column and sprints as the second one. 

## What if the sprint field is not visible in the work package?

First, you have to make sure the backlog module is active within a project.

- An admin needs to add the field to existing work package forms. 
- Once added, the sprint field becomes visible on the work package details page and can be edited there as well.

## Where are my backlog buckets and sprints now?

All buckets have been migrated as sprints, which are now visible on the right-hand side. Starting with version 17.4, there are backlog buckets on the left-hand side, allowing you to sort and organize your backlog in a better way.

## How is the backlog generated?

Your backlog automatically shows all work packages from your project which are not closed and can be worked on. It is possible to exclude certain work package types from the automated backlog. This can be defined under [project backlog settings](../../projects/project-settings/backlogs-settings).

## How is the backlog sorted?

The backlog can be sorted manually:

- When you open your backlog, the oldest items appear at the top. 
- The work packages are sorted by creation date.
- When you add a new work package to the project, it is automatically placed at the bottom of the backlog. 

## How are sprint containers sorted?

- Sprint containers with start/completion dates are sorted by date showing the latest one on the top. 
- Sprint containers without dates are sorted in an alphanumeric way.

## My task board is gone, where can I get another board?

You can use the automated sprint boards, which show the entire sprint scope.

- Define sprint dates and start your sprint. You will be automatically forwarded to your board.
- For an active sprint you will find a shortcut to the board in the sprint menu. 
- Click the menu of an active sprint and select the option "Sprint board".

Additionally, if you would like to see the parent/child relationships, please use the parent-child boards.

## Where is my Burndown chart?

Nothing has changed with the Burndown chart. It is synced with the sprint object and can be accessed from the menu of an active sprint.
