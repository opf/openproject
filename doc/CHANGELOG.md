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

* `#1913` [Timelines] Enable drag&drop for select2 items in order to rearrange the order of the columns
* `#1978` Migrate legacy issues
* `#1979` Migrate legacy planning elements
* `#1982` Migrate planning element types
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
* `#1923` Add permission that allows hiding repository statistics on commits per author
* `#1950` Grey line near the lower end of the modal, cuts off a bit of the content
* `#1921` Allow disabling done ratio for work packages

## 3.0.0pre15

* `#1301` Ajax call when logged out should open a popup window
* `#1351` Generalize Modal Creation
# `#1557` Timeline Report Selection Not Visible
* `#1755` Migrate helper-tests for issues into specs for work package
* `#1766` Fixed bug: Viewing diff of Work Package description results in error 500
* `#1767` Fixed bug: Viewing changesets results in "page not found"
* `#1789` Move validation to Work Package
* `#1800` Add settings to change software name and URL and add additional footer content
* `#1808` Add option to log user for each request
* `#1875` Added test steps to reuse steps for my page, my project page, and documents, no my page block lookup at class load time
* `#1876` Timelines do not show work packages when there is no status reporting
* `#1896` Moved visibility-tests for issues into specs for workpackages
# `#1911` Change mouse icon when hovering over drag&drop-enabled select2 entries
* `#1912` Merge column project type with column planning element type
* `#1918` Custom fields are not displayed when issue is created

## 3.0.0pre14

* `#1873` Move Validations from Issue into Workpackage
* `#825` Migrate Duration
* `#828` Remove Alternate Dates
* `#1421` Adapt issue created/updated wording to apply to work packages
* `#1610` Move Planning Element Controller to API V2
* `#1686` Issues not accessible in public projects when not a member
* `#1768` Fixed bug: Klicking on Wiki Edit Activity results in error 500
* `#1787` Remove Scenarios
* `#1813` Run Data Generator on old AAJ schema
* `#1859` Fix 20130814130142 down-migration (remove_documents)

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
* `#1598` Switching type of work package looses inserted data
* `#1596` Copy/Move work packages between projects
* `#1618` Deactivate modal dialogs and respective cukes
* `#1637` Removed files module
* `#1648` Arbitrarily failing cuke: Navigating to the timeline page

## 3.0.0pre10

* `#1536` Fixed bug: Reposman.rb receives xml response for json request
* `#1520` PlanningElements are created without the root_id attribute being set
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
* `#1577` Searching for project member candidates is only possible when using "firstname lastname" (or parts of it)

## 3.0.0pre9

* `#1517` Journal changed_data cannot contain the changes of a wiki_content content
* `#779`  Integrate password expiration
* `#1461` Integration Activity Plugin
* `#1505` Removing all roles from a membership removes the project membership
* `#1405` Incorrect message when trying to login with a permanently blocked account
* `#1488` Fixes multiple and missing error messages on project settings' member tab (now with support for success messages)
* `#1409` Changing pagination limit on members view looses members tab
* `#1371` Changing pagination per_page_param does not change page
* `#1314` Always set last activity timestamp and check session expiry if ttl-setting is enabled
* `#1414` Remove start & due date requirement from planning elements
* `#1493` Exporting work packages to pdf returns 406

## 3.0.0pre8

* `#1420` Allow for seeing work package description changes inside of the page
* `#1488` Fixes multiple and missing error messages on project settings' member tab
* `#377`  Some usability fixes for members selection with select2
* `#1406` Creating a work package w/o responsible or assignee results in 500
* `#1391` Opening the new issue form in a project with an issue category defined produces 500 response
* `#1063` Added helper to format the time as a date in the current user or the system time zone
* `#1024` Add 'assign random password' option to user settings

## 3.0.0pre7

* `#820` Implement awesome nested set on work packages
* `#1119` Creates a unified view for work_package show, new and create
* `#780` Add password brute force prevention
* `#1214` Fix pagination label and 'entries_per_page' setting
* `#1303` Watcherlist contains unescaped HTML
* `#1315` Correct spelling mistakes in German translation
* `#1299` Refactor user status
* `#1301` Ajax call when logged out should open a popup window
* `#778` Integrate ban of former passwords
* `#1209` Fix adding watcher to issue
* `#1034` Create changelog and document format

