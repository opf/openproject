---
title: OpenProject 13.0.2
sidebar_navigation:
    title: 13.0.2
release_version: 13.0.2
release_date: 2023-09-07
---

# OpenProject 13.0.2

Release date: 2023-09-07

We released [OpenProject 13.0.2](https://community.openproject.com/versions/1868).
The release contains several bug fixes and we recommend updating to the newest version.

<!--more-->
#### Bug fixes and changes

- Fixed: [AppSignal] Performance MessagesController#show \[[#47871](https://community.openproject.com/wp/47871)\]
- Fixed: Number of wp no longer shown in bars on the graph \[[#49767](https://community.openproject.com/wp/49767)\]
- Fixed: Not optimal texts for activity entry for migrated file links \[[#49770](https://community.openproject.com/wp/49770)\]
- Fixed: Description in a box having too little height when the browser window's width is decreased  \[[#49831](https://community.openproject.com/wp/49831)\]
- Fixed: "share_calendars" permission does not register dependencies and contract actions \[[#49833](https://community.openproject.com/wp/49833)\]
- Fixed: OAuth remapping of existing users using case sensitive login match while user registration does not \[[#49834](https://community.openproject.com/wp/49834)\]
- Fixed: Users SEEM to be able to reset password for invited, not yet activated accounts \[[#49836](https://community.openproject.com/wp/49836)\]
- Fixed: Fix untranslated strings \[[#49848](https://community.openproject.com/wp/49848)\]
- Fixed: Switch branch in repository doesn't do anything \[[#49852](https://community.openproject.com/wp/49852)\]
- Fixed: `packager:postinstall` task fails, if `OPENPROJECT_HOST__NAME` is set in environment \[[#49867](https://community.openproject.com/wp/49867)\]
- Fixed: Eager loading for API not working in parts leading to degraded performance \[[#49915](https://community.openproject.com/wp/49915)\]
- Fixed: Docker instance: No svn present in v13? \[[#49930](https://community.openproject.com/wp/49930)\]
- Fixed: Add in all reported missing translations \[[#49937](https://community.openproject.com/wp/49937)\]
- Fixed: Accidentaly granting access to Nextcloud project folders that are no members of the project \[[#49956](https://community.openproject.com/wp/49956)\]
- Changed: Forbid user to enable misconfigured storages for a project. \[[#49218](https://community.openproject.com/wp/49218)\]
- Changed: Remove the "show" view for a storage's settings page \[[#49676](https://community.openproject.com/wp/49676)\]

#### Contributions
A big thanks to community members for reporting bugs and helping us identifying and providing fixes.

Special thanks for reporting and finding bugs go to

Bernhard Kroll, Mario Haustein, Markus K.
