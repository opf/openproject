---
title: OpenProject 11.3.3
sidebar_navigation:
    title: 11.3.3
release_version: 11.3.3
release_date: 2021-07-20
---

# OpenProject 11.3.3

Release date: 2021-07-20

We released [OpenProject 11.3.3](https://community.openproject.org/versions/1484).
The release contains several bug fixes and we recommend updating to the newest version.

## Security issues

**CVE-2021-32763**: Regular Expression Denial of Service in OpenProject forum messages

An unoptimized regular expression in the quote functionality of the OpenProject forum feature in versions before 11.3.3 allows an attacker to perform a denial of service attack by passing a particularly crafted string to increase the runtime of the regular expression evaluation drastically.

Please see the advisory for [CVE-2021-32763](https://github.com/opf/openproject/security/advisories/GHSA-qqvp-j6gm-q56f) for more information.

**CVE-2021-36390**: Host Header Injection in unproxied Docker installations

The default ServerName configuration of the all-in-one and docker-compose based Docker containers of OpenProject allow for HOST header injection if they are operated without a proxying web server / load balancer in front of it with a proper ServerName setup.

Operating public facing docker containers is not recommended by OpenProject. The embedded server of the docker containers are not designed to be publicly accessible. Instead, use a proxying or load balancing web server that is bound to your public hostname. If you are using such an external web server, this advisory does not affect you.

Please see the advisory for [CVE-2021-36390](https://github.com/opf/openproject/security/advisories/GHSA-r8f8-pgg2-2c26) for more information.

## Bug fixes and changes

- Fixed: Database migration fails on upgrade from 11.2.2 to 11.3.X \[[#37687](https://community.openproject.org/wp/37687)\]
- Fixed: Renaming a group removes all group members \[[#38017](https://community.openproject.org/wp/38017)\]
- Fixed: Fix catastrophic backtracking in MessagesController#quote regular expression \[[#38021](https://community.openproject.org/wp/38021)\]
- Fixed: Public-facing docker AIO container vulnerable to HOST header injection by default \[[#38067](https://community.openproject.org/wp/38067)\]

## Contributions

A big thanks to community members for reporting bugs and helping us identifying and providing fixes.
Special thanks for reporting and finding bugs go to Rob A, Milad P.
