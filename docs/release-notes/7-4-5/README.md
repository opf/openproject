---
  title: OpenProject 7.4.5
  sidebar_navigation:
      title: 7.4.5
  release_version: 7.4.5
  release_date: 2018-05-28
---


# OpenProject 7.4.5

<span class="explanatory-dictionary-highlight" data-definition="explanatory-dictionary-definition-10">Version</span>
7.4.5 of OpenProject has been released. The release contains several bug
fixes. We recommend the update to the current version.

  - Fixed: Cookie *secure* flag was not applied in all cases even when
    SSL was enabled
    ([\#27763](https://community.openproject.com/wp/27763))
  - Fixed:
    <span class="explanatory-dictionary-highlight" data-definition="explanatory-dictionary-definition-90">Calendar</span>
    widget on
    *<span class="explanatory-dictionary-highlight" data-definition="explanatory-dictionary-definition-57">My
    page</span>*  overlapped the project dropdown
    ([\#27765](https://community.openproject.com/wp/27765))
  - Fixed: Removed text formatting other than references in commit
    messages ([\#27769](https://community.openproject.com/wp/27769))
  - Fixed: Flashing of content
    on *<span class="explanatory-dictionary-highlight" data-definition="explanatory-dictionary-definition-58">My
    account</span>* on initial page load
    ([\#25795](https://community.openproject.com/wp/25795))
  - Fixed: Chrome where the right column of a two-column work package
    layout (on larger screens) was not receiving any clicks
    ([\#27687](https://community.openproject.com/wp/27687))
  - Fixed: Updating overridden labor and unit costs reset all other
    overridden costs to their calculated values
    ([\#](https://community.openproject.com/wp/27692)[27692](https://community.openproject.com/wp/27692))
  - Fixed: Unable to update parent to previous sibling work package in
    shared hierarchy
    ([\#27746](https://community.openproject.com/wp/27746))
  - Fixed: English language option displayed twice in the administration
    ([\#27696](https://community.openproject.com/wp/27696),
    [\#27751](https://community.openproject.com/wp/27751))
  - Improved: Error messages when dependent work package is invalid
    (e.g., trying to save child with invalid parent)
  - Improved: Parent wiki pages can be selected when creating new wiki
    pages through content links
    ([\#26189](https://community.openproject.com/wp/26189))

For more information, please see the [v7.4.5 version in our
community](https://community.openproject.com/versions/990) or <span style="font-size: 1.125rem;">take
a look
at </span>[GitHub](https://github.com/opf/openproject/tree/v7.4.5)<span style="font-size: 1.125rem;">.</span>

Special thanks go to all OpenProject contributors for [reporting
bugs](https://www.openproject.org/development/report-a-bug/) and helping
us to reproduce them.

### DSGVO consenting feature

Users can now be requested to consent into the privacy and usage
policies of your instance. To configure consent, enable the setting in
the global administration under *System administration * \> *Users*


