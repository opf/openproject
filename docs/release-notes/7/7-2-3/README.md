---
title: OpenProject 7.2.3
sidebar_navigation:
  title: 7.2.3
release_version: 7.2.3
release_date: 2017-09-04
---

# OpenProject 7.2.3

## Bug: Assigned to filter returns work packages set to assignee’s group

When filtering by *Assigned to* with a single user selected, the filter
returns work packages assigned to that user. Since OpenProject 7.0,  it
also returns work packages assigned to any of the groups the user is a
member of. This is a side effect of a deliberate change made in 7.0.
Some customers depend on returning only the work packages assigned to
the single user. This bugfix release restores the original behavior.

If you want to filter for this exact behavior, a new filter named
*Assignee or belonging group* is now added that returns:

  - **when filtering for a single user**: Work packages assigned to this
    user, and any group it belongs to
  - **when filtering for a group**: Work packages assigned to this
    group, and any users within

Bug reference: [#26207](https://community.openproject.org/wp/26207)
