<!---- copyright
OpenProject Backlogs Plugin

Copyright (C)2013-2014 the OpenProject Foundation (OPF)
Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
Copyright (C)2010-2011 friflaj
Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
Copyright (C)2009-2010 Mark Maglana
Copyright (C)2009 Joe Heck, Nate Lowrie

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License version 3.

OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
The copyright follows:
Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany

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

See docs/COPYRIGHT.rdoc for more details.

++-->

# Changelog

* `#10848` Duplicated status select on type switch

## 3.0.7

* new version scheme
* `#7782` Long target version names destroy layout
* `#10228` Font size in backlog and taskboard to small
* `#10232` Work package filter introduced by plugins not displayed

## 3.0.7

* `#8413` Collapse/Expand arrow not displayed

## 3.0.6

* `#5357` Adapt released plugins to base on plugins functionality
* Migration fix: Also used plugin_redmine_backlogs as old setting name when migrating

## 3.0.5

* `#542` Fix: Deleting the sprint dates still allows to create burndown charts that wont show
* `#2526` Fix: Burndown chart for future versions not working
* `#3440` New workpackage form layout
* `#4118` [FIX] Add missing labels
* `#4152` Page not found when only one export card configuration is specified
* `#4223` Fix: Taskboard is translated to "Aufgabenliste" in German
* `#4224` "Create stories" is translated to "Sprints anlegen" in Roles & Permissions
* `#4821` Edit sprint from menu
* `#4862` Fix: Internal error with custom field for projects
* show description on pdf export modal

## 3.0.5.pre3

* `#2259` [Accessibility] linearisation of issue show form (2)
* `#3546` Better icon for Timelines Module
* use pdf export plugin to export story cards

## 3.0.5.pre2

* `#2167` [Accessibility] Link form elements to their label - backlogs - new task
* `#2229` [Accessibility] low contrast in backlogs task view
* `#2258` [Accessibility] linearisation of issue show form
* `#2607` [Agile] Display Storypoints in Taskboard view
* `#3532` Fix: [API] It is possible to set statuses that are not allowed by the workflow
* `#3649` A backlog item should get the highest position when moved to another backlog

## 3.0.5.pre1

* `#2395` [Work Package Tracking] Internal Error when entering a character in a number field in a filter
* `#3339` [Agile] Display work package numbers with 7 digits in backlog view
* Adaptations for new icon font
* Fix: Backlog data existence check

## 3.0.4

* `#2728` Prepared public release
* updated dependency to OpenProject core
* list story_points in the api/v1 if we have them
* added icon for new project menu

## 3.0.4.pre10

* Fixed missing migration of setting values

## 3.0.4.pre9

* `#2545` Migrated old plugin settings
* `#2461` Fixed saving of setting for version fold status
* `#2413` Squashed old migrations

## 3.0.4.pre8

* `#2274` Add foldable versions

## 3.0.4.pre7

* `#1093` Fix missing permission translations
* `#2070` Adapted to changed core asset locations
* fixed specs and cukes
* fixed taskboard javascript bug
* Rename Issue to WorkPackage

## 3.0.4.pre6

* `#2039` Adapt to OpenProject core changes
** Renamed Issue 2 WorkPackage
** Renamed IssueStatus 2 Status
** Renamed Tracker 2 Type
** Adaptions for group assigned work packages
** Adaptions for new journal handling

## 3.0.4.pre5 - 2013-07-11

* Adapt to OpenProject core changes

## 3.0.4.pre4 - 2013-06-21

* Adapt to OpenProject core changes

## 3.0.4.pre3 - 2013-06-21

### Minor Change

* Use final plugin name schema

## 3.0.4.pre2 - 2013-06-14

### Minor Change

* added dependency to OpenProject core >= 3.0.0beta1
* more robust tests by dropping IE7 workaround

## 3.0.4.beta - 2013-05-31

### Minor Change

* Fixed Translation bugs
* Fixed task color setting
* Fixed sprint date validation

## 3.0.3.rc1 - 2013-05-24

### Major Change

* RC1 of the Rails 3 version
* This version is no longer compatible with the Rails 2 core

## 2.1.0 - 2012-04-13

### Major Change

* Fixing mass assignment vulnerabilities

## 2.0.4 - 2012-04-03

### Minor Change

* fix acts_as_journalized issues
* fix showing multiple status in backlogs view

## 2.0.3 - 2012-03-14

### Minor Change

* Fixing typo


## 2.0.2 - 2012-03-12

### Minor Change

* Design fixes

## 2.0.1 - 2012-03-02

### Minor Change

* Design fixes

## 2.0.0 - 2012-02-16

Incompatible with older versions of ChiliProject

### Major Change

* Adds support for breadcrumb navigation within OpenProject

## 1.2.7 - 2012-02-13

### Minor Change

* Design fix

## 1.2.6 - 2012-02-02

### Minor Change

* Supporting changes in accessibility master
** Sub issues are now rendered differently and therefor the link has changed

## 1.2.5 - 2012-01-30

### Minor Change

* Removing BETA
* Removing font-size definitions to let the global ones kick in

## 1.2.4 - 2012-01-25

### Minor Change

* Improved accessibility of issue box's issue hierarchy view

## 1.2.3 - 2012-01-20

### Minor Test Change

* Moving cucumber step definitions to chiliproject cucumber to use them in other plugins as well.

## 1.2.2 - 2012-01-16

### Minor Test Change

* Moving cucumber step definitions to chiliproject cucumber to use them in other plugins as well.

## 1.2.1 - 2012-01-05

### Minor Change

* Adding missing space on version setting page to fix test and design

## 1.2.0 - 2012-01-02

### Minor Changes

* Improved Ruby 1.9 support
* Improved support for the proposed fix of Chili #780
* Moved from symbol keys to string keys for plugin settings

## 1.1.0 - 2011-12-16

### Minor Changes

* Tested with the new layout of yet to be released ChiliProject 3.0
* Loading jQuery only if ChiliProject doesn't

### Bug Fixes

* Fixing syntactic ambiguity in Ruby 1.9 (#1)

## 1.0.2 - 2011-11-21

### Minor Changes

* Removing unneccesary migrations
* Added information about the needed core patch

### Bug fixes

* Fixing tests on Postgres

## 1.0.1 - 2011-11-16

### Minor Changes

* Adding links to ChiliProject Plugin configuration.
* Requiring released version od ChiliProject NIssue Plugin

## 1.0.0 - 2011-11-16 - Initial Release
