---
  title: OpenProject 5.0.0
  sidebar_navigation:
      title: 5.0.0
  release_version: 5.0.0
  release_date: 2015-08-21
---


# **OpenProject 5.0.0**

## **Work package creation via split screen**

OpenProject 5.0 extends the work package split screen functionality and
allows users to create work packages from the work package list via the
work package split screen
([\#17549](https://community.openproject.com/work_packages/17549/activity)).

Attachments can now be more easily added by using the drag and drop area
on the work package split screen.



## **New work package full screen view**

The existing work package screen has been replaced by a new responsive
work package screen, making it possible to quickly switch from the work
package page to the full screen view
([\#16364](https://community.openproject.com/work_packages/16364/activity)).

Similar to the work package split screen, the work package full screen
contains information which can be accessed via different tabs while
still maintaining the main area for the description and attributes.

In addition, the behavior for watchers has been changed: Email
notifications are sent out immediately when adding a watcher to a work
package.



## **Improved work package split screen**

  - It is possible to edit and comment in one step in the work package
    split screen
    ([\#20208](https://community.openproject.com/work_packages/20208/activity)).
  - Watcher behavior changed: User receive an email notification when
    they have been added as watchers.
  - Repository revisions are shown in the activity tab on the work
    package split screen
    ([\#15422](https://community.openproject.com/work_packages/15422/activity)).



## **New home screen**

With OpenProject 5.0, the new home screen of OpenProject instances
displays important information (such as existing projects and registered
users) as a dashboard. In addition, links to important resources and
references have been added.

Optionally, a welcome text block with custom notifications can be added.



## **Aggregated work package activities and email notifications**

In order to reduce the amount of activity and email notifications on
work package entries, activities which are performed on a work package
within a short time period are aggregated.

Work package updates by the same user within this time period are shown
as one activity entry. Email notifications are sent based on these
aggregated
activities ([\#20694](https://community.openproject.com/work_packages/20694/activity),
[\#21035](https://community.openproject.com/work_packages/21035/activity)).



## **Enhanced repository management**

**Important:** When updating your existing OpenProject installation,
please note that you need to adjust the repository configuration.
Otherwise, repositories will not work properly. Details are included in
the “OpenProject 5.0 upgrade guide”.

With OpenProject 5.0 the repository functionality has been significantly
improved
([\#20218](https://community.openproject.com/work_packages/20218/activity)):
When deleting a project, the associated repository is deleted
automatically as well.

Additionally, repository settings can be configured project-wise,
allowing project admins to configure the description and checkout
information for their projects.

Furthermore, it is possible to see the disk space used by the used
repositories in order to get a better overview of the data usage.



## **Invite project members to OpenProject and add to a project in one step**

With OpenProject 5.0 users can be invited to a project via email without
first creating an account for them in the admin settings.

The user then receives an email notification and can create an account
for OpenProject.

Additionally, the member tab in projects has been removed from the
project settings and has been added to the project side menu.

The create user functionality has been simplified, so that only the most
important values have to be entered during creation.



## **Improved project administration page**

The project page in the administration not only includes the used disk
space for the repositories but also lists the number of projects.

Columns in the project table can be sorted (e.g. project name, creation
date, used disk storage).

The project list is paginated in order to reduce loading time when there
are a lot of projects.



## **Restructured my account section**

The My Account page has been restructured and the settings are spread
out across different sections
([\#19753](https://community.openproject.com/work_packages/19753/activity)).

Profile images can be set in my account section (local avatar plugin).



## **Simplified project and user creation**

The project and user creation has been simplified and only shows the
most important information
([\#20884](https://community.openproject.com/work_packages/20884/activity)).

The create project screen only shows the project name and required
custom fields.

Attributes shown on user invitation screen are limited to most important
attributes.



## **Deprecated features**

In order to reduce complexity, some rarely used OpenProject features
have been deprecated and removed with OpenProject 5.0:

  - The field “Homepage” in the project settings has been removed to
    reduce complexity. Instead a custom field or the project description
    can be used to contain the homepage information
    ([\#1928](https://community.openproject.com/work_packages/1928/activity)).
  - The field “Summary” in the project settings has been removed to
    reduce complexity. Instead of the summary the first row of the
    project description is shown on the project list.
  - Project dependencies have been removed from OpenProject since they
    didn’t serve  a significant purpose. Additionally, the “second
    grouping criterion” has been removed from the timelines filters
    ([\#21509](https://community.openproject.com/work_packages/21509/activity)).
  - The column “Set current rate” has been removed from the project
    member table
    ([\#21501](https://community.openproject.com/work_packages/21501/activity)).
    A user’s hourly rate can be set in the user administration.

The **copy** and **duplicate** functionality on the work package
fullscreen and split screen has been temporarily excluded. It will be
re-implemented in the next OpenProject version.

## **Usability improvements**

Aside from the main features, several smaller usability improvements are
included in OpenProject 5.0:

  - The custom fields have been moved to a separate tab in the project
    settings
    ([\#20841](https://community.openproject.com/work_packages/20841/activity)).
  - Status reports are no longer a separate menu entry in the side menu
    but they have been moved to the timeline
    toolbar ([\#21822](https://community.openproject.com/work_packages/21822/activity)).

## **Improved design**

OpenProject 5.0 includes several design improvements. For example, the
button styling has been improved
([\#19675](https://community.openproject.com/work_packages/19675/activity)).

The notification and alert messages for work packages have been
re-styled
([\#18623](https://community.openproject.com/work_packages/18623/activity))
and the layout has been improved in many other places as well.

## **Additional functionalities for API v3**

The future OpenProject API (API v3) has been extended by several
functionalities. For instance, the [API
v3](https://www.openproject.org/development/api/) now includes an
endpoint for the work package index-action.

Please note that the API v3 is still a draft.

## **Updated Rails version**

Rails – the main framework used for OpenProject – has been updated to
Rails 4.2
([\#20045](https://community.openproject.com/work_packages/20045/activity)).

This ensures the technical reliability and allows future improvements.

## **New plugins released (included in packager community edition)**

Several new plugins have been published. They are included in the
OpenProject Packager edition.

  - OpenProject – Local Avatars ([Read more on
    GitHub](https://www.github.com/finnlabs/openproject-local_avatars))
  - OpenProject – Announcements ([Read more on
    GitHub](https://www.github.com/finnlabs/openproject-announcements))
  - OpenProject – XLS-Export ([Read more on
    GitHub](https://www.github.com/finnlabs/openproject-xls_export))
  - OpenProject – Dark-Theme ([Read more on
    GitHub](https://www.github.com/finnlabs/openproject-themes-dark))
  - OpenProject – OpenID-Connect ([Read more on
    GitHub](https://www.github.com/finnlabs/openproject-openid_connect))
  - OpenProject – OmniAuth OpenID-Connect-Providers ([Read more on
    GitHub](https://www.github.com/finnlabs/omniauth-openid-connect))

## **Substantial number of bug fixes**

A large number of bugs have been fixed with the release of OpenProject
5.0.


