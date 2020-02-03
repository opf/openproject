---
  title: OpenProject 4.2.3
  sidebar_navigation:
      title: 4.2.3
  release_version: 4.2.3
  release_date: 2015-07-23
---


# OpenProject 4.2.3

OpenProject 4.2.3 contains several bug fixes and updated translations.

The following bugs have been fixed:

  - A bug was fixed which could lead to an error 500 if a work package
    was created in a project which has a lot of possible watchers and
    /or custom fields
    ([\#20998](https://community.openproject.org/work_packages/20998)).
  - With OpenProject 4.2.2 logged out users could see the “Modules” menu
    even when the option “Authentication required” was activated. This
    has been fixed
    ([\#20935](https://community.openproject.org/work_packages/20935)).
  - In some circumstances journal entires in work packages were
    displayed twice. This has been fixed
    ([\#20914](https://community.openproject.org/work_packages/20914)).
  - The REST API option is now activated for new OpenProject instances
    by default
    ([\#20914](https://community.openproject.org/work_packages/20914)).

Apart from the OpenProject core, several wrong strings in plugins have
been fixed:

  - Global Roles: In the details view of a role a wrong string was
    displayed
    ([\#21001](https://community.openproject.org/work_packages/21001)).
  - PDF Export: A success notification contained a type
    ([\#20996](https://community.openproject.org/work_packages/20996)).

For further information on the release, please refer to the [Changelog
v.4.2.3](https://community.openproject.org/versions/748) or take a look
at [GitHub](https://github.com/opf/openproject/tree/v4.2.3).


