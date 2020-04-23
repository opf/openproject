---
sidebar_navigation:
  title: Cloud Edition
  priority: 999
description: OpenProject Cloud Edition guide.
robots: index, follow
keywords: Cloud Edition
---
# Cloud Edition guide

Welcome to the OpenProject **Cloud edition guide**.

![image-20200113133750107](image-20200113133750107.png)

<div class="alert alert-info" role="alert">
**Note**: This guide only describes the cloud management part of OpenProject. The feature descriptions are included at the respective parts in the OpenProject [user guide](../user-guide/#readme).
</div>

## Overview

| Popular Topics                                               | Description                                                  |
| ------------------------------------------------------------ | :----------------------------------------------------------- |
| [Create a free trial](./create-trial-installation)           | Learn more how to create a free trial for the cloud instance. |
| [Sign in](./sign-in/)                                        | Sing in to your OpenProject Cloud Edition.                   |
| [View payment history or download invoices](./invoices-and-billing-history) | How to see your payment history and download invoices?       |
| [Upgrade, downgrade or cancel subscription](./manage-subscription/#update-existing-subscriptions) | How to upgrade your plan, downgrade or cancel your subscription for the Cloud Edition? |
| Manage your subscription                                     | How to change billing address, add or edit Credit Card details? |

The OpenProject Cloud Edition contains all OpenProject Community features plus the additional OpenProject premium features, as well as professional support.

For the Cloud Edition the OpenProject experts will take care of the installation as well as maintenance of your OpenProject installation, so you will be able to concentrate on your core business. We will perform regular backups of your Cloud Edition. You will have the latest OpenProject release installed. Hence, you do not have to take care of updates or installation of security patches yourself.

You will get a detailed feature comparison [here](https://www.openproject.org/pricing/#features).



## Frequently asked questions - FAQ 



### **Can I import my** **OpenProject** **community instance into my cloud environment?**

Yes, we provide an upload possibility of your data to move from a Community installation to the Cloud Edition.To import your community instance into our cloud environment, please send us the following files:1. the database SQL dump of your local installation2. the attachments of your local installation For a package-based installation, you can create both as root user on your environment as follows openproject run backupThis creates the attachment and postgresql-dump or mysql-dump under /var/db/openproject/backup.If you are still running OpenProject under MySQL, your dump will be converted to PostgreSQL before importing, we will do this for you. More information about the backup tool can be found under this link: https://www.openproject.org/operations/backup/backup-guide-packaged-installation/Before uploading the attachments securely to us using the following form, please contact us via support@openproject.com:https://openproject.org/saas-importThe form generates a direct upload to our secure S3 environment from which the import takes place. 



### Is there an advantage of the annual over the monthly** **OpenProject** **plan?**

We offer two months of the cloud edition for free if you choose an annual plan.



### Where geographically is the** **OpenProject** **cloud data stored?**

OpenProject cloud environment are hosted on a logically isolated virtual cloud at Amazon Web Services with all services being located in Ireland. AWS is a [GDPR compliant](https://aws.amazon.com/compliance/gdpr-center/) cloud infrastructure provider [with extensive security and compliance programs](https://aws.amazon.com/security/) as well as unparalleled access control mechanisms to ensure data privacy. Employed facilities are compliant with the ISO 27001 and 27018 standards. OpenProject cloud environment is continuously backing up user data with data at rest being fully encrypted with AES-256.  Each individual instance is logically separated and data is persisted in a unique database schema, reducing the risk of intersection or data leaks between instances.[ https://www.openproject.org/gdpr-compliance/](https://www.openproject.org/gdpr-compliance/) 



### Is there a size limit for uploading documents to the** **OpenProject** **cloud edition?**

There is no limit in OpenProject in terms of the number of files that you can upload and work with in OpenProject. There is only a restriction in terms of the maximum file size: A file can have a size up to 256 MB. 



### My OpenProject cloud trial expired – can I still access my data?**

Due to data privacy reasons we automatically delete OpenProject trial environments a couple of weeks after they have expired.If your OpenProject Trial is not accessible through the known URL, it has likely been deleted.You can easily create a new OpenProject trial environment from https://start.openproject.com/. Simply enter your organization name (you can use the same name as before) and click on "Start Free Trial".In order to avoid that your data is getting deleted, please select a plan during your trial duration or shortly after your OpenProject trial environment has expired. 



### Can we pay the** **OpenProject** **cloud edition by transfer?**

Yes, for customers in the EU it is possible to pay by bank transfer (as well as by credit card).To do this, you can sign into your OpenProject environment and select the "Buy now" button from the top menu. You are then directed to the payment page, where you can select the number of users you want to work with and your country. Then you can check the option to pay by invoice and fill out the billing information. You will then receive an invoice from us. 