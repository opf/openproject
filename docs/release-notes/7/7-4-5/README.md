---
title: OpenProject 7.4.5
sidebar_navigation:
  title: 7.4.5
release_version: 7.4.5
release_date: 2018-05-28
---

# OpenProject 7.4.5

Version 7.4.5 of OpenProject has been released. The release contains several bug
fixes. We recommend the update to the current version.

## Bug fixes and changes

- Fixed: Cookie *secure* flag was not applied in all cases even when
  SSL was enabled
  ([#27763](https://community.openproject.org/wp/27763))
- Fixed:
  Calendar widget on
  *My page*  overlapped the project dropdown
  ([#27765](https://community.openproject.org/wp/27765))
- Fixed: Removed text formatting other than references in commit
  messages ([#27769](https://community.openproject.org/wp/27769))
- Fixed: Flashing of content
  on *My account* on initial page load
  ([#25795](https://community.openproject.org/wp/25795))
- Fixed: Chrome where the right column of a two-column work package
  layout (on larger screens) was not receiving any clicks
  ([#27687](https://community.openproject.org/wp/27687))
- Fixed: Updating overridden labor and unit costs reset all other
  overridden costs to their calculated values
  ([#](https://community.openproject.org/wp/27692)[27692](https://community.openproject.org/wp/27692))
- Fixed: Unable to update parent to previous sibling work package in
  shared hierarchy
  ([#27746](https://community.openproject.org/wp/27746))
- Fixed: English language option displayed twice in the administration
  ([#27696](https://community.openproject.org/wp/27696),
  [#27751](https://community.openproject.org/wp/27751))
- Improved: Error messages when dependent work package is invalid
  (e.g., trying to save child with invalid parent)
- Improved: Parent wiki pages can be selected when creating new wiki
  pages through content links
  ([#26189](https://community.openproject.org/wp/26189))

For more information, please see the [v7.4.5 version in our community](https://community.openproject.org/versions/990)
or take a look at [GitHub](https://github.com/opf/openproject/tree/v7.4.5).

Special thanks go to all OpenProject contributors for [reporting bugs](../../../development/report-a-bug/)
and helping us to reproduce them.

## DSGVO consenting feature

Users can now be requested to consent into the privacy and usage
policies of your instance. To configure consent, enable the setting in
the global administration under *System administration* \> *Users*
