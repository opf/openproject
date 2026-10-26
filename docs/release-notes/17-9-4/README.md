---
title: OpenProject 17.9.4
sidebar_navigation:
    title: 17.9.4
release_version: 17.9.4
release_date: 2026-10-26
---

# OpenProject 17.9.4

Release date: 2026-10-26

We released [OpenProject 17.9.4](https://community.openproject.org/versions/2340).
There are dependency updates for Ruby and NodeJS that fix CVEs reported recently, we strongly recommend updating to the newest version.
Below you will find a complete list of all changes and bug fixes.
<!-- BEGIN SECURITY FIXES AUTOMATED SECTION -->
<!-- END SECURITY FIXES AUTOMATED SECTION -->
<!--more-->



### Ruby 4.0.9

- CVE-2026-93577: integer overflow in the regular expression compiler
- CVE-2026-97229: integer overflow in the CI/CD regular expression compiler
- CVE-2026-110264: integer overflow in the regular expression compiler



### Node.js 24.22.1

- CVE-2026-105482 (High): dns.resolve*() and dns.reverse() silently truncate hostnames that contain a NUL byte
- CVE-2026-105483 (High): tls.checkServerIdentity() does not see fullwidth-digit IPs as IP addresses
- CVE-2026-106069 (High): leading-zero IPv4 literals are checked against a different IP than the one connected to
- CVE-2026-111497 (High): out-of-bounds write in the bundled Brotli decoder
- CVE-2026-105481 (Medium): a keep-alive socket accepts an unsolicited response as the response to a new request
- CVE-2026-106072 (Medium): certificates with only a DNS SAN can authenticate non-canonical IPv4 endpoints
- CVE-2026-106074 (Medium): crypto random caches are saved into startup snapshots and SEAs
- CVE-2026-106073 (Low): fs.realpathSync() skips read permission checks under --permission





## Bug fixes and changes

<!-- Warning: Anything within the below lines will be automatically removed by the release script -->
<!-- BEGIN AUTOMATED SECTION -->

- Bugfix: Board lists reload all their cards twice after dragging a card to another list \[[#81760](https://community.openproject.org/wp/81760)\]

<!-- END AUTOMATED SECTION -->
<!-- Warning: Anything above this line will be automatically removed by the release script -->

## Contributions
A big thanks to our Community members for reporting bugs and helping us identify and provide fixes.
This release, special thanks for reporting and finding bugs go to Alex Orlov.
