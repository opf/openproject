---
sidebar_navigation:
  title: Secure coding guidelines
description: An introduction and description of guidelines for writing secure code at OpenProject and preventing common security vulnerabilities.
keywords: infrastructure, security, coding, guidelines
---

# Secure coding Guidelines

This document provides secure coding development guidelines for developers working on OpenProject. The objective is to help identify and mitigate potential security vulnerabilities early in the development process. This document is based on the best practices following the [Open Web Application Security Project (OWASP)](https://www.owasp.org).

By following these guidelines, developers can contribute to OpenProject while ensuring the security of OpenProject and reduce the risk of vulnerabilities being released into production.

The following guidelines are a starting point for developers interesting in contributing in OpenProject to ensure they are developing secure code. We recommend to refer to the [OWASP cheat sheets](https://cheatsheetseries.owasp.org) as well as the [OWASP Top Ten](https://owasp.org/www-project-top-ten/) for the most recent and detailed guidelines. The following sections are heavily inspired and cross-referencing the well-known recommendations from the the OWASP, each section providing links for further references to generic, Rails-centered as well as OpenProject-specific information when available.

By adhering to these secure coding development guidelines, contributors to OpenProject can help to significantly reduce the risk of adding potentially unsecure code. Regardless of these guidelines, be mindful when reviewing pull requests of features touching any of these guidelines, keep security in mind whenever you write new code for OpenProject to ensure we deliver a secure and trustworthy software.

The guidelines mentioned below are implemented by OpenProject currently when not specified differently.

## Authentication and Credentials

Implement strong authentication mechanisms for any sensitive credentials to be used in OpenProject. Currently these credentials are one of:

- A user's own login and password for direct logins
- Access tokens for API, OAuth, or external integrations
- Session cookies

**Risks and Impacts**

- _Unauthorized Access:_ Attackers could gain unauthorized access on improper authentication mechanisms to protected resources, user accounts, or administrative functions. Resulting consequences are data breaches, unauthorized actions, and potential exposure of sensitive information.
- _Authentication Bypass:_ Flaws in authentication logic can permit attackers to bypass the authentication process. Resulting consequences are the same as _Unauthorized Access_.
- _Credential Theft or Stuffing:_ Weak authentication methods may lead to attackers stealing user credentials  (e.g., usernames and passwords) or reusing from credentials exploited on other services. Consequences are unauthorized access, account hijacking, and potential misuse of user accounts.
- _Brute Force Attacks:_ Insufficient protection against brute force attacks can allow attackers to guess or crack passwords. This could result in account lockouts or takeovers despite otherwise sound mechanisms.
- _Insecure Password Storage_: Storing passwords improperly (e.g., in plaintext or in outdated or incorrectly constructed cryptographic hash functions) can expose them to theft in case of data breaches. This in turn could result in a mass compromise of account data.
- _Insufficient Multi-Factor Authentication (MFA):_ Lack of MFA support makes it easier for attackers to compromise accounts with stolen credentials. This results in reduced account security and higher risk of unauthorized access.

**Guidelines**

- Ensure uniqueness and case-insensitivity of user logins.
- Use cryptographic hashes for password or credentials storage
- Allow administrators to enforce strong password policies  with a combination of characters, numbers, and special symbols. Implement password expiration and account lockout mechanisms.
- Implement mechanisms to protect against brute force attacks, such as account lockouts, rate limiting, or increasing delays after multiple failed login attempts.
- Use strong password controls and validations
- Provide secure mechanisms for account recovery, such as sending a reset link to the user's registered email address. Avoid leaking the existence of user accounts by always returning the same response.
- Provide means of auditing, maintaining detailed logs of authentication events, including successful and failed login attempts. Log sufficient information for auditing and incident response.
- Use the provided features by Rails to prevent cross-site request forgery (CSRF) attacks by utilizing anti-CSRF tokens for all state-changing requests and ensuring that authentication requests are immune to CSRF.

<a id="usage-at-openproject"></a>

**Usage at OpenProject**

OpenProject uses industry standard authentication mechanisms that follow the best practices and are the de-facto norm for many organizations:

- External authentication providers using OpenID connect protocols or SAML 2.0 protocol
- External authentication through LDAP user binds, optional LDAP user and group membership synchronization (Enterprise-Edition add-on)
- OAuth 2.0 application authentication and authorization with OpenProject acting as the authorization server. Access tokens are hashed using SHA256 in the database.
- Internal user credential authentication against passwords stored in BCrypt with a high default yet configurable cost factor depending on the organizational requirements.

<a id="usage-recommendations"></a>

OpenProject recommends these authentication mechanisms:

- All connections to and from OpenProject should be secured through TLS/SSL transport encryption. OpenProject assumes connections are secured through TLS/SSL by default in all production systems. Note that OpenProject does not provide TLS/SSL termination itself for Docker-based installations. The customer's IT department needs to configure and maintain the TLS certificates at the load balancer or proxying server before connections reach the application server.
- For any external connection (Database, LDAP, etc.), OpenProject uses openssl library for the host or container's openssl certificate store. Use your distribution's mechanisms to add verified certificate or certificate chains. For more information, see the [Ruby OpenSSL X509 Store documentation](https://ruby-doc.org/stdlib-2.4.0/libdoc/openssl/rdoc/OpenSSL/X509/Store.html).

- For smaller to medium organizations with no centralized authentication mechanism, use the internal username / password authentication mechanism for secure storing of your user's credentials using BCrypt salted cryptographic hash function.
- For organizations with a centralized and accessible LDAP server, [OpenProject provides LDAP userbind authentication](../../../system-admin-guide/authentication/ldap-connections/) to forward the authentication request to your LDAP server. Use TLS or LDAPS encrypted connections to the LDAP server to ensure transport level security. Optionally, synchronize roles and permissions using the [LDAP Group sync functionality](../../../system-admin-guide/authentication/ldap-connections/ldap-group-synchronization/).
- If your organization operates a central authentication services, it is very likely it supports one of the standard remote authentication mechanisms for single sign-on, such as [OpenID connect](../../../system-admin-guide/authentication/openid-providers/),  [SAML](../../../system-admin-guide/authentication/saml/), or [Kerberos](../../../system-admin-guide/authentication/kerberos/). Use these mechanisms to ensure a standardized and secure authentication of users without requiring the storage of any credentials at OpenProject while providing a high level of usability due to centralized logins.

**References**

- https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- https://guides.rubyonrails.org/security.html

### Session Management

As OpenProject is a web application, the web session is the central mechanism of authentication for users using the application with their browser. A secure session cookie is used to identify a user's active session.

**Risks and Impacts**

- _Session Hijacking:_ Attackers may steal or manipulate active user session identifiers, gaining unauthorized access to user accounts or sensitive areas of the application.  Resulting consequences are unauthorized access, data exposure, and potential misuse of user accounts.

- _Session Fixation:_ Vulnerabilities that allow session fixation attacks can enable attackers to set a user's session ID and take control of their session. Resulting consequences are unauthorized access, data manipulation, and session theft.

- _Improper Session Timeout:_ Inadequate session timeout settings can lead to prolonged active sessions, increasing the window and surface of opportunity for attackers. Resulting consequences are exposure to session-related attacks and unauthorized access.

- _Insecure Session Storage:_ Storing session data insecurely (e.g., in client-side storage or without proper care) can expose it to theft or tampering. Potential impacts are unauthorized data access or manipulation, data breaches, and privacy violations.

- _Insufficient Session Revocation:_ Lack of proper mechanisms to revoke or terminate user sessions can result in prolonged access for users who should no longer have it. Potential impacts are unauthorized access to protected resources and data.

- _Cross-Site Scripting (XSS) and Session Theft:_  If an application is vulnerable to XSS attacks, attackers can steal session identifiers and impersonate users.

- _Lack of Session Regeneration:_ Failure to regenerate session identifiers upon login or privilege changes can expose users to session fixation attacks.

- _Session Data Tampering:_ Inadequate session data validation and protection can lead to attackers modifying session attributes to gain unauthorized privileges.

- _Weak Session Tokens:_ Weak or predictable session token generation can make it easier for attackers to guess or brute-force session identifiers.

**Guidelines**

- Use Rails' built-in secure session cookies for maintaining the users' session. It incorporates best-practices to ensure strong session tokens, tamper resistance, and proper expiration.
- Ensure session cookies are marked `secure` and `httponly`, as well as providing the appropriate `SameSite` and expiration flags according to the instance's configuration.
- Provide a secure logout mechanism that invalidates the session and clears session cookies. Ensure that users are logged out after a period of inactivity.
- Implement session fixation protection mechanisms to prevent attackers from fixing a user's session to a known value.
- Prevent storing sensitive unencrypted session information on the client device
- Allow users to terminate sessions themselves, as well as allow instances to prevent simultaneous session logins by terminating other sessions.
- Implement strong Cross-site scripting (XSS) protections as listed further down below, as the target of XSS attacks is often exploitation of the user's session credential.

**References**

- https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html

## Authorization and Access Control

At its core, permissions in OpenProject are the central key to determine who can access which projects and modules of an instance, as well as what actions they can perform on these pages. OpenProject application uses a Role-based access control (RBAC) approach to grant individual users permissions to projects. The risks associated with security vulnerabilities in the authorization code can have serious implications for the security.

**Risks and Impact**

- _Unauthorized access_: Users gaining or exploiting access to sensitive resources or functionalities they are not supposed to have access to. Potential consequences in data breaches, unauthorized actions, and potential exposure of confidential information.
- _Over-Privileged Users_:  Users receiving more permissions than necessary for their role, leading to potential misuse of privileges. Potential consequences are unauthorized data modifications, data leaks, or abuse of system capabilities.

**Guidelines**

- Allow flexible assignment of permissions for individual projects and objects, following the _Least Privilege_ rule.
- Implement controls and authorization checks with a _Deny by default_ or _Fallback deny_ rule, preventing authorization flows to miss certain steps and allowing user requests to fall through the authorization checks.
- Validate the permissions of a user on every request, regardless of the origin of it.
- Enforce proper authorization controls to ensure that users only access their own data.
- Provide extensive tests for permission checks, making assertions of all available cases and using visibility testing for asserting that certain actors _cannot_ access data or perform actions.
- Regularly review and update access controls to reflect changes in application functionality and roles.

**References**

- https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html
- https://guides.rubyonrails.org/security.html

## User Input Validation

OpenProject is a form-driven application, meaning that users input a lot of data into the system to use it. Proper validation and encoding of user input is crucial to ensure data can be processed in a responsible way.

**Risks and Impacts**

- _Injection attacks:_ Attackers could inject malicious code or payloads into the application, leading to vulnerabilities such as SQL injection, or OS-level command injection. Potential consequences are unauthorized data access, data manipulation, and potentially complete system compromise.
- _Cross-site scripting (XSS)_: Failure to validate and sanitize user inputs can allow malicious scripts to be executed in the context of other users' browsers. Potential consequences are: Theft of sensitive user data, session hijacking, and potential defacement or compromise of the web application.
- _Cross-Site Request Forgery (CSRF):_ Lack of proper request validation can make it easier for attackers to trick users into performing unintended actions on their behalf. Potential consequences are unauthorized actions, such as account changes, data deletion, or fund transfers, performed without user consent.
- _File Upload Vulnerabilities_: Insufficient input validation on file uploads can lead to arbitrary file uploads, enabling attackers to upload malicious files or execute code. Potential consequences are remote malware distribution, and remote code execution.
- _Open Redirects_: Insufficient validation of redirect URLs leading users to external pages, which might end in phishing attacks.

**Guidelines**

- Understand and use the [Rails framework's mechanisms](https://guides.rubyonrails.org/security.html#injection) to prevent injection and CSRF attacks
- Understand and use the Rails framework to use its built-in security measures such as proper encoding of HTML output, CSRF tokens in all state-changing requests, and automatic escaping of user input in ActiveRecord SQL queries.
- Implement a strict [content security policy](https://cheatsheetseries.owasp.org/cheatsheets/Content_Security_Policy_Cheat_Sheet.html) to mitigate common XSS, CSRF and similar cross-site attack vectors. OpenProject uses the Rails framework defaults to define the CSP.
- Learn about the [different types of XSS](https://owasp.org/www-community/Types_of_Cross-Site_Scripting#stored-xss-aka-persistent-or-type-i) and their impacts: Reflected XSS, Stored XSS, Dom-based XSS and server vs client side XSS
- Implement file upload filters based on file type, and ensure user-provided files cannot be executed as code.
- Ensure transmission of confidential data does not happen through GET requests, but use POST/PUT/PATCH requests instead.

**References**

- https://guides.rubyonrails.org/security.html#injection
- https://owasp.org/www-community/Types_of_Cross-Site_Scripting#stored-xss-aka-persistent-or-type-i
- https://cheatsheetseries.owasp.org/cheatsheets/Injection_Prevention_Cheat_Sheet.html
- https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html

## Virus and Malware protection

As OpenProject may handle and distribute sensitive user data, attack vectors such as malicious user input as specified in the previous section pose a threat to the integrity, confidentiality, and availability of data. In the following, we will evaluate different risks and guidelines on the protection against viruses and other malware during operation of an OpenProject instance.

**Risks and impacts**

- _Viruses and malware uploads_: Whenever users are able to upload files to a system, potentially malicious files could be provided and distributed through OpenProject by users with the appropriate upload permission.
- _Malware in software_: OpenProject carefully selects and updates third-party dependencies. Please see the following section on [external dependencies](#external-dependencies) for more information on the best practices of external dependencies.

**Guidelines**

- Virus and malware uploads
  - OpenProject provides users with fine-grained access to control which user groups are allowed to upload files
  - Whitelist for uploads can be provided by MIME type, rejecting any non-matching files
  - OpenProject currently does not provide a built-in virus scanner. However, using [webhooks](../../../system-admin-guide/api-and-webhooks/#webhooks) and the [attachments API](../../../api/endpoints/attachments/), users can plug existing virus scanning tools and scrub any uploaded files.
- _Malware in software_:
  - OpenProject uses statical code analysis on every change provided to the application as well as code scanners on the artifacts generated from the source code (such as Snyk vulnerability scanner for Docker images).
  - We recommend users to perform their own

## Logging and Error Handling

Inconsiderate use of error handling, logging, and monitoring mechanisms of a web frameworks can lead to the following risks and impacts.

**Risks and Impacts**

- _Information Disclosure:_ Improper error handling may reveal sensitive information or internal details about the application's infrastructure. Resulting consequences are Exposure of sensitive data, such as database errors or stack traces, which can aid attackers in planning further attacks.
- _Data Leakage:_ Inadequate logging and error handling can inadvertently log sensitive user data or credentials. This may result in unauthorized access to user data, privacy violations, and compliance breaches.
- _Log Injection Attacks:_ Lack of input validation on log entries can expose the application to log injection attacks where attackers manipulate log entries to inject malicious code or content. Resulting impacts are Malicious code execution, log manipulation, and potential system compromise.

**Guidelines**

- Implement proper exception handling to catch and handle unexpected errors. Log the exceptions for further analysis.
- The application should fail in a secure manner. If an error occurs, the system should revert to a safe state that doesn't expose sensitive information or functionality.
- Use generic error messages for end users to prevent information leakage. Avoid exposing stack traces, database error messages, or any detailed system information. If providing summaries or error reports to users, make sure no sensitive data or system information is included.
- Scrub and filter user data being logged or output in error messages to prevent data leakage.
- Only log necessary information. Avoid logging sensitive data such as passwords, payment information, or Personally Identifiable Information (PII).
- Log data in a standard format to make parsing, auditing, and monitoring of that information easy.
- Ensure that actions are aborted in case of errors

**Usage at OpenProject**

- Exception handlers catch all StandardErrors whenever your controller inherits from ApplicationController
- Exception responses are disconnected from the actual errors and provide user-friendly messages without error details
- Database transaction wrapping for any actions is wrapped in the [BaseContracted services](https://github.com/opf/openproject/blob/dev/app/services/base_services/base_contracted.rb#L54). Transactions are automatically rolled back in [Rails when exceptions occur](https://api.rubyonrails.org/v5.0.1/classes/ActiveRecord/Transactions/ClassMethods.html).
- OpenProject uses a LogRage formatter for flexible, yet easily parsable formats

**References**

- https://cheatsheetseries.owasp.org/cheatsheets/Error_Handling_Cheat_Sheet.html
- https://cheatsheetseries.owasp.org/cheatsheets/Logging_Cheat_Sheet.html

## External dependencies

OpenProject includes a number of external dependencies both in Ruby as well as in the JavaScript ecosystem. Regardless of the selection of these dependencies, maintaining and keeping the dependencies up-to-date is a critical part of the security of the application. We have seen a lot of attacks surface in the past years originating from either outdated or manipulated dependencies.

**Risks**

- _Outdated code or known Vulnerabilities_: Older versions of libraries or dependencies may have publicly disclosed vulnerabilities. If these known vulnerabilities are not patched, they can be readily exploited by attackers.
- _Increased Attack Surface_: Over time, libraries can become bloated with features, some of which may not be needed in OpenProject. This increases the overall attack surface, making the application more vulnerable to potential attacks.
- _Lack of Support_: Outdated libraries may no longer be maintained. This means no more security updates, bug fixes, or support from the developer community.
- _Legacy Code and Deprecated Functions_: Outdated dependencies might utilize functions or methods that have since been deprecated or replaced without OpenProject developers being aware of that fact, leading to unreliable or unsafe code practices.
- _Reduced Performance_: Newer versions of libraries often come with performance improvements. Using outdated dependencies can lead to inefficiencies or bottlenecks in the application.
- _Increased maintenance burden_: With a rising number of dependencies that are outdated or unmaintained, providing a secure upgrade path becomes harder due to e.g., newer versions of Rails or Ruby no longer being compatible with the gem or package in question.
- _Chain of Dependencies_: Some dependencies rely on other dependencies. Using an outdated library might cause a cascading effect where multiple parts of your application become outdated and vulnerable. Also, selection of dependencies is important to minimize attack vectors. Every platform handles this differently.

**Guidelines**

- _Automate Updates_: Use and maintain automated tools such as Dependabot and workflows that check for dependency updates regularly, and run tests when updates are available. Before updating the dependencies, review its changelog or release notes to understand changes and potential impacts on your application.
- _Manual update checking:_ For pinned versions, use `npm outdated`, `bundle outdated` or `npm-check-updates` to ensure you stay on top of new versions and see if breaking changes occurred.
- _Lockfile integrity_: Use `package-lock.json` and `Gemfile.lock` to pin exact version for a released version of OpenProject, ensuring that all environments use the same versions.
- _Stay Informed_: Subscribe to mailing lists, newsletters, or vulnerability databases to receive timely information on crucial updates or security patches so that updates can be performed as fast as possible.
- _Vet new dependencies_: Before adding a new gem or package, research its maintenance history, last update, known vulnerabilities, and community reviews. Check if it's actively maintained, and evaluate all the alternatives.
- _Remove outdated dependencies_ :Only include gems and packages that are absolutely necessary for your project. Less dependencies mean a reduced attack surface. Remove libraries if they become unused.

**References**

- https://cheatsheetseries.owasp.org/cheatsheets/Vulnerable_Dependency_Management_Cheat_Sheet.html

## Packaging and containerization

Packaging and containerization are critical artifacts in the delivery pipeline of OpenProject. They encapsulate the application and its environment, ensuring consistent operation across different systems and infrastructures. These artifacts need to provide a secure and stable default for maintaining and upgrading OpenProject.

Properly managed packaging and containerization pipelines ensure smooth installations, upgrades, and scaling, enhancing the deployment process and - as a result - the overall user experience. This section highlights risks connected to improper containerization or packaging as well as our main objectives and  best practices to provide a secure, efficient, and reliable software delivery process.

OpenProject provides several installation mechanisms:

- [Packaged installations](../../../installation-and-operations/installation/packaged/) using the distribution's package manager for dependency control

- [Slim and all-in-one docker images](../../../installation-and-operations/installation/docker/) for manual operation with docker

- [OpenProject helm chart](../../../installation-and-operations/installation/helm-chart/) , as a "package" for kubernetes clusters

**Risks and Impact**

- _Security Vulnerabilities_: Containers may inherit vulnerabilities from base images or packages.
- _Update Management_: Inability to provide an easy and fast upgrade may lead to installations remaining outdated and as a result, vulnerable to known exploits.
- _Configuration Drift_: Variations in configurations across different environments can lead to unexpected behaviors. They also make documentation of these variations harder, and lead to confusion for administrators and users.
- _Resource Utilization_: Inefficient containerization can lead to excessive resource usage or an unstable software.
- _Dependency conflicts_: Heterogenous installations may result in dependency conflicts or incompatibilities when using packages for installations.
- _Orchestration Complexity_: With more dependencies and services, deployments add complexity that can introduce errors in service discovery, networking, and persistence.
- _Compliance and Compatibility_: Ensuring that packaging and containerization meet known regulatory compliance requirements and are compatible with commonly used platforms.

**Guidelines**

- _Use Immutable Tags_: Provide specific, immutable tags for Docker images and fixed packaged versions to ensure consistency and provide clear upgrade paths instead of automatically pulling the latest image
- _Scan for Vulnerabilities_: Regularly scan container images for vulnerabilities and promptly update them. On top of statical code analysis for code and dependencies (see above), OpenProject uses Snyk and Docker scout for its public docker images to be informed of which vulnerabilities exist in the base images.
- _Minimal base Images_: Use minimal base images for Docker containers to reduce the attack surface. OpenProject currently uses a `ruby-${version}-${debianversion}` image as its base.
- _Configuration Management_: Ensure configuration management is consistent between deployments. OpenProject provides an interface to ENV-based configuration for packages and Docker to ensure both can be configured similarly. Where necessary, different configuration mechanisms are documented for the different installation mechanisms.
- _Resource Limits_: Set resource limits and requests in container definitions to prevent resource contention. The packaged installation provides a set of default scaling services. The OpenProject helm-charts define limits and resource requirements in the helm values.
- _Monitor and Logging_: Implement robust monitoring and logging to track the health and performance of containers. [OpenProject provides individually pluggable health checks for various services as well as flexible logging](../../../installation-and-operations/operation/monitoring/).
- _Continuous Integration/Continuous Deployment (CI/CD)_: Automate the building, testing, and deployment of containers using CI/CD pipelines. OpenProject builds `dev` containers and packages for every change to the core application.
- _Documentation_: Maintain comprehensive documentation for installation and configuration processes across different mechanisms. OpenProject documents all changes as part of the standard development workflow. Documentation is released together with OpenProject to ensure consistency. [The documentation workflow is part of the product development handbook.](../../product-development-handbook/)

**Artifact integrity and attestations**

OpenProject publishes signed and attested container images so that consumers and operators can verify the origin and integrity of the delivery artifacts before deployment:

- All public images are signed using [Sigstore cosign](https://github.com/sigstore/cosign) with keyless (OIDC) signing, allowing consumers to cryptographically verify that an image was built and published by OpenProject.
- Each image carries signed attestations:
  - a **Release attestation** documenting build provenance, including the source package, build workflow, git ref, commit SHA, actor and timestamp
  - a **Software Bill of Materials (SBOM)** in CycloneDX 1.6 format listing all components contained in the image
  - a **Vulnerability Exploitability eXchange (VEX)** document in CycloneDX 1.6 format describing the exploitability status of known vulnerabilities in the image
  - the same VEX in **OpenVEX 0.2.0** format, which is the format Docker Scout expects
- The VEX triage is written primarily as CycloneDX, the other format is a conversion of that original. When in doubt, use the CycloneDX attestation.
- The OpenVEX document is also embedded in the image filesystem and published as an OCI referrer, so a scanner can apply the triage directly from the image.
- Vulnerability scanning is VEX-aware: the automated Docker Scout scan (see [Security tests](../../testing/#security-tests)) applies the VEX so it reports the vulnerabilities that actually affect OpenProject rather than raw CVE counts. Findings never fail the build; unresolved critical and high findings are reported to the security team.
- The images are immutable delivery artifacts and are subject to static analysis and vulnerability scanning before and during the build (see above). Operators can verify the signatures and attestations before deployment, see [Verifying image integrity and provenance](../../../installation-and-operations/installation/docker/#verifying-image-integrity-and-provenance).

**Protecting source files at runtime**

The OpenProject source code is included inside the application container image as part of the runtime artifact, but is not intended to be retrievable through the web application. Requests are served through the application server and any ingress or reverse proxy in front of it, which only expose the application's HTTP endpoints. Preventing direct retrieval of source files, configuration files, secrets and runtime directories - for example through correct web server configuration, file permissions and volume mounts - is the responsibility of the operator deploying and running OpenProject.
