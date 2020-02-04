---
  title: OpenProject 6.0.0
  sidebar_navigation:
      title: 6.0.0
  release_version: 6.0.0
  release_date: 2016-05-27
---


# **OpenProject 6.0.0**

OpenProject 6.0.0 contains many new features, mainly for the work
package page.

## **Inline create for work packages**

OpenProject 6.0 adds the ability to rapidly create a list of work
packages (e.g. tasks) via the work package list
([\#13702](https://community.openproject.com/work_packages/13702/activity)).

As a result, you can now easily and swiftly create task lists.



## Inline edit in work package list

With OpenProject 6.0 it is possible to use inline editing to swiftly
update work packages (such as tasks, features, milestones) directly from
the work package
list ([\#18404](https://community.openproject.com/work_packages/18404/activity)).

It is no longer necessary to open a separate split screen view. Note,
that all links (except for ID) have been removed from the work package
list and form.



## Automatic synchronization between work package split screen and work package list

The split screen view automatically reflects changes in the work package
list.  When a work package is created, it is immediately shown in the
list. Likewise, the work package list directly displays changes on the
split screen.



## Configuration of visible work package attributes in OpenProject

With OpenProject 6.0 you can configure the attributes shown for each
work package type. For instance you can configure tasks to only include
information like status and assignee, while milestones and phases show
the start and due date.

Users can either completely deactivate or initially hide attributes. (to
be shown when clicking on the “Show all” button on work packages).



## Extended help menu and onboarding video

The help menu in OpenProject has been extended. As a result, it now
includes references to user guides, shortcuts and other relevant
information.

Additionally, a *First steps* video makes it easier for new users to
start working with OpenProject.



## **Usability improvements**

Aside from the main features, OpenProject 6.0 includes several smaller
usability improvements:

  - You can add attachment (e.g. images) to the work package description
    using drag and drop.
  - It is possible to create work packages from the global work package
    list.
  - It is possible to set the project when creating a work package.
  - Users can more easily create work packages on the split and full
    screen through the removed dropdown menu.

## **Improved design**

OpenProject 6.0 includes several design improvements.

 

## **URL slugs for wiki pages**

In OpenProject versions prior to 6.0.0., specific characters of wiki
titles were removed upon saving – especially dots and spaces. Spaces
were replaced with an underscore, while other characters were removed.  
Still, linking to these pages was possible with either the original
title (e.g., ‘\[\[Title with spaces\]\]’), or the processed title (e.g.,
‘\[\[title\_with\_spaces\]\]’).  
Starting with OpenProject 6.0.0, titles are allowed to contain arbitrary
characters. The titles are processed into a permalink (URL slug) upon
saving.  
This causes the identifiers of wiki pages with non-ascii characters to
be more visually pleasing and easier to link to. When upgrading to 6.0.,
permalinks for all your pages will be generated automatically.

 

##  **Substantial number of bug fixes**

OpenProject 6.0 contains a large number of bugs fixes.

For an extensive overview of bug fixes please refer to the [following
list](https://community.openproject.com/projects/openproject/work_packages?query_props=%7B%22c%22:%5B%22id%22,%22type%22,%22status%22,%22subject%22,%22assigned_to%22%5D,%22t%22:%22parent:desc%22,%22f%22:%5B%7B%22n%22:%22fixed_version_id%22,%22o%22:%22%253D%22,%22t%22:%22list_optional%22,%22v%22:%22666%22%7D,%7B%22n%22:%22type_id%22,%22o%22:%22%253D%22,%22t%22:%22list_model%22,%22v%22:%221%22%7D,%7B%22n%22:%22subproject_id%22,%22o%22:%22*%22,%22t%22:%22list_subprojects%22%7D%5D,%22pa%22:1,%22pp%22:20%7D).


