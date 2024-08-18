---
title: OpenProject 6.0.1
sidebar_navigation:
  title: 6.0.1
release_version: 6.0.1
release_date: 2016-08-01
---

# OpenProject 6.0.1

**OpenProject 6.0.1 contains the following changes for the Wiki module:**

In OpenProject versions prior to 6.0.0., specific characters of
[wiki](../../../user-guide/wiki/) titles were removed
upon saving – especially dots and spaces. Spaces were replaced with an
underscore, while other characters were removed.  
Still, linking to these pages was possible with either the original
title (e.g., ‘\[\[Title with spaces\]\]’), or the processed title (e.g.,
‘\[\[title\_with\_spaces\]\]’).  
Starting
with [OpenProject 6.0.0](https://www.openproject.org/blog/openproject-6-0-released/), titles
were allowed to contain arbitrary characters and were linked to using
escaped links.
([#20151](https://community.openproject.org/wp/20151)).  
That change caused those links with spaces to wiki pages to break after
the migration to OpenProject 6.0.0, since they now linked to a new page
(with actual spaces in its title, since that was allowed now).

This bug was fixed in
[#23674](https://community.openproject.org/wp/23674) alongside
a more permanent change to how wiki titles are produced. Titles may
still contain arbitrary characters now, but are processed into a
permalink (URL slug) upon saving.  
This causes the identifiers of wiki pages with non-ascii characters to
be more visually pleasing and easier to link to. When upgrading to
OpenProject 6.0.1., permalinks for all your pages will be generated
automatically.

**Additionally, the following errors have been fixed in OpenProject
6.0.1:**

  - Activity
    on work package was not instantly updated when making changes to a
    work package
    ([#23675](https://community.openproject.org/wp/23675)).
  - Copy function was missing from fullscreen work package page
    ([#23685](https://community.openproject.org/wp/23685)).
  - Type
    and status could not be selected when copying a work package
    ([#23690](https://community.openproject.org/wp/23690)).
  - Custom field of type “List” could not be changed (always switched
    back to previous value)
    ([#23696](https://community.openproject.org/wp/23696)).
  - Grouped versions from other projects (inherited) in work package
    table were not displayed correctly
    ([#23697](https://community.openproject.org/wp/23697)).
  - Work package export (XLS, PDF, CSV) ignored filters, sorting and
    grouping
    ([#23713](https://community.openproject.org/wp/23713)).
  - Collapsing groups in work package page did not collapse related rows
    ([#23718](https://community.openproject.org/wp/23718)).
  - Inherited versions were lost when making changes in the work package
    table
    ([#23719](https://community.openproject.org/wp/23719)).
  - Custom fields were not displayed in queries
    ([#23725](https://community.openproject.org/wp/23725)).
  - Timeline
    graph was not displayed when timeline was embedded (e.g. on overview
    page)
    ([#23689](https://community.openproject.org/wp/23689)).
  - Sorting of cost type was not working
    ([#23213](https://community.openproject.org/wp/23213)).
  - Various design errors
    ([#23645](https://community.openproject.org/wp/23645), \#[23650](https://community.openproject.org/wp/23650),
    [#23653](https://community.openproject.org/wp/23653),
    [#23660](https://community.openproject.org/wp/23660),
    [#23664](https://community.openproject.org/wp/23664),
    [#23710](https://community.openproject.org/wp/23710))
  - Several accessibility improvements.

Thanks a lot to Guillaume Ferry and Willy Gardiol for [reporting
bugs](../../../development/report-a-bug/).

For further information on the release, please refer to the  
[Changelog v.6.0.1](https://community.openproject.org/versions/807)
or take a look at
[GitHub](https://github.com/opf/openproject/tree/v6.0.1).

For a free 30 day trial create your own OpenProject instance on
[OpenProject.org](https://openproject.org/).
