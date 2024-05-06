---
title: OpenProject 12.5.8
sidebar_navigation:
    title: 12.5.8
release_version: 12.5.8
release_date: 2023-07-18
---

# OpenProject 12.5.8

Release date: 2023-07-18

We released [OpenProject 12.5.8](https://community.openproject.org/versions/1829).
The release contains several bug fixes and we recommend updating to the newest version.

<!--more-->
## Bug fixes and changes

- Fixed: After calling "Create project copy" API endpoint, the Job Status API should return the new projects id, not only its identifier  \[[#37783](https://community.openproject.org/wp/37783)\]
- Fixed: Entries in summary emails not clickable in Outlook (links not working) \[[#40157](https://community.openproject.org/wp/40157)\]
- Fixed: Custom project attribute triggers error when selected during project creation \[[#46827](https://community.openproject.org/wp/46827)\]
- Fixed: Preview of linked WP is cut off in split view when close to the edge \[[#46837](https://community.openproject.org/wp/46837)\]
- Fixed: Selected date (number) not visible when matches with Today \[[#47145](https://community.openproject.org/wp/47145)\]
- Fixed: Opening of CKEditor sporadically taking 10s+ when trying to comment on work packages \[[#47795](https://community.openproject.org/wp/47795)\]
- Fixed: Projects tab of group administration should not offer adding to archived projects \[[#48263](https://community.openproject.org/wp/48263)\]
- Fixed: Grape responds with text/plain 303 redirect to a JSON api \[[#48622](https://community.openproject.org/wp/48622)\]
- Fixed: Meeting Minutes double submit causes lock version error \[[#49061](https://community.openproject.org/wp/49061)\]
- Fixed: Cost reports XLS export results in timeout of web request \[[#49083](https://community.openproject.org/wp/49083)\]
- Fixed: Internal error occurs when invalid project is set to template \[[#49116](https://community.openproject.org/wp/49116)\]
- Changed: Allow internal login even if omniauth direct provider selected \[[#47930](https://community.openproject.org/wp/47930)\]

## Contributions

A big thanks to community members for reporting bugs and helping us identifying and providing fixes.

Special thanks for reporting and finding bugs go to

Petros Christopoulos, Gerrit Bonn
