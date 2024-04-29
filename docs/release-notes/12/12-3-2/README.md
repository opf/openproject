---
title: OpenProject 12.3.2
sidebar_navigation:
    title: 12.3.2
release_version: 12.3.2
release_date: 2022-10-26
---

# OpenProject 12.3.2

Release date: 2022-10-26

We released [OpenProject 12.3.2](https://community.openproject.org/versions/1608).
The release contains several bug fixes and we recommend updating to the newest version.

## Bug fixes and changes

- Fixed: Multiple identical Webhooks are sent for each WP change applied, not considering the Aggregated WorkPackage Journal \[[#44158](https://community.openproject.org/wp/44158)\]
- Fixed: Moving a week-days-only WP on Gantt chart and falling its end-date to a non-working date is not possible \[[#44501](https://community.openproject.org/wp/44501)\]
- Fixed: Migration to 12.3.1 fails with Key columns "user_id" and "id" are of incompatible types: numeric and bigint. \[[#44634](https://community.openproject.org/wp/44634)\]
- Fixed: rake assets:precompile fails with NameError: uninitialized constant ActiveRecord::ConnectionAdapters::PostgreSQLAdapter \[[#44635](https://community.openproject.org/wp/44635)\]

## Contributions

A big thanks to community members for reporting bugs and helping us identifying and providing fixes.

Special thanks for reporting and finding bugs go to

Nico Aymet, Johannes Zellner
