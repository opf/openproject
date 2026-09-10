---
title: OpenProject 17.9.0
sidebar_navigation:
    title: 17.9.0
release_version: 17.9.0
release_date: 2026-09-10
---

# OpenProject 17.9.0

Release date: 2026-09-10

We released [OpenProject 17.9.0](https://community.openproject.org/versions/2322).
The release contains several bug fixes and we recommend updating to the newest version.
In these Release Notes, we will give an overview of important feature changes. At the end, you will find a complete list of all changes and bug fixes.
## Important feature changes

<!-- Inform about the major features in this section -->

## Important updates and breaking changes

<!-- Remove this section if empty, add to it in pull requests linking to tickets and provide information -->

<!-- BEGIN SECURITY FIXES AUTOMATED SECTION -->

<!-- END SECURITY FIXES AUTOMATED SECTION -->
<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Feature: 1st iteration of filters within the backlog \[[#74387](https://community.openproject.org/wp/74387)\]
- Feature: Sprint report page with burndown chart widget  \[[#76118](https://community.openproject.org/wp/76118)\]
- Feature: Allow to track time through MCP \[[#78402](https://community.openproject.org/wp/78402)\]
- Feature: Limit work package search results responses by default when using MCP \[[#78602](https://community.openproject.org/wp/78602)\]
- Feature: MCP: Allow searching work packages by their display id \[[#79255](https://community.openproject.org/wp/79255)\]
- Feature: Rename &quot;Form configuration&quot; to &quot;Form&quot; \[[#79202](https://community.openproject.org/wp/79202)\]
- Feature: Primerize role administration table \[[#79489](https://community.openproject.org/wp/79489)\]
- Feature: Create work package via slash command in a document \[[#67552](https://community.openproject.org/wp/67552)\]
- Feature: Create work package via text selection in a document \[[#78337](https://community.openproject.org/wp/78337)\]
- Feature: Introduce observed in versions \[[#76236](https://community.openproject.org/wp/76236)\]
- Feature: Primerise Interface tab of Admin/Design page \[[#56341](https://community.openproject.org/wp/56341)\]
- Feature: Show subitem widget only when subitems exist \[[#78005](https://community.openproject.org/wp/78005)\]
- Feature: Jira Migrator shows progress during import of projects, leveraging concurrency \[[#73094](https://community.openproject.org/wp/73094)\]
- Feature: Make meeting default date today. Time now (rounded) \[[#69574](https://community.openproject.org/wp/69574)\]
- Feature: Give users the choice to not include descendants when deleting work packages \[[#77999](https://community.openproject.org/wp/77999)\]
- Feature: Global default settings for PDF exports by type \[[#78333](https://community.openproject.org/wp/78333)\]
- Feature: Add the date alert feature to the community edition \[[#78407](https://community.openproject.org/wp/78407)\]
- Feature:     Allow planned labor to be entered in hours, days, weeks, or months \[[#78544](https://community.openproject.org/wp/78544)\]
- Feature: PMflex Artefact PDF: Include project phases and budgets \[[#78561](https://community.openproject.org/wp/78561)\]
- Feature: Allow differing time stamps between SAML IdP and SP (OpenProject) within margin (allowed\_clock\_drift) \[[#79019](https://community.openproject.org/wp/79019)\]
- Feature: Allow restricting password login for SSO authenticated users \[[#79300](https://community.openproject.org/wp/79300)\]
- Feature: For number custom fields, replace min and max length with minimum and maximum values \[[#79759](https://community.openproject.org/wp/79759)\]
- Feature: Add browsing in the tree view when no search is conducted \[[#75610](https://community.openproject.org/wp/75610)\]
- Bugfix: Starting a sprint fails with HTTP 422 and generic error banner \[[#75958](https://community.openproject.org/wp/75958)\]
- Bugfix: &quot;Search&quot; placeholder is missing on the dropdown on sprints and backlog buckets \[[#76641](https://community.openproject.org/wp/76641)\]
- Bugfix: Backlogs: autoscroll doesn&#39;t work on DnD on Chrome/Android \[[#77991](https://community.openproject.org/wp/77991)\]
- Bugfix: Display deleted custom field journals in the Project activities \[[#78432](https://community.openproject.org/wp/78432)\]
- Bugfix: Display the correct activity message when the user doesn&#39;t have the permission to see admin only custom field journals. \[[#78439](https://community.openproject.org/wp/78439)\]
- Bugfix: Spacing disappeared between the \[Start sprint\] button and the sprint date in the backlog \[[#78595](https://community.openproject.org/wp/78595)\]
- Bugfix: Sprint report: breadcrumb and title overlap with long titles \[[#78958](https://community.openproject.org/wp/78958)\]
- Bugfix: Sprint report: long titles take too much space on mobile as they are not truncated \[[#78963](https://community.openproject.org/wp/78963)\]
- Bugfix: Fix description of tools so that LLM understand that filters can be an array of IDs \[[#75407](https://community.openproject.org/wp/75407)\]
- Bugfix: Documents: two wps highlighted at once in wp dropdown on ios safari \[[#75812](https://community.openproject.org/wp/75812)\]
- Bugfix: Documents: size menu on wp link closes automatically when tapped on ios safari \[[#75815](https://community.openproject.org/wp/75815)\]
- Bugfix: Documents: overflow in the work package preview when the wp type is long \[[#77690](https://community.openproject.org/wp/77690)\]
- Bugfix: Context menu scrolls over header on mobile \[[#77693](https://community.openproject.org/wp/77693)\]
- Bugfix: Documents: issues with tiny work package link preview on mobile iOS \[[#77720](https://community.openproject.org/wp/77720)\]
- Bugfix: Creating a work package via slash command in a list should render an inline, &quot;regular&quot; sized work package link \[[#78973](https://community.openproject.org/wp/78973)\]
- Bugfix: Linking a work package inside a headline via slash command looks broken \[[#78974](https://community.openproject.org/wp/78974)\]
- Bugfix: Resizing menu of work package links cut off at the bottom of the document \[[#79353](https://community.openproject.org/wp/79353)\]
- Bugfix: Values in dropdown not shown for required field \[[#79747](https://community.openproject.org/wp/79747)\]
- Bugfix: Paragraph in Firefox document is infinite in width \[[#76694](https://community.openproject.org/wp/76694)\]
- Bugfix: Cleanup job can delete Attachments uploaded to a new work package when attachments drag and drop field is missing during the upload  \[[#76870](https://community.openproject.org/wp/76870)\]
- Bugfix: Updating a document title does not update the browser page title \[[#77618](https://community.openproject.org/wp/77618)\]
- Bugfix: First headline not rendered correctly when opening a document \[[#77648](https://community.openproject.org/wp/77648)\]
- Bugfix: When work packages are grouped by X, it&#39;s not possible to drag and drop an item to the last line inside the same group \[[#79220](https://community.openproject.org/wp/79220)\]
- Bugfix: Search is missing an index for work\_package\_semantic\_aliases which makes it slow \[[#79497](https://community.openproject.org/wp/79497)\]
- Bugfix: &quot;Only changes&quot; work packages activity filter hides target and observed-in version changes \[[#79498](https://community.openproject.org/wp/79498)\]
- Bugfix: When work packages are grouped by X, drag and drop of items on the last position between the groups works only downwards, not upwards \[[#79741](https://community.openproject.org/wp/79741)\]
- Bugfix: When entering days it defaults to 24h instead of workdays \[[#78588](https://community.openproject.org/wp/78588)\]
- Bugfix: Children ticket time entries are not reassigned when parent ticket is deleted \[[#79479](https://community.openproject.org/wp/79479)\]
- Bugfix: \[Accessibility\] Colour blind users cannot distinguis the overview graph bars \[[#64237](https://community.openproject.org/wp/64237)\]
- Bugfix: Unnecessary loading indicator and success message on going from team planner to work packages list \[[#76534](https://community.openproject.org/wp/76534)\]
- Bugfix: Milestones in the project timeline widget cannot be opened with a keyboard or screen reader \[[#79044](https://community.openproject.org/wp/79044)\]
- Bugfix: Inconsistent usage for &quot;built-in&quot; labels \[[#79059](https://community.openproject.org/wp/79059)\]
- Bugfix: Sprints are not clickable in timeline widget \[[#79411](https://community.openproject.org/wp/79411)\]
- Bugfix: &#39;No items&#39; shown on wiki tree view is not translated  \[[#79389](https://community.openproject.org/wp/79389)\]
- Bugfix: Updating the &#39;Custom touch icon&#39; actually update the &#39;Custom favicon&#39; \[[#79757](https://community.openproject.org/wp/79757)\]
- Bugfix: Jira import errors are not legible in dark mode \[[#79584](https://community.openproject.org/wp/79584)\]
- Bugfix: Flicker on page when switching between upcoming and past tabs \[[#60296](https://community.openproject.org/wp/60296)\]
- Bugfix: Using the past filter on Meeting index always shows results for &#39;My meetings&#39; \[[#78865](https://community.openproject.org/wp/78865)\]
- Bugfix: Changed schedule does not import/update in OX/Mailbox.org \[[#79337](https://community.openproject.org/wp/79337)\]
- Bugfix: Round corner on the not header box in File Storages \[[#52792](https://community.openproject.org/wp/52792)\]
- Bugfix: Accessibility: Primer Text Field clear button does not show tooltip \[[#69916](https://community.openproject.org/wp/69916)\]
- Bugfix: Popup for copying Calendar url disappears after 5 secs (too short) \[[#73512](https://community.openproject.org/wp/73512)\]
- Bugfix: Assignee filter does not recognize assignees of shared work packages \[[#73908](https://community.openproject.org/wp/73908)\]
- Bugfix: Seeded meeting agenda items description is not translated \[[#74752](https://community.openproject.org/wp/74752)\]
- Bugfix: HTML numeric entities shown instead of Cyrillic characters in &quot;My spent time&quot; tooltip \[[#75277](https://community.openproject.org/wp/75277)\]
- Bugfix: Sibling morph breaks after OPCE-\* replaceWith in dialog preview \[[#76653](https://community.openproject.org/wp/76653)\]
- Bugfix: Page takes a long time to load and does not sort correctly when removing &#39;Start time&#39; from &#39;All filters&#39; \[[#76655](https://community.openproject.org/wp/76655)\]
- Bugfix: Related work package table configuration shows two non-clickable tabs \[[#77073](https://community.openproject.org/wp/77073)\]
- Bugfix: Required user custom fields interfere with LDAP group and department synchronisation \[[#77192](https://community.openproject.org/wp/77192)\]
- Bugfix: Project selector cuts off all subsequent projects \[[#77481](https://community.openproject.org/wp/77481)\]
- Bugfix: Can&#39;t upload IFC file when S3 storage is configured \[[#78085](https://community.openproject.org/wp/78085)\]
- Bugfix: Description field of (new) forum is too small. \[[#78503](https://community.openproject.org/wp/78503)\]
- Bugfix: MeetingOutcome invalid kind value crashes with 500 instead of 422 \[[#78526](https://community.openproject.org/wp/78526)\]
- Bugfix: RecurringMeeting occurrence init crashes with 500 on a draft template \[[#78527](https://community.openproject.org/wp/78527)\]
- Bugfix: UserWorkingHours create crashes with 500 when a weekday is nil \[[#78528](https://community.openproject.org/wp/78528)\]
- Bugfix: wiki\_page\_links pagination silently ignores offset \[[#78529](https://community.openproject.org/wp/78529)\]
- Bugfix: Writing end\_time on a time entry crashes with NoMethodError (500) \[[#78530](https://community.openproject.org/wp/78530)\]
- Bugfix: time\_entries hours-to-duration serialization truncates instead of rounds \[[#78531](https://community.openproject.org/wp/78531)\]
- Bugfix: Backup via web ui is missing the option to include attachments \[[#78559](https://community.openproject.org/wp/78559)\]
- Bugfix: User Filter cannot show Departments, Groups, Projects and Status \[[#78800](https://community.openproject.org/wp/78800)\]
- Bugfix: Groups: Subgroup does not inherit parent group&#39;s project role assignments despite correctly set Parent group \[[#79043](https://community.openproject.org/wp/79043)\]
- Bugfix: Migration from 17.3.1 to 17.8 fails \[[#79482](https://community.openproject.org/wp/79482)\]
- Bugfix: Tooltip for &quot;My spent time&quot; entries that are only partially visible is shown in wrong place \[[#79486](https://community.openproject.org/wp/79486)\]
- Bugfix: Project attribute removed from projects after update of attribute section in administration \[[#79591](https://community.openproject.org/wp/79591)\]
- Bugfix: When trying to login with password, and password login being disabled for SSO users, the error message does not say about this \[[#79693](https://community.openproject.org/wp/79693)\]
- Bugfix: When a wiki page is added to the WP description on the WP page, the page is not shown on the mentioned description box \[[#78133](https://community.openproject.org/wp/78133)\]
- Bugfix: Persist collaped state for the wiki blocks when wiki tab is updated \[[#78978](https://community.openproject.org/wp/78978)\]
- Bugfix: Return URL is not visible if a user enters their own client ID for wiki integration \[[#79508](https://community.openproject.org/wp/79508)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->

## Contributions
A very special thank you goes to our sponsors for this release.
Also a big thanks to our Community members for reporting bugs and helping us identify and provide fixes.
Special thanks for reporting and finding bugs go to Sonita Soth, Hagen Mahnke, Daniel Paulo Dos Santos, Max Tachkov, Tobias Nowakow, Michael Gillen, Jürgen Tauschl, Raphael Zoppoth, Paul Grimes.

Last but not least, we are very grateful for our very engaged translation contributors on Crowdin, who translated quite a few OpenProject strings!
Would you like to help out with translations yourself?
Then take a look at our translation guide and find out exactly how you can contribute.
It is very much appreciated!

