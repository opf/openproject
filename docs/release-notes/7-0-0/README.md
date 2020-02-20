---
  title: OpenProject 7.0.0
  sidebar_navigation:
      title: 7.0.0
  release_version: 7.0.0
  release_date: 2017-05-18
---


# OpenProject 7.0

OpenProject 7.0 is the biggest OpenProject release yet with amazing new
features: A new interactive timeline, hierarchies in the work package
list, multi-select custom fields and much more.

## New integrated Gantt chart / timeline

OpenProject 7.0 introduces a new Gantt chart which is integrated in the
work package list
([\#13785](https://community.openproject.com/projects/openproject/work_packages/13785/activity)).

The new timeline is much more interactive and user-friendly than the old
timeline.



## Display hierarchies in work package list

You can display hierarchies on the work package list and collapse and
expand them
([\#24647](https://community.openproject.com/projects/openproject/work_packages/24647/activity)).



## Attribute group configuration for work package types

With OpenProject 7.0 you can configure which attributes
are displayed for a work package type
([\#24123](https://community.openproject.com/projects/openproject/work_packages/24123/activity)).

You can therefore control which attributes are shown and which are
hidden by default.



## Filter based on date in work package list

The work package list now supports filtering based on fixed dates. This
affects all date attributes (e.g. start / due date, created on / updated
on)
([\#22585](https://community.openproject.com/projects/telekom/work_packages/22585/activity)).



## New header navigation

The header navigation in OpenProject is updated and displays the current
project. Additionally, the logo has been centered and existing menus
have been reordered
([\#24465](https://community.openproject.com/projects/design/work_packages/24465/activity)).



## Archive and delete projects from project settings

As an administrator you can archive and delete projects right from the
project settings
([\#24913](https://community.openproject.com/projects/openproject/work_packages/24913/activity)).



## Zen-mode on work package page

With the zen mode on the work package list, you can maximize the
available screen real estate by hiding the side and top navigation
([\#18216](https://community.openproject.com/projects/openproject/work_packages/18216/activity)).

This provides a cleaner and larger user interface to work with.



## Multi-select custom fields (Enterprise / Cloud Edition)

Users of the OpenProject [Enterprise
Edition](https://www.openproject.org/enterprise-edition/) and [Cloud
Edition](https://www.openproject.org/hosting/) can create multi-select
custom fields
([\#24793](https://community.openproject.com/projects/openproject/work_packages/24793/activity)).

With these custom fields you can select multiple values for work package
custom fields at once and also filter based on them.



## Logo upload and custom color scheme (Enterprise / Cloud Edition)

Users of the OpenProject Enterprise Edition and Cloud Edition can upload
their own company’s logo instead of the OpenProject logo.

Additionally, you can change the colors by using a custom color scheme
([\#18099](https://community.openproject.com/projects/gmbh/work_packages/18099/activity),
[\#24460](https://community.openproject.com/projects/gmbh/work_packages/24460/activity)).



## Performance improvements

The performance – especially for the work package list – has been
improved. Loading and displaying work packages is faster.

## Improved design

OpenProject 7.0 includes several design improvements and improves the
user experience for users accessing OpenProject on a mobile device.

## Substantial number of bug fixes

OpenProject 7.0 contains a large number of bugs fixes.

For an extensive overview of bug fixes please refer to the [following
list](https://community.openproject.com/projects/openproject/work_packages?query_props=%7B%22c%22:%5B%22id%22,%22subject%22,%22type%22,%22status%22,%22assignee%22%5D,%22p%22:%22openproject%22,%22t%22:%22parent:desc%22,%22f%22:%5B%7B%22n%22:%22version%22,%22o%22:%22%253D%22,%22t%22:%22list_optional%22,%22v%22:%22750%22%7D,%7B%22n%22:%22type%22,%22o%22:%22%253D%22,%22t%22:%22list_model%22,%22v%22:%221%22%7D,%7B%22n%22:%22subprojectId%22,%22o%22:%22*%22,%22t%22:%22list_subprojects%22,%22v%22:%5B%5D%7D%5D,%22pa%22:1,%22pp%22:20%7D).


