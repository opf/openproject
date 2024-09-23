---
title: OpenProject 12.5.4
sidebar_navigation:
    title: 12.5.4
release_version: 12.5.4
release_date: 2023-05-02
---

# OpenProject 12.5.4

Release date: 2023-05-02

We released [OpenProject 12.5.4](https://community.openproject.org/versions/1728).
The release contains two security related bug fixes and we recommend updating to the newest version.

## CVE-2023-31140

Invalidation of existing sessions when 2FA activated \[[#48035](https://community.openproject.org/wp/48035)\]

When a user registers and confirms their first two-factor authentication (2FA) device for an account, existing logged in sessions for that user account are not terminated. Likewise, if an administrators creates a mobile phone 2FA device on behalf of a user, their existing sessions are not terminated. The issue has been resolved in OpenProject version 12.5.4 by actively terminating sessions of user accounts having registered and confirmed a 2FA device.

This security related issue was responsibly disclosed by [Vaishnavi Pardeshi](mailto:researchervaishnavi0@gmail.com). Thank you for reaching out to us and your help in identifying this issue. If you have a security vulnerability you would like to disclose, please see our [statement on security](../../../security-and-privacy/statement-on-security/).

For more information, [please see our security advisory](https://github.com/opf/openproject/security/advisories/GHSA-xfp9-qqfj-x28q).

**Workarounds**

As a workaround, users who register the first 2FA device on their account can manually log out to terminate all other active sessions. This is the default behavior of OpenProject but might be disabled [through a configuration option](../../../installation-and-operations/configuration/#setting-session-options). Double check that this option is not overridden if you plan to employ the workaround.

**Invalidation of password reset link when user changes password in the meantime \[[#48036](https://community.openproject.org/wp/48036)\]**

When a user requests a password reset, an email is sent with a link to confirm and reset the password. If the user changes the password in an active session in the meantime, the password reset link was not invalidated and continued to be usable for the duration of its validity period.

The issue has been resolved in OpenProject version 12.5.4 by actively revoking any active password reset tokens for user accounts having changed their passwords successfully within the application.

This security related issue was responsibly disclosed by [Vaishnavi Pardeshi](mailto:researchervaishnavi0@gmail.com). Thank you for reaching out to us and your help in identifying this issue. If you have a security vulnerability you would like to disclose, please see our [statement on security](../../../security-and-privacy/statement-on-security/).

## Bug fixes and changes

- Fixed: Google reCAPTCHA v2 and V3 changed implementation \[[#44115](https://community.openproject.org/wp/44115)\]
- Fixed: User activity: Previous link removes user parameter from URL \[[#47855](https://community.openproject.org/wp/47855)\]
- Fixed: Work package HTML titles needlessly truncated \[[#47876](https://community.openproject.org/wp/47876)\]
- Fixed: Wrong spacing in Firefox when using line breaks in user content tables \[[#48027](https://community.openproject.org/wp/48027)\]
- Fixed: Previously Created Session Continue Being Valid After 2FA Activation \[[#48035](https://community.openproject.org/wp/48035)\]
- Fixed: Forgotten password link does not expire when user changes password in the meantime \[[#48036](https://community.openproject.org/wp/48036)\]

## Contributions

A big thanks to community members for reporting bugs and helping us identifying and providing fixes.
Special thanks for reporting and finding bugs go to Björn Schümann
