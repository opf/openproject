---
title: OpenProject 6.0.4
sidebar_navigation:
  title: 6.0.4
release_version: 6.0.4
release_date: 2016-08-30
---

# OpenProject 6.0.4

OpenProject 6.0.4 contains several bug and accessibility fixes.

**The following bugs have been fixed in OpenProject 6.0.4:**

  - The *+ New Project*
    button was displayed even to users who didn’t have the permission to
    create new work packages
    ([#23881](https://community.openproject.org/wp/23881)).
  - Work package attribute were sometimes not saved properly when
    multiple attributes were changed in quick succession
    ([#23589](https://community.openproject.org/wp/23859)).
  - In the work package split screen the subject was not updated when it
    was changed in the work package table
    ([#23879](https://community.openproject.org/wp/23879)).
  - The project list on the work package screen appeared to be ordered
    randomly. It’s now sorted alphabetically
    ([#23786](https://community.openproject.org/wp/23786)).
  - The global setting to display work packages from subprojects in main
    projects did not work
    ([#23814](https://community.openproject.org/wp/23814)).
  - The *Cancel* button on wiki pages was missing
    ([#23829](https://community.openproject.org/wp/23829)).
  - The link to add additional work package attachments on the wiki page
    redirected users to the landing page instead
    ([#23820](https://community.openproject.org/wp/23820)).
  - Wiki
    menu items were showing the slug instead of the title
    ([#23818](https://community.openproject.org/wp/23818)).
  - The *Send for review* button on the meeting page did not work when a
    timezone was set
    ([#23758](https://community.openproject.org/wp/23758)).
  - Cost reports grouped by year and months were displayed in the wrong
    order
    ([#23773](https://community.openproject.org/wp/23773)).
  - Several styling errors have been fixed
    ([#23808](https://community.openproject.org/wp/23808),
    [#23834](https://community.openproject.org/wp/23834)).
  - Several missing translations have been added (e.g.
    [#23877](https://community.openproject.org/wp/23877)).

Thanks a lot to the community, in particular to Marc Vollmer, for
[reporting
bugs](../../../development/report-a-bug/)!

For further information on the release, please refer to the  
[Changelog v.6.0.4](https://community.openproject.org/versions/816)
or take a look at
[GitHub](https://github.com/opf/openproject/tree/v6.0.4).

You can try OpenProject for free. For a free 30 day trial create your
OpenProject instance on [OpenProject.org](https://openproject.org/).
