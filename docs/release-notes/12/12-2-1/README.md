---
title: OpenProject 12.2.1
sidebar_navigation:
  title: 12.2.1
release_version: 12.2.1
release_date: 2022-08-18
---

# OpenProject 12.2.1

Release date: 2022-08-18

We released [OpenProject 12.2.1](https://community.openproject.org/versions/1594).
The release contains a critical bug fixes that resolves a data corruption issue and we urge updating to the newest version. Please see the details below for more information.

## Important bug fix for activity records

In OpenProject 12.2.0, a critical bug may randomly corrupt the activity records in the database, controlling
the display and aggregation of changes in work packages, meetings, wiki pages, and so on.

When aggregating an activity (the user edits the same object within the first 5 minutes), wrong database object might have being removed, resulting in errors when trying to update that item afterwards.

This error manifests itself as:

- Being unable to access the notification center (page stays blank).
- Being unable to see activities in work package [#43773](https://community.openproject.org/wp/43773).
- Getting internal errors trying to update an existing work package.

The upgrade to 12.2.1 fixes this bug and includes a migration to try and restore the intermediate activities for the records that were affected. **Please note that the newest version was unaffected and all the changes you made in the system are still correct.**

However, affected activities had to be restored and may be missing some changes or contain changes from previous or following activities. Any activity that had its record restored contains a note that this has happened.

If you did not yet upgrade your system to 12.2.0., please update to 12.2.1 directly to avoid being exposed to the bug.

For cloud customers of OpenProject: The records affected by this bug were restored already in the same fashion. If your instance has been affected by this bug, we will reach out to you separately to inform you.

## Changes to the HTTPS settings

If you are running OpenProject in a docker-based or if you manually integrate the packaged installation into your existing web server, you might need to set a new configuration value if you're not running under HTTPS.

For these installations, you will need to set the environment variable `OPENPROJECT_HTTPS=false` if you actively want to disable HTTPS mode.

For more information on this setting and how to configure it for your installation type, please see the respective installation pages:

- [Packaged installation](../../../installation-and-operations/installation/packaged/#step-3-apache2-web-server-and-ssl-termination)
- [Docker installation](../../../installation-and-operations/installation/docker/#configuration)

## All bug fixes

- Fixed: Wrong html title while selecting filters in notification center \[[#43122](https://community.openproject.org/wp/43122)\]
- Fixed: Outdated app description for the OpenProject app in the Nextcloud App Store \[[#43715](https://community.openproject.org/wp/43715)\]
- Fixed: Error message on subprojects boards \[[#43755](https://community.openproject.org/wp/43755)\]
- Fixed: New HTTPS flag is poorly documented and breaks quick start docker containers \[[#43759](https://community.openproject.org/wp/43759)\]
- Fixed: Wrong days highlighted as weekend in Gantt diagram \[[#43762](https://community.openproject.org/wp/43762)\]
- Fixed: OpenProject Docker Installation \[[#43767](https://community.openproject.org/wp/43767)\]
- Fixed: Unable to see activities in work package \[[#43773](https://community.openproject.org/wp/43773)\]
- Fixed: Timeline shows bar at wrong time after collapsing a group \[[#43775](https://community.openproject.org/wp/43775)\]

## Contributions

A big thanks to community members for reporting bugs and helping us identifying and providing fixes.

Special thanks for reporting and finding bugs go to

Daniel Hug, Daniel Narberhaus, Dan W, Kenneth Kallevig
