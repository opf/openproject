---
title: OpenProject 12.0.4
sidebar_navigation:
    title: 12.0.4
release_version: 12.0.4
release_date: 2021-12-14
---

# OpenProject 12.0.4

Release date: 2021-12-14

We released [OpenProject 12.0.4](https://community.openproject.org/versions/1502).
The release contains several bug fixes and we recommend updating to the newest version.

## CVE-2021-43830

OpenProject versions >= 12.0.0 are vulnerable to a SQL injection in the budgets module. For authenticated users with the "Edit budgets" permission, the request to reassign work packages to another budget insufficiently sanitizes user input in the reassign_to_id parameter.

### Patches

The vulnerability has been fixed in version 12.0.4. Versions prior to 12.0.0 are not affected. If you're upgrading from an older version, ensure you are upgrading to at least version 12.0.4.

### Workaround

If you are unable to upgrade in a timely fashion, the following patch can be applied: [https://github.com/opf/openproject/pull/9983.patch](https://github.com/opf/openproject/pull/9983.patch)

### Credits

This security issue was responsibly disclosed by [Daniel Santos](https://github.com/bananabr) (Twitter [@bananabr](https://twitter.com/bananabr)). Thank you for reaching out to us and your help in identifying this issue. If you have a security vulnerability you would like to disclose, please see our [statement on security](../../../security-and-privacy/statement-on-security/).

## Bug fixes and changes

- Fixed: Frontend including editor and time logging unusable when there are many activities \[[#40314](https://community.openproject.org/wp/40314)\]
- Fixed: Change of View within OpenProject triggers reload of Viewer \[[#40315](https://community.openproject.org/wp/40315)\]

## Contributions

A big thanks to community members for reporting bugs and helping us identifying and providing fixes.
Special thanks for reporting and finding bugs go to Daniel Santos, Valentin Ege
