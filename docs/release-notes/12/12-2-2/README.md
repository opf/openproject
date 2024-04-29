---
title: OpenProject 12.2.2
sidebar_navigation:
    title: 12.2.2
release_version: 12.2.2
release_date: 2022-08-31
---

# OpenProject 12.2.2

Release date: 2022-08-31

We released [OpenProject 12.2.2](https://community.openproject.org/versions/1597).
The release contains several bug fixes and we recommend updating to the newest version.

## Known issues

### Pending database migration issue

When upgrading to 12.2.1, a migration was added to restore some deleted historical values. For more information, please see the release notes for [12.2.1](../12-2-1/)

For a few customers, this migration appears to have been unsuccessful to restore all affected journal entries. This resulted in the migration to fail and being unable to continue with the update. As we could not reproduce this issue as of now, you can choose to ignore the missing journals if you're affected.

When you update to OpenProject 12.2.2 and the migration fails again, it will output steps on how to force the migration to complete. Doing that will output a debug log of all relevant information on these journals. Please help us identifying this issue by posting this log in this ticket: https://community.openproject.org/wp/43876, or reaching out to support@openproject.org.

## Bug fixes and changes

- Fixed: Wrong link for "Documents added" email notification \[[#41114](https://community.openproject.org/wp/41114)\]
- Fixed: Bulk copy error when Assignee value set 'nobody' \[[#43145](https://community.openproject.org/wp/43145)\]
- Fixed: Impossible to deselect all days when choosing days to receive mail reminders \[[#43158](https://community.openproject.org/wp/43158)\]
- Fixed: Error message "Assigned to invalid" syntactically wrong \[[#43514](https://community.openproject.org/wp/43514)\]
- Fixed: Graphics bugs on mobile \[[#43555](https://community.openproject.org/wp/43555)\]
- Fixed: New project selector does not work correctly \[[#43720](https://community.openproject.org/wp/43720)\]
- Fixed: Error 500 (undefined method `getutc') when opening activities \[[#43771](https://community.openproject.org/wp/43771)\]
- Fixed: Wiki accessible if last menu item got lost \[[#43841](https://community.openproject.org/wp/43841)\]
- Fixed: Unable to set LDAP filter string through rake task ldap:register \[[#43848](https://community.openproject.org/wp/43848)\]
- Fixed: Upgrade 12.1.4 to 12.2.1 fails: pending database migration \[[#43876](https://community.openproject.org/wp/43876)\]
- Fixed: System 'read only' field \[[#43893](https://community.openproject.org/wp/43893)\]

## Contributions

A big thanks to community members for reporting bugs and helping us identifying and providing fixes.

Special thanks for reporting and finding bugs go to

Anatol Gafenco, Christina Vechkanova, Helmut Fritsche, Martin Dittmar, André van Kaam
