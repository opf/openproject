---
sidebar_navigation:
  title: Backlogs FAQ
  priority: 001
description: Frequently asked questions regarding the backlogs module
keywords: backlogs FAQ, back-logs. task board, version, sprint, scrum
---

# Frequently asked questions (FAQ) for Backlogs

## What can I do to show the tasks of shared sub-projects in the backlog?

This is not possible. "Work packages from sub-projects are not displayed in the backlog of a main project" is the currently implemented behavior.

## I assigned a version to work packages. Why can't I see them in the respective backlog?

Please make sure that

- The respective version is not in the status "locked" or "closed"
- The respective version is assigned to a column in the backlog (see *Project settings ->Versions*).
- The work packages you want to display in the backlog are of a type that gets displayed in the backlog. If not: Either change the work package type or change the backlog setting (see *Administration ->Backlogs*).

## When I try to move a work package to another column in the task board I receive an error message similar to "Backlog Plugin 500 Internal Server Error". What can I do?

Please try these approaches:

- check whether your role in the current project (e.g. "Member") has sufficient rights to move the the work package (e.g. from "new" to "in progress") in the [workflow settings](../../../system-admin-guide/manage-work-packages/work-package-workflows/)
- remove unused story types in the administration
- deactivate the Backlogs module in the project settings

## How can I change the user's colors in the task board?

The colors can be changed in each user's personal settings: Please click on your avatar, then navigate to *My account ->Settings ->Backlogs*. There you can change the task color.
