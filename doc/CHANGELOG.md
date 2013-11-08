<!---- copyright
OpenProject is a project management system.
Copyright (C) 2012-2013 the OpenProject Foundation (OPF)

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License version 3.

OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
Copyright (C) 2006-2013 Jean-Philippe Lang
Copyright (C) 2010-2013 the ChiliProject Team

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

See doc/COPYRIGHT.rdoc for more details.

++-->

# Changelog

## 3.0.0pre28

* `#1910` New menu structure for pages of timelines module
* `#2363` When all wiki pages have been deleted new wiki pages cannot be created (respecification)
* `#2566` Fix: [Timelines] Searching when selecting columns for a timeline configuration does not work
* `#2631` Fix: [Timelines] Work package cannot be created out of timeline.
* `#2685` [Work package tracking] 404 when deleting work package priority which is assigned to work package
* `#2686` Fix: [Work package tracking] Work package summary not displayed correctly
* `#2687` Fix: [Work Package Tracking] No error for parallel editing
* `#2708` Fix: API key auth does not work for custom_field actions
* `#2712` Fix: Journal entry on responsible changes displayed as numbers
* `#2715` [Journals] Missing attachable journals
* `#2716` Fix: Repository is not auto-created when activated in project settings
* `#2717` Fix: Multiple journal entries when adding multiple attachments in one change
* `#2721` Fix: Fix: Missing journal entries for customizable_journals
* Add indices to to all the journals (improves at least WorkPackage show)
* Improve settings performance by caching whether the settings table exists

## 3.0.0pre27

* `#416`  Fix: Too many users selectable as watchers
* `#2697` Fix: Missing migration of planning element watchers
* `#2564` Support custom fields in REST API v2 for work packages and projects
* `#2567` [Timelines] Select2 selection shows double escaped character
* `#2586` Query available custom fields in REST API v2
* `#2637` Migrated timestamps to UTC
* `#2696` CustomValues still associated to issues
* Reverts `#2645` Remove usage of eval()
* Fix work package filter query validations

## 3.0.0pre26

* `#2624` [Journals] Fix: Work package journals that migrated from legacy planning elements lack default references
* `#2642` [Migration] Empty timelines options cannot be migrated
* `#2645` Remove usage of eval()
* `#2585` Special characters in wiki page title

## 3.0.0pre25

* `#2515` Fix: Calendar does not support 1st of December
* `#2574` Fix: Invalid filter options and outdated names in timeline report form
* `#2613` Old IE versions (IE 7 & IE 8) are presented a message informing about the incompatibilities.
* `#2615` Fix board edit validations
* `#2617` Fix: Timelines do not load users for non-admins.
* `#2618` Fix: When issues are renamed to work packages all watcher assignments are lost
* `#2623` [Journals] Images in journal notes are not displayed
* `#2624` [Journals] Work package journals that migrated from legacy planning elements lack default references.
* `#2625` [Membership] Page not found when editing member and display more pages
* Improved newline handling for journals
* Improved custom field comparison for journals
* Respect journal data serialized with legacy YAML engine 'syck'

## 3.0.0pre24

* `#2593` Work Package Summary missing
* `#1749` Prevent JSON Hijacking
* `#2281` The context menu is not correctly displayed
* `#2348` [Timelines] Using planning element filter and filtering for status "New" leads always to plus-sign in front of work packages
* `#2357` [Timelines] Change API v2 serialization to minimize redundant data
* `#2363` When all wiki pages have been deleted new wiki pages cannot be created
* `#2380` [Timelines] Change API v2 serialization to maximize concatenation speed
* `#2420` Migrate the remaining views of api/v2 to rabl
* `#2478` Timeline with lots of work packages doesn`t load
* `#2525` Project Settings: Forums: Move up/down result in 404
* `#2535` [Forum] Atom feed on the forum's overview-page doesn't work
* `#2576` [Timelines] Double scrollbar in modal for Chrome
* `#2577` [Timelines] Users are not displayed in timelines table after recent API version
* `#2579` [Core] Report of spent time (without cost reporting) results in 404
* `#2580` Fixed some unlikely remote code executions
* `#2592` Search: Clicking on 'Next' results in 500
* `#2593` Work Package Summary missing
* `#2596` [Roadmap] Closed tickets are not striked out
* `#2597` [Roadmap] Missing english/german closed percentage label
* `#2604` [Migration] Attachable journals incorrect
* `#2608` [Activity] Clicking on Atom-feed in activity leads to 500 error
* `#2598` Add rake task for changing timestamps in the database to UTC

