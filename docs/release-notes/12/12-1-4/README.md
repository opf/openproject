---
title: OpenProject 12.1.4
sidebar_navigation:
    title: 12.1.4
release_version: 12.1.4
release_date: 2022-05-17
---

# OpenProject 12.1.4

Release date: 2022-05-17

We released [OpenProject 12.1.4](https://community.openproject.org/versions/1551).
The release contains several bug fixes and we recommend updating to the newest version.

**Centos 7 support**
This version restores support for OpenProject packages on centos 7. A PostgreSQL bump has caused incompatibility issues with the centos7 versions that are shipped and extra effort was needed to provide compatible newer dev headers.

## Bug fixes and changes

- Fixed: Removal of the new SPOT buttons because of consistency \[[#42251](https://community.openproject.org/wp/42251)\]
- Fixed: Incorrect project assignment in the team planner \[[#42271](https://community.openproject.org/wp/42271)\]
- Fixed: Create form crashes when inviting placeholder user into "assigned to" or "responsible" \[[#42348](https://community.openproject.org/wp/42348)\]
- Fixed: openproject configure fails Ubuntu 20.04 \[[#42375](https://community.openproject.org/wp/42375)\]
- Fixed: Project clone with global basic auth not working \[[#42377](https://community.openproject.org/wp/42377)\]
- Fixed: Project include modal doesn't close when clicking the create button \[[#42380](https://community.openproject.org/wp/42380)\]
- Fixed: Installation packages broken for centos 7 \[[#42384](https://community.openproject.org/wp/42384)\]
- Fixed: starttls_auto forced to true since Ruby 3 upgrade \[[#42385](https://community.openproject.org/wp/42385)\]
- Fixed: LDAP user synchronization - administrator  flag is overwritten  \[[#42396](https://community.openproject.org/wp/42396)\]
- Fixed: Project filter is not applied in embedded table \[[#42397](https://community.openproject.org/wp/42397)\]

## Contributions

A big thanks to community members for reporting bugs and helping us identifying and providing fixes.

Special thanks for reporting and finding bugs go to

Harald Herz, Matthias Tylkowski, Jason Hydeman, Maximilian Hippler, Klemen Sorčnik
