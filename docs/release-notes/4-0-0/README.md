---
  title: OpenProject 4.0.0
  sidebar_navigation:
      title: 4.0.0
  release_version: 4.0.0
  release_date: 2014-11-06
---


# OpenProject 4.0.0

## OmniAuth integration for OpenProject

It is possible to extend OpenProject by using Omni-Auth providers. Users
can for example use the [OpenProject Auth
plugin](https://community.openproject.org/projects/auth-plugins) for an
easy integration with OmniAuth strategy providers such as Google.

  - Authentication in OpenProject via OmniAuth provider
  - Easier integration with OmniAuth providers (such as Google) via
    OpenProject Auth plugin
  - Easier implementation of OmniAuth strategies
  - Multiple authentication provider can be integrated and are shown in
    the login screen

## Integrated toolbar on work package page

OpenProject 4.0 replaces the old filter and options section on the work
package page with a convenient integrated toolbar.  
Now users no longer need to leave the work package list in order to use
many features that were previously only available on a separate
configuration page.  
In addition, filters are now expandable and it is possible to create
work packages right from the work package table.  
Accessing, filtering and changing the work package page has become even
more intuitive.

  - Expandable filter section
  - Instantly applied work package filters
  - Work package creation from work package table
  - Two different views: Work package table and split-screen
  - Create new queries based on existing ones (Save as)

## Integrated query title on work package page

The query selection is now integrated in the work package title. Queries
are being persisted.

  - Title includes query selection
  - Auto-completion of queries is supported
  - Selected query is persisted

## Column header functions in work package table

To provide users with a maximum of flexibility and convenience, it is
possible to perform some of the most frequently used actions in the work
package table right on a column header.

  - Perform often used functions right on the column header
  - Sort by column
  - Group by column attribute
  - Hide / Remove column
  - Add new column

## Split screen mode added to work package page

A split screen mode has been added to the work package table which
allows to display the work package details view alongside the work
package table, allowing a quick overview of work packages details
without leaving the overview page.  
The included work package details pane is separated in the different
tabs **Overview, Activity, Relations, Watchers** and **Attachments**,
allowing users to see the most important information at a glance.

  - Expandable work package details pane
  - “Overview” tab for general work package information
  - “Activity” tab showing history
  - “Relations” tab for dependencies
  - “Watchers” tab to follow work package
  - “Attachments” tab showing attached documents

## Improved design

Several design changes have been made to improve the readability and
overall usability of OpenProject.

  - Bigger line spacing in work package table
  - Table background single color white
  - All-cap headings throughout the application
  - New hovering color in work package table
  - Changed headlines
  - Round avatars

## Many accessibility improvements

Numerous accessibility improvements – especially in the work package
page.

  - Work package page very accessible
  - Extension of work package context menu to include option to activate
    work package split screen
  - Keyboard shortcuts and access key fully functional in work package
    page

## New plugins released

  - OpenProject Auth plugin
    ([News](https://community.openproject.org/news/66-plugin-providing-an-api-for-authentication-plugins-released),
    [GitHub](https://github.com/opf/openproject-auth_plugins),
    [Project](https://community.openproject.org/projects/auth-plugins))
  - OpenProject GitHub integration plugin
    ([News](https://community.openproject.org/news/57-openproject-github-integration-plugin-released),
    [GitHub](https://github.com/finnlabs/openproject-github_integration),
    [Project](https://community.openproject.org/projects/github-integration?jump=news))

## Substantial Number of Bug Fixes

A large number of bugs have been fixed with the release of OpenProject
4.0.