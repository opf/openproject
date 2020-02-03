---
  title: OpenProject 7.2.0
  sidebar_navigation:
      title: 7.2.0
  release_version: 7.2.0
  release_date: 2017-08-09
---


# OpenProject 7.2

OpenProject 7.2 includes several improvements: Relations can be
displayed as a column in the work package page, the Gantt chart can be
expanded to full width, weekends are shown in the Gantt chart and it is
possible to use copy / paste to add screenshots from the clipboard.
Users of the Enterprise Edition and Cloud Edition can specify attribute
help texts which make working with attributes easier.

### Gantt chart includes weekends, subject and dates

The Gantt chart highlights the weekend (Saturday, Sunday) so users can
see when to not schedule phases or milestones. Additionally, the subject
is shown in the Gantt chart and start and due date is visible on hover.



### Full-width Gantt chart / timeline

By removing columns from the work package list the width of the Gantt
chart can be increased. By removing all columns, the Gantt chart expands
to almost the entire width of the page.



### Add screenshots to work package description and comments with copy / paste

You can add screenshots to work packages by copying and pasting them
into the description, the comments or custom fields of type long text.



### Show only comments on work package activity tab

When working with long work package activities it can get difficult to
see the most important information. You can choose to only show comments
on the activity tab to hide all other activity entries.



### Relations in the work package list (Enterprise Edition / Cloud Edition)

With OpenProject 7.2 you can show relation columns in the work package
list. A label shows how many related elements a work package has. By
clicking on the label, the related work packages are shown.



### Attribute help texts (Enterprise Edition / Cloud Edition)

Users of the Enterprise Edition and Cloud Edition can specify attribute
help texts which show additional information for attributes (e.g. custom
fields).



## Improved usability and design

OpenProject 7.2 includes several usability improvements.

For example, we removed the *Show all* button.
<span class="explanatory-dictionary-highlight" data-definition="explanatory-dictionary-definition-45">Project</span>
members can see the number of relations a work package has, by looking
at the label shown next to the *Relations* tab.

## Substantial number of bug fixes

OpenProject 7.2 contains a large number of bugs fixes.

For an extensive overview of bug fixes please refer to the [following
list](https://community.openproject.com/projects/openproject/work_packages?query_props=%7B%22c%22:%5B%22id%22,%22subject%22,%22type%22,%22status%22,%22assignee%22%5D,%22tzl%22:%22days%22,%22hi%22:true,%22t%22:%22parent:desc%22,%22f%22:%5B%7B%22n%22:%22version%22,%22o%22:%22%253D%22,%22v%22:%5B%22824%22%5D%7D,%7B%22n%22:%22type%22,%22o%22:%22%253D%22,%22v%22:%5B%221%22%5D%7D,%7B%22n%22:%22subprojectId%22,%22o%22:%22*%22,%22v%22:%5B%5D%7D%5D,%22pa%22:1,%22pp%22:20%7D).


