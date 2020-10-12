---
  title: OpenProject 7.2.2
  sidebar_navigation:
      title: 7.2.2
  release_version: 7.2.2
  release_date: 2017-09-04
---


# OpenProject 7.2.2

## Bug fixes (6)

  - Row highlighting in the work package table and timeline view ceases
    to work after using the timeline.
    \[[\#26168](https://community.openproject.com/wp/26168)\]
  - A textile parsing error causes the description field of a work
    package to no longer be rendered.
    \[[\#26159](https://community.openproject.com/wp/26159)\]
  - Pending attachments can not be removed from a new work package form.
    \[[\#26117](https://community.openproject.com/wp/26117)\]
  - Summary field width in the news entry form suggested an allowed
    value of more than 256 characters.
    \[[\#26113](https://community.openproject.com/wp/26113)\]
  - Clicking an external link in a work package’s description works, but
    also shows an error notification in Firefox.
    \[[\#26163](https://community.openproject.com/wp/26163)\]
  - Usage of a non-transpiled ES6 value causes older browsers to display
    nothing at all, instead of an “This browser is unsupported”
    notification.
    \[[\#26153](https://community.openproject.com/wp/26153)\]

## Visual changes

  - Editing attributes in the table should no longer cause large changes
    to the column’s width.
    \[[\#26100](https://community.openproject.com/wp/26100)\]
  - The icons of regular and custom field attributes in the form
    configuration tab were not identical.
    \[[\#26129](https://community.openproject.com/wp/26129)\]

Thanks a lot to the community, in particular to Frank Schmid, Markus
Hillenbrand, and Marc Vollmer for reporting bugs\!

For further information on the 7.2.2 release, please refer to
the [Changelog
v7.2.2](https://community.openproject.com/versions/846) or take a look
at [GitHub](https://github.com/opf/openproject/tree/v7.2.2).

## A note on CentOS 7 packages

If you’re using CentOS 7 and want to upgrade to OpenProject 7.2 or later
versions, please also upgrade your package source according to
the [Download and
Installation](https://www.openproject.org/download-and-installation/) page.  
For more information, please also see ticket
\[[\#26144](https://community.openproject.com/wp/26144)\] and [this
forum post](https://community.openproject.com/topics/8114).

 


