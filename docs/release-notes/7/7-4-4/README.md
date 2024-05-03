---
title: OpenProject 7.4.4
sidebar_navigation:
  title: 7.4.4
release_version: 7.4.4
release_date: 2018-05-07
---

# OpenProject 7.4.4

Version 7.4.4 of OpenProject has been released. This release contains:

## Bug fixes

- Work package modification for regular users on MySQL-based
  instances ([#27237](https://community.openproject.org/wp/27237))
- Child work packages were not deleted when the parent element is
  deleted ([#27280](https://community.openproject.org/wp/27280))
- The fuzzy project autocompletion has been corrected to provide
  better matching when a substring is matched
  ([#27447](https://community.openproject.org/wp/27447))
- The GitHub integration plugin did not properly receive events due to
  a naming clash
  ([#27448](https://community.openproject.org/wp/27448))
- Creating new wiki pages from a wiki link (e.g,  *\[\[Wiki page\]\]*) now retains the correct title instead of the
  generated URL slug ([#27462](https://community.openproject.org/wp/27462))
- A subsequent search for documents in the global search disabled the
  documents search checkbox
  ([#27479](https://community.openproject.org/wp/27479))
- The reset button for RSS tokens generated a new API token instead
  ([#27498](https://community.openproject.org/wp/27498))
- Wiki start pages (titled *Wiki*) could not be renamed back if the name was changed at one point
  ([#27576](https://community.openproject.org/wp/27576))

## Changes

- Meetings
  plugin: The *close* button of the show page now requires a
  confirmation before closing
  ([#27336](https://community.openproject.org/wp/27336))
- The restriction to create a time entry with at maximum 1000 hours on
  a single work package has been lifted
  ([#27457](https://community.openproject.org/wp/27457))

For more information, please see the [v7.4.4 version in our community](https://community.openproject.org/versions/924)
or take a look at [GitHub](https://github.com/opf/openproject/tree/v7.4.4).
