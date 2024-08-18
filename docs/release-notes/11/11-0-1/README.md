---
title: OpenProject 11.0.1
sidebar_navigation:
    title: 11.0.1
release_version: 11.0.1
release_date: 2020-10-28
---

# OpenProject 11.0.1

We released [OpenProject 11.0.1](https://community.openproject.org/versions/1453).
The release contains several bug fixes and we recommend updating to the newest version.

<!--more-->
## Bug fixes and changes

- Fixed: Gantt chart: styles conflict between last active work package and hovered work package  \[[#34126](https://community.openproject.org/wp/34126)\]
- Fixed: Displaced datepicker for custom fields in the project dashboard \[[#34253](https://community.openproject.org/wp/34253)\]
- Fixed: Date field for version cannot be set / edited from Backlogs page anymore \[[#34436](https://community.openproject.org/wp/34436)\]
- Fixed: Gantt chart and table scroll independently (e.g. when creating subtask) \[[#34828](https://community.openproject.org/wp/34828)\]
- Fixed: Error message when copying boards not scrollable \[[#34842](https://community.openproject.org/wp/34842)\]
- Fixed: Burndown button shown on task board that just reloads page \[[#34880](https://community.openproject.org/wp/34880)\]
- Fixed: Datepicker doesn't work on Firefox \[[#34910](https://community.openproject.org/wp/34910)\]
- Fixed: Highlighting in date picker incorrect \[[#34929](https://community.openproject.org/wp/34929)\]
- Fixed: Migration to 11.0.0 fails for users having had MySQL \[[#34933](https://community.openproject.org/wp/34933)\]
- Fixed: Settings page "API": Page not found  \[[#34938](https://community.openproject.org/wp/34938)\]
- Fixed: User language is not updating through api \[[#34964](https://community.openproject.org/wp/34964)\]
- Fixed: Filter on CF string brakes form in split screen. \[[#34987](https://community.openproject.org/wp/34987)\]
- Fixed: API Settings Page Broken - ActionController::RoutingError (uninitialized constant Settings::ApiController \[[#34994](https://community.openproject.org/wp/34994)\]
- Fixed: Repo Management Not Working \[[#35011](https://community.openproject.org/wp/35011)\]

## Contributions

A big thanks to community members for reporting bugs and helping us identifying and providing fixes.

Special thanks for reporting and finding bugs go to

Frank Schmid, Nayan Sharma, Boris Lukashev