## 3.0.0pre23

* `#165`  [Work Package Tracking] Self-referencing ticket breaks ticket
* `#709`  Added test for double custom field validation error messages
* `#902`  Spelling Mistake: Timelines Report Configuration
* `#959`  Too many available responsibles returned for filtering in Timelines
* `#1738` Forum problem when no description given.
* `#1916` Work package update screen is closed when attached file is deleted
* `#1935` Fixed bug: Default submenu for wiki pages is wrong (Configure menu item)
* `#2009` No journal entry created for attachments if the attachment is added on container creation
* `#2026` 404 error when letters are entered in category Work Package
* `#2129` Repository: clicking on file results in 500
* `#2221` [Accessibility] enhance keyboard shortcuts
* `#2371` Add support for IE10 to Timelines
* `#2400` Cannot delete work package
* `#2423` [Issue Tracker] Several Internal Errors when there is no default work package status
* `#2426` [Core] Enumerations for planning elements
* `#2427` [Issue Tracker] Cannot delete work package priority
* `#2433` [Timelines] Empty timeline report not displayed initially
* `#2448` Accelerate work package updates
* `#2464` No initial attachment journal for messages
* `#2470` [Timelines] Vertical planning elements which are not displayed horizontally are not shown in timeline report
* `#2479` Remove TinyMCE spike
* `#2508` Migrated former user passwords (from OpenProject 2.x strong_passwords plugin)
* `#2521` XSS: MyPage on unfiltered WorkPackage Subject
* `#2548` Migrated core settings
* `#2557` Highlight changes of any work package attribute available in the timelines table
* `#2559` Migrate existing IssueCustomFields to WorkPackageCustomFields
* `#2575` Regular expressions should use \A and \z instead of ^ and $
* Fix compatibility with old mail configuration

## 3.0.0pre22

* `#1348` User status has no database index
* `#1854` Breadcrumbs arrows missing in Chrome
* `#1935` Default submenu for wiki pages is wrong (Configure menu item)
* `#1991` Migrate text references to issues/planning elements
* `#2297` Fix APIv2 for planning elements
* `#2304` Introduce keyboard shortcuts
* `#2334` Deselecting all types in project configuration creates 500
* `#2336` Cukes for timelines start/end date comparison
* `#2340` Develop migration mechanism for renamed plugins
* `#2374` Refactoring of ReportsController
* `#2383` [Performance] planning_elements_controller still has an n+1-query for the responsible
* `#2384` Replace bundles svg graph with gem
* `#2386` Remove timelines_journals_helper
* `#2418` Migrate to RABL
* Allow using environment variables instead of configuration.yml

## 3.0.0pre21

* `#1281` I18n.js Not working correctly. Always returns English Translations
* `#1758` Migrate functional-tests for issues into specs for work package
* `#1771` Fixed bug: Refactor Types Project Settings into new Tab
* `#1880` Re-introduce at-time scope
* `#1881` Re-introduce project planning comparison in controller
* `#1883` Extend at-time scope for status comparison
* `#1884` Make status values available over API
* `#1994` Integrational tests for work packages at_time (API)
* `#2070` Settle copyright for images
* `#2158` Work Package General Setting
* `#2173` Adapt client-side to new server behavior
* `#2306` Migrate issues controller tests
* `#2307` Change icon of home button in header from OpenProjct icon to house icon
* `#2310` Add proper indices to work_package
* `#2319` Add a request-store to avoid redundant calls

## 3.0.0pre20

