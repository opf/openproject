---
sidebar_navigation:
  title: GDPR
  priority: 600
description: GDPR, DPA, AV
keywords: GDPR, DPA, Data Processing Agreement, AVV, AV
---

# GDPR

The General Data Protection Regulation (GDPR) is a European regulation to harmonize the rules within the EU for handling personal  data of private companies or public organizations. The GDPR also extends this EU data protection regulation law to all foreign companies  processing data of EU residents. The GDPR compliance is self-evident for OpenProject.

As a firm believer in open-source, OpenProject is invested heavily in the freedom of users. This encompasses the software freedoms granted by the [GPLv3](https://www.gnu.org/licenses/quick-guide-gplv3.en.html) and employed by OpenProject and naturally extends to the rights and  freedoms granted by the General Data Protection Regulation (GDPR). In  the same transparent fashion that we develop our software, we are  committed to transparency regarding data privacy protection of our users.

## Information Security and Compliance

### Hosting infrastructure

OpenProject cloud environment is hosted on a logically isolated virtual cloud at Amazon Web Services with all services being located in Europe. AWS is a [GDPR compliant](https://aws.amazon.com/compliance/gdpr-center/) cloud infrastructure provider [with extensive security and compliance programs](https://aws.amazon.com/security/) as well as unparalleled access control mechanisms to ensure data privacy. Employed facilities are compliant with the ISO 27001 and 27018 standards.

**Hosting in Germany (on request)**

We offer secure hosting of your OpenProject cloud also in a German data center on request. Please [contact us](https://www.openproject.org/contact/).

### Data backups and https encryption

OpenProject cloud environment is continuously backing up data with data encrypted in transit (via TLS/https) and at rest (files, database (including backups) via AES-256). Each individual instance is logically separated and data is persisted in a unique database schema, reducing the risk of intersection or data leaks between instances.

### Access to data and infrastructure

Production infrastructure is accessible only for a strict set of authorized system operations personnel from a secure internal maintenance VPN. Services employed by employees are secured by Two-factor-authentication where available. Access to customer data is performed only when requested by the customer (i.e., as part of a support or data import/export request).

All OpenProject GmbH employees employ industry standard data security measurements to secure their devices and access to cloud and on-premises infrastructure. All sensitive user data on laptops and workstations are encrypted and machines are maintained to receive system updates.

## Data Management and Portability

The GDPR includes grants to every data subject the right to access, modify, receive, and delete their own data.

OpenProject customers with admin accounts on their instance act as data controllers for their team members and have elaborate means to perform these request on behalf of the data subjects they are responsible for.

We detail some of these rights of the data subject in the following segments.

### Right to Access and Rectification

With OpenProject, data controllers have fine-grained user and rights management to perform these requests. Individual data subjects can forward any request to their responsible data controller of their information.

The following resources provide additional information:

- [Managing accounts and users in your instance](../../../system-admin-guide/users-permissions/) (for data controllers).

### Right to Erasure (“Right to be forgotten”)

OpenProject provides means to fully erase both all identifiable information of a user from the application. If the user is still referenced from data within the instance, these references are replaced with an anonymous user to ensure the data integrity of the application.

- Data controllers can perform the deletion [through the administration](../../../system-admin-guide/users-permissions/users/).

- Depending on the configuration of your OpenProject instance, individual data subjects may perform the deletion of their own account through the [Delete Account](../../../user-guide/my-account/) page. If this is disabled, the request may be stated to the data controller.

### Data Portability

OpenProject provides means to data controllers in order to receive *all* personal data connected to the OpenProject instance. This encompasses all user and system data (in the form of an SQL dump) as well as a collection of all uploaded files.
This is now possible by controllers on their own using the [backup feature of OpenProject](../backups/).

## Signing a Data Processing Agreement (DPA) for the Enterprise cloud

For EU customers it is required by the GDPR to sign a data processing agreement (sometimes called data processing addendum) before using our Enterprise cloud edition.

With OpenProject 11.1, we have automated this process in order to reduce manual  effort on both sides. This way, it is even easier to comply with GDPR.  

Please navigate to -> Administration -> GDPR and you can now online review and sign your DPA document directly within the application.

![OpenProject DPA](DPA.png)

Find out more about [OpenProject's security features](../../../security-and-privacy/statement-on-security/#openproject-security-features).
