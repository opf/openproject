<!---- copyright
OpenProject Costs Plugin

Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
version 3.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

++-->

# Changelog

## 3.0.8 (new versions scheme)

* `#8230` Missing Translation when deleting Cost Type
* `#8233` Changing the default rate with invalid values
* `#10232` Work package filter introduced by plugins not displayed

## 5.0.4

* `#4024` Fix: Subpages have no unique page titles
* `#5357` Adapt released plugins to base on plugins functionality
* Fix: Edit accesskey for budget
* Adapted setting registration to changes in plugins plugin

## 5.0.3

* `#3440` New workpackage form layout
* `#4024` Subpages have no unique page titles
* `#4123` Add missing translation of save rate button
* `#4112` Layouttabellen: Zwei Layouttabellen erschweren das Verständnis
* `#4797` Fix: [Subdirectory] Broken Links
* Updated to use cost formatter in openproject-xls_export 1.0.0.pre5

## 5.0.2

* Adapted to renaming of core method
* use icons from icon font

## 5.0.1

* `#2259` [Accessibility] linearisation of issue show form (2)
* `#2465` [Costs] Wrong link in ticket overview for budget
* `#3065` [Work package tracking] Internal error when selecting costs in columns and displaying sums
* `#3077` Public Release Costs plugin
* `#3787` [Accessibility] Required fields MUST be displayed as required - new cost type
* `#3862` Deleting fixed date results in internal error

## 5.0.1.pre11

* `#2250` [Accessibility] activity icon labels
* `#2256` [Accessibility] no alt-texts in cost-types index view
* `#2258` [Accessibility] linearisation of issue show form
* removed not needed require of core css files
* firxed cuke

## 5.0.1.pre10

* Adaptations for new icon font
* `#1020` fix XSS when displaying costs
* `#2591` Fix: Costs prevents work package context menu
* `#2759` Fix: [Performance] Activity View very slow
* `#3329` Refactor Duplicated Code Journals
* added icon for new project menu

## 5.0.1.pre9

* Added missing translations

## 5.0.1.pre8

* `#2402` Squash old migrations
* `#2545` Migrated old plugin settings
* `#2570` Work package deletion no longer handles cost entries

## 5.0.1.pre7

* `#2376` Fix incorrect asset location.

## 5.0.1.pre6

* `#2070` Adaptions after changing core asset locations

## 5.0.1.pre5

* `#2050` Migrate to new data model.

## 5.0.1.pre4 - 2013-07-11

* Allows for assigning budgets to work_packages
* Allows for assigning cost entries to work_packages

## 5.0.1.pre3 - 2013-06-21

* Removes csv and atom export for costlog (where non working)
* Add missing translations
* Adapt to OpenProject core changes

##  5.0.1.pre2 - 2013-06-21

* Use final plugin name schema
* Removed reporting related code
* Permission fix

## 5.0.1.pre1 - 2013-05-24

* fixed failing migrations when TimeEntry(s) exists
* removed a lot of reporting-plugin patches
* Translations fixes
* added dependency to OpenProject core >= 3.0.0beta1

## 5.0.1.beta - 2013-05-24

* Fixed API requests for issues#destory
* Added budget icon for activity view
* Fixed budget overview table layout
* Fixed costobject view
* Removed signoff
* Translations fixes
* Enable enter key for the hourly rate forms

## 5.0.0.rc1 - 2013-05-24

* RC1 of the Rails 3 version
* This version is no longer compatible with the Rails 2 core