* `#1560` WorkPackage/update does not retain some fields when validations fail
* `#1771` Refactor Types Project Settings into new Tab
* `#1878` Project Plan Comparison(server-side implementation): api/v2 can now resolve historical data for work_packages
* `#1929` Too many lines in work package view
* `#1946` Modal shown within in Modal
* `#1949` External links within modals do not work
* `#1992` Prepare schema migrations table
* `#2125` All AJAX actions on work package not working after update
* `#2237` Migrate reports controller tests
* `#2246` Migrate issue categories controller tests
* `#2262` Migrate issue statuses controller tests
* `#2267` Rename view issue hooks

## 3.0.0pre19

* `#2055` More dynamic attribute determination for journals for extending journals by plugins
* `#2203` Use server-side responsible filter
* `#2204` Implement server-side status filter.
* `#2218` Migrate context menus controller tests

## 3.0.0pre18

* `#1715` Group assigned work packages
* `#1770` New Comment Section layout errors
* `#1790` Fix activity view bug coming up during the meeting adaptions to acts_as_journalized
* `#1793` Data Migration Journals
* `#1977` Set default type for planning elements
* `#1990` Migrate issue relation
* `#1997` Migrate journal activities
* `#2008` Migrate attachments
* `#2083` Extend APIv2 to evaluate filter arguments
* `#2087` Write tests for server-side type filter
* `#2088` Implement server-side filter for type
* `#2101` 500 on filtering multiple values
* `#2104` Handle incomplete trees on server-side
* `#2105` Call PE-API with type filters
* `#2138` Add responsible to workpackage-search

## 3.0.0pre17

* `#1323` Wrong Calendarweek in Datepicker, replaced built in datepicker with jQuery UI datepicker
* `#1843` Editing Membership Duration in admin area fails
* `#1913` [Timelines] Enable drag&drop for select2 items in order to rearrange the order of the columns
* `#1934` [Timelines] Table Loading takes really long
* `#1978` Migrate legacy issues
* `#1979` Migrate legacy planning elements
* `#1982` Migrate planning element types
* `#1983` Migrate queries
* `#1987` Migrate user rights
* `#1988` Migrate settings
* `#2019` Migrate auto completes controller tests
* `#2078` Work package query produces 500 when grouping on exclusively empty values

## 3.0.0pre16

* `#1418` Additional changes: Change links to issues/planning elements to use work_packages controller
* `#1504` Initial selection of possible project members wrong (accessibility mode)
* `#1695` Cannot open links in Projects menu in new tab/window
* `#1753` Remove Issue and replace with Work Package
* `#1754` Migrate unit-tests for issues into specs for work_package
* `#1757` Rename Issues fixtures to Work Package fixtures
* `#1759` Remove link_to_issue_preview, replace with link_to_workpackage_preview
* `#1822` Replace Issue constant by WorkPackage constant
* `#1850` Disable atom feeds via setting
* `#1874` Move Scopes from Issue into Workpackage
* `#1898` Separate action for changing wiki parent page (was same as rename before)
* `#1921` Allow disabling done ratio for work packages
* `#1923` Add permission that allows hiding repository statistics on commits per author
* `#1950` Grey line near the lower end of the modal, cuts off a bit of the content

## 3.0.0pre15

* `#1301` Ajax call when logged out should open a popup window
* `#1351` Generalize Modal Creation
* `#1557` Timeline Report Selection Not Visible
* `#1755` Migrate helper-tests for issues into specs for work package
* `#1766` Fixed bug: Viewing diff of Work Package description results in error 500
* `#1767` Fixed bug: Viewing changesets results in "page not found"
* `#1789` Move validation to Work Package
* `#1800` Add settings to change software name and URL and add additional footer content
* `#1808` Add option to log user for each request
* `#1875` Added test steps to reuse steps for my page, my project page, and documents, no my page block lookup at class load time
* `#1876` Timelines do not show work packages when there is no status reporting
* `#1896` Moved visibility-tests for issues into specs for workpackages
* `#1911` Change mouse icon when hovering over drag&drop-enabled select2 entries
* `#1912` Merge column project type with column planning element type
* `#1918` Custom fields are not displayed when issue is created

## 3.0.0pre14

