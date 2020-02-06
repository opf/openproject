---
  title: OpenProject 4.0.2
  sidebar_navigation:
      title: 4.0.2
  release_version: 4.0.2
  release_date: 2014-11-20
---


# OpenProject 4.0.2

OpenProject 4.0.2 was released today which contains several security and
bug fixes.  
We advise everyone to update their OpenProject installations.

With OpenProject 4.0.2 the Rails version has been updated to 3.2.21
([\#17467](https://community.openproject.org/work_packages/17467 "Updating Rails to 3.2.21 (closed)")).  
In addition, several bugs have been fixed:

  - An error preventing work packages from being created with an
    activated split screen has been resolved
    ([\#17333](https://community.openproject.org/work_packages/17333 "Not possible to create work package from work package page with activated split screen (wrong link) (closed)"))
  - Errors with regards to time tracking have been fixed
    ([\#17500](https://community.openproject.org/work_packages/17500 "Permission for 'spent time' not applied on legacy WP view and list of time entries (closed)"),
    [\#17499](https://community.openproject.org/work_packages/17499 "Spent time not part of work package API (closed)"),
    [\#17222](https://community.openproject.org/work_packages/17222 "[TimeEntries] spent_on date always displays the current date (closed)"))
  - Timelines embedded via wiki macros are now properly sized
    ([\#17353](https://community.openproject.org/work_packages/17353 "[Wiki] Timelines macro does not have sufficient width (closed)"))
  - Custom fields of type version are now displayed in the work package
    split screen
    ([\#17354](https://community.openproject.org/work_packages/17354 "Value for custom fields of type version not displayed in details pane (closed)"))
  - Accessibility improvements have been made
    ([\#17230](https://community.openproject.org/work_packages/17230 "[Accessibility] Star/Watch icon in Details pane not accessible  (closed)")).

A big thanks to everyone involved in fixing and reporting those bugs\!

For a complete list of changes, please refer to the [Changelog
v4.0.2](https://community.openproject.org/versions/532) or to
[Github](https://github.com/opf/openproject/tree/v4.0.2).


