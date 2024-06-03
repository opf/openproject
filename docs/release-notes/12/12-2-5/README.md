---
title: OpenProject 12.2.5
sidebar_navigation:
    title: 12.2.5
release_version: 12.2.5
release_date: 2022-10-04
---

# OpenProject 12.2.5

Release date: 2022-10-04

We released [OpenProject 12.2.5](https://community.openproject.org/versions/1602).
The release contains several bug fixes and we recommend updating to the newest version.

## Bug fixes and changes

## LDAP group synchronization bug

Users synchronized from LDAP into OpenProject groups were incorrectly removed when, in the same group, a new user was added in the same synchronization step.
This results in users still being present in the group despite being removed in LDAP.

To aid in the discovery of these users, you can use the following rake task to print synchronized groups that have members originating not from LDAP:

- Packaged installation: `sudo openproject run bundle exec rake ldap_groups:print_unsynced_members`
- Docker-based installation: `docker exec -it <web container ID> bash -c "bundle exec rake ldap_groups:print_unsynced_members"`

Please note that these affected users are not automatically removed in this patch release, due to the system not knowing if are expected to be members.

- Fixed: User from synchronized group not removed in OpenProject group after removed in LDAP \[[#41256](https://community.openproject.org/wp/41256)\]
- Fixed: When adding users to a group, existing users are shown in the autocompleter \[[#43892](https://community.openproject.org/wp/43892)\]