* `#825`  Migrate Duration
* `#828`  Remove Alternate Dates
* `#1421` Adapt issue created/updated wording to apply to work packages
* `#1610` Move Planning Element Controller to API V2
* `#1686` Issues not accessible in public projects when not a member
* `#1768` Fixed bug: Klicking on Wiki Edit Activity results in error 500
* `#1787` Remove Scenarios
* `#1813` Run Data Generator on old AAJ schema
* `#1859` Fix 20130814130142 down-migration (remove_documents)
* `#1873` Move Validations from Issue into Workpackage

## 3.0.0pre13

* `#1606` Update journal fixtures
* `#1608` Change activities to use the new journals
* `#1609` Change search to use the new journals
* `#1616` Serialization/Persistence
* `#1617` Migrate database to new journalization
* `#1724` PDF Export of Work Packages with Description
* `#1731` Squash old migrations into one

## 3.0.0pre12

* `#1417` Enable default behavior for types
* `#1631` Remove documents from core

## 3.0.0pre11

* `#1418` Change links to issues/planning elements to use work_packages controller
* `#1541` Use Rails 3.2.14 instead of Git Branch
* `#1595` Cleanup action menu for work packages
* `#1596` Copy/Move work packages between projects
* `#1598` Switching type of work package looses inserted data
* `#1618` Deactivate modal dialogs and respective cukes
* `#1637` Removed files module
* `#1648` Arbitrarily failing cuke: Navigating to the timeline page

## 3.0.0pre10

* `#1246` Implement uniform "edit" action/view for pe & issues
* `#1247` Implement uniform "update" action for pe & issues
* `#1411` Migrate database tables into the new model
* `#1413` Ensure Permissions still apply to the new Type
* `#1425` Remove default planning element types in favor of enabled planning element types in the style of has_and_belongs_to_many.
* `#1427` Enable API with the new Type
* `#1434` Type controller
* `#1435` Type model
* `#1436` Type views
* `#1437` Update seed data
* `#1512` Merge PlanningElementTypes model with Types model
* `#1520` PlanningElements are created without the root_id attribute being set
* `#1520` PlanningElements are created without the root_id attribute being set
* `#1536` Fixed bug: Reposman.rb receives xml response for json request
* `#1577` Searching for project member candidates is only possible when using "firstname lastname" (or parts of it)

## 3.0.0pre9

* `#779`  Integrate password expiration
* `#1314` Always set last activity timestamp and check session expiry if ttl-setting is enabled
* `#1371` Changing pagination per_page_param does not change page
* `#1405` Incorrect message when trying to login with a permanently blocked account
* `#1409` Changing pagination limit on members view looses members tab
* `#1414` Remove start & due date requirement from planning elements
* `#1461` Integration Activity Plugin
* `#1488` Fixes multiple and missing error messages on project settings' member tab (now with support for success messages)
* `#1493` Exporting work packages to pdf returns 406
* `#1505` Removing all roles from a membership removes the project membership
* `#1517` Journal changed_data cannot contain the changes of a wiki_content content

## 3.0.0pre8

* `#377`  Some usability fixes for members selection with select2
* `#1024` Add 'assign random password' option to user settings
* `#1063` Added helper to format the time as a date in the current user or the system time zone
* `#1391` Opening the new issue form in a project with an issue category defined produces 500 response
* `#1406` Creating a work package w/o responsible or assignee results in 500
* `#1420` Allow for seeing work package description changes inside of the page
* `#1488` Fixes multiple and missing error messages on project settings' member tab

## 3.0.0pre7

* `#778` Integrate ban of former passwords
* `#780` Add password brute force prevention
* `#820` Implement awesome nested set on work packages
* `#1034` Create changelog and document format
* `#1119` Creates a unified view for work_package show, new and create
* `#1209` Fix adding watcher to issue
* `#1214` Fix pagination label and 'entries_per_page' setting
* `#1299` Refactor user status
* `#1301` Ajax call when logged out should open a popup window
* `#1303` Watcherlist contains unescaped HTML
* `#1315` Correct spelling mistakes in German translation

