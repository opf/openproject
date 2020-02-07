---
  title: OpenProject 6.0.1
  sidebar_navigation:
      title: 6.0.1
  release_version: 6.0.1
  release_date: 2016-08-01
---


# OpenProject 6.0.1

**OpenProject 6.0.1 contains the following changes for the
<span class="explanatory-dictionary-highlight" data-definition="explanatory-dictionary-definition-8">Wiki</span>
module:**

In OpenProject versions prior to 6.0.0., specific characters of
[wiki](../../user-guide/wiki/) titles were removed
upon saving – especially dots and spaces. Spaces were replaced with an
underscore, while other characters were removed.  
Still, linking to these pages was possible with either the original
title (e.g., ‘\[\[Title with spaces\]\]’), or the processed title (e.g.,
‘\[\[title\_with\_spaces\]\]’).  
Starting
with [OpenProject 6.0.0](https://www.openproject.org/openproject-6-0-released/), titles
were allowed to contain arbitrary characters and were linked to using
escaped links.
([\#20151](https://community.openproject.com/work_packages/20151/activity)).  
That change caused those links with spaces to wiki pages to break after
the migration to OpenProject 6.0.0, since they now linked to a new page
(with actual spaces in its title, since that was allowed now).

This bug was fixed in
[\#23674](https://community.openproject.com/work_packages/23674) alongside
a more permanent change to how wiki titles are produced. Titles may
still contain arbitrary characters now, but are processed into a
permalink (URL slug) upon saving.  
This causes the identifiers of wiki pages with non-ascii characters to
be more visually pleasing and easier to link to. When upgrading to
OpenProject 6.0.1., permalinks for all your pages will be generated
automatically.

**Additionally, the following errors have been fixed in OpenProject
6.0.1:**

  - <span class="explanatory-dictionary-highlight" data-definition="explanatory-dictionary-definition-99">Activity</span>
    on work package was not instantly updated when making changes to a
    work package
    ([\#23675](https://community.openproject.com/work_packages/23675/activity)).
  - Copy function was missing from fullscreen work package page
    ([\#23685](https://community.openproject.com/work_packages/23685/activity)).
  - <span class="explanatory-dictionary-highlight" data-definition="explanatory-dictionary-definition-13">Type</span>
    and status could not be selected when copying a work package
    ([\#23690](https://community.openproject.com/work_packages/23690/activity)).
  - <span class="explanatory-dictionary-highlight" data-definition="explanatory-dictionary-definition-82">Custom
    field</span> of type “List” could not be changed (always switched
    back to previous value)
    ([\#23696](https://community.openproject.com/work_packages/23696/activity)).
  - Grouped versions from other projects (inherited) in work package
    list were not displayed correctly
    ([\#23697](https://community.openproject.com/work_packages/23697/activity)).
  - <span class="explanatory-dictionary-highlight" data-definition="explanatory-dictionary-definition-7">Work
    package</span> export (XLS, PDF, CSV) ignored filters, sorting and
    grouping
    ([\#23713](https://community.openproject.com/work_packages/23713/activity)).
  - Collapsing groups in work package page did not collapse related rows
    ([\#23718](https://community.openproject.com/work_packages/23718/activity)).
  - Inherited versions were lost when making changes in the work package
    list
    ([\#23719](https://community.openproject.com/work_packages/23719/activity)).
  - Custom fields were not displayed in queries
    ([\#23725](https://community.openproject.com/work_packages/23725/activity)).
  - <span class="explanatory-dictionary-highlight" data-definition="explanatory-dictionary-definition-17">Timeline</span>
    graph was not displayed when timeline was embedded (e.g. on overview
    page)
    ([\#23689](https://community.openproject.com/work_packages/23689/activity)).
  - Sorting of cost type was not working
    ([\#23213](https://community.openproject.com/work_packages/23213/activity)).
  - Various design errors
    ([\#23645](https://community.openproject.com/work_packages/23645/activity), \#[23650](https://community.openproject.com/work_packages/23650/activity),
    [\#23653](https://community.openproject.com/work_packages/23653/activity),
    [\#23660](https://community.openproject.com/work_packages/23660/activity),
    [\#23664](https://community.openproject.com/work_packages/23664/activity),
    [\#23710](https://community.openproject.com/work_packages/23710/activity))
  - Several accessibility improvements.

Thanks a lot to Guillaume Ferry and Willy Gardiol for [reporting
bugs](https://www.openproject.org/development/report-a-bug/).

For further information on the release, please refer to the [Changelog
v.6.0.1](https://community.openproject.com/versions/807) or take a look
at [GitHub](https://github.com/opf/openproject/tree/v6.0.1).

For a free 30 day trial create your own OpenProject instance on
[OpenProject.org](https://openproject.org/).


