---
sidebar_navigation:
  title: FAQ
  priority: 001
description: Frequently asked questions regarding the boards module
robots: index, follow
keywords: kanban faq, boards, agile board, basic board, swimlane
---

# Frequently asked questions (FAQ) for Agile boards

## How can I display in a Kanban board which of my tasks are due in the next two weeks?

To do this, you can (provided you have set the end dates for the work packages) add the filter "finish date" to the Kanban board and select "In less than 15 days" there. Then you will see the tasks that have a finish date in less than 15 (i.e. 14 days or less).

## How can I activate Boards in OpenProject? 

The Boards module is a premium feature of OpenProject Enterprise on-premises and OpenProject Enterprise cloud. You can upgrade your Community Edition installation by entering a valid subscription token in the application administration. You can purchase the token on our [website](https://www.openproject.org/enterprise-edition/).
In addition, you need to activate the Boards module in the project settings.

## Is it possible that we can have a board over all OpenProject tasks and users? 

Yes, to achieve the desired result you can navigate to the main project and on the Kanban view add the filter "subproject" "all". This will display the work packages in the main project and all subprojects. As a precondition, you will need a central parent project within your project hierarchy.

## What does the error message "Parent is invalid because the work package (...) is a backlog task and therefore cannot have a parent outside of the current project" mean?

This message appears when the Backlogs module is activated and you try to set a work package belonging to project A as a child of another work package belonging to project B. 
In the Backlogs module work packages can only have children of the same version and the same project. To avoid displaying different information in the backlog and in the boards view this restriction is in place. You can solve it by disabling the Backlogs module or by changing the project (and if necessary version) of the work package you'd like to move.