---
  title: OpenProject 7.1.0
  sidebar_navigation:
      title: 7.1.0
  release_version: 7.1.0
  release_date: 2017-07-04
---


# OpenProject 7.1.0

OpenProject 7.1.0 improves timeline queries, provides additional
customization options and improves the design. There are also several
bug fixes included.

## Features (4)

  - The style of the sidebar has been updated
    ([\#25556](https://community.openproject.com/projects/openproject/work_packages/25556/activity)).
  - The timeline zoom factor is now saved in queries: When you open a
    saved timeline query the same zoom level as before is shown
    ([\#25318](https://community.openproject.com/projects/openproject/work_packages/25318/activity)).
  - As a user of the [Cloud
    Edition](https://www.openproject.org/hosting/) or [Enterprise
    Edition](https://www.openproject.org/enterprise-edition/), you can
    now upload a custom favicon which is shown in the browser. You can
    also set a touch icon which is shown on smartphones (e.g. when
    setting a
    bookmark)([\#25517](https://community.openproject.com/projects/openproject/work_packages/25517/activity)).
  - Users of the Cloud Edition and Enterprise Edition can now also set
    white headers and there are two additional configuration options:
    Setting the hover background color and the hover font color
    ([\#25275](https://community.openproject.com/projects/openproject/work_packages/25275/activity)).

## Bug fixes (20)

  - Deactivated groupings on the work package page were not properly
    saved in queries. This has been fixed.
    ([\#25606](https://community.openproject.com/projects/openproject/work_packages/25606/activity))
  - When grouping by assignee while the author is shown as a column, the
    same groups were shown multiple times. This has been resolved.
    ([\#25605](https://community.openproject.com/projects/openproject/work_packages/25605/activity))
  - In some cases type-specific attributes were not shown for work
    packages. This has been fixed.
    ([\#25594](https://community.openproject.com/projects/openproject/work_packages/25594/activity))
  - Deep links to a repository page redirected back to the root
    repository page. This has been resolved.
  - We fixed an error prevented users from scrolling the work package
    query menu.
    ([\#25572](https://community.openproject.com/projects/telekom/work_packages/25572/activity))
  - When filtering for Boolean work package custom fields incorrect
    results were shown. This has been resolved.
  - Bulk deleting work packages which contain time entries caused an
    error. This has been fixed.
    ([\#25569](https://community.openproject.com/projects/openproject/work_packages/25569/activity))
  - Long text work package custom fields were not shown in correct size
    in work package fullscreen mode. This has been resolved.
  - Categories with long names caused rows in the work package table to
    span multiple lines. This has been fixed.
  - Exported work package CSV files could not be opened properly if the
    ID was displayed as the first column. This has been resolved.
    ([\#25536](https://community.openproject.com/projects/openproject/work_packages/25536/activity))
  - Search results for work package relations showed HTML attributes.
    This has been fixed.
    ([\#25534](https://community.openproject.com/projects/openproject/work_packages/25534/activity))
  - We fixed an error that caused work package attributes to sometimes
    not be saved properly when editing in quick succession.
  - There was an error that caused Boolean custom fields to always be
    set to “True” after copying a work package – even when the value was
    set to “False” in the original work package. This has been
    fixed.
  - <span class="explanatory-dictionary-highlight" data-definition="explanatory-dictionary-definition-17">Timeline</span>
    relationships between milestones and phases were sometimes not shown
    correctly. This has been addressed.
  - In some cases the hierarchy mode was only applied after clicking the
    respective icon multiple times. This has been resolved.
  - When saving an query that has been added to the side menu, the new
    query was not shown as part of the side menu. We fixed this issue.
  - Several design bugs have been fixed
    ([\#25595](https://community.openproject.com/projects/openproject/work_packages/25595/activity),
    [\#25371](https://community.openproject.com/projects/openproject/work_packages/25371/activity),
    [\#25356](https://community.openproject.com/projects/openproject/work_packages/25356/activity),
    [\#25298](https://community.openproject.com/projects/openproject/work_packages/25298/activity)).

## Deprecations

  - The calendar module is now marked deprecated and will be removed as
    part of OpenProject 8.0.0. An appropriate warning has been added to
    the module.

Thanks a lot to the community, in particular to Peter F, Jochen Gehlbach
and Ole Odendahl for reporting bugs\!

For further information on the release, please refer to the [Changelog
v7.1.0](https://community.openproject.com/versions/836) or take a look
at [GitHub](https://github.com/opf/openproject/tree/v7.1.0).


