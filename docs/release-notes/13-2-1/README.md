---
title: OpenProject 13.2.1
sidebar_navigation:
    title: 13.2.1
release_version: 13.2.1
release_date: 2024-01-31
---

# OpenProject 13.2.1

Release date: 2024-01-31

We released [OpenProject 13.2.1](https://community.openproject.org/versions/1991).
The release contains several bug fixes and we recommend updating to the newest version.

<!--more-->

## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Bugfix: Underscore is treated as wildcard in search filter \[[#33574](https://community.openproject.org/wp/33574)\]
- Bugfix: Custom actions buttons look inactive until we hover over them and click \[[#45677](https://community.openproject.org/wp/45677)\]
- Bugfix: Remove custom field from all type configurations leaves them active in project, shown in bulk edit \[[#49619](https://community.openproject.org/wp/49619)\]
- Bugfix: Columns in task board not in sync for more than one task (column width not working)  \[[#49788](https://community.openproject.org/wp/49788)\]
- Bugfix: IFC conversion fails (libhostfxr.so not found) (reintroduced bug) \[[#50172](https://community.openproject.org/wp/50172)\]
- Bugfix: Please refrain from overwriting logrotate settings with every single update \[[#50477](https://community.openproject.org/wp/50477)\]
- Bugfix: Work packages get lost when Teamplanner's time frame switch from Work week to 2 weeks \[[#50895](https://community.openproject.org/wp/50895)\]
- Bugfix: Can't pay for the Subscription after my trial period has ended \[[#51230](https://community.openproject.org/wp/51230)\]
- Bugfix: Checkboxes are not correctly displayed in the CkEditor \[[#51247](https://community.openproject.org/wp/51247)\]
- Bugfix: Error 500 when trying to view a budget with a running WP timer \[[#51460](https://community.openproject.org/wp/51460)\]
- Bugfix: /opt/openproject/lib/redmine/imap.rb:53:in `new': DEPRECATED: Call Net::IMAP.new with keyword options (StructuredWarnings::StandardWarning) \[[#51799](https://community.openproject.org/wp/51799)\]
- Bugfix: Renaming Work Package Views/ Boards : Edit Lock Issue \[[#51851](https://community.openproject.org/wp/51851)\]
- Bugfix: Date is not correct on the boards cards due to time zone difference \[[#51858](https://community.openproject.org/wp/51858)\]
- Bugfix: Enterprise icon is inconsistently aligned in the sidebar \[[#52097](https://community.openproject.org/wp/52097)\]
- Bugfix: Files tab shows bad error message on request timeout to remote storage \[[#52181](https://community.openproject.org/wp/52181)\]
- Bugfix: OIDC backchannel logout broken as retained session values are not available in the user_logged_in_hook \[[#52185](https://community.openproject.org/wp/52185)\]
- Bugfix: PDF export fails with "undefined method `sourcepos'" \[[#52193](https://community.openproject.org/wp/52193)\]
- Bugfix: Roadmap progress is overflowing \[[#52232](https://community.openproject.org/wp/52232)\]
- Bugfix: Work package "+ Create" button drop down only opening every second time \[[#52260](https://community.openproject.org/wp/52260)\]
- Bugfix: Creating Work Package - Mentions not working anymore \[[#52298](https://community.openproject.org/wp/52298)\]
- Bugfix: remaining hours cropped on task board view \[[#52362](https://community.openproject.org/wp/52362)\]
- Bugfix: Work packages: Create child fails if milestone is first selected type \[[#52373](https://community.openproject.org/wp/52373)\]
- Bugfix: Copying project fails when work package with children is copied \[[#52384](https://community.openproject.org/wp/52384)\]
- Bugfix: Dynamic meeting HTML titles missing \[[#52389](https://community.openproject.org/wp/52389)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->

## Contributions

A big thanks to community members for reporting bugs and helping us identifying and providing fixes.

Special thanks for reporting and finding bugs go to

Pawlik Wini, Arved Kampe, Thomas Wiemann, Jeffrey McDole, Tom Gugel, Oleksii Borysenko, René Schodder, Sreekanth Gopalakris, Various Interactive, Kajetan Ignaszczak
