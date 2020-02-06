---
  title: OpenProject 7.3.0
  sidebar_navigation:
      title: 7.3.0
  release_version: 7.3.0
  release_date: 2017-09-29
---


# OpenProject 7.3

OpenProject 7.3 includes several improvements: You can configure which
labels are shown on Gantt charts, notify users on work packages with
@notations and resize the work package split screen with drag & drop.
Additionally, OpenProject 7.3 brings many additional usability
improvements.

## Labels on Gantt chart

With OpenProject 7.3 you can configure which information is shown
directly in the Gantt chart. You can display up to three different
attributes at the same time for each work package. Aside from the
default work package attributes you can also show custom fields in the
Gantt chart. This provides a lot of flexibility and allows you to for
example show the progress (in %) and the assignee directly in the Gantt
chart without having to include those attributes as separate work
package columns.



## Auto zoom in Gantt chart

Especially for large projects Gantt charts can become difficult to
manage. In order to quickly see all the work package and intelligently
adjust the zoom level, we implemented an intelligent zoom button. This
allows you to immediately switch to the optimal zoom level to see all
work packages without zooming out too much.



## Notify users with @notations on work package page

While working with work packages, you may want to quickly reference a
project member and inform him or her about the current status. While you
could accomplish this by adding the user as a watcher, it is often more
clear and personal to directly address the person. This is possible with
@notations. When you write a comment for a work package (or filling out
a description), simply enter an *@* sign, followed by the user’s name.
The user then receives an email notification.



## Resize work package split screen with drag & drop

With OpenProject 7.3 you can resize the work package split screen using
drag & drop. Especially on smaller screens it can be useful to increase
the width of the split screen. OpenProject remembers the new size, so
you don’t have to resize the split screen whenever you open a new work
package.



## Breadcrumb on work package page

Work packages are often part of a hierarchy which is not immediately
visible when looking at a work package in fullscreen or split screen
view. In order to make the hierarchy more transparent, OpenProject 7.3
introduces a breadcrumb for work packages (shown in both the fullscreen
and split screen view).



## Improved usability and design

OpenProject 7.3 includes several usability improvements.

The context menu on the work package page – which you can use to perform
bulk updates – was quite hidden. (You need to right-click on the work
package list to open the menu.) Therefore, the work package list now
contains an additional icon for each row that allows you to open the
context menu.

Prior to OpenProject 7.3, when you deleted work packages all the child
work packages were deleted as well – without any notice. We changed
this: Now you are notified about the child work packages which would be
deleted as well.

When copying projects, you can now also choose to copy work package
attachments as well.

In order to make it more clear in which project a work package is
located, we added a notification that is shown when the work package you
are looking at is in a different project from your current project. We
also removed the project attribute from the work package page. Instead,
you can use the *Move* function from the *More* menu to assign a work
package to another project.

## Substantial number of bug fixes

OpenProject 7.3 contains a large number of bugs fixes.

For an extensive overview of bug fixes please refer to the [following
list](https://community.openproject.com/projects/openproject/work_packages?query_props=%7B%22c%22:%5B%22id%22,%22subject%22,%22type%22,%22status%22,%22assignee%22%5D,%22tzl%22:%22days%22,%22hi%22:true,%22t%22:%22parent:desc%22,%22f%22:%5B%7B%22n%22:%22version%22,%22o%22:%22%253D%22,%22v%22:%5B%22841%22%5D%7D,%7B%22n%22:%22type%22,%22o%22:%22%253D%22,%22v%22:%5B%221%22%5D%7D,%7B%22n%22:%22subprojectId%22,%22o%22:%22*%22,%22v%22:%5B%5D%7D%5D,%22pa%22:1,%22pp%22:20%7D).


