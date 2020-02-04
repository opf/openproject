---
  title: OpenProject 3.0.13
  sidebar_navigation:
      title: 3.0.13
  release_version: 3.0.13
  release_date: 2014-11-04
---


# OpenProject 3.0.13

The 3.0.13 patch release for OpenProject contains several bug fixes.

In particular, an internal error occurring when adding two identically
named queries as menu entries to the project menu has been fixed
([\#15447](https://community.openproject.org/work_packages/15447 "Duplicate shared queries lead to internal server errors upon menu rendering (closed)")).

Displaying the work package details page in the previous version could
take quite long – depending on the number of watchers on the OpenProject
instance. This has been fixed as well so that the work package details
page is displayed quickly again
([\#15705](https://community.openproject.org/work_packages/15705 "Details view slow (closed)")).

Additionally, a bug in the API v2 has been fixed
([\#15958](https://community.openproject.org/work_packages/15958 "API v2: parent id not returned when using ids-filter (regression) (closed)")).

An error preventing to copy projects in OpenProject persists in 3.0.13
([\#15706](https://community.openproject.org/work_packages/15706 "[Copy project] Projects cannot be copied (formerly: Subprojects are not copied correctly and the ... (closed)")),
it will be addressed in the next patch release (3.0.14).

For a complete list of changes, please refer to the [OpenProject 3.0.13
query](https://community.openproject.org/versions/466).


