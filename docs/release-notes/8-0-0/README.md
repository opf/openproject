---
  title: OpenProject 8.0.0
  sidebar_navigation:
      title: 8.0.0
  release_version: 8.0.0
  release_date: 2018-08-29
---


# OpenProject 8.0

OpenProject 8.0 introduces a new, professional text editor which makes
editing wiki pages, meetings, news and work packages much easier and
comfortable. In addition, intelligent workflows are possible – thanks to
custom actions. With the click of a button several attributes can be
updated at once. Thanks to a new side navigation and a new design
OpenProject offers a fresh, new look.

The old timeline view has been removed and is replaced by the new
interactive Gantt chart. Make sure to [migrate your timeline
reports](https://www.openproject.org/old-timeline-view-discontinued-please-migrate-timeline-openproject-7-0/)
prior to upgrading to OpenProject 8. Embedded timeline views (using the
old timeline) are removed. Instead, you can use embedded work package
tables (see below).

Read below to get a detailed overview of what is new in OpenProject 8.

## WYSIWYG Markdown text editor

A new WYSIWYG editor replaces the existing editor in OpenProject
([18039](https://community.openproject.com/projects/openproject/work_packages/18039/activity)).
Based on CKEditor 5, the new editor makes it easy to create and format
texts. Users do no longer have to remember textile syntax and can
directly see the changes they make. No matter whether you want to add an
image, enter a macro or create a table – everything is just one click
away.

The syntax format powering the editor is CommonMark, a joint standard
around the Markdown format. When migrating to 8.0., your Textile
documents will be converted to the new format automatically using
pandoc.



## New side navigation

Navigating within OpenProject is now even easier: The new side
navigation
([26824](https://community.openproject.com/projects/openproject/work_packages/26824/activity),
[27828](https://community.openproject.com/projects/openproject/work_packages/27828/activity))
allows you to easily navigate within projects. To get additional screen
real estate, just hide the entire side navigation. In addition, work
package views and wiki pages are now much easier to find and navigate
to.



## Embedded work package tables

With OpenProject 8 you can easily embed work package views and the Gantt
chart in wiki pages
([26233](https://community.openproject.com/projects/openproject/work_packages/26233/activity)).
This way you can display key project information (such as the current
milestone plan) directly in a wiki page or in the project overview page.



## Full text search for work package attachments (Enterprise / Cloud Edition)

Looking for a specific document or some text in that document? This is
no problem with the new full text search capability for work package
attachments
([26817](https://community.openproject.com/projects/openproject/work_packages/26817/activity)).
You can either search by file name of the content of the file from the
work package page. This allows you to quickly find all the work packages
with certain attachments.



## Custom actions (Enterprise / Cloud Edition)

With OpenProject 8 you can model intelligent workflows using custom
actions
([26612](https://community.openproject.com/projects/openproject/work_packages/26612/activity)).
Simply select which actions should be triggered when you click a custom
action button. You can e.g. change the assignee, status and priority of
a work package with the click of a single button. This gives you a
powerful way to easily and quickly update your work packages based on
predefined workflows. You save time and avoid errors.



## Conditional formatting for work package list (Enterprise / Cloud Edition)

Rows in the work package page page can be highlighted based on the
status or priority of the work packages. This makes it very easy to see
which tasks are most important or need attention. In addition, the due
date can be highlighted so that you see right away which phases,
milestones or tasks are due soon or overdue.



## Subelement groups for work package types (Enterprise / Cloud Edition)

To quickly add child work packages for an existing work package, you can
add a subelement group to a work package type. This allows you to add a
small work package table as an attribute group to a work package. You
can configure which columns and which types of child work packages are
displayed.



## Usability improvements

OpenProject’s overall usability has been improved. The functionality of
several existing modules has changed.  
In particular, the work package page configuration has been updated to
be usable for embedded tables as well. In addition
*<span class="explanatory-dictionary-highlight" data-definition="explanatory-dictionary-definition-36">Responsible</span>*
has been renamed to *Accountable*.



## New design

With version 8, OpenProject gets a fresh new look: Both the OpenProject
logo and default color theme has been updated. As a user of the Cloud
Edition or Enterprise Edition you can of course change the default color
theme.

## Performance improvements

OpenProject 8 also includes several performance improvements, e.g. for
the work package page.

## Upgrade to Angular 6

On the technical side, OpenProject 8 uses the latest version of Angular
(Angular 6) instead of AngularJS. This improves the overall performance
and ensures that OpenProject is future-proof.

## Substantial number of bug fixes

OpenProject 8.0 contains a large number of bugs fixes.

For an extensive overview of bug fixes please refer to the [following
list](https://community.openproject.com/projects/openproject/work_packages?query_props=%7B%22c%22:%5B%22id%22,%22subject%22,%22type%22,%22status%22,%22assignee%22%5D,%22tzl%22:%22days%22,%22hi%22:false,%22g%22:%22%22,%22t%22:%22parent:desc%22,%22f%22:%5B%7B%22n%22:%22version%22,%22o%22:%22%253D%22,%22v%22:%5B%22818%22%5D%7D,%7B%22n%22:%22type%22,%22o%22:%22%253D%22,%22v%22:%5B%221%22%5D%7D,%7B%22n%22:%22subprojectId%22,%22o%22:%22*%22,%22v%22:%5B%5D%7D%5D,%22pa%22:1,%22pp%22:20%7D).

## Upgrading your installation to OpenProject 8.0.

If you’re on our hosted environment of OpenProject, you are already
running on the latest version of OpenProject 8.0.0. For your local
installations, there are some minor changes you need to do in order to
perform the upgrade.

[Please visit our upgrade guides for more
information](https://www.openproject.org/operations/upgrading/).

 

</div>
