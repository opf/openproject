---
  title: OpenProject 8.2.0
  sidebar_navigation:
      title: 8.2.0
  release_version: 8.2.0
  release_date: 2018-12-17
---


# OpenProject 8.2

OpenProject 8.2 includes several improvements, such as a modernized
calendar as well as many usability improvements.

Users of the [Cloud Edition](https://www.openproject.org/hosting/) and
[Enterprise Edition](https://www.openproject.org/enterprise-edition/)
can change work packages to a read-only mode to avoid unwanted changes.
Additionally, embedded work package now also support relations.

## Modernized calendar view

The existing calendar view has been replaced with a new, modern calendar
view with OpenProject 8.2. This affects all existing calendar views
(e.g. in a project, on the
<span class="explanatory-dictionary-highlight" data-definition="explanatory-dictionary-definition-57">My
page</span>).

![Calendar](https://1t1rycb9er64f1pgy2iuseow-wpengine.netdna-ssl.com/wp-content/uploads/2018/12/Calendar-1024x605.png)

## Usability improvements

OpenProject 8.2 includes many usability improvements which make
OpenProject easier and smoother to use. Some examples of usability
improvements include:

  - Create a version from the roadmap and backlog page.
  - Change a work package parent directly from the breadcrumb.
  - A “Related to” relation is created automatically when copying a work
    package.
  - The OpenProject search searches the current project and subprojects
    by default.

## Read-only mode for work packages (Enterprise Edition / Cloud Edition)

Users of the Enterprise Edition and Cloud Edition can define read-only
work package statuses. When you change a work package’s status to a
read-only status, the work package can no longer be modified. This
allows you to avoid users to e.g. make changes to a work package once it
has been approved.

![Read-only mode work
packages](https://1t1rycb9er64f1pgy2iuseow-wpengine.netdna-ssl.com/wp-content/uploads/2018/12/Read-only-mode-work-packages-1024x432.png)

## Embedded work packages with other relation types (Enterprise Edition / Cloud Edition)

With OpenProject 8.2 the embed work package capability introduced with
OpenProject 8 is extended to be used with other relation types besides
hierarchical relationships.

![Embedded work package
table](https://1t1rycb9er64f1pgy2iuseow-wpengine.netdna-ssl.com/wp-content/uploads/2018/12/WorkPackage-Table-1024x457.png)

## Technical improvements and bug fixes

The OpenProject API now allows you to update times in OpenProject
([\#29003](https://community.openproject.com/projects/openproject/work_packages/29003/activity))
and delete time entries
([\#29029](https://community.openproject.com/projects/openproject/work_packages/29029/activity)),
OpenProject 8.2 contains a large number of smaller improvements and bug
fixes.

For an overview, please take a look at the [list of bug
fixes](https://community.openproject.com/projects/openproject/work_packages?query_props=%7B%22c%22%3A%5B%22id%22%2C%22subject%22%2C%22type%22%2C%22status%22%2C%22assignee%22%2C%22version%22%5D%2C%22hi%22%3Atrue%2C%22g%22%3A%22%22%2C%22t%22%3A%22parent%3Aasc%22%2C%22f%22%3A%5B%7B%22n%22%3A%22status%22%2C%22o%22%3A%22*%22%2C%22v%22%3A%5B%5D%7D%2C%7B%22n%22%3A%22version%22%2C%22o%22%3A%22%3D%22%2C%22v%22%3A%5B%221253%22%5D%7D%2C%7B%22n%22%3A%22type%22%2C%22o%22%3A%22%3D%22%2C%22v%22%3A%5B%221%22%5D%7D%2C%7B%22n%22%3A%22subprojectId%22%2C%22o%22%3A%22*%22%2C%22v%22%3A%5B%5D%7D%5D%2C%22pa%22%3A1%2C%22pp%22%3A20%7D).


