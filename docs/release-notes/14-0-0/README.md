---
title: OpenProject 14.0.0
sidebar_navigation:
  title: 14.0.0
release_version: 14.0.0
release_date: 2024-04-08
---

# OpenProject 14.0.0

Release date: 2024-04-08

We released [OpenProject 14.0.0](https://community.openproject.org/versions/1356).
The release contains several bug fixes and we recommend updating to the newest version.

## Important updates and breaking changes

### API V3: Renaming of Delay to Lag

In the relations API, the attribute `delay` has been renamed to `lag`.
This change is to align the API with the terminology used in project management and the UI.

For more information, see [#44054](https://community.openproject.org/work_packages/44054)

### Removed deprecated methods for permission checks

In version 13.1 we have overhauled our system to handle internal permission checks by allowing permissions to not only be
defined on project or global level, but also on resources like work packages. Therefore we have introduced new methods to
check permissions. The old methods have been marked as deprecated and are now removed in 14.0.

Affected methods are:
- `User#allowed_to?`
- `User#allowed_to_globally?`
- `User#allowed_to_in_project?`

If you have developed a plugin or have custom code that uses these methods, you need to update your code to use the new
methods.

For more information, see [#51212](https://community.openproject.org/work_packages/51212).

### Reduced number of configurable design variables

We have changed the number and naming of the [configurable design variables](https://www.openproject.org/docs/system-admin-guide/design/#advanced-settings).
This simplifies the process of setting the desired colour scheme for users.
It also allows us to get closer to the **Primer design system** in order to benefit from its other modes such as the dark mode or the colourblind mode in the future.

The following variables have been changed:

| Old name           | New name             | Notes                                                                                                                                                                      |
|--------------------|----------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| primary-color      | primary-button-color | Was merged with the previous "alternative-color". The value of "alternative-color" was kept.                                                                               |
| alternative-color  | primary-button-color | Was merged with the previous "primary-color". The value of "alternative-color" was kept.                                                                                   |
| primary-color-dark | -                    | Will now be calculated automatically based on the "primary-button-color"                                                                                                   |
| link-color         | accent-color         | Is not only used for links, but for all decently highlighted elements (e.g. the selection state in a datepicker).<br/>The (old) value of "primary-color" was use for this. |


If you have developed a plugin or have custom code that uses these variables, you need to update your code to use the new
names. The rest of the variables is unchanged.

For more information, see [#53309](https://community.openproject.org/work_packages/53309).

### Removal of the model_changeset_scan_commit_for_issue_ids_pre_issue_update hook

The `model_changeset_scan_commit_for_issue_ids_pre_issue_update` hook has been removed completely. This was made necessary as the code around it was not making use of the proper update mechanisms (Service objects) which lead to inconsistencies in the data, i.e. ancestor work packages.

For more information, see [#40749](https://community.openproject.org/work_packages/40749)

### Removal of the commit_fix_done_ratio setting

Since the done_ratio is now a read only value, derived from work and remaining work, the `commit_fix_done_ratio` setting has been removed.

For more information, see [#40749](https://community.openproject.org/work_packages/40749)

### Removed `available_responsibles` from the API

The `available_responsibles` endpoint has been removed from the API. This endpoint was used to retrieve a list of users that could be set as the **responsbile** for a work package. This information has been identical to the results by the  `available_assignees` endpoint. When you are using the `available_responsibles` endpoint in your application, you should switch to using the `available_assignees` endpoint instead.

<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Bugfix: Roadmap graph shows only work packages of current
  project \[[#30865](https://community.openproject.org/wp/30865)\]
- Bugfix: Saving changes to user profile after handling error message leads to user profile instead of edit user
  page \[[#36521](https://community.openproject.org/wp/36521)\]
- Bugfix: Search bar doesn't have focus state and the first element on the list seams always
  selected \[[#43520](https://community.openproject.org/wp/43520)\]
- Bugfix: Search field is not cleared after selection on
  Watchers \[[#44469](https://community.openproject.org/wp/44469)\]
- Bugfix: Users who are not allowed to see hourly rates see planned and booked labor costs in
  budgets \[[#45834](https://community.openproject.org/wp/45834)\]
- Bugfix: No space between avatar and username in the github tab of a work
  package \[[#46215](https://community.openproject.org/wp/46215)\]
- Bugfix: Missing space on the left of the advanced filter \[[#46346](https://community.openproject.org/wp/46346)\]
- Bugfix: Meeting Minutes: Toggling preview mode causes losing
  content \[[#48210](https://community.openproject.org/wp/48210)\]
- Bugfix: +Create button disabled after creating a child work package until reloading the
  page \[[#49136](https://community.openproject.org/wp/49136)\]
- Bugfix: Missing space between avatars and usernames in Administration ->
  Users \[[#50213](https://community.openproject.org/wp/50213)\]
- Bugfix: Taskboard column width stopped working \[[#51416](https://community.openproject.org/wp/51416)\]
- Bugfix: Double close button on Share modal for mobile \[[#51699](https://community.openproject.org/wp/51699)\]
- Bugfix: Odd spacing in Notification and Email Reminder personal setting
  pages \[[#51772](https://community.openproject.org/wp/51772)\]
- Bugfix: Misleading error message: IFC upload (file size) \[[#52098](https://community.openproject.org/wp/52098)\]
- Bugfix: OpenProject behind prefix some assests still loaded from web
  root \[[#52292](https://community.openproject.org/wp/52292)\]
- Bugfix: Position of status selector too high after opening the drop
  down \[[#52669](https://community.openproject.org/wp/52669)\]
- Bugfix: Add meaningful flash error message when user cancels OAuth flow on
  OneDrive/SharePoint \[[#52798](https://community.openproject.org/wp/52798)\]
- Bugfix: Waiting modal stuck on network error \[[#53005](https://community.openproject.org/wp/53005)\]
- Bugfix: Imprint Menu Label is not localized \[[#53062](https://community.openproject.org/wp/53062)\]
- Bugfix: Logo not reset when logo file is deleted \[[#53121](https://community.openproject.org/wp/53121)\]
- Bugfix: Health status is not showing for OneDrive storages \[[#53202](https://community.openproject.org/wp/53202)\]
- Bugfix: Error when sorting projects list by "latest activity
  at" \[[#53315](https://community.openproject.org/wp/53315)\]
- Bugfix: Cannot modify a query that was created by a deleted
  user \[[#53344](https://community.openproject.org/wp/53344)\]
- Bugfix: [AppSignal] Investigate absence of oauth_client for OneDrive
  storage. \[[#53345](https://community.openproject.org/wp/53345)\]
- Bugfix: Autocompleters do not find users with accent when using simple
  letter \[[#53371](https://community.openproject.org/wp/53371)\]
- Bugfix: Project custom fields and project description no longer allows
  macros \[[#53391](https://community.openproject.org/wp/53391)\]
- Bugfix: OAuth flow causes loss of already selected option while adding a storage to a
  project \[[#53394](https://community.openproject.org/wp/53394)\]
- Bugfix: Calendar buttons are not translated \[[#53422](https://community.openproject.org/wp/53422)\]
- Bugfix: Project storage main-menu links do not include prefix \[[#53429](https://community.openproject.org/wp/53429)\]
- Bugfix: Empty assignee board for user with reader role \[[#53436](https://community.openproject.org/wp/53436)\]
- Bugfix: Toolbar buttons too close on user page \[[#53477](https://community.openproject.org/wp/53477)\]
- Bugfix: Link on top of the storage should be removed if the read_files permission is missing when it is a
  automatically managed project folder. \[[#53484](https://community.openproject.org/wp/53484)\]
- Bugfix: Buttons have the wrong colour in freshly seeded BIM
  instance \[[#53504](https://community.openproject.org/wp/53504)\]
- Bugfix: Removing a project custom field stored as a filter in a project list leads to wrong counter
  value \[[#53585](https://community.openproject.org/wp/53585)\]
- Bugfix: Meetings: Remove the "Add notes" item from the dropdown menu when notes already
  exist \[[#53618](https://community.openproject.org/wp/53618)\]
- Bugfix: Macros text should wrap \[[#53644](https://community.openproject.org/wp/53644)\]
- Bugfix: Error in french translation \[[#53673](https://community.openproject.org/wp/53673)\]
- Bugfix: Visible=false project attribute values are deleted when a non-admin user edits the
  attributes \[[#53704](https://community.openproject.org/wp/53704)\]
- Bugfix: Reordering project attributes is popping back on
  render \[[#53706](https://community.openproject.org/wp/53706)\]
- Bugfix: ckEditor "..." more menu is overflowing the project custom field
  dialog. \[[#53724](https://community.openproject.org/wp/53724)\]
- Bugfix: Fill custom_field_section_id when migrating CreateCustomFieldSections for the first
  time \[[#53728](https://community.openproject.org/wp/53728)\]
- Bugfix: Insert code snippet or link modal opens behind the project attributes
  modal \[[#53730](https://community.openproject.org/wp/53730)\]
- Bugfix: Action menu position on project attributes admin settings page
  broken \[[#53735](https://community.openproject.org/wp/53735)\]
- Bugfix: Project attribute edit button doesn't work \[[#53739](https://community.openproject.org/wp/53739)\]
- Bugfix: Missing translation in help menu for Legal Notice menu
  item \[[#53768](https://community.openproject.org/wp/53768)\]
- Bugfix: Project attribute edit menu jumps out of place \[[#53790](https://community.openproject.org/wp/53790)\]
- Bugfix: Deletion dialog does not provide enough context \[[#53802](https://community.openproject.org/wp/53802)\]
- Bugfix: Meeting agenda item overflow with long work package
  subject \[[#53812](https://community.openproject.org/wp/53812)\]
- Bugfix: Blank page when clicking a link in meeting agenda item
  notes \[[#53813](https://community.openproject.org/wp/53813)\]
- Bugfix: workPackageValue macro for milestone cannot use startDate and
  dueDate \[[#53814](https://community.openproject.org/wp/53814)\]
- Bugfix: Dynamics meetings: Macro button for new work packages leads to a blank
  page \[[#53935](https://community.openproject.org/wp/53935)\]
- Bugfix: New GitLab integration tab content is displayed in front of all
  popups \[[#53948](https://community.openproject.org/wp/53948)\]
- Bugfix: Editing the work package to a different work package doesn't show clearly in the Meeting
  history \[[#53976](https://community.openproject.org/wp/53976)\]
- Bugfix: Impossible to copy a project \[[#53990](https://community.openproject.org/wp/53990)\]
- Feature: Consistent calculation of progress (% Complete) in work package
  hierarchies \[[#40749](https://community.openproject.org/wp/40749)\]
- Feature: Rename Delay to Lag \[[#44054](https://community.openproject.org/wp/44054)\]
- Feature: Save the "trashed" state of linked files in OpenProject's
  cache \[[#45940](https://community.openproject.org/wp/45940)\]
- Feature: Group agenda items with sections \[[#49060](https://community.openproject.org/wp/49060)\]
- Feature: Exclude by status some work packages from the calculation of % Complete and work
  estimates \[[#49409](https://community.openproject.org/wp/49409)\]
- Feature: Remove member and revoke shared work packages \[[#50266](https://community.openproject.org/wp/50266)\]
- Feature: Show meeting history / changes \[[#50820](https://community.openproject.org/wp/50820)\]
- Feature: Inform an admin via email about an unhealthy automatically managed file
  storage \[[#50913](https://community.openproject.org/wp/50913)\]
- Feature: Fix seeding of status to include % Complete values \[[#50965](https://community.openproject.org/wp/50965)\]
- Feature: Persist the sort order of project lists \[[#51671](https://community.openproject.org/wp/51671)\]
- Feature: Allow renaming persisted project lists \[[#51673](https://community.openproject.org/wp/51673)\]
- Feature: "Save as" option in project list more menu \[[#51675](https://community.openproject.org/wp/51675)\]
- Feature: Global project attributes administration \[[#51789](https://community.openproject.org/wp/51789)\]
- Feature: Project-specific project attributes mapping \[[#51790](https://community.openproject.org/wp/51790)\]
- Feature: Display project attributes on project overview page \[[#51791](https://community.openproject.org/wp/51791)\]
- Feature: Remove project custom fields from global custom field settings
  page \[[#51792](https://community.openproject.org/wp/51792)\]
- Feature: Split existing project administration settings into multiple
  pages \[[#51793](https://community.openproject.org/wp/51793)\]
- Feature: Remove project custom fields widget \[[#51794](https://community.openproject.org/wp/51794)\]
- Feature: Adjust project API in order to respect project-specific custom
  fields \[[#51796](https://community.openproject.org/wp/51796)\]
- Feature: Changing a persisted list (only own) \[[#52144](https://community.openproject.org/wp/52144)\]
- Feature: Copy automatically managed project folder on project copy for
  OneDrive/SharePoint \[[#52175](https://community.openproject.org/wp/52175)\]
- Feature: Add toggle to deactivate/activate admin health notification for a
  storage \[[#52449](https://community.openproject.org/wp/52449)\]
- Feature: File Storage Permissions explanation \[[#52571](https://community.openproject.org/wp/52571)\]
- Feature: Update the PageHeader component to do all required
  actions \[[#52582](https://community.openproject.org/wp/52582)\]
- Feature: Changes in meeting automatically trigger email notification with updated ics
  file \[[#52829](https://community.openproject.org/wp/52829)\]
- Feature: Show involved persons of agenda items \[[#52830](https://community.openproject.org/wp/52830)\]
- Feature: Improve UI for OneDrive/SharePoint file storage
  settings \[[#52892](https://community.openproject.org/wp/52892)\]
- Feature: Restrict filtering on custom values that are not active
  attributes \[[#53007](https://community.openproject.org/wp/53007)\]
- Feature: Sort work packages autocompletion by descending updated at time in meetings
  module \[[#53033](https://community.openproject.org/wp/53033)\]
- Feature: Nudge user to login to storage upon project storage
  edit \[[#53058](https://community.openproject.org/wp/53058)\]
- Feature: Reduce configurable design variables \[[#53309](https://community.openproject.org/wp/53309)\]
- Feature: Change row break in email notifications \[[#53316](https://community.openproject.org/wp/53316)\]
- Feature: Disable name and email fields in user profile for LDAP
  user \[[#53330](https://community.openproject.org/wp/53330)\]
- Feature: Have only non bundled gems appear in the Plugin list \[[#53346](https://community.openproject.org/wp/53346)\]
- Feature: Fine-tuning of truncation feature in project list and project
  overview \[[#53373](https://community.openproject.org/wp/53373)\]
- Feature: Before saving a OneDrive/SharePoint storage the storage settings should be validated against
  OneDrive/SharePoint \[[#53386](https://community.openproject.org/wp/53386)\]
- Feature: Allow setting createdAt, author via API \[[#53423](https://community.openproject.org/wp/53423)\]
- Feature: Make the Author field editable or settable \[[#53444](https://community.openproject.org/wp/53444)\]
- Feature: Allow 4 and 8 week display modes in team planner \[[#53475](https://community.openproject.org/wp/53475)\]
- Feature: Allow umlauts for login name in OpenProject, LDAP
  authentication \[[#53486](https://community.openproject.org/wp/53486)\]
- Feature: Meetings: Improve attachments \[[#53506](https://community.openproject.org/wp/53506)\]
- Feature: Support setting accountable to current user via custom
  action \[[#53507](https://community.openproject.org/wp/53507)\]
- Feature: Add separate checkbox about attachments when user copies a
  meeting \[[#53568](https://community.openproject.org/wp/53568)\]
- Feature: Handle no active project attributes in project overview
  sidebar \[[#53577](https://community.openproject.org/wp/53577)\]
- Feature: Check if and how project activity logs should be
  adapted \[[#53580](https://community.openproject.org/wp/53580)\]
- Feature: Disable the macros for the project custom fields. \[[#53701](https://community.openproject.org/wp/53701)\]
- Feature: Project creation with project attributes \[[#53703](https://community.openproject.org/wp/53703)\]
- Feature: Project copy with project attributes \[[#53705](https://community.openproject.org/wp/53705)\]
- Feature: Project export with disabled project attributes \[[#53733](https://community.openproject.org/wp/53733)\]
- Feature: Removing a work package from a agenda should be called "Remove" instead of "
  Delete" \[[#53766](https://community.openproject.org/wp/53766)\]
- Feature: Add % Complete to section "Estimates and time" \[[#53771](https://community.openproject.org/wp/53771)\]
- Feature: Show diff for changes in meeting agenda items \[[#53975](https://community.openproject.org/wp/53975)\]
- Feature: Progress reporting for work package hierarchies \[[#40867](https://community.openproject.org/wp/40867)\]
- Feature: Custom set of project attributes grouped in sections \[[#49688](https://community.openproject.org/wp/49688)\]
- Feature: Copy of template projects including their project folders in
  SharePoint \[[#51000](https://community.openproject.org/wp/51000)\]
- Feature: Email notifications for unhealthy file storages \[[#52840](https://community.openproject.org/wp/52840)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->

#### Contributions

A big thanks to community members for reporting bugs and helping us identifying and providing fixes.

Special thanks for reporting and finding bugs go to

Silas Kropf, Philipp Schulz, Benjamin Rönnau, Mario Haustein, Matt User, Mario Zeppin, Romain Besson, Cécile Guiot,
Daniel Hilbrand, Christina Vechkanova, Sven Kunze, Richard Richter, Julian Wolff
