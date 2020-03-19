---
  title: OpenProject 3.0.0
  sidebar_navigation:
      title: 3.0.0
  release_version: 3.0.0
  release_date: 2014-10-08
---


# OpenProject 3.0.0

## New Design

  - Use of icon fonts
  - New header and side navigation
  - Contractible side navigation
  - New work package form
  - Design customization via Themes

## Major Accessibility Improvements

  -  Contrast changes supported
  - Keyboard focus highlighted by blue box
  - Keyboard focus order aligned with process order
  - Form elements linked to their labels
  - Screen reader support for multiple languages (English, German)

## Keyboard Shortcuts for Power Users

  -  Implementation of keyboard shortcuts for power users
  - Shortcuts can be accessed by pressing “?” on the keyboard

## Adaptive Timeline Reports

  - Issues and planning elements combined to work packages
  - Multi project reports
  - Filter by project attributes
  - Historic planning comparison
  - Support of custom fields
  - Autocompletion in filter (select2)
  - Support for Internet Explorer 11 added (Internet Explorer 8 no
    longer supported)
  - Performance improvements

## Improved Work Package Functionality

  - Auto-completion for work packages
  - Quick selection for custom queries
  - Responsible added to work package summary
  - Responible can be assigned via context menu and bulk edit
  - Easier navigation to work packages through shorter URL

## Add work package queries as menu items to sidebar

  -  Frequently used work package queries can be added to the side
    navigation
  - Subsequently, query pages can be renamed or deleted

## Copy projects based on Templates

  -  New projects can be created based on existing projects / project
    templates
  - Select different project settings to be copied (e.g. work packages)

## Improved Project Settings

  - Improved member configuration
  - Improved and extended type configuration

## Additional Account Security Features

  -  Random passwords
  - Stronger passwords through required characters
  - Password expiration
  - Ban of former passwords
  - Automated user blocking after certain number of failed login
    attempts
  - Automated logout on inactivity

 

## Substantial Number of Bug Fixes

Many bugs have been fixed with the release of OpenProject 3.0.  
 

## Migration to Ruby 2.1 and Rails 3.2

To ensure better performance, security and support OpenProject has been
updated to a new version of Ruby (2.1) and Rails (3.2).

The update fixes some important security vulnerabilities. For those
vulnerabilities alone, you should no longer use OpenProject 2.4.

For an extensive overview of new features in Ruby 2.1 and Rails 3.2
please refer to the release notes:

[Ruby 2.1 release
notes](https://www.ruby-lang.org/en/news/2013/12/25/ruby-2-1-0-is-released/)

[Rails 3.2 release
notes](http://guides.rubyonrails.org/v3.2.14/3_2_release_notes.html)

If you have an older version of OpenProject, please follow the
[migration guideline](https://docs.openproject.org/installation-and-operations/operation/upgrading/).
