---
sidebar_navigation:
  title: Enterprise cloud FAQ
  priority: 001
description: Frequently asked questions regarding Enterprise cloud
keywords: Enterprise cloud, FAQ, cloud edition, hosted by OpenProject
---

# Frequently asked questions (FAQ) for Enterprise cloud

## How can I test the Enterprise cloud version?

Simply create a 14 days free trial on: [start.openproject.com](https://start.openproject.com/). Enter your organization name in small letters, without spaces (e.g. openproject) and press the blue Start Free Trial button.

## How can I book additional users for the Enterprise cloud?

You can do this in your OpenProject instance in the administration. The number of users can be increased in steps of 5. Find out [here](../manage-cloud-subscription/#upgrade-or-downgrade-subscription) how to change the number of users in your system administration. A reduction in the number of users takes effect at the beginning of the next subscription period.

## How can I change my payment details (e.g. new credit card)?

Please have a look at [this instruction](../manage-cloud-subscription/) for the Enterprise cloud edition to change your payment details.

## Does OpenProject comply with GDPR?

Yes. The protection of personal data is for OpenProject more than just a legal requirement. We are highly committed to data security and privacy. We are a company based in Berlin, the European Union, and the awareness and importance for data security and privacy actions have always been a major topic for us. OpenProject complies with GDPR and we handle our customer’s data with care. Get more detailed information [here](https://www.openproject.org/security-and-privacy/).

## Is the Enterprise cloud certified?

The data center (AWS) we use for Enterprise cloud edition is ISO27001 certified.

For more information please visit the [information regarding security measures](https://www.openproject.org/legal/data-processing-agreement/technical-and-organizational-data-security-measures) on our website.

## How to change the OpenProject Enterprise cloud creators account?

Users (who are administrators) can change email addresses and accounts of other users, but not their own account. Single administrators can change their own account/email address by creating a second administrator account and using the new administrator to change data of the first administrator. The second administrator could be deactivated again afterwards by the first administrator. Normal users CAN change their own email address, just not their login.

## Does OpenProject employ sub-processors for the OpenProject Enterprise cloud edition from outside the EU?

A list of all sub-processors used in the OpenProject Enterprise cloud can be found [here](https://www.openproject.org/legal/data-processing-agreement/sub-processors/).

Please note: For the OpenProject Enterprise cloud we currently have two SaaS infrastructures:

**OpenProject.com**

This infrastructure is hosted at AWS in Dublin. For sending transactional emails we use the service Postmark which is based in the US.

**OpenProject.eu (beta)**

Starting from April 2022, we will also offer hosting of the OpenProject Enterprise cloud in our new SaaS infrastructure *OpenProject.eu*. In this new environment there is no transfer to sub-processors outside the EU. If you want to join the beta program please contact privacy@openproject.com (GPG Key: [BDCFE01EDE84EA199AE172CE7D669C6D47533958](https://keys.openpgp.org/vks/v1/by-fingerprint/BDCFE01EDE84EA199AE172CE7D669C6D47533958)).

**Migration after the beta phase in April 2022**

After the end of the beta phase we plan to migrate <u>all</u> customers to the new infrastructure *OpenProject.eu*. Before this migration we (Processor) notified in March 2022 all clients (Controller) about the new sub-processors by email.  After the expiry of the objection period of two weeks, the modification shall be deemed approved within the meaning of Article 28  (2) GDPR. If the the Controller objects by email to privacy@openproject.com within two weeks we will <u>not</u> migrate their data. For more information please have a look at [Use of sub-processors](https://www.openproject.org/legal/data-processing-agreement/#77-use-of-sub-processors) in your DPA.

## Can I get a custom domain name instead of example.openproject.com?

Yes, you can create your custom domain name. For this service we charge €100 per month. Please contact us via email (support@openproject.com) if you are interested.

## Can I import my OpenProject community instance into my Enterprise cloud environment?

Yes, we provide an upload possibility of your data to move from a Community edition installation to the Enterprise cloud edition.
To import your community instance into our cloud environment, please send us the following files:

1. The database SQL dump of your local installation
2. The attachments of your local installation

For a package-based installation, you can create both as root user on your environment as follows: `openproject run backup`
This creates the attachment and PostgreSQL-dump or MySQL-dump under /var/db/openproject/backup.
If you are still running OpenProject under MySQL, your dump will be converted to PostgreSQL before importing, we will do this for you. More information about the backup tool can be found [here](../../../installation-and-operations/operation/backing-up/).

Please upload these documents as an attachment to a work package within your new OpenProject Enterprise cloud environment and send us the link to this work package via email.

If you are having trouble accessing the files on your server with your browser, you can upload them directly from the server using [this script](./op-file-upload.sh). Simply download it and run it (`bash op-file-upload.sh`) to find out more.

## How can I export the documents loaded on OpenProject?

Currently, there is unfortunately no option to export all the documents in OpenProject at once. We could manually export the entire database (including the attachments) for you. Due to the manual effort, we would however need to charge a service fee for this. Please contact sales@openproject.com.

## Is it possible to access the PostgreSQL tables (read-only) on a hosted OpenProject instance via ODBC or another protocol (e.g. to extract data for PowerBI)?

Access to the database (including the PostgreSQL tables) is restricted for the Enterprise cloud edition due to technical and security reasons. Instead, you can use the OpenProject [API](../../../api) to both read and write data (where supported). If you require direct database access, you may want to take a look at the OpenProject [Enterprise on-premises edition](https://www.openproject.org/enterprise-edition) which you can run on your own server.

## Can I use LDAP authentication in my Enterprise cloud environment?

You can use [LDAP authentication](../../../system-admin-guide/authentication/ldap-connections/) in your cloud environment. **However**, usually LDAP servers will _not_ be exposed to the internet, which they have to be for this to work.
Whitelisting IPs is no option since the OpenProject servers' IPs are not permanent and can change without notice.
Moreover we do not have a mechanism to list all IP addresses currently in use.

If you really did want to do it still you would have to whitelist any IP included in the [IP ranges](https://ip-ranges.amazonaws.com/ip-ranges.json) published by AWS for the eu-west-1 region. This is not recommended, though.

## Can I use inbound emails in my Enterprise cloud environment?

Yes if you’re using the Enterprise cloud, inbound emails are already configured.

## How do I use inbound emails?

Inbound emails are already configured in Enterprise cloud.
You can see how to use in the [inbound email documentation](../../../installation-and-operations/configuration/incoming-emails/).

## Can I set a default project for inbound emails?

No it's not possible to set a default project for inbound mails.
The project must set as an argument in the email as described in the [inbound email documentation](../../../installation-and-operations/configuration/incoming-emails/).
