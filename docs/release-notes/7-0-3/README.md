---
  title: OpenProject 7.0.3
  sidebar_navigation:
      title: 7.0.3
  release_version: 7.0.3
  release_date: 2017-06-29
---


# OpenProject 7.0.3

The release contains an important security fix regarding session expiry
and several bug fixes.

For details on the security fix, take a look at the [release
news](https://www.openproject.org/openproject-7-0-3-released/).

## Bug fixes (7)

  - Boolean custom fields were set to true when copying a work package
    with such a field activated.
    ([\#25494](https://community.openproject.com/projects/openproject/work_packages/25494/activity))
  - Filtering for boolean custom fields did not function properly.
    ([\#25570](https://community.openproject.com/projects/openproject/work_packages/25570/activity))
  - The names of work packages have been escaped needlessly in the
    relations autocompleter.
    ([\#25534](https://community.openproject.com/projects/openproject/work_packages/25534/activity))
  - The height of the query dropdown no longer exceeds the total
    available space when lots of queries are saved.
    ([\#25572](https://community.openproject.com/projects/openproject/work_packages/25572/activity))
  - Bulk deleting work packages across more than one project failed with
    an error.
    ([\#25569](https://community.openproject.com/projects/openproject/work_packages/25569/activity))
  - Removed an unnecessary horizontal scrollbar in the query dropdown.
    ([\#25593](https://community.openproject.com/projects/openproject/work_packages/25593/activity))
  - Path parameters of the repository view are now preserved when the
    user needed to pass through the login screen first.
    ([\#25586](https://community.openproject.com/projects/openproject/work_packages/25586/activity))

We recommend the update to the current version.

Thanks a lot to the community, in particular to Mohamed A. Baset from
Seekurity SAS de C.V, Peter F, Jochen Gehlbach and Ole Odendahl for
reporting bugs\!

For further information on the release, please refer to the [Changelog
v7.0.3](https://community.openproject.com/versions/839) or take a look
at [GitHub](https://github.com/opf/openproject/tree/v7.0.3).


