# Changelog

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
