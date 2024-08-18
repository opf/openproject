---
title: OpenProject 7.1.0
sidebar_navigation:
  title: 7.1.0
release_version: 7.1.0
release_date: 2017-07-04
---


# OpenProject 7.1.0

OpenProject 7.1.0 improves timeline queries, provides additional
customization options and improves the design. There are also several
bug fixes included.

## Features (4)

  - The style of the sidebar has been updated
    ([#25556](https://community.openproject.org/wp/25556)).
  - The timeline zoom factor is now saved in queries: When you open a
    saved timeline query the same zoom level as before is shown
    ([#25318](https://community.openproject.org/wp/25318)).
  - As a user of the [Enterprise cloud edition](https://www.openproject.org/enterprise-edition/#hosting-options) or
    [Enterprise on-premises edition](https://www.openproject.org/enterprise-edition/), you can
    now upload a custom favicon which is shown in the browser. You can
    also set a touch icon which is shown on smartphones (e.g. when
    setting a
    bookmark)([#25517](https://community.openproject.org/wp/25517)).
  - Users of the OpenProject Enterprise cloud and Enterprise on-premises edition can now also set
    white headers and there are two additional configuration options:
    Setting the hover background color and the hover font color
    ([#25275](https://community.openproject.org/wp/25275)).

## Bug fixes (20)

  - Deactivated groupings on the work package page were not properly
    saved in queries. This has been fixed.
    ([#25606](https://community.openproject.org/wp/25606))
  - When grouping by assignee while the author is shown as a column, the
    same groups were shown multiple times. This has been resolved.
    ([#25605](https://community.openproject.org/wp/25605))
  - In some cases type-specific attributes were not shown for work
    packages. This has been fixed.
    ([#25594](https://community.openproject.org/wp/25594))
  - Deep links to a repository page redirected back to the root
    repository page. This has been resolved.
  - We fixed an error prevented users from scrolling the work package
    query menu.
    ([#25572](https://community.openproject.org/projects/telekom/work_packages/25572))
  - When filtering for Boolean work package custom fields incorrect
    results were shown. This has been resolved.
  - Bulk deleting work packages which contain time entries caused an
    error. This has been fixed.
    ([#25569](https://community.openproject.org/wp/25569))
  - Long text work package custom fields were not shown in correct size
    in work package fullscreen mode. This has been resolved.
  - Categories with long names caused rows in the work package table to
    span multiple lines. This has been fixed.
  - Exported work package CSV files could not be opened properly if the
    ID was displayed as the first column. This has been resolved.
    ([#25536](https://community.openproject.org/wp/25536))
  - Search results for work package relations showed HTML attributes.
    This has been fixed.
    ([#25534](https://community.openproject.org/wp/25534))
  - We fixed an error that caused work package attributes to sometimes
    not be saved properly when editing in quick succession.
  - There was an error that caused Boolean custom fields to always be
    set to “True” after copying a work package – even when the value was
    set to “False” in the original work package. This has been
    fixed.
  - Timeline
    relationships between milestones and phases were sometimes not shown
    correctly. This has been addressed.
  - In some cases the hierarchy mode was only applied after clicking the
    respective icon multiple times. This has been resolved.
  - When saving an query that has been added to the side menu, the new
    query was not shown as part of the side menu. We fixed this issue.
  - Several design bugs have been fixed
    ([#25595](https://community.openproject.org/wp/25595),
    [#25371](https://community.openproject.org/wp/25371),
    [#25356](https://community.openproject.org/wp/25356),
    [#25298](https://community.openproject.org/wp/25298)).

## Deprecations

  - The calendar module is now marked deprecated and will be removed as
    part of OpenProject 8.0.0. An appropriate warning has been added to
    the module.

Thanks a lot to the community, in particular to Peter F, Jochen Gehlbach
and Ole Odendahl for reporting bugs!

For further information on the release, please refer to the [Changelog
v7.1.0](https://community.openproject.org/versions/836)
or take a look at
[GitHub](https://github.com/opf/openproject/tree/v7.1.0).
