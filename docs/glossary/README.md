---
sidebar_navigation:
  title: Glossary
  priority: 945
description: Glossary of OpenProject project management software related terms, with definitions and additional links.
keywords: glossary, help, documentation, terms, keywords, vocabulary, definition, dictionary, lexicon, index, list, wordbook
---

# OpenProject Glossary

![Glossary of OpenProject](glossary-openproject-header.png)

## A

<div id="agile-project-management"></div>

### Agile project management

Agile project management is an iterative and flexible approach to managing projects. It focuses on collaboration, adaptability, and self-organizing teams. OpenProject supports agile project management as well as [classic project management](#classic-project-management) and works best for [hybrid project management](#hybrid-project-management).

<div id="authentication"></div>

### Authentication

In OpenProject, authentication is an important element to guarantee a data protected usage. To adapt these authentication settings, navigate to your user name and select -> Administration -> Authentication. At OpenProject, we use [OAuth 2.0](#oauth) as this is the definitive industry standard for online authorization.

**More information on authentication in OpenProject**

- [See answers to frequently asked questions (FAQ) for authentication](https://www.openproject.org/docs/system-admin-guide/authentication/authentication-faq/)
- [See our blog post on multi-factor authentication to improve data security](https://www.openproject.org/blog/multi-factor-authentication-for-data-security/)
- [Read more about Two-factor authentication (2FA) in OpenProject](https://www.openproject.org/docs/system-admin-guide/authentication/two-factor-authentication/)
- [Read more about LDAP Authentication in OpenProject](https://www.openproject.org/docs/system-admin-guide/authentication/ldap-authentication/)

## B

<div id="backlogs"></div>

### Backlogs

A backlog in OpenProject is defined as a [plugin](#plugins) that allows to use the backlogs feature in OpenProject. The backlog is a tool in scrum: a list that contains everything needed to achieve a specific outcome. In order to use backlogs in OpenProject, the backlogs module has to be activated in the [project settings](#project-settings). [Read how to work with backlogs in OpenProject](https://www.openproject.org/docs/user-guide/backlogs-scrum)

<div id="baseline"></div>

### Baseline (Comparisons)

Baseline is a feature in OpenProject that will be released with 13.0. It allows users to quickly track changes on [filtered](#filters) work packages list views. [Read more about technical challenges, design and next steps for Baseline in the OpenProject blog](https://www.openproject.org/blog/news-product-team-baseline/)

<div id="bim"></div>

### BIM

BIM stands for Building Information Modeling. In OpenProject, we offer a special plan for users working in the construction industry. On top of the general project management features, OpenProject BIM enables construction teams to better plan, communicate and collaborate in their building projects. [Read the OpenProject BIM guide to get more information](https://www.openproject.org/docs/bim-guide/)

<div id="board"></div>

### Board

A board in OpenProject is a view that allows you to see your work packages as cards divided into columns. A board is a typical element in [agile project management](#agile-project-management), supporting methodologies such as Scrum or Kanban. As a [Community user](#community-edition) of OpenProject, you can use a [basic board](https://www.openproject.org/docs/user-guide/agile-boards/#basic-board-community-edition). [Advanced Action boards](https://www.openproject.org/docs/user-guide/agile-boards/#action-boards-enterprise-add-on) are part of the [Enterprise add-on](#enterprise-add-on). Use advanced Action boards to quickly change attributes of your work package. [Read more about boards for agile project management](https://www.openproject.org/docs/user-guide/agile-boards/)

**More information on boards in OpenProject**

- [Examples of agile boards in OpenProject](https://www.openproject.org/docs/user-guide/agile-boards/#agile-boards-examples)
- [Blog post on 5 agile boards to boost efficiency in multi-team projects](https://www.openproject.org/blog/agile-boards/)

## C

<div id="classic-project-management"></div>

### Classic project management

Classic project management is a structured and sequential approach to project management. It often follows a hierarchical structure with a project manager overseeing team coordination, and is associated with methodologies like Waterfall. OpenProject supports classic project management as well as [agile project management](#agile-project-management) and works best for [hybrid project management](#hybrid-project-management).

<div id="community-edition"></div>

### Community edition

Community edition is defined as the main and free-of-charge edition of OpenProject software. It is installed [on-premises](#on-premises) and therefore self-managed. Benefit from a wide range of features, data sovereignty in a free and open source project management software. The Community edition is actively maintained and is continuously being further developed. [Read more about OpenProject Community edition](https://www.openproject.org/community-edition/)

<div id="custom-action"></div>

### Custom action

A custom action in OpenProject is defined as customizable buttons which trigger a certain action upon work packages. Custom actions are included in the [Enterprise](#enterprise-add-on) edition of OpenProject and part of automated *workflows*. Custom actions support you to easily update several workpackage attributes at once – with a single click.

**More information on custom actions in Openproject**

- [Watch a short video how custom actions work](https://www.openproject.org/docs/system-admin-guide/manage-work-packages/custom-actions/#automated-workflows-with-custom-actions-enterprise-add-on)
- [Read this guide on how to create custom actions](https://www.openproject.org/docs/system-admin-guide/manage-work-packages/custom-actions/#create-custom-actions)
- [Read this blog article on how to create an intelligent workflow with custom action - explained with an example](https://www.openproject.org/blog/customise-workflows/)

<div id="custom-field"></div>

### Custom field

In OpenProject, a custom field is defined as an additional value field which can be added to existing value fields. Custom fields can be created for the following resources: [work packages](#work-package), [spent time](#time-and-costs), [projects](#project), [versions](#versions), [users](#user), and [groups](#group).

![Custom fields in OpenProject](glossary-openproject-custom-field.png)

**More information on custom fields in OpenProject**
- [Read how to enable custom fields in projects to use them in work packages](https://www.openproject.org/docs/user-guide/projects/project-settings/custom-fields/)
- [Read how to create custom fields as an admin in OpenProject](https://www.openproject.org/docs/system-admin-guide/custom-fields/)

<div id="custom-query"></div>

### Custom query

A custom query in OpenProject consists of saved [filters](#filters), sort criteria, and [groupings](#group) in the [work package table](#work-package-table). Custom queries can be either set to public (visible by any user who is allowed to see the project and the work package table) or to private (visible only to the person creating the query).

## D

<div id="dashboard"></div>

### Dashboard

A dashboard is defined as an overview page in a software. In OpenProject, you have several options to create dashboards:

1. You have the [My Page](#my-page) which shows your personal customized [widgets](#widget) on one page, for example a calendar or work package reports.

2. You have the [project overview](#project-overview) dashboard which gives you an overview of your project. Please note that only admins can add and remove widgets to the project overview. 

3. Every [member](#member) can create private dashboards inside your project by [filtering](#filters) a [work package view](#work-package-view) and then saving it under a new name. For example, filter all work packages assigned to yourself and save this view as "assigned to me", to quickly navigate to those work packages.

4. Admins of a project can also create dashboards that are visible to everyone in the project.

<div id="date-alerts"></div>

### Date alerts

Date alerts in OpenProject are an [Enterprise add-on](#enterprise-add-on) and defined as a feature to generate automatic and customized [notifications](#notifications) regarding a work package's due date or start date. You can find the date alerts feature in your notification center, symbolized by a little bell on the right upper side of your instance. [Read more about the date alerts feature in our user guide](https://www.openproject.org/docs/user-guide/notifications/notification-settings/#date-alerts-enterprise-add-on) or in [this article on deadline management with OpenProject](https://www.openproject.org/blog/deadline-management-date-alert/)

## E

<div id="enterprise-add-on"></div>

### Enterprise add-on

In OpenProject, some features are defined as an Enterprise add-on. This means, they are not part of the [Community edition](#community-edition) and therefore not free of charge. Enterprise add-ons are available as Cloud or [on-premises](#on-premises) versions. You can chose from the following plans to get access to all Enterprise add-ons: Basic, Professional, Premium and Corporate. [Read more about OpenProject plans and pricing](https://www.openproject.org/pricing/)

<div id="enumerations"></div>

### Enumerations

Enumerations in OpenProject is defined as a menu item in the admin settings that allows the configuration of Activities (for [time tracking](#time-and-costs)), [project status](#project-status) and work package priorities. (Read more about enumerations in OpenProject)[https://www.openproject.org/docs/system-admin-guide/enumerations/]

<div id="excel-synchronisation"></div>

### Excel synchronisation

Excel synchronisation is a module in OpenProject which allows you to easily import your issues from Excel to OpenProject or upload your work packages into an Excel spreadsheet. [See our video tutorials on how to work with the Excel synchronisation module](https://www.openproject.org/docs/system-admin-guide/integrations/excel-synchronization/)

## F

<div id="file-storage"></div>

### File storage

File storages can be configured in the System Administration and then be selected in the [project settings](#project-settings). OpenProject offers a [Nextcloud integration](#nextcloud-integration) to support file storage. [More information on file storage with the Nextcloud integration](https://www.openproject.org/docs/user-guide/nextcloud-integration/)

<div id="filters"></div>

### Filters

Filters are essential for task and project management in OpenProject. You have several filtering options applicable to a [work package table](#work-package-table). Filter options can be saved via [custom queries](#custom-query). A filtered work packages list view (e.g. only open work packages) can be safed and therefore work as a [dashboard](#dashboard). 

<div id="forum"></div>

### Forum

A forum in OpenProject is defined as a module used to display forums and forum messages. The module has to be activated in the [project settings](#project-settings) and a forum has to be created in the forums tab in the project settings to be displayed in the side navigation. [Read more about forums in OpenProject](https://www.openproject.org/docs/user-guide/forums/)

## G

<div id="gantt-chart"></div>

### Gantt chart

The Gantt chart in OpenProject displays the work packages in a timeline. You can collaboratively create and manage your project plan. Have your project timelines available for all team [members](#member) and share up-to-date information with stakeholders. You can add start and finish dates and adapt it with drag and drop in the Gantt chart. Also, you can add dependencies, predecessor or follower within the Gantt chart.

[Read more about how to activate and work with Gantt charts in OpenProject](https://www.openproject.org/docs/user-guide/gantt-chart/)

![A gantt chart in OpenProject](glossary-openproject-gantt-chart.png)

<div id="group"></div>

### Group

A Group in OpenProject is defined as a list of users which can be added as a member to projects with a selected [role](#role). Groups can also be assigned to work packages. New groups can be defined in Administration -> Users and permissions -> Groups.

## H

<div id="hybrid-project-management"></div>

### Hybrid project management

Hybrid project management is an approach that combines elements of both classic and agile project management methodologies. It allows flexibility and adaptability while still incorporating structured planning and control. OpenProject works best for hybrid project management and also supports [classic project management](#classic-project-management) as well as [agile project management](#agile-project-management).

<div id="meetings"></div>

### Meetings

In OpenProject Software, Meetings is defined as a [module](#module) that allows the organization of meetings. The module has to be activated in the [project settings](#project-settings) in order to be displayed in the side navigation.

<div id="member"></div>

### Member

In OpenProject Software, a member is defined as a single person in a project. Project members are added in the Members [module](#module) in the project menu.

<div id="module"></div>

### Module

A module in OpenProject is defined as an independent unit of functionality that can be used to extend and improve the existing core functions.

<div id="my-page"></div>

### My Page

The My Page in OpenProject is defined as your personal [dashboard](#dashboard) with important overarching project information, such as work package reports, news, spent time, or a calendar. It can be configured to your specific needs. [Read more about the My Page in OpenProject](https://www.openproject.org/docs/getting-started/my-page/)

## N

<div id="news"></div>

### News

In OpenProject, News is defined as a [module](#module) that allows the publication and use of news entries. On the news page, you can see the latest news in a project in reverse chronological order. News communicate general topics to all team members. They can be displayed on the project [dashboard](#dashboard). (Read more about how to work with the News module in OpenProject)[https://www.openproject.org/docs/user-guide/news/]

<div id="nextcloud-integration"></div>

### Nextcloud integration

OpenProject offers a Nextcloud integration which allows you to manage files in a secure and easy way, e.g. to link files or folders in Nextcloud or upload files to Nextcloud on work packages. You find the Nextcloud integration in the Files tab of your work package, if you have activated the Nextcloud integration for your instance. Get access to the OpenProject-Nextcloud integration by downloading and activating it in the built-in [Nextcloud app store](https://apps.nextcloud.com/) within your Nextcloud instance. [Read more about the Nextcloud integration of OpenProject](https://www.openproject.org/docs/user-guide/nextcloud-integration/)

<div id="notifications"></div>

### Notifications

In OpenProject, you get in-app notifications about important changes that are relevant to you – for example new comments that mention you, updates to status, [type](#work-package-types) or dates or new assignments. This feature is enbled by default and can be used as an addition or an alternative to email notifications. To view the notifications, click the bell icon at the top right of the header. The bell icon will be displayed with a red badge if there are new notifications for you. (Read more about notifications in OpenProject)[https://www.openproject.org/docs/user-guide/notifications/]

## O

<div id="oauth"></div>

### OAuth

OAuth is an open authorization standard. It allows you to access certain information or resources on behalf of a user without accessing their username and password on each individual service. OpenProject acts as an OAuth provider, allowing you to optionally grant permissions to access your data to authorized third-party applications or services. [Read more about OAuth applications in OpenProject](https://www.openproject.org/docs/system-admin-guide/authentication/oauth-applications/)

<div id="on-premises"></div>

### On-premises

OpenProject on-premises is a self-hosted version of OpenProject. As opposed to the Cloud version, you install, run and maintain the hardware locally and manage the software application there. The on-premises [Community Edition](#community-edition) is free of charge.

**More information on OpenProject on-premises**
- [See our pricing side about your options for OpenProject](https://www.openproject.org/pricing/)
- [Read a blog article comparing on-premises and cloud](https://www.openproject.org/blog/why-self-hosting-software/)
- [Read how to activate the Enterprise on-premises edition](https://www.openproject.org/docs/enterprise-guide/enterprise-on-premises-guide/activate-enterprise-on-premises/)
- [Read how to start a trial for Enterprise on-premises](https://www.openproject.org/docs/enterprise-guide/enterprise-on-premises-guide/enterprise-on-premises-trial/)

## P

<div id="phase"></div>

### Phase

A phase in OpenProject is defined as a [work package type](#work-package-types) which usually includes several work packages of types like task or feature. For example, typical phases for a construction repair project would be the following: Project definition, detailed Design & Tender, Construction and Post project.

<div id="plugins"></div>

### Plugins / Integrations

In OpenProject, you can chose from several plugins or integrations or add your own plugins to the Community. As an open source software, OpenProject is open to Community-created plugins. Please note that we do not guarantee error-free and seamless use of those plugins. There are also integrations developed by the core OpenProject team, such as the *Excel synchronization* or the [Nextcloud integration](#nextcloud-integration).

Your activated plugins are listed together with your [modules](#module) in your instance under --> Administration --> Plugins. 

**More information on plugins in OpenProject**
- [See all available plugins and integrations for OpenProject](https://www.openproject.org/docs/system-admin-guide/integrations/)
- [Read how to create an OpenProject plugin](https://www.openproject.org/docs/development/create-openproject-plugin/)

<div id="project"></div>

### Project

In OpenProject, a [project](https://www.openproject.org/docs/user-guide/projects/) is defined as an individual or collaborative enterprise that is carefully planned to achieve a particular aim. Projects are the central organizational unit in OpenProject. Your projects can be available publicly or internally. OpenProject does not limit the number of projects, neither in the [Community edition](#community-edition) nor in the Enterprise cloud or in Enterprise on-premises edition. If you have more than one project in your instance, projects build a structure in OpenProject. You can have parent projects and sub-projects. For example, a project can represent

- an organizational unit of a company,
- an overarching team working on one topic or
- separate products or customers.

<div id="project-identifier"></div>

### Project identifier

The project identifier is defined as the unique name used to identify and reference projects in the application as well as in the address bar of your browser. Project identifiers can be changed in the [project settings](#project-settings).

<div id="project-navigation"></div>

### Project navigation

The project navigation is the side navigation within a project. Entries in the project navigation can be added and removed by activating and deactivating [modules](#module) in the [project settings](#project-settings).

<div id="project-overview"></div>

### Project overview

In OpenProject, the project overview is defined as a single [dashboard](#dashboard) page where all important information of a selected project can be displayed. The idea is to provide a central repository of information for the whole project team. Project information is added to the dashboard as [widgets](#widget). Open the project overview by navigating to "Overview" in the project menu on the left. [Read more about the project overview in OpenProject](https://www.openproject.org/docs/user-guide/project-overview/#project-overview)

<div id="project-settings"></div>

### Project settings

Project settings means project-specific setting configuration. The project settings contain general settings (e.g. the name and ID of the project), configuration of [modules](#module), [work package categories](#work-package-categories) and [types](#work-package-types), [custom fields](#custom-field), [version](#versions) settings, [time tracking activities](#time-and-costs), required disk storage, [file storages](#file-storage) and [Backlog](#backlog) settings (if plugin is installed). [Read more about project settings in OpenProject](https://www.openproject.org/docs/user-guide/projects/#project-settings)

<div id="project-status"></div>

### Project status

The project status in OpenProject is defined as an information for yourself and the team if the project is on track – to then being able to quickly act in case it is off track. [Read more about the project status in OpenProject](https://www.openproject.org/docs/user-guide/projects/project-status/)

<div id="project-status-reporting"></div>

### Project status reporting

The status reporting in OpenProject is the reporting relationship between different [projects](#project). Reporting relationships can be assigned a [project status](#project-status). Status reportings can be used to display multiple projects (and the associated [work packages](#work-package)) in a single timeline: The reporting project and its work packages are displayed in the timeline of the project that is reported to.

<div id="project-template"></div>

### Project template

A project template in OpenProject is defined as a dummy project to copy and adjust as often as you want. Project templates can be used for several projects that are similar in structure and [members](#member). Creating project templates can save time when creating new projects. [Read more about project templates in OpenProject in our user guide](https://www.openproject.org/docs/user-guide/projects/project-templates/) and see [this blog article to learn how to work with project templates](https://www.openproject.org/blog/project-templates/).

<div id="public-project"></div>

### Public project

In OpenProject, projects can be private or public. Public means that the project is visible to any user regardless of project [membership](#member). The visibility of a project can be changed in the project settings. [Read how to set a project to public in OpenProject](https://www.openproject.org/docs/user-guide/projects/#set-a-project-to-public)

## R

<div id="repository"></div>

## Repository

A repository is defined as a document or source code management system that allows users to manage files and folders via different version control systems (such as Subversion or Git). [Read more about Repository for source code control](https://www.openproject.org/docs/user-guide/repository/)

<div id="roadmap"></div>

### Roadmap

In OpenProject, a roadmap is defined as an overview page displaying the [versions](#versions) sorted alphabetically and the [work packages](#work-package) assigned to them. The roadmap is displayed in the [project navigation](#project-navigation) when the work package module is activated and a version has been created ([project settings](#project-settings)).

<div id="role"></div>

### Role

In OpenProject, a role is defined as a set of permissions defined by a unique name. Project [members](#member) are assigned to a project by specifying a user’s, [group’s](#group) or placeholder user’s name and the role(s) they should assume in the project.

## S

<div id="story-points"></div>

### Story points

Story points is a term known in Scrum. They are defined as numbers assigned to a [work package](#work-package) used to estimate (relatively) the size of the work. In OpenProject, you can add story points to work packages. [Read how to work with story points in OpenProject](https://www.openproject.org/docs/user-guide/backlogs-scrum/work-with-backlogs/#working-with-story-points)

## T

<div id="team-planner"></div>

### Team planner

The team planner in OpenProject is defined as a [module](#module) ([Enterprise add-on](#enterprise-add-on)) that helps you get a complete overview of what each [member](#member) of your team is working on in weekly or bi-weekly view. You can use it to track the current progress of [work packages](#work-package) your team is working on, schedule new tasks, reschedule them or even reassign them to different members. [Read more about the OpenProject team planner](https://www.openproject.org/docs/user-guide/team-planner/)

<div id="time-and-costs"></div>

### Time and costs

Time and costs in OpenProject is defined as a [module](#module) which allows users to log time on [work packages](#work-package), track costs and create time and cost reports. Once the time and costs module is activated, time and unit cost can be logged via the action menu of a work package. Logged time and costs can be searched for, aggregated and reported using the Cost reports menu item. [Read more about the time and costs module in OpenProject](https://www.openproject.org/docs/user-guide/time-and-costs/)

## U

<div id="user"></div>

### User

In OpenProject, a user is defined as a person who uses OpenProject, described by an identifier. New users can be created in the admin settings. Users can become project [members](#member) by either assigning them a role and adding them via the [project settings](#project-settings). Or by adding them to a project by the system admin at: Administration --> Users and permissions --> Users. Then clicking on the username and navigating to the tab "Projects". 

## V

<div id="versions"></div>

### Versions

Versions in OpenProject are defined as an attribute for [work packages](#work-package) or in the [Backlogs](#backlogs) module. Versions will be displayed in the [Roadmap](#roadmap). In the [Enerprise edition](#enterprise-add-on), you can also create a version [board](#board) to get an overview of the progress of your versions. (Read more about how to manage versions in OpenProject)[https://www.openproject.org/docs/user-guide/projects/project-settings/versions/]

## W

<div id="widget"></div>

### Widget

A widget in OpenProject is defined as a small and customizable element that provides relevant information at a glance. Use widgets on your [My Page](#my-page) dashboard or on the [project overview](#project-overview). [See all available project overview widgets](https://www.openproject.org/docs/user-guide/project-overview/#available-project-overview-widgets) and read [how to add a widget to the project overview](https://www.openproject.org/docs/user-guide/project-overview/#add-a-widget-to-the-project-overview)

<div id="wiki"></div>

### Wiki

In OpenProject, a wiki is defined as a [module](#module) that allows to use textile-based wiki pages. In order to use the wiki module, it has to be activated in the [project settings](#project-settings). [Read more about wikis in OpenProject](https://www.openproject.org/docs/user-guide/wiki/)

![A wiki module in OpenProject](glossary-openproject-wiki.png)

<div id="workflow"></div>

### Workflow

A workflow in OpenProject is defined as the allowed transitions between status for a [role](#role) and a type, i.e. which status changes can a certain role implement depending on the [work package type](#work-package-types). Workflows can be defined in the admin settings. For example, you might only want developers to be able to set the status "developed". [Read more about work package workflows in OpenProject](https://www.openproject.org/docs/system-admin-guide/manage-work-packages/work-package-workflows/#manage-work-package-workflows)

![glossary-openproject-sys-admin-edit-workflow](glossary-openproject-sys-admin-edit-workflow.png)

<div id="work-package"></div>

### Work package

In OpenProject, a [work package](https://www.openproject.org/docs/user-guide/work-packages/#overview) is defined as an item in a project. It is a subset of a project that can be assigned to users for execution, such as Tasks, Bugs, User Stories, Milestones, and more. Work packages have a [type](#work-package-types), an [ID](#work-package-id) and a subject and may have additional attributes, such as assignee, responsible, [story points](#story-points) or target version. Work packages are displayed in a project timeline (unless they are [filtered](#filters) out in the timeline configuration) - either as a milestone or as a [phase](#phase). In order to use the work packages, the work package module has to be activated in the [project settings](#project-settings).

![A work package in OpenProject](glossary-openproject-work-package.png)

**More information on work packages in OpenProject**
- [Read our user guide on work packages](https://www.openproject.org/docs/user-guide/work-packages/)
- [Read a blog article on how to work with work packages](https://www.openproject.org/blog/how-to-work-with-work-packages/)

<div id="work-package-table"></div>

### Work package table

The work package table in OpenProject is defined as the overview of all work packages in a project, together with their attributes in the columns. A synonym for work package table is the term "work package list". [Read how to configure a work package table](https://www.openproject.org/docs/user-guide/work-packages/work-package-table-configuration/)

![A work package table in OpenProject](glossary-openproject-work-package-table.png)

<div id="work-package-types"></div>

### Work package types

Work package types are the different items a work package can represent. Each work package is associated to exactly one type. Examples for most used work package types are a Task, a Milestone, a [Phase](#phase) or a Bug. The work package types can be customized in the system administration. [Read more about work package types in OpenProject](https://www.openproject.org/docs/user-guide/projects/project-settings/work-package-types/#work-package-types).

<div id="work-package-categories"></div>

### Work package categories

Work package categories are a functionality used to automatically assign a [member](#member) to a work package by specifying a category.[Read more about work package categories in OpenProject](https://www.openproject.org/docs/user-guide/projects/project-settings/work-package-categories/#manage-work-package-categories).

<div id="work-package-view"></div>

### Work package view

A list of work packages is considered a view. The containing work packages in any view can be displayed a number of different ways. Examples for most used work package views are the list view or the split screen view. [Read more about work package views in OpenProject](https://www.openproject.org/docs/user-guide/work-packages/work-package-views/#work-packages-views).

<div id="work-package-id"></div>

### Work package ID

Work package ID is defined as a unique ascending number assigned to a newly created work package. Work package IDs cannot be changed and are numbered across all projects of an OpenProject instance (therefore, the numbering within a project may not be sequential).