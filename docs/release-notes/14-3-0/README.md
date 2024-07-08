---
title: OpenProject 14.3.0
sidebar_navigation:
    title: 14.3.0
release_version: 14.3.0
release_date: 2024-07-17
---

# OpenProject 14.3.0

Release date: 2024-07-17

We released OpenProject [OpenProject 14.3.0](https://community.openproject.org/versions/2053). The release contains several bug fixes and we recommend updating to the newest version. In these Release Notes, we will give an overview of important feature changes. At the end, you will find a complete list of all changes and bug fixes.


## Important feature changes

<!-- Inform about the major features in this section -->

## Important updates and breaking changes

<!-- Remove this section if empty, add to it in pull requests linking to tickets and provide information -->

<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Feature: Users are able to create multiple API access tokens \[[#48619](https://community.openproject.org/wp/48619)\]
- Feature: Starring favorite project lists \[[#51672](https://community.openproject.org/wp/51672)\]
- Feature: Public and shared project lists \[[#51779](https://community.openproject.org/wp/51779)\]
- Feature: Add searchbar to Submenu component \[[#52555](https://community.openproject.org/wp/52555)\]
- Feature: Unselect projects from the project selector \[[#53026](https://community.openproject.org/wp/53026)\]
- Feature: Add "Connection validation" functionality for OneDrive/SharePoint storages \[[#55443](https://community.openproject.org/wp/55443)\]
- Feature: Primerize the user profile page \[[#55605](https://community.openproject.org/wp/55605)\]
- Feature: Add CRUD News API endpoints to allow automatic creation of the release news \[[#55764](https://community.openproject.org/wp/55764)\]
- Feature: Configure SMTP timeout over ENV variable \[[#55879](https://community.openproject.org/wp/55879)\]
- Feature: Gantt chart PDF export: add date zoom based on calendar weeks \[[#55954](https://community.openproject.org/wp/55954)\]
- Feature: Allow admins to choose between display in hours-only or days and hours \[[#55997](https://community.openproject.org/wp/55997)\]
- Bugfix: Removing logged activity via spent time widget freezes the site and destroys spent time widget \[[#53200](https://community.openproject.org/wp/53200)\]
- Bugfix: The label for "Spent time" is still visible after deactiving the module "Time and costs" \[[#53772](https://community.openproject.org/wp/53772)\]
- Bugfix: Keyboard navigation for agenda item creation in meetings does not work as expected \[[#54376](https://community.openproject.org/wp/54376)\]
- Bugfix: Milestones are showing the children ticket section \[[#54983](https://community.openproject.org/wp/54983)\]
- Bugfix: Meeting Attachments not visible after changing from open to close - reload required \[[#55144](https://community.openproject.org/wp/55144)\]
- Bugfix: Set correct guards for action: deactivate\_work\_package\_attachments \[[#55194](https://community.openproject.org/wp/55194)\]
- Bugfix: Switch to show favorite projects is shown for anonymous user \[[#55254](https://community.openproject.org/wp/55254)\]
- Bugfix: PDF report: multi column table with pictures not included \[[#55268](https://community.openproject.org/wp/55268)\]
- Bugfix: Endless loop with work package attributes value macro for description \[[#55320](https://community.openproject.org/wp/55320)\]
- Bugfix: Shared work packages in template projects cause several flaws in new projects \[[#55362](https://community.openproject.org/wp/55362)\]
- Bugfix: Individual work packages in ID filter cannot be removed \[[#55447](https://community.openproject.org/wp/55447)\]
- Bugfix: Client Credential caching affecting debugging and Issue Resolution \[[#55620](https://community.openproject.org/wp/55620)\]
- Bugfix: Presenter field on agenda item becomes tiny if the current presenter is removed and a new one is searched for \[[#55621](https://community.openproject.org/wp/55621)\]
- Bugfix: Meeting Participants dialog is broken when the project has no members \[[#55624](https://community.openproject.org/wp/55624)\]
- Bugfix: Page title is wrong on project attributes settings page \[[#55657](https://community.openproject.org/wp/55657)\]
- Bugfix: Failing storage sync breaks integration job  \[[#55767](https://community.openproject.org/wp/55767)\]
- Bugfix: Type gets automatically changed on move to target project if type not activated in project (possible data loss) \[[#55771](https://community.openproject.org/wp/55771)\]
- Bugfix: Preselected colors for Status and Type are hard to see in dark mode \[[#55774](https://community.openproject.org/wp/55774)\]
- Bugfix: Click the title of "LATEST ACTIVITY AT" column in project list will meet an error notification. \[[#55783](https://community.openproject.org/wp/55783)\]
- Bugfix: Main menu resizer handle icon change on hover not working for Safari \[[#55786](https://community.openproject.org/wp/55786)\]
- Bugfix: Deactivating work package attachment on project fails, if project has unset required project attribute \[[#55789](https://community.openproject.org/wp/55789)\]
- Bugfix: Form validation in add project dialog missing \[[#55801](https://community.openproject.org/wp/55801)\]
- Bugfix: Handle errors of misconfigured storages during project copy \[[#55805](https://community.openproject.org/wp/55805)\]
- Bugfix: Project list filter component extends to the width of project columns \[[#55812](https://community.openproject.org/wp/55812)\]
- Bugfix: Export XLS button is out of screen on Time & Cost page \[[#55874](https://community.openproject.org/wp/55874)\]
- Bugfix: Star for favourite projects is black \[[#55914](https://community.openproject.org/wp/55914)\]
- Bugfix: Projects list drop down cut off in memberships page \[[#55922](https://community.openproject.org/wp/55922)\]
- Bugfix: Boards icon in the waffle menu doesn't show all boards \[[#55924](https://community.openproject.org/wp/55924)\]
- Bugfix: Invalid refresh tokens of Nextcloud are not handled correctly  \[[#56011](https://community.openproject.org/wp/56011)\]
- Bugfix: BIM-Model - Viewpoint - all Viepoints are saved to the last BCF after the refresh of the Viewer \[[#56012](https://community.openproject.org/wp/56012)\]
- Bugfix: File Upload fails if exactly 4096 Byte \[[#56032](https://community.openproject.org/wp/56032)\]
- Bugfix: Icon is missing for Slack integration menu item \[[#56035](https://community.openproject.org/wp/56035)\]
- Bugfix: LDAP seeder: Password interpreted as YAML \[[#56039](https://community.openproject.org/wp/56039)\]
- Bugfix: hal+json requests treated as plain html requests \[[#56040](https://community.openproject.org/wp/56040)\]
- Bugfix: \[BUG\] Gantt Diagrams not sorted alphabetically in the left side menu \[[#56042](https://community.openproject.org/wp/56042)\]
- Bugfix: Spacing between title and tabs in page headers is too small \[[#56060](https://community.openproject.org/wp/56060)\]
- Bugfix: Loading gif in notification center and enterprise videos have white background in dark mode \[[#56157](https://community.openproject.org/wp/56157)\]
- Bugfix: Work package description disappears if user edits title at the same time \[[#56159](https://community.openproject.org/wp/56159)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->

## Contributions
A very special thank you goes to our sponsors for this release. Also a big thanks to our Community members for reporting bugs and helping us identify and provide fixes. Special thanks for reporting and finding bugs go to Bill Bai, Alexander Hosmann, Alexander Aleschenko, and Sven Kunze.

Last but not least, we are very grateful for our very engaged translation contributors on Crowdin, who translated quite a few OpenProject strings! Would you like to help out with translations yourself? Then take a look at our translation guide and find out exactly how you can contribute. It is very much appreciated!