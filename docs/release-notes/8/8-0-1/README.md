---
title: OpenProject 8.0.1
sidebar_navigation:
  title: 8.0.1
release_version: 8.0.1
release_date: 2018-09-26
---


# OpenProject 8.0.1

We released
[OpenProject 8.0.1](https://community.openproject.org/versions/1154).
The release contains bug fixes from the 8.0 release. We recommend
updating to the newest version.

## Bug fixes and changes

  - Fixed: Highlighting of timeline missing with highlighting mode none
    \[[#28564](https://community.openproject.org/wp/28564)\]
  - Fixed: Jumping comment container when reverse activity sorting is
    activated
  - Fixed: Signed outgoing webhooks incorrectly set signature header
  - Fixed: A newline was added to WYSIWYG code blocks when editing a
    document that contained such blocks
    \[[#28609](https://community.openproject.org/wp/28609)\]
  - Fixed:
    Repository
    statistics SVG reports were not rendered due to
    Content-Security-Policy forbidding SVG elements \[#28612\]
  - Fixed: Regression that did not detect work package links within
    braces \[[#28578](https://community.openproject.org/wp/28578)\]
  - Fixed: Long-running databases of OpenProject run into PostgreSQL
    index error while migrating *planning\_element\_type\_colors*
    indexes to 8.0.0
    \[[#28556](https://community.openproject.org/wp/28556)\]
  - Fixed:
    Calendar
    filter toggles not working properly
    \[[#28588](https://community.openproject.org/wp/28588)\]
  - Fixed:
    Repository
    unfolding directory tree not working properly
    \[[#28613](https://community.openproject.org/wp/28613)\]
  - Fixed: Memory leak in repeated work package form requests
    \[[#28611](https://community.openproject.org/wp/28611)\]
  - Fixed: Login dropdown labels were styled as buttons on hover
    \[[#28616](https://community.openproject.org/wp/28616)\]
  - Fixed: Editing work package after submission with
    add\_work\_packages permission
    \[[#28580](https://community.openproject.org/wp/28580)\]
  - Fixed: Fast click on subsequent query elements in the sidebar result
    in invalid table
    \[[#28539](https://community.openproject.org/wp/28539)\]
  - Fixed: Two scrollbars in activity comments on narrow browser windows
    \[[#28553](https://community.openproject.org/wp/28553)
  - Fixed: Can’t upload attachments on comments with add\_work\_packages
    permission \[[#28541](https://community.openproject.org/wp/28541)\]
  - Fixed: Collapsing views on global work package page removes entries
    \[[#28584](https://community.openproject.org/wp/28584)\]
  - Improved: Restored status column on subelements table of a work
    package \[[#28526](https://community.openproject.org/wp/28526)\]
  - Fixed:
    Type
    is invalid when creating new project
    \[[#28543](https://community.openproject.org/wp/28543)\]

## Contributions

A big thanks to community members for reporting bugs, especially to Marc
Vollmer, Frank Schmid, and Nicolas Salguero for their aid in identifying
and providing fixes for multiple bug reports.
