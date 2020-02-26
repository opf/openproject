---
  title: OpenProject 7.4.0
  sidebar_navigation:
      title: 7.4.0
  release_version: 7.4.0
  release_date: 2017-12-15
---


# OpenProject 7.4

OpenProject 7.4 includes several improvements: The project list has been
improved and the project list in the administration and user page have
been combined.

Additionally, you can resize the Gantt chart via drag and drop and the
work package status is highlighted more prominently. As a user of the
[Cloud Edition](https://www.openproject.org/hosting/) or [Enterprise
Edition](https://www.openproject.org/enterprise-edition/), custom fields
are shown in the project list.

In addition, two factor authentication is available for Enterprise
Edition and Cloud Edition users.

## Updated project list (project portfolio list)

With OpenProject 7.4 the project list is combined with the project admin
list. As a user you can choose to expand or collapse the project
description. As a result, you can see all projects in one place.  
As a user of the [Enterprise
Edition](https://www.openproject.org/enterprise-edition/) or [Cloud
Edition](https://www.openproject.org/hosting/),  you can also see
project custom fields (e.g. project status, project responsible)
directly in the list. You can also filter by those project custom
fields. This provides a good foundation for project portfolio
management.  
We removed the projects entry from the administration. Administrators
can simply navigate to the project list and copy, archive or delete
projects from the list view. For more information take a look at [this
blog
post](https://www.openproject.org/openproject-7-4-project-list-moves-administration-view-projects-page/).



## Resize Gantt chart with drag & drop

A frequent request we received is the ability to easily resize the Gantt
chart. This is possible with OpenProject 7.4. Simply select the handle
on the left side of the Gantt chart drag to increase or decrease the
width of the Gantt chart.



## Work package status more prominent

The status of a work package (e.g. task, phase or milestone) is one of
the most important pieces of information. Therefore, the status is
highlighted with OpenProject 7.4 and displayed right below the work
package subject. You can see the status right away.

## Set avatar in account settings

With OpenProject 7.4 you can easily set or change your user avatar in
your account settings. You can easily upload an avatar image.  
If you prefer not to use avatars (or gravatars), you can deactivate this
setting in the Plugins settings in the administration and thereby
prevent users from uploading an avatar or set a gravatar.

## Wiki macro for work package create buttons

<span style="font-size: 1.125rem;">The ability to quickly create a new
work package is critical. With OpenProject 7.4 you can use work package
create buttons to create work packages from any page in OpenProject that
supports the wiki syntax.  
</span>Users can therefore create work packages right from the project
overview page, from the wiki page or from a meeting.  
It is even possible to set a default type to allow users to rapidly
create e.g. bugs or tasks.



## Two factor authentication (Enterprise Edition / Cloud Edition)

Users of the Enterprise Edition and Cloud Edition can activate two
factor authentication with OpenProject 7.4 to increase the security of
their OpenProject environments.  
You can choose between authentication by text message or authentication
via app. Upon entering your username and password you are prompted to
enter a token. You are only logged in when the correct token is
provided. This provides a much higher level of security.

## OpenProject webhooks

OpenProject offers an [extensive
API](https://docs.openproject.org/api/) to synchronize data between
OpenProject and third party applications.  
With OpenProject 7.4, OpenProject also offers a webhook plugin which can
be used to actively send data from OpenProject to other applications.

## Faster performance

One major advantage of OpenProject 7.4 is the improved work package
performance. We refactored the work package and Gantt chart
functionality to allow you to work and update your data more smoothly.

## Improved usability and design

OpenProject 7.4 includes several usability improvements.

The PDF print layout for the work package list has been improved. When
you print out a work package in fullscreen view (using the browser’s
print functionality), the layout is optimized and unnecessary
information is hidden.

When you assign a date to a work package (e.g. phase, milestone) for the
first time, the current month is pre-selected. This makes setting start
and due dates very easy.

We optimized the mobile view for the work package view.

## Substantial number of bug fixes

OpenProject 7.4 contains a large number of bugs fixes.

For an extensive overview of bug fixes please refer to the [following
list](https://community.openproject.com/projects/openproject/work_packages?query_props=%7B%22c%22:%5B%22id%22,%22subject%22,%22type%22,%22status%22,%22assignee%22%5D,%22tzl%22:%22days%22,%22hi%22:true,%22g%22:%22%22,%22t%22:%22parent:desc%22,%22f%22:%5B%7B%22n%22:%22version%22,%22o%22:%22%253D%22,%22v%22:%5B%22845%22%5D%7D,%7B%22n%22:%22type%22,%22o%22:%22%253D%22,%22v%22:%5B%221%22%5D%7D,%7B%22n%22:%22subprojectId%22,%22o%22:%22*%22,%22v%22:%5B%5D%7D%5D,%22pa%22:1,%22pp%22:20%7D).


