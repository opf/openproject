---
sidebar_navigation:
  title: Statement on security
  priority: 600
description: Statement of data security in OpenProject
keywords: GDPR, data security, security, OpenProject security, security alerts, single sign-on, password security, mailing list
---

# Statement on security

At its core, OpenProject is an open-source software that is [developed and published on GitHub](https://github.com/opf/openproject). Every change to the OpenProject code base ends up in an open repository accessible to everyone. This results in a transparent software where every commit can be traced back to the contributor.

Automated tests and manual code reviews ensure that these contributions are safe for the entire community of OpenProject. These tests encompass the correctness of security and access control features. We have ongoing collaborations with security professionals from to test the OpenProject code base for security exploits.

For more information on security and data privacy for OpenProject, please visit: [www.openproject.org/security-and-privacy](https://www.openproject.org/security-and-privacy/).

## Security announcements mailing list

If you want to receive immediate security notifications via email as we publish them, please sign up to our security mailing list: https://www.openproject.org/security-and-privacy/#mailing-list.

No messages except for security advisories or security related announcements will be sent there.

To unsubscribe, you will find a link at the end of every email.

Any security related information will also be published on our [blog](https://www.openproject.org/blog/) and in the [release notes](../../release-notes/).

## Security advisory list

OpenProject uses GitHub to manage and publish security advisory listings: https://github.com/opf/openproject/security/advisories

## Security vulnerability processing

When we receive vulnerability reports from researchers or through internal identification, the following process is taking place immediately:

1. A security vulnerability is reported internally or through security@openproject.com (see below on how to disclose vulnerabilities responsibly).
2. A security engineer is receiving and validating the report. An internal tracking ticket is created with a checklist template on how to process the report.
3. The reporter receives a timely response with an acknowledgement of the report, further questions if present, and an estimated timeline and complexity of a potential fix.
4. The security engineer coordinates with the security and development team to prepare and test a fix for the report.
5. A GitHub advisory draft is created and a CVE is requested, if appropriate. Security researchers are invited to collaborate on the draft, if available.
6. A patch is returned to the reporter and awaited for confirmation unless fix is trivial
7. A patch release is created, published and distributed for all supported installations
8. The security vulnerability is publicly disclosed on GitHub and communicated through the mailing list

## Reporting a vulnerability

We take all facets of security seriously at OpenProject. If you want to report a security concerns, have remarks, or contributions regarding security at OpenProject, please reach out to us at [security@openproject.com](mailto:security@openproject.com).

If you can, please send us a PGP-encrypted email using the following key:

- Key ID: [0x7D669C6D47533958](https://keys.openpgp.org/vks/v1/by-fingerprint/BDCFE01EDE84EA199AE172CE7D669C6D47533958),
- Fingerprint BDCF E01E DE84 EA19 9AE1 72CE 7D66 9C6D 4753 3958
- You may also find the key [attached in our OpenProject repository.](security-at-openproject.com.asc)

You can also [report a vulnerability directly in GitHub](https://github.com/opf/openproject/security/advisories/new), if you prefer.  In that case, please _also_ send an informal email to [security@openproject.com](mailto:security@openproject.com) with the link to the advisory, as GitHub notifications are sometimes hard to fully dig through, and we wouldn't want to miss your report.

Please include a description on how to reproduce the issue if possible. Our security team will get your email and will attempt to reproduce and fix the issue as soon as possible.

> **Please note:** OpenProject currently does not offer a bug bounty program. We will do our best to give you the appropriate credits for responsibly disclosing a security vulnerability to us. We will gladly reference your work, name, website on every publication we do related to the security update.

## OpenProject security features

### Authentication and password security

OpenProject administrators can enforce **authentication mechanisms and password rules** to ensure users choose secure passwords according to current industry standards. Passwords stored by OpenProject are securely stored using salted bcrypt. Alternatively, external authentication providers and protocols (such as LDAP, SAML) can be enforced to avoid using and exposing passwords within OpenProject.

### User management and access control

Administrators are provided with **fine-grained role-based access control mechanisms** to ensure that users are only seeing and accessing the data they are allowed to on an individual project level.

### Definition of session runtime

Admins can set a specific session duration in the system administration, so that it is guaranteed that a session is automatically terminated after inactivity.

### Two-factor authentication

Secure your authentication mechanisms with a second factor by TOTP and WebAuthn standards (or SMS, depending on your instance) to be provided by users upon logging in.

### Security badge

This badge shows the current status of your OpenProject installation. It will inform administrators of an installation on whether new releases or security updates are available for your platform.

### Security alerts

Security updates allow a fast fix of security issues in the system. Relevant channels will be monitored regarding security topics and the responsible contact person will be informed. Software packages for security fixes will be provided promptly. Sign up to our [security mailing list](#security-announcements-mailing-list) to receive all security notifications via e-mail.

### LDAP sync (Enterprise add-on)

Synchronize OpenProject users and groups with your company’s LDAP to update users and group memberships based on LDAP group members.

### Single sign-on

With the single sign-on feature you can securely access OpenProject. Control and secure access to your projects with the main authentication providers.

Find out more about our [GDPR compliance](../../enterprise-guide/enterprise-cloud-guide/gdpr-compliance/).
