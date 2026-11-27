# Changelog

All notable changes to `@openproject/blocknote-extensions` are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Changes that are not released yet are collected in [changelog/unreleased](changelog/unreleased).

## [0.3.5]

### Fixed

- Allow any minute in date and time fields of the create work package dialog, not only multiples of five ([BNE-177](https://community.openproject.org/wp/BNE-177))
- Select only the new block, not the cards around it, when linking a work package with /wp between two work package cards ([BNE-179](https://community.openproject.org/wp/BNE-179))
- Show a single selection ring on selected work packages and work package attributes instead of a second lighter one inside it ([BNE-180](https://community.openproject.org/wp/BNE-180))
- Step over a work package block another collaborator is still choosing, instead of selecting it as an empty blue square ([BNE-181](https://community.openproject.org/wp/BNE-181))
- Give work package attributes the same options menu as work package links, including keyboard access ([BNE-183](https://community.openproject.org/wp/BNE-183))
- Outline work package attributes and work package links covered by a text selection in Safari too ([BNE-184](https://community.openproject.org/wp/BNE-184))
- Format dates and times of work package attributes according to the user's settings ([BNE-187](https://community.openproject.org/wp/BNE-187))
- Open the create work package dialog on the portfolio or program the document belongs to, as it does for projects ([BNE-189](https://community.openproject.org/wp/BNE-189))
- Show cut off picker options and the chosen work package in full on hover, and keep long types from overflowing the work package picker ([BNE-190](https://community.openproject.org/wp/BNE-190))
- Keep the insert work package attribute dialog open on an outside click or Escape once values are filled in ([BNE-191](https://community.openproject.org/wp/BNE-191))
- Block work package attributes and cards inserted in the middle of a line split the line ([BNE-192](https://community.openproject.org/wp/BNE-192))
- The attributes in the "Insert work package attribute" dialog are sorted alphabetically, and the field no longer looks like it can be typed into ([BNE-193](https://community.openproject.org/wp/BNE-193))
- Keep the "Create new work package" entry at the bottom of the work package search when nothing is found and the search opens above the text ([BNE-196](https://community.openproject.org/wp/BNE-196))
- Grow and shrink the insert work package attribute dialog smoothly instead of jumping when its content changes ([BNE-197](https://community.openproject.org/wp/BNE-197))
- Announce the shown value of a selected work package attribute and the dash of semantic identifiers to screen readers ([BNE-198](https://community.openproject.org/wp/BNE-198))

## [0.3.4]

Changes up to and including this version were not recorded.
