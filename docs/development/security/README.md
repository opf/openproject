## Statement on Security

At its core, OpenProject is an open-source software that is [developed and published on GitHub](https://github.com/opf/openproject). Every change to the OpenProject code base ends up in an open repository accessible to everyone. This results in a transparent software where every commit can be traced back to the contributor.

Automated tests and manual code reviews ensure that these contributions are safe for the entire community of OpenProject. These tests encompass the correctness of security and access control features. We have ongoing collaborations with security professionals from to test the OpenProject code base for security exploits.



### Security announcements mailing list

We provide a mailing list for security advisories on OpenProject at <https://groups.google.com/forum/#!forum/openproject-security>. Please register there to get immediate notifications as we publish them.

Any security related information will also be published on our blog and website at https://www.openproject.com



### Reporting a vulnerability

We take all facets of security seriously at OpenProject. If you want to report a security concerns, have remarks, or contributions regarding security at OpenProject, please reach out to us at [security@openproject.com](mailto:security@openproject.com).

If you can, please send us a PGP-encrypted email using the following key:

- Key ID: [0x7D669C6D47533958](https://pgp.mit.edu/pks/lookup?op=get&search=0x7D669C6D47533958) , 
- Fingerprint BDCF E01E DE84 EA19 9AE1 72CE 7D66 9C6D 4753 3958
- You may also find the key [attached in our OpenProject repository.](https://github.com/opf/openproject/blob/dev/docs/development/security/security-at-openproject.com.asc)

Please include a description on how to reproduce the issue if possible. Our security team will get your email and will attempt to reproduce and fix the issue as soon as possible.



## OpenProject Security features

### Authentication.

OpenProject administrators can enforce [authentication mechanisms and password rules]() to ensure users choose secure passwords according to current industry standards. Passwords stored by OpenProject are securely stored using salted bcrypt. Alternatively, external authentication providers and protocols (such as LDAP, SAML) can be enforced to avoid using and exposing passwords within OpenProject.

### Two-step user registration

In compliance with common requirements in works committees, ensure that new users added by project responsibles are confirmed by a superior before allowing the user to enter the system for the first time.

### User management and access control.

Administrators are provided with [fine-grained role-based access control mechanisms]() to ensure that users are only seeing and accessing the data they are allowed to on an individual project level.

### Two-Factor authentication. (Cloud or Enterprise Edition)

Secure your authentication mechanisms with a second factor by TOTP standard (or SMS, depending on your instance) to be entered by users upon logging in. [More information]().