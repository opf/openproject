---
sidebar_navigation:
  title: Enterprise Cloud Guide
  priority: 999
description: OpenProject Enterprise Cloud Edition guide.
robots: index, follow
keywords: Cloud Edition
---
# Enterprise cloud edition guide

Welcome to the OpenProject **Enterprise cloud edition guide**.

![image-20200113133750107](image-20200113133750107.png)

<div class="alert alert-info" role="alert">
**Note**: This guide only describes the cloud management part of OpenProject. The feature descriptions are included at the respective parts in the OpenProject [user guide](../user-guide/#readme).
</div>

## Overview

| Topic                                                        | Content                                                      |
| ------------------------------------------------------------ | :----------------------------------------------------------- |
| [Create a free trial](./create-trial-installation)           | Learn more about how to create a free trial for the Enterprise cloud instance. |
| [Sign in](./sign-in/)                                        | Sign in to your OpenProject Enterprise cloud edition.        |
| [Create a quote](./create-quote-cloud)                       | How to create a quote within your Enterprise cloud instance? |
| [View payment history or download invoices](./invoices-and-billing-history) | How to see your payment history and download invoices?       |
| [Upgrade, downgrade or cancel subscription](./manage-subscription) | How to upgrade your plan, downgrade or cancel your subscription for the Enterprise cloud edition? |
| [Manage your subscription](./manage-subscription)            | How to change billing address, add or edit credit card details? |
| [Backups](./backups)                                         | How do backups work in the cloud?                            |
| [GDPR and DPA](./GDPR)                                       | Review and sign a Data Processing Agreement (DPA)            |

The OpenProject Enterprise cloud edition contains all OpenProject Community features plus the additional OpenProject premium features, as well as professional support.

For the Enterprise cloud edition the OpenProject experts will take care of the installation as well as maintenance of your OpenProject installation, so you will be able to concentrate on your core business. We will perform regular backups of your Enterprise cloud edition. You will have the latest OpenProject release installed. Hence, you do not have to take care of updates or installation of security patches yourself.

Please find a detailed feature comparison [here](https://www.openproject.org/pricing/#features).



## Frequently asked questions - FAQ

### How can I book additional users for the Enterprise cloud?

You can do this in your subscription. Please have a look at [this instruction](./manage-subscription/#upgrade-or-downgrade-subscription).

### Can I import my OpenProject community instance into my Enterprise cloud environment?

Yes, we provide an upload possibility of your data to move from a Community installation to the Enterprise cloud edition.
To import your community instance into our cloud environment, please send us the following files:
1. the database SQL dump of your local installation
2. the attachments of your local installation For a package-based installation, you can create both as root user on your environment as follows openproject run backup
This creates the attachment and postgresql-dump or mysql-dump under /var/db/openproject/backup.
If you are still running OpenProject under MySQL, your dump will be converted to PostgreSQL before importing, we will do this for you. More information about the backup tool can be found under this [link](https://www.openproject.org/operations/backup/backup-guide-packaged-installation/).
Before uploading the attachments securely to us using the [following form](https://openproject.org/saas-import), please contact us via support@openproject.com.
The form generates a direct upload to our secure S3 environment from which the import takes place.


### Where geographically is the OpenProject Enterprise cloud data stored?

The OpenProject Enterprise cloud environment is hosted on a logically isolated virtual cloud at Amazon Web Services with all services being located in Ireland. AWS is a GDPR compliant cloud infrastructure provider with extensive security and compliance programs as well as unparalleled access control mechanisms to ensure data privacy. Employed facilities are compliant with the ISO 27001 and 27018 standards. OpenProject Enterprise cloud environment is continuously backing up user data with data at rest being fully encrypted with AES-256. Each individual's instance is logically separated and data is persisted in a unique database schema, reducing the risk of intersection or data leaks between instances. You can find more information [here](https://www.openproject.org/gdpr-compliance/).


### Does OpenProject comply with GDPR?

The protection of personal data is for OpenProject more than just a legal requirement. We are highly committed to data security and privacy. We are a company based in Berlin, the European Union, and the awareness and importance for data security and privacy actions have always been a major topic for us. OpenProject complies with GDPR and we handle our customer’s data with care. Get more detailed information [here](https://www.openproject.org/gdpr-compliance/).


### How can I export the documents loaded on OpenProject?

Currently, there is unfortunately no option to export all the documents in OpenProject. We could manually export the entire database (including the attachments) for you. Due to the manual effort, we would however need to charge a service fee for this. Please contact sales@openproject.com.


### Can I create a custom domain name instead of example.openproject.com?

Yes, you can create your custom domain name. For this service we charge €100 once-off. Please add it in your booking process (will soon be available) or contact us via email (support@openproject.com).

### Is it possible to access the PostgreSQL tables (read-only) on a hosted OpenProject instance via ODBC or another protocol (e.g. to extract data for PowerBI)?

Access to the database (including the PostgreSQL tables) is restricted for the Enterprise cloud edition due to technical and security reasons. Instead, you can use the OpenProject API to both read and write data (where supported): https://docs.openproject.org/api. If you require direct database access, you may want to take a look at the OpenProject Enterprise on-premises edition which you can run on your own server: https://www.openproject.org/enterprise-edition.