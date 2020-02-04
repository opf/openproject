---
  title: OpenProject 4.1.0
  sidebar_navigation:
      title: 4.1.0
  release_version: 4.1.0
  release_date: 2015-05-21
---


# **OpenProject 4.1.0**

## **Updated work package split screen**

The layout of the work package split screen was updated to provide a
clearer, more accessible interface. Several changes have been
implemented to the split screen:

  - In order to allow users to see the most relevant work package
    information at a glance, only the work package attributes which have
    values assigned are displayed by default.
  - Work package attributes which have no values assigned can be
    displayed via the “Show all” button, which has been moved to the top
    of the attribute list.
  - To provide a logical structure to the work package, work package
    attributes are clustered into separate groups (Details, People,
    Estimates & Time, Costs, Other).



## **In-place editing on work package split screen**

OpenProject 4.1 enhances the work package split screen by allowing users
to update work packages without leaving the work package list. Via the
split screen many work package attributes can be edited on the fly, such
as:

  - Work package subject
  - Work package description
  - Work package attributes (including custom fields)

Several work package values can be edited at once.



## **Improved work package list and filters**

The work package filter section now shows the number of activated
filters – even when the filter section is collapsed. Additionally, the
work package ID in the work package list is no longer static, but can be
configured as the other columns in the work package list:

  - Number of activated filters shown
  - Work package ID in work package list can be added, removed, changed
    in order



## **Improved work package full screen**

The design of the work package page and the work package form has been
updated:

  - When editing a work package, the type, parent and subject can be
    edited right away without having to expand a separate section.
  - The spacing of the work package attributes has been increased.
  - The work package hierarchy, related work packages and watchers have
    been styled more prominently.



## **New design through Foundation framework**

The underlying CSS-framework is changed to “Foundation”:
<http://foundation.zurb.com/>. This change ensures an easier
adaptability in the future and allows a more responsive design. As a
result, the overall design of the application has been changed
with OpenProject 4.1.



## **Many accessibility improvements**

Numerous accessibility improvements have been introduced – particularly
on the work package page.

  - Split screen accessible
  - In-place editing can be performed via keyboard
  - Modal windows on work package page include helpful hints for both
    seeing and blind users
  - Additional access key for switching between work package list and
    split screen
  - Contrast for watcher icon improved



## **Substantial number of bug fixes**

A large number of bugs have been fixed with the release of OpenProject
4.1.


