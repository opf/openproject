---
title: OpenProject 12.2.0
sidebar_navigation:
  title: 12.2.0
release_version: 12.2.0
release_date: 2022-08-15
---

# OpenProject 12.2.0

Release date: 2022-08-15

We have now released [OpenProject 12.2.0](https://community.openproject.org/versions/1494).

This new release brings the long-awaited **Nextcloud integration**. No more spending hours searching for the right version of the right file! With OpenProject 12.2, you can easily find your project-related files (stored in Nextcloud) directly from the relevant work packages and always have the correct version at your fingertips. Data sovereignty remains a strong common ground between Nextcloud and OpenProject and this integration strengthens our collaboration while improving the productivity of our users.

Additionally, this release introduces **improvements to the date picker**, the possibility to **log time for other users** and mark work packages with notifications as read outside of notification center.

As always, this release also contains many more improvements and bug fixes. We recommend updating to the newest version as soon as possible.

## File management with Nextcloud

With OpenProject 12.2, you can now use Nextcloud, the world’s most-deployed on-premises content collaboration platform, together with OpenProject, the leading free and open source project management software, to combine project management and file management. Data sovereignty and open source are important core values to both OpenProject and Nextcloud and form the foundation for this integration.

We believe the productivity of users of both platforms will increase significantly as a result of this integration.

**In OpenProject:** In addition to listing files attached to a work package, the Files tab now also shows you Nextcloud files that are linked to the current work package, allowing users to ensure they always have the latest version at hand. Secondary actions on each file allow you to directly **open or download the file, show the containing folder in Nextcloud or remove the link**.

![Nextcloud files linked in OpenProject](display-nextcloud-files.png)**In Nextcloud:** You will be able to access the OpenProject tab in Nextcloud by accessing the details split screen of any file. In this tab, you will be able to search for the work package(s) to which you would like to add a link to the current file. Once a work package is linked to a file, you can always unlink it by clicking on the **unlink** icon.

![Link work packages in Nextcloud](link-workpackages-nextcloud.png)

Further integration efforts are under way, notably to make it possible to create links to Nextcloud files from directly from OpenProject (it is currently only possible via Nextcloud) and adding complete project folders.

You can find out more [how to use the Nextcloud integration](../../../user-guide/file-management/nextcloud-integration/) as well as the [how to setup the Nextcloud integration](../../../system-admin-guide/integrations/nextcloud/) in our documentation.

## Contextual information and warnings when scheduling work packages

For OpenProject 12.2, the team has worked on **improving the date picker** to give you more clarity when scheduling work packages. To choose [automatic or manual scheduling mode](../../../user-guide/gantt-chart/scheduling/), the selection box moved to the top of the date picker to be more visible. We are also introducing information and warning banners that provide important contextual information before modifying dates of work packages that have relations with other work packages.

*Blue banners* will indicate information that maybe be helpful (such as if the work package's dates are automatically derived from relations, or if available date ranges are limited by relations) and *orange banners* will warn of possible consequences to other work packages (existing relations being ignored as a result of enabling manual scheduling, or the dates of related work packages changing as a result of changes to the current work package).

Additionally, a new "**Show relations**" on these banners allows you to quickly generate a Gantt view showing all directly related work packages in hierarchy view, so you can preview which work packages might be affected before making a change.

![warning in date picker](date-picker-warning.png)

Find out more about how to set and change dates with the [improved date picker](../../../user-guide/work-packages/set-change-dates/) in our documentation.

## Log time for other users

OpenProject 12.2 gives an administrator the possibility to grant permissions to log time for other users. With the required permissions, you can now select the team member for whom you want to log time from a drop down.

![log time for other users](image-20220811130616209.png)

Find out more about [logging time for other users](../../../user-guide/time-and-costs/time-tracking/#log-and-edit-time-for-other-users) in our documentation.

## Improved navigation bar

When you open the project drop down from the header menu to view all projects, you are now also able to create new projects, simply by clicking on **+ Project**.

To view all available projects, simply click on the **Projects list** button at the bottom of the modal.

![improved project selection](improved-navigation-bar.png)

## Mark notifications as read outside of Notification Center

In OpenProject 12.2, you are now able to mark work packages with notifications as read also in the work packages details view by clicking on the **Mark as read** button on the top right toolbar.

![mark-notifications-as-read](mark-notifications-as-read.png)o

## Deprecations and breaking changes

### Changed settings for HTTPs management

In 12.2, the way settings are being handled for controlling HTTPs mode of OpenProject have changed.
In case of a packaged installation, the configuration from the packager wizard will result in the correct configuration.

For docker you will need to set the environment variable `OPENPROJECT_HTTPS=false` if you actively want to disable HTTPS mode.

For more information, please see the respective installation pages:

- [Packaged installation](../../../installation-and-operations/installation/packaged/#step-3-apache2-web-server-and-ssl-termination)
- [Docker installation](../../../installation-and-operations/installation/docker/#configuration)

## List of all bug fixes and changes

- Changed: Log time for other users \[[#21754](https://community.openproject.org/wp/21754)\]
- Changed: Send out an email reply if an incoming email could not be processed correctly \[[#35823](https://community.openproject.org/wp/35823)\]
- Changed: Make the empty notification inbox nicer \[[#40148](https://community.openproject.org/wp/40148)\]
- Changed: Show the project hierarchy in the project selector  \[[#40286](https://community.openproject.org/wp/40286)\]
- Changed: OAuth settings of Nextcloud in OpenProject \[[#40375](https://community.openproject.org/wp/40375)\]
- Changed: Unify Enterprise edition pages \[[#40774](https://community.openproject.org/wp/40774)\]
- Changed: Keep cached file data up to date \[[#40892](https://community.openproject.org/wp/40892)\]
- Changed: Apply style changes to new date picker \[[#41814](https://community.openproject.org/wp/41814)\]
- Changed: List file links in Files tab \[[#41905](https://community.openproject.org/wp/41905)\]
- Changed: Navigation bar project selection \[[#41948](https://community.openproject.org/wp/41948)\]
- Changed: Date picker modal (without duration and non-working days) \[[#42047](https://community.openproject.org/wp/42047)\]
- Changed: Add packaged installation support for Ubuntu 22.04 \[[#42069](https://community.openproject.org/wp/42069)\]
- Changed: Show banner information in new date picker \[[#42184](https://community.openproject.org/wp/42184)\]
- Changed: Change date selection logic in new date picker \[[#42185](https://community.openproject.org/wp/42185)\]
- Changed: Link to digital accessibility statement from ADDITIONAL RESOURCES \[[#42298](https://community.openproject.org/wp/42298)\]
- Changed: New attachments style on the work package creation form \[[#42369](https://community.openproject.org/wp/42369)\]
- Changed: Enable feature flags by default in the development environment \[[#42414](https://community.openproject.org/wp/42414)\]
- Changed: Enable feature flag for storages module on pull preview \[[#42628](https://community.openproject.org/wp/42628)\]
- Changed: Map available icons in the files list to relevant file types (in attachments/Nextcloud links) \[[#42884](https://community.openproject.org/wp/42884)\]
- Changed: Include work package for which relations are shown when following the "show relations" link \[[#42898](https://community.openproject.org/wp/42898)\]
- Changed: Access project dropdown entries via arrow keys \[[#43118](https://community.openproject.org/wp/43118)\]
- Changed: Show alert when storage is not added to any project \[[#43185](https://community.openproject.org/wp/43185)\]
- Changed: Update NEW FEATURES teaser block on application start page \[[#43485](https://community.openproject.org/wp/43485)\]
- Changed: Persist OpenProject notifications to avoid loss of information \[[#43518](https://community.openproject.org/wp/43518)\]
- Fixed: Circular dependency can be created \[[#34928](https://community.openproject.org/wp/34928)\]
- Fixed: Sorting via "projects" doesn't work \[[#37149](https://community.openproject.org/wp/37149)\]
- Fixed: Quick-add menu not showing on smaller screens \[[#37539](https://community.openproject.org/wp/37539)\]
- Fixed: Default status is shown multiple times in new board \[[#40858](https://community.openproject.org/wp/40858)\]
- Fixed: "expected at least one error" - Work package errors in dependent work packages not displayed \[[#40921](https://community.openproject.org/wp/40921)\]
- Fixed: OpenProject docker installation uses port 3000 as the outward-facing port but documentation says 8080 \[[#41287](https://community.openproject.org/wp/41287)\]
- Fixed: Deleted users are not properly anonymized in tagged messages \[[#41499](https://community.openproject.org/wp/41499)\]
- Fixed: Cannot inline-create a work package on views that filter by WP ID \[[#41667](https://community.openproject.org/wp/41667)\]
- Fixed: In team planner and calendar, the sidebar should not use the word "views" \[[#41830](https://community.openproject.org/wp/41830)\]
- Fixed: Distances in work package details tabs inconsistent \[[#41845](https://community.openproject.org/wp/41845)\]
- Fixed: Blank Email reminders page when creating account manually \[[#41851](https://community.openproject.org/wp/41851)\]
- Fixed: Cannot add attachment to existing comment \[[#41940](https://community.openproject.org/wp/41940)\]
- Fixed: Closed cards in the team planner behave strangely \[[#42413](https://community.openproject.org/wp/42413)\]
- Fixed: Project appearing twice in Dropdown List if Project Member has two or more roles \[[#42477](https://community.openproject.org/wp/42477)\]
- Fixed: Date picker gets cut when there is no scroll \[[#42748](https://community.openproject.org/wp/42748)\]
- Fixed: Packager builds failing since gem bump \[[#42871](https://community.openproject.org/wp/42871)\]
- Fixed: Custom action button in combination with parallel changes leads to conflicting modification error \[[#42878](https://community.openproject.org/wp/42878)\]
- Fixed: Attachments are assigned to the wrong Work Package \[[#42933](https://community.openproject.org/wp/42933)\]
- Fixed: Navigation Link Not Working \[[#42984](https://community.openproject.org/wp/42984)\]
- Fixed: Unable to create child work package \[[#42988](https://community.openproject.org/wp/42988)\]
- Fixed: Size of dropdowns in work-package list too small especially for project hierarchy \[[#43083](https://community.openproject.org/wp/43083)\]
- Fixed: Internal server error when navigating to the work package module (page size) \[[#43120](https://community.openproject.org/wp/43120)\]
- Fixed: webhook is not working \[[#43129](https://community.openproject.org/wp/43129)\]
- Fixed: Split screen persistent with empty state switching toggle from All to Unread \[[#43146](https://community.openproject.org/wp/43146)\]
- Fixed: Missing plural in user settings -> access tokens \[[#43151](https://community.openproject.org/wp/43151)\]
- Fixed: Fix storage admin breadcrumbs \[[#43153](https://community.openproject.org/wp/43153)\]
- Fixed: Two English language \[[#43192](https://community.openproject.org/wp/43192)\]
- Fixed: Remove OAuth cookie after successful authorization against Nextcloud \[[#43193](https://community.openproject.org/wp/43193)\]
- Fixed: Project export confusingly uses "Work packages export limit" setting \[[#43202](https://community.openproject.org/wp/43202)\]
- Fixed: Mobile: The right margin for the files list is not correct \[[#43207](https://community.openproject.org/wp/43207)\]
- Fixed: Double click to open work packages in the Team Planner \[[#43222](https://community.openproject.org/wp/43222)\]
- Fixed: Able to set a follower starting before its predecessor \[[#43223](https://community.openproject.org/wp/43223)\]
- Fixed: Migration::MigrationUtils::PermissionAdder.add not idempotent \[[#43231](https://community.openproject.org/wp/43231)\]
- Fixed: imap ssl settings are evaluated as booleans when they are strings \[[#43237](https://community.openproject.org/wp/43237)\]
- Fixed: Work Package Relation entry not styling type properly \[[#43239](https://community.openproject.org/wp/43239)\]
- Fixed: Work packages in Gantt chart in light grey hard to see \[[#43240](https://community.openproject.org/wp/43240)\]
- Fixed: Work package types with color white are not visible in emails \[[#43247](https://community.openproject.org/wp/43247)\]
- Fixed: Can not find users with the user creation/invitation form  \[[#43257](https://community.openproject.org/wp/43257)\]
- Fixed: The list style in the "Nextcloud" section is not correct \[[#43259](https://community.openproject.org/wp/43259)\]
- Fixed: Remove hover effect on files list when there is a connection error to Nextcloud \[[#43260](https://community.openproject.org/wp/43260)\]
- Fixed: The space between the form and the buttons on the 2nd and 3rd step of Nextcloud OAuth settings is not correct \[[#43263](https://community.openproject.org/wp/43263)\]
- Fixed: Can not access the main actions on work package on mobile from the details view \[[#43296](https://community.openproject.org/wp/43296)\]
- Fixed: Mobile: The right margin for activity comments is not correct \[[#43304](https://community.openproject.org/wp/43304)\]
- Fixed: Wrong positioning of workers in notification \[[#43306](https://community.openproject.org/wp/43306)\]
- Fixed: (Mobile) Clicking on notification row does not scroll to activity \[[#43311](https://community.openproject.org/wp/43311)\]
- Fixed: Project name overflows header on mobile  \[[#43314](https://community.openproject.org/wp/43314)\]
- Fixed: Info boxes in the Administration are not shown correctly \[[#43320](https://community.openproject.org/wp/43320)\]
- Fixed: Nextcloud: Validation error in New storage - Host field \[[#43323](https://community.openproject.org/wp/43323)\]
- Fixed: Project field limited to 30 items \[[#43386](https://community.openproject.org/wp/43386)\]
- Fixed: Start date automatically entered by default on new work packages \[[#43429](https://community.openproject.org/wp/43429)\]
- Fixed: There is no empty status in the Project Select when search criteria is not met \[[#43479](https://community.openproject.org/wp/43479)\]
- Fixed: Focus status on the Project Selector has no background \[[#43482](https://community.openproject.org/wp/43482)\]
- Fixed: Invalid link/href returned by API \[[#43486](https://community.openproject.org/wp/43486)\]
- Fixed: Show better error for dependent result for StoragesController Create action \[[#43487](https://community.openproject.org/wp/43487)\]
- Fixed: Date picker not working as expected for UTC time hour minus \[[#43504](https://community.openproject.org/wp/43504)\]
- Fixed: "No SSL" option in packaged installation of 12.2 does not work \[[#43530](https://community.openproject.org/wp/43530)\]
- Fixed: Focus and selection different for project selection component \[[#43544](https://community.openproject.org/wp/43544)\]
- Fixed: First greyed out item is selected in project dropdown \[[#43545](https://community.openproject.org/wp/43545)\]
- Fixed: Time entry widget column translations missing \[[#43558](https://community.openproject.org/wp/43558)\]
- Fixed: Disable LDAP user status synchronization by default \[[#43561](https://community.openproject.org/wp/43561)\]
- Fixed: Datepicker jumps with negative time zone \[[#43562](https://community.openproject.org/wp/43562)\]
- Epic: Files tab that shows linked files in Nextcloud \[[#40203](https://community.openproject.org/wp/40203)\]
- Epic: Settings connection between Nextcloud and OpenProject (OAuth) \[[#42072](https://community.openproject.org/wp/42072)\]

## Contributions

A big thanks to community members for reporting bugs, helping us identify issues and providing fixes.

- Special thanks for City of Cologne and University of Duisburg-Essen for sponsoring the development of the Nextcloud integration.
- Special thanks for reporting and finding bugs go to kak tux, Karl Sebera, Christina Vechkanova, Ulrich Germann, Kiran Kafle, Alexander Seitz, Max Chen, PD Inc Support, Rince wind, Simon Rohart, Sander Kleijwegt, Sreekanth Gopalakris.
- A big thank you to every other dedicated user who has [reported bugs](../../../development/report-a-bug) and supported the community by asking and answering questions in the [forum](https://community.openproject.org/projects/openproject/boards).
- A big thank you to all the dedicated users who provided translations on [CrowdIn](https://crowdin.com/projects/opf).
