---
  title: OpenProject 3.0.12
  sidebar_navigation:
      title: 3.0.12
  release_version: 3.0.12
  release_date: 2014-11-04
---


# OpenProject 3.0.12

With the release of version 3.0.12 several security threats in
OpenProject are fixed.  
These concern user permissions and the visibility of administration
settings for logged out users. We advise everybody to update their
OpenProject installation.

In addition, an error concerning the API v2 has been solved
([\#6688](https://community.openproject.org/work_packages/6688 "APIv2: ids-parameter ignored for planning_elements.json (closed)"))
and several usability bug fixes in the meetings and documents plugin are
included in 3.0.12:

  - Meetings plugin:  
    The preview function for the agenda and minutes which produced an
    internal error has been fixed and works properly now
    ([\#15208](https://community.openproject.org/work_packages/15208 "Internal error when clicking on preview on agenda/minutes (closed)")).

<!-- end list -->

  - Documents plugin:  
    With 3.0.12 an error in the documents plugin which caused an
    internal error when opening a user page
    ([\#12620](https://community.openproject.org/work_packages/12620 "Missing event type cause 500 ERROR on user page. (closed)"))
    has been fixed. Many thanks to [Björn
    Blissing](https://github.com/bjornblissing) who reported and fixed
    this error.

For a complete list of changes, pleas refer to the [OpenProject 3.0.12
query](https://community.openproject.org/versions/450).


