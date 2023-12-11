---
title: OpenProject 13.1.0
sidebar_navigation:
    title: 13.1.0
release_version: 13.1.0
release_date: 2023-12-13
---

# OpenProject 13.1.0

Release date: 2023-12-13

We released [OpenProject 13.1.0](https://community.openproject.com/versions/1486).

This new release brings a great update to our **Meetings module** along with many smaller changes and improvements, including the integration of **Primer** and providing a  **high contrast mode** to improve accessibility of OpenProject.

Enterprise customers will benefit from two more features that will make  it easier than ever to work efficiently with OpenProject: **Share work  packages with users outside a project** and a brand new  **OneDrive/SharePoint integration**. 

As always, this release contains several bug fixes and we recommend updating to the newest version.

## Dynamic meetings and agenda items linked to work packages

If you are already a user of OpenProject, you are probably familiar  with the Meetings module, which allows you to document meeting details.  Previously, it was only possible to use this module to create the agenda of a meeting in a single text block. 

With the introduction of  OpenProject 13.1,  in addition to the traditional meeting format a more dynamic  approach is offered. This enhanced module enables the **creation and management of individual agenda items**.

![OpenProject dynamic meetings example](openproject-13-1-dynamic-meetings.png)

In addition, it is now possible to **create direct links to specific meetings from a work package**. To do this, a new **“Meetings“ tab** is added to every work package, providing a comprehensive overview of  the discussions and linking directly to the meeting associated with the  work package.

![Dynamic meeting in OpenProject work package](openproject-dynamic-meeting-work-package.png)

This feature, designed with the latest Primer UI components and UX  patterns, is funded by the German Federal Ministry of the Interior and  Home Affairs (BMI) as part of the [openDesk](././././blog/sovereign-workplace/) project.

> Please note: The already existing classic meetings will be removed with one of the upcoming releases and only the new dynamic meetings will remain.  Migrations will be provided.

See our user guide to learn more about the [updated meetings module and how to use it](./././user-guide/meetings/dynamic-meetings/).

## OneDrive/SharePoint integration (Enterprise add-on)

Document sharing is an important aspect of collaboration, and  OpenProject has long been integrated with Nextcloud, a well-known open  source collaboration platform. However, OpenProject has recognized that  some customers use other document storage solutions, such as Microsoft  SharePoint, and has therefore developed integrations as an Enterprise  add-on. With OpenProject 13.1, users now have the option to upload,  link, and open files from work packages in OpenProject to  OneDrive/SharePoint.

> Please note: The Nextcloud integration remains part of the free Community edition. We plan to regularly publish Enterprise add-ons for the Community version.

![SharePoint integration in OpenProject](openproject-13-1-onedrive-sharepoint-integration.png)

See our user guide to learn more about this Enterprise add-on and how to [use the SharePoint integration](././user-guide/file-management/one-drive-integration/).

## Share work packages with external users and groups (Enterprise add-on)

The new version 13.1 of OpenProject introduces a new work package  sharing feature available as an Enterprise add-on. With this feature,  work packages can be shared with users or groups that have no  permissions to see this project, while maintaining confidentiality and  data integrity. This way, stakeholders can get easy access to relevant  project information without having to see all of a project’s work  packages.

![Share work packages with external users in OpenProject](openproject-13-1-share-work-packages.png)

However, this sharing is limited to users who are already part of the instance or who can be invited to join the instance. Guest accounts for sharing with external parties are not part of OpenProject 13.1 - but  may be considered in a future release.

See the user guide for [instructions on how to use this new feature](./././user-guide/work-packages/share-work-packages/).

## Attribute help texts are released into Community edition

We remain committed to our Community and believe that continuous  development of the OpenProject Community edition will benefit everyone.  Therefore, we plan to regularly publish Enterprise add-ons for the  Community version. With OpenProject 13.1, we release [Attribute help texts](./././system-admin-guide/attribute-help-texts/) for the Community.

For all project attributes, including status, accountable, or any custom  field, you can set up explanatory help text. This will be represented by a small question mark icon positioned next to the attribute, aiding in  the input process and helping to reduce mistakes.

![Example of an attribute text in OpenProject](openproject-13-1-help-texts.png)

## Accessibility improvements and high contrast mode

We continued to work on improving accessibility of OpenProject according to the WCAG 2.1 AA. You can now select to use a high contrast mode in your [profile settings](./././getting-started/my-account/#select-the-high-contrast-color-mode), which will override the current OpenProject theme and be especially valuable for OpenProject users with visual impairments. 

![High contrast mode in OpenProject](openproject_my_account_high_contrast_mode.png)

## Continued integration of Primer design system

With OpenProject 13.1 we have continued to integration the [Primer Design system](https://primer.style/). This will especially be noticeable in the new features, such as the new Meetings module. 

#### List of all bug fixes and changes

- Epic: Share work packages with external users and groups that are not member of the project team \[[#31150](https://community.openproject.com/wp/31150)\]
- Epic: Link work packages with files and folders in OneDrive/SharePoint \[[#36057](https://community.openproject.com/wp/36057)\]
- Epic: Dynamic meetings and agenda items linked to work packages \[[#37297](https://community.openproject.com/wp/37297)\]
- Epic: File Storages - Administration settings with Primer \[[#49841](https://community.openproject.com/wp/49841)\]
- Changed: Allow attachment upload on read-only work packages \[[#29203](https://community.openproject.com/wp/29203)\]
- Changed: Allow filtering of "empty" date fields (start/finish/custom) \[[#39455](https://community.openproject.com/wp/39455)\]
- Changed: Meeting module: Modes and permission levels \[[#49334](https://community.openproject.com/wp/49334)\]
- Changed: Workflow for sharing work packages \[[#49482](https://community.openproject.com/wp/49482)\]
- Changed: Upload custom picture for cover page of pdf export \[[#49684](https://community.openproject.com/wp/49684)\]
- Changed: Meetings tab on work package page  \[[#49951](https://community.openproject.com/wp/49951)\]
- Changed: PDF export (single work package): Include all attributes and fields according to the work package type form configuration \[[#49977](https://community.openproject.com/wp/49977)\]
- Changed: Make the seed data in the teaser sections "Welcome to OpenProejct" more robust for user that do not have the correct permissions \[[#50070](https://community.openproject.com/wp/50070)\]
- Changed: Skip project selection step in onboarding tour \[[#50073](https://community.openproject.com/wp/50073)\]
- Changed: Activate meeting module and one meeting "weekly" to the seed data \[[#50132](https://community.openproject.com/wp/50132)\]
- Changed: Update project deletion danger zone to include project folders as a dependent relation \[[#50233](https://community.openproject.com/wp/50233)\]
- Changed: [API] Add storage filter to project and project storage collection \[[#50234](https://community.openproject.com/wp/50234)\]
- Changed: Ensuring connection and permissions on project folder while redirecting users to Nextcloud/OneDrive from project menu. \[[#50437](https://community.openproject.com/wp/50437)\]
- Changed: Optionally allow locked/closed versions for custom field \[[#50526](https://community.openproject.com/wp/50526)\]
- Changed: Hide the sidebar in all tappable screens (tablet and mobile) \[[#50652](https://community.openproject.com/wp/50652)\]
- Changed: Revise permissions for seeded roles \[[#50827](https://community.openproject.com/wp/50827)\]
- Changed: Equals All (&=) operator for user action filter on project collection \[[#50910](https://community.openproject.com/wp/50910)\]
- Changed: Present the storage health information on the admin page \[[#50921](https://community.openproject.com/wp/50921)\]
- Changed: Show work package's meeting tab count \[[#51012](https://community.openproject.com/wp/51012)\]
- Changed: Mobile, the participant section should move to details section \[[#51015](https://community.openproject.com/wp/51015)\]
- Changed: Show identity_url in users edit form \[[#51027](https://community.openproject.com/wp/51027)\]
- Changed: Update strings for user role/status line in share work package modal \[[#51165](https://community.openproject.com/wp/51165)\]
- Changed: openDesk: Navigation quick wins \[[#51264](https://community.openproject.com/wp/51264)\]
- Changed: Add Enterprise Banner and checks for OneDrive/SharePoint file storage integration \[[#51305](https://community.openproject.com/wp/51305)\]
- Changed: Move the custom Help Texts to Community edition \[[#51306](https://community.openproject.com/wp/51306)\]
- Changed: Redirect uri flow \[[#51372](https://community.openproject.com/wp/51372)\]
- Changed: Display since when a failure state is occurring \[[#51423](https://community.openproject.com/wp/51423)\]
- Fixed: Unable to mention User when name display is lastname, firstname \[[#43856](https://community.openproject.com/wp/43856)\]
- Fixed: Total progress does not change color \[[#44859](https://community.openproject.com/wp/44859)\]
- Fixed: Work-package relationship are lost when copying \[[#45533](https://community.openproject.com/wp/45533)\]
- Fixed: No reCAPTCHA during user registration \[[#47796](https://community.openproject.com/wp/47796)\]
- Fixed: Work package can be only once modified in the calendar on Overview page, error on 2nd time \[[#48333](https://community.openproject.com/wp/48333)\]
- Fixed: Save Team Planner view as 2 weeks view not only 1 week view. \[[#48355](https://community.openproject.com/wp/48355)\]
- Fixed: [Roadmap] Cannot deselect subprojects on roadmap page \[[#49135](https://community.openproject.com/wp/49135)\]
- Fixed: Work Package Roles shown as options in "Assignee's role" filter \[[#49987](https://community.openproject.com/wp/49987)\]
- Fixed: Wiki: embedded work package table: filter on (deleted) subprojects prevents editing  \[[#50080](https://community.openproject.com/wp/50080)\]
- Fixed: Breadcrumb and menu structure is inconsistent for user administration \[[#50109](https://community.openproject.com/wp/50109)\]
- Fixed: When disabling the default `admin` user, after an update two `admin` users exists in the database. \[[#50208](https://community.openproject.com/wp/50208)\]
- Fixed: Missing space between avatars and usernames in Administration -> Users \[[#50213](https://community.openproject.com/wp/50213)\]
- Fixed: Custom export cover background overlay color won't return to the default one after deleting \[[#50219](https://community.openproject.com/wp/50219)\]
- Fixed: Custom actions still shown on WP page after switching from Enterprise free trial to Community \[[#50237](https://community.openproject.com/wp/50237)\]
- Fixed: Authorization::UserGlobalRolesQuery wrongfully returns WorkPackageRoles \[[#50287](https://community.openproject.com/wp/50287)\]
- Fixed: PageHeader component should not have the divider on mobile screens \[[#50303](https://community.openproject.com/wp/50303)\]
- Fixed: Unexpected default value for limit_self_registration option of omniauth providers \[[#50432](https://community.openproject.com/wp/50432)\]
- Fixed: Attribute help text icon overlaps with the field \[[#50436](https://community.openproject.com/wp/50436)\]
- Fixed: Removing "use_graph_api" in azure form does not unset it \[[#50448](https://community.openproject.com/wp/50448)\]
- Fixed: Overview page is blank on QA Edge \[[#50455](https://community.openproject.com/wp/50455)\]
- Fixed: On Storage name update, also update PageHeader title without refreshing the full page \[[#50738](https://community.openproject.com/wp/50738)\]
- Fixed: DELETE storage button fails and is converted to a GET request \[[#50739](https://community.openproject.com/wp/50739)\]
- Fixed: Global and Admin hamburger menu is missing \[[#50758](https://community.openproject.com/wp/50758)\]
- Fixed: iCalender are not updated automatically \[[#50768](https://community.openproject.com/wp/50768)\]
- Fixed: Default activity assigned in project where it is inactive breaks time tracking button \[[#50784](https://community.openproject.com/wp/50784)\]
- Fixed: Starting Guided Tour (from the Scrum project) does not work for non-admin \[[#50881](https://community.openproject.com/wp/50881)\]
- Fixed: Incorrect (default) provider type (Nextcloud) mentioned in error message when upload does not work (for SharePoint) \[[#50898](https://community.openproject.com/wp/50898)\]
- Fixed: PDF Export not using default export filename sanitation \[[#50912](https://community.openproject.com/wp/50912)\]
- Fixed: (QA Edge) Jobs are queued but are not worked on, resulting in impossibility to copy project, export etc.  \[[#50917](https://community.openproject.com/wp/50917)\]
- Fixed: [Error 500] occurs when switching to "ALL" result when searching for "meeting" word in Chinese/Korean/Japanese language in all projects \[[#50972](https://community.openproject.com/wp/50972)\]
- Fixed: In the global calendar create form invalid projects are selectable \[[#50995](https://community.openproject.com/wp/50995)\]
- Fixed: In work packages list, selecting first option of "group by" does not work \[[#51135](https://community.openproject.com/wp/51135)\]
- Fixed: No free sorting of enumerations \[[#51183](https://community.openproject.com/wp/51183)\]
- Fixed: Non-existing user's workflow issues with account creation \[[#51262](https://community.openproject.com/wp/51262)\]
- Fixed: When OAuth clients are "Incomplete" we should skip alert confirmation and icon should be pencil icon \[[#51266](https://community.openproject.com/wp/51266)\]
- Fixed: When you only have work package permissions, the project index page gives you a 403 error \[[#51267](https://community.openproject.com/wp/51267)\]
- Fixed: Sidebar is missing when directly opening a work package via its URL \[[#51268](https://community.openproject.com/wp/51268)\]
- Fixed: Users with only WP edit access cannot update status \[[#51269](https://community.openproject.com/wp/51269)\]
- Fixed: Direct upload to empty Microsoft drive fails \[[#51274](https://community.openproject.com/wp/51274)\]
- Fixed: Primer checkboxes lack a background in High Contrast Mode \[[#51275](https://community.openproject.com/wp/51275)\]
- Fixed: Edit project storage leads to project folder for one drive storages \[[#51319](https://community.openproject.com/wp/51319)\]
- Fixed: Dismiss action of the primer banner is not translated \[[#51360](https://community.openproject.com/wp/51360)\]
- Fixed: In mobile view, the primer banner does not take the full width \[[#51370](https://community.openproject.com/wp/51370)\]
- Fixed: Disk shown on checkmark list's second level \[[#51401](https://community.openproject.com/wp/51401)\]
- Fixed: Date field on work package too narrow \[[#51402](https://community.openproject.com/wp/51402)\]
- Fixed: Users with edit rights cannot see their logged time \[[#51403](https://community.openproject.com/wp/51403)\]
- Fixed: Nextcloud storage not displayed in Files tab for users with edit rights \[[#51404](https://community.openproject.com/wp/51404)\]
- Fixed: Users with Edit rights cannot copy the WP \[[#51405](https://community.openproject.com/wp/51405)\]
- Fixed: Users with comment rights cannot upload attachments \[[#51408](https://community.openproject.com/wp/51408)\]
- Fixed: Upon submitting the general info the storage view component is nested \[[#51411](https://community.openproject.com/wp/51411)\]
- Fixed: Lines not aligned with text on the login screen \[[#51412](https://community.openproject.com/wp/51412)\]
- Fixed: Search not working on some meetings (possibly because of agenda items containing macros) \[[#51426](https://community.openproject.com/wp/51426)\]
- Fixed: Overview page suggests some information (e.g. custom fields, status, description) not set when they are hidden \[[#51431](https://community.openproject.com/wp/51431)\]

#### Contributions
A big thanks to Community members for reporting bugs and helping us identifying and providing fixes.

- Special thanks for reporting and finding bugs go to Jeff Tseung, Richard Richter, Daniel Elkeles, Jörg Mollowitz, Christina Vechkanova, Sven Kunze, Jeff Li, Mario Haustein, Mario Zeppin

- A big thank you to every other dedicated user who has [reported bugs](https://www.openproject.org/docs/development/report-a-bug) and supported the community by asking and answering questions in the [forum](https://community.openproject.org/projects/openproject/boards).

- A big thank you to all the dedicated users who provided translations on [CrowdIn](https://crowdin.com/projects/opf).