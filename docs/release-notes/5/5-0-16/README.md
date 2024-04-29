---
title: OpenProject 5.0.16
sidebar_navigation:
  title: 5.0.16
release_version: 5.0.16
release_date: 2016-03-08
---

# OpenProject 5.0.16

OpenProject 5.0.16 contains several bug
    fixes:

  - Work package links (via \#\# and \#\#\#) in emails sent when
    watching forums were not displayed properly. This has been fixed
    ([#22728](https://community.openproject.org/work_packages/22728)).
  - An error on the work package page has been fixed which caused
    multiple work packages to be created when clicking the “Create”
    button multiple times
    ([#22735](https://community.openproject.org/work_packages/22735)).
  - The selected work package type when creating a new child work
    package was not based on the type order displayed in the
    administration. This has been adjusted
    ([#22639](https://community.openproject.org/work_packages/22639)).
  - Due to an error the project list could not be accessed in the
    accessibility mode. This has been fixed.
  - The star icon in the project list showing which project the user is
    a member in was missing. It has been added
    ([#22692](https://community.openproject.org/work_packages/22692)).
  - In the cost report, the cells were not displayed properly when
    applying a grouping in the report. This has been fixed
    ([#22762](https://community.openproject.org/work_packages/22762)).
  - In the Task board the option to adjust the column width was only
    shown when the burndown chart option was available. It has been
    adjusted to always be displayed
    ([#22297](https://community.openproject.org/work_packages/22297)).
  - Several design issues have been fixed
    ([#22805](https://community.openproject.org/work_packages/22805),
    [#22802](https://community.openproject.org/work_packages/22802),
    [#22803](https://community.openproject.org/work_packages/22803),
    [#22732](https://community.openproject.org/work_packages/22732),
    [#22716](https://community.openproject.org/work_packages/22716),
    [#22705](https://community.openproject.org/work_packages/22705),
    [#22686](https://community.openproject.org/work_packages/22686),
    [#21902](https://community.openproject.org/work_packages/21902)).

Furthermore, the performance on the work package page has been improved
([#22586](https://community.openproject.org/work_packages/22586),
[#22669](https://community.openproject.org/work_packages/22669))
and several new icons have been added to the administration
([#22063](https://community.openproject.org/work_packages/22063)).

In addition, an error has been fixed which prevented the proper use to
the TaskConnector for MS Project.
This is now fully functional again
([#22390](https://community.openproject.org/work_packages/22390)).

For further information on the release, please refer to the  
[Changelog v.5.0.16](https://community.openproject.org/versions/804)
or take a look at
[GitHub](https://github.com/opf/openproject/tree/v5.0.16).
