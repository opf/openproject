---
  title: OpenProject 4.0.4
  sidebar_navigation:
      title: 4.0.4
  release_version: 4.0.4
  release_date: 2014-12-11
---


# OpenProject 4.0.4

OpenProject 4.0.4 (and 4.0.3) have been released which contain several
bug fixes.  
We advise everyone to update their OpenProject installations to
OpenProject 4.0.4.

## OpenProject 4.0.3

OpenProject 4.0.3 fixes several bugs relating to the work package table.
In addition, font errors in Chrome have been addressed.

  - Under some circumstances no text was displayed when using Chrome.
    This error has been fixed
    ([\#17567](https://community.openproject.org/work_packages/17567 "No text rendered at all on some versions of Chrome (closed)"))
  - Custom fields of type user and version are now properly displayed in
    the work package table
    ([\#17660](https://community.openproject.org/work_packages/17660 "Missing user links in work package list for custom fields of type user (closed)"),
    [\#17630](https://community.openproject.org/work_packages/17630 "Custom values for CF of type version not properly displayed in work package list (closed)"))
  - Wrong error messages when using queries have been addressed
    ([\#17572](https://community.openproject.org/work_packages/17572 "Error message \"Unable to retrieve query\" wrongly displayed when changing WP attributes in query (closed)"))
  - It is now possible to remove grouping options from queries which was
    not possible before
    ([\#17570](https://community.openproject.org/work_packages/17570 "Removing grouping not saved on existing queries (closed)"))
  - Errors occuring in subfolder installations of OpenProject have been
    resolved
    ([\#17566](https://community.openproject.org/work_packages/17566 "Parent change via wp-detail view stuck at loading in subfolder installation (closed)"),
    [\#17564](https://community.openproject.org/work_packages/17564 "Export function throws \"object not found\" error when used in subfolder installation (closed)"))
  - It is possible again to display multiple timelines in a wiki page
    (by using a macro)
    ([\#17568](https://community.openproject.org/work_packages/17568 "Not possible to display more than one timeline via macro in wiki (closed)"))

In addition, there has been a small change to the backlogs plugin:

  - The function “Copy tasks” has been renamed to “Copy work packages”
    when duplicating work packages with children
    ([\#17602](https://community.openproject.org/work_packages/17602 "Rename \"Copy tasks\" to \"Copy work packages\" on copy of work package (with Backlogs enabled) (closed)")).

## OpenProject 4.0.4

An additional bug fix has been added with OpenProject 4.0.4:

  - Due to a regression it was not possible to group by attributes which
    are not displayed in the work package list. This has been resolved
    ([\#17738](https://community.openproject.org/work_packages/17738 "500 on WP table on grouping by non displayed column (closed)")).

## List of changes

For a complete list of changes, please refer to the [Changelog
v4.0.3](https://community.openproject.org/versions/543) and [Changelog
v.4.0.4](https://community.openproject.org/versions/559).


