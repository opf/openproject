---
sidebar_navigation:
  title: Statement on security
  priority: 600
description: Statement of data security in OpenProject
keywords: GDPR, data security, security, OpenProject security, security alerts, single sign-on, password security, mailing list, vulnerability, responsible disclosure, bug bounty, supply chain security, SBOM, VEX, image signing, cosign, attestation
---

# Statement on security

At its core, OpenProject is an open-source software that is [developed and published on GitHub](https://github.com/opf/openproject). Every change to the OpenProject code base ends up in an open repository accessible to everyone. This results in a transparent software where every commit can be traced back to the contributor.

Automated tests and manual code reviews ensure that these contributions are safe for the entire community of OpenProject. These tests encompass the correctness of security and access control features. We have ongoing collaborations with security professionals to test the OpenProject code base for security exploits.

For more information on security and data privacy for OpenProject, please visit: [www.openproject.org/security-and-privacy](https://www.openproject.org/security-and-privacy/).

**security.txt**

OpenProject uses the `security.txt` standard for defining security policies.
You can find our `security.txt` here: [www.openproject.org/security.txt](https://www.openproject.org/security.txt)

Please see [securitytxt.org](https://securitytxt.org/) for more information.

## Communication channels

### Security announcements mailing list

If you want to receive immediate security notifications via email as we publish them, please sign up to our [security mailing list](https://www.openproject.org/security-and-privacy/#mailing-list).

No messages except for security advisories or security related announcements will be sent there.

To unsubscribe, you will find a link at the end of every email.

Any security related information will also be published in the [release notes](../../release-notes/) and as [GitHub Security Advisories](https://github.com/opf/openproject/security/advisories).

### Security advisory list

OpenProject uses GitHub to manage and publish [security advisory listings](https://github.com/opf/openproject/security/advisories). All publicly known security issues on OpenProject with at least a medium CVSS score are reported as CVEs and can be found through these advisories. All published CVEs will also be listed on [cve.org](https://www.cve.org/CVERecord/SearchResults?query=OpenProject).

### Email

Next to GitHub advisories, you may also directly reach out to the security team via email using [security@openproject.com](mailto:security@openproject.com).

## Reporting a vulnerability

We take all facets of security seriously at OpenProject. If you want to report a security concern, have remarks, or contributions regarding security at OpenProject, please reach out to us at [security@openproject.com](mailto:security@openproject.com).

If you can, please send us a PGP-encrypted email using the following key:

- Key ID: [0x7D669C6D47533958](https://keys.openpgp.org/vks/v1/by-fingerprint/BDCFE01EDE84EA199AE172CE7D669C6D47533958),
- Fingerprint `BDCF E01E DE84 EA19 9AE1 72CE 7D66 9C6D 4753 3958`
- You may also find the key [attached in our OpenProject repository.](security-at-openproject.com.asc)

You can also [report a vulnerability directly in GitHub](https://github.com/opf/openproject/security/advisories/new), if you prefer. When in doubt, please _also_ send an informal email to [security@openproject.com](mailto:security@openproject.com) with the link to the advisory. The advisories allows us to communicate and collaborate privately with you, and it will remain private until we publish the vulnerability.

### What to include in a report

To help us validate and address the issue efficiently, your report should include:

- A general description of the vulnerability
- Details about the impacted function and specific conditions to be met, including the vulnerable code snippet (if applicable)
- The impacted version of OpenProject
- Step-by-step instructions to reliably reproduce the issue
- Screenshots, videos, logs, or other evidence demonstrating the full exploitation
- The security impact on the application, its users, and the organization
- Recommendations and fix suggestions (optional, but appreciated)

Providing clear reproduction steps is essential. Reports that lack sufficient detail for us to validate the issue may take significantly longer to process.

### Responsible disclosure and testing policy

Please adhere to the following rules when reporting or researching security issues:

- **Only test your own instances**: Targeting other users' instances is forbidden. Only test against your own OpenProject installation. If you need additional testing instances or other data from us, feel free to reach out.
- **No public disclosure without agreement**: No vulnerability disclosure, full, partial, or otherwise, is allowed without prior agreement from us. Please avoid submitting security issues on our public repositories before reporting them through the proper channels.
- **Redact sensitive data**: Do not include Personally Identifiable Information (PII) in your report. Redact or obfuscate PII, secrets, keys, and credentials that appear in screenshots, server responses, or other evidence.
- **Human interaction required:** Please do not report unchecked and obvious AI-generated reports, or we may have to close them without further comments.

## Criteria for security vulnerabilities

We appreciate your time in every security report you communicate to us. There are a number of cases that can be viewed as security vulnerabilities, but for which we might either reject or not follow up with a full CVE publication. We still welcome you to reach out and discuss potential mitigations or attack vectors with us. Examples for these cases could be

- Outdated versions of OpenProject. Please ensure you have confirmed the vulnerability against the **latest stable** version of OpenProject. If you have found new issues as part of the unreleased `dev` branch, of course please also contact us for that.
- Tab nabbing
- Content/text injections that do not result in an XSS attack due to other mitigations
- Denial of service attacks through memory exhaustion, content size, or similar measures
- Race conditions for business logic constraints (e.g., duplicating unique names through timing attacks) without further impact
- HTML injection in formattable content (e.g., links, images) that duplicates what Markdown already allows. Formattable content is sanitized, and reports need to demonstrate impact beyond basic HTML injection
- Clickjacking / UI redressing due to inline CSS styles being allowed in certain formattable places.
- Recently disclosed CVEs (less than 30 days since patch release) for third party libraries
- Presence of autocomplete attribute on web forms
- Vulnerabilities affecting outdated browsers or platforms
- Hypothetical flaws or best practice recommendation without an exploitable vulnerability and proof of concept
- Reports with attack scenarios requiring MITM or physical access to the victim's device
- Disclosure of information without exploitable vulnerabilities (e.g., stack traces, path disclosure, directory listings, software versions, IP disclosure, third-party secrets, EXIF metadata, origin IP)
- Blind SSRF without exploitable vulnerabilities and proof of concept (e.g., DNS and HTTP pingback)
- Ability to spam users (email, SMS, or direct message flooding)
- Exploits that rely on a voluntarily downgraded configuration, or on not-recommended security settings
- Stolen secrets, credentials, or information gathered from a third-party asset outside our control

## Severity assessment

The severity of security issues is assessed on a case-by-case basis by our security team using the [CVSS v3.1 calculator](https://nvd.nist.gov/vuln-metrics/cvss/v3-calculator). We consider both the potential impact (e.g., a vulnerability affecting all users is more severe than one requiring specific conditions) and the difficulty to exploit (e.g., a vulnerability requiring administrator access or advanced permissions is less severe than one exploitable by unauthenticated users).

As a general guideline:

- **Critical**: Vulnerabilities with a high CVSS score that can be exploited remotely with no or low privileges, no user interaction, and high impact on confidentiality, integrity, or availability.
- **High**: Vulnerabilities with significant impact but that require some privileges, user interaction, or have high attack complexity.
- **Medium/Low**: Vulnerabilities with limited impact or that require high privileges, unusual configurations, or active user interaction to exploit.

## Security vulnerability processing

When we receive vulnerability reports from researchers or through internal identification, the following process takes place:

1. A security vulnerability is reported internally, through GitHub advisories, an active bug bounty program, or through [security@openproject.com](mailto:security@openproject.com).
2. A security engineer receives and validates the report. An internal tracking ticket is created.
3. The reporter receives a timely response with an acknowledgement of the report, further questions if present, and an estimated timeline and complexity of a potential fix.
4. The security engineer coordinates with the security and development teams to prepare and test a fix.
5. A GitHub advisory draft is created or updated, if appropriate. Security researchers are invited to collaborate on the draft, if available.
6. If possible, a patch or fixed version is provided to the reporter for feedback and confirmation.
7. For critical and high-severity issues, a **pre-release notification** is sent to the security mailing list at least **3 business days** before the planned release, including the release date, time and severity of the fixed vulnerability (but no vulnerability details).
    - This information will include the current releases an upgrade will be available for.
    - For security fixes deemed critical, we will attempt to provide fixes for the newest versions of the last two minor releases.
    - Generally, OpenProject only supports the **latest stable** release. Please consult your enterprise contract or our [terms of services](https://www.openproject.org/legal/terms-of-service/) for details.
8. A patch release is created, published, and distributed for all supported installations.
    - When the release contains fixes for **high** or **critical** vulnerabilities, the release notes will mention this, but will not contain any details about the vulnerabilities yet.
9. The security mailing list is notified of the release with upgrade guidance when the releases are available.
10. The advisory with full details and full release notes are published and if needed, a CVE is requested
    - for **low** and **medium** vulnerabilities: with the release.
    - for **high** and **critical** vulnerabilities: 24 hours after the release.

### How long does it take to fix a security issue?

We fix **critical** and **high** vulnerabilities as soon as possible, and at the latest **14 calendar days** after we confirm the vulnerability. The fix will be made available as a patch release of the latest stable version of OpenProject according to the process steps outlined earlier.

A vulnerability is confirmed when our security team has reproduced it on the latest stable version of OpenProject and has assessed its severity. We assess the severity with CVSS for a default installation of OpenProject. This severity can be different from the severity in the report. For example, the severity can be lower when an attack needs a non-default configuration, administrator privileges, or conditions outside of OpenProject. If we decide that the reported behavior is not a vulnerability (see [cases we might reject](#criteria-for-security-vulnerabilities)), no fix timeline applies. In all cases, we communicate openly with the reporter about our decision and the reasons for it.

If a complete fix needs more than 14 days, for example because it needs larger changes, we tell the reporter before the 14 days end. In that case, we provide a mitigation or workaround within the 14 days, and give a new date for the complete fix.

### When is a security issue considered fixed?

A security issue is considered fixed when a release with a fix for the vulnerability has been released and the advisory and/or CVE have been published.

### Security vulnerabilities in external dependencies

Like every modern software product, OpenProject depends on libraries and when security vulnerabilities are discovered in those libraries, we learn about them once they are publicly disclosed. When a dependency publishes a **high** or **critical** vulnerability we attempt to release a version of OpenProject with a fixed version of that library within **7 business days**, if the vulnerability can actively be exploited in OpenProject.

For our main dependencies, we are actively monitoring their security mailing lists or release channels. We have [Dependabot](https://docs.github.com/en/code-security/tutorials/secure-your-dependencies/dependabot-quickstart) enabled on our repositories so security updates in our dependencies are actively being pushed into the repository.

### Pre-release notification

For critical and high-risk vulnerabilities with clear attack vectors, and immediate action to be taken by administrators, subscribers of our [security mailing list](#security-announcements-mailing-list) will receive a pre-release notification at least **3 business days before** the security release. This notification will include the planned release date, time and the severity of the issue, but will not include vulnerability details or patches. This gives administrators time to schedule maintenance windows and prepare for an upgrade.

### Public disclosure

Because OpenProject is open source, every fix merged into our public repository is visible to anyone. Fixes for **high** and **critical** vulnerabilities are therefore developed in a private fork and merged into the public repository only right before the release is built. From then until the advisory is published, the fix is public and the vulnerability could be deduced from it. This window is inherent to open-source development, and we keep it as short as possible.

The timing of the disclosure depends on the severity of the fixed vulnerabilities. Details of **low** and **medium** vulnerabilities are disclosed simultaneously with the patch release. Details of **high** and **critical** vulnerabilities are disclosed 24 hours after the patch release, giving administrators a head start to upgrade before the details become public.

For releases with only **low** and/or **medium** fixes:
- The GitHub security advisory and full vulnerability details are published **at the same time** as the patch release.
- If a CVE is requested, this happens when the security advisory is published.
- The security mailing list is notified immediately upon publication.
- Fixed security issues will appear in the corresponding release notes.

For releases with **high** and **critical** fixes:
- The GitHub security advisory and full vulnerability details are published **24 hours after** the patch release and a CVE will be requested.
- The security mailing list is notified when the release is published. We do not notify the list again after the details have been published. Interested parties are encouraged to check the [release notes](../../release-notes/) or [GitHub Security Advisories](https://github.com/opf/openproject/security/advisories).
- Initially, the release notes will only mention that vulnerabilities have been fixed. Full release notes will be amended when the security advisory is published.

## Bug bounty program

Please note that OpenProject does not currently offer its own bug bounty program. For any security vulnerability you responsibly disclose to us, whether through another bug bounty program or through our website, we will do our best to give you appropriate credit. We will gladly reference your work, name, and website on every publication we make related to the security update.

## Software supply chain security

OpenProject secures the software it delivers, not only the source code it is built from. Every container image published to Docker Hub is a signed, immutable artifact whose origin and contents can be verified before deployment.

- **Signed images and attestations**: images are signed with [Sigstore cosign](https://github.com/sigstore/cosign) using keyless (OIDC) signing. Each image carries signed attestations describing its build provenance (in-toto release attestation), a Software Bill of Materials (SBOM, CycloneDX 1.6) listing every component, and a Vulnerability Exploitability eXchange (VEX) document, published in both CycloneDX 1.6 and OpenVEX 0.2.0.
- **Continuous vulnerability scanning**: published images are scanned automatically with [Docker Scout](https://www.docker.com/products/docker-scout/), including a daily re-scan of the development and release-candidate images against the latest vulnerability data, so newly disclosed issues are detected quickly. The scan applies the VEX triage, so results reflect the vulnerabilities that actually affect OpenProject. Unresolved critical and high findings are reported to the security team and handled through the process described above.
- **Transparent exception documentation**: the exploitability assessment for each known vulnerability is published in the VEX documents, so operators and auditors can see why a given CVE is or is not considered exploitable in OpenProject.

Operators can verify the signatures, read the SBOM, and reproduce the scan by following [Verifying image integrity and provenance](../../installation-and-operations/installation/docker/#verifying-image-integrity-and-provenance). The build-pipeline details are described in the [secure coding guidelines](../../development/concepts/secure-coding/#packaging-and-containerization).

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

Synchronize OpenProject users and groups with your company's LDAP to update users and group memberships based on LDAP group members.

### Single sign-on

With the single sign-on feature you can securely access OpenProject. Control and secure access to your projects with the main authentication providers.

Find out more about our [GDPR compliance](../../enterprise-guide/enterprise-cloud-guide/gdpr-compliance/).
