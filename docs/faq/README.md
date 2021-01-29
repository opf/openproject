---
sidebar_navigation:
  title: OpenProject FAQ
  priority: 999
description: Frequently asked questions for OpenProject (FAQ)
robots: index, follow
keywords: FAQ, introduction, tutorial, OpenProject, project management software, frequently asked questions 
---
# Frequently asked questions (FAQ) for OpenProject

Welcome to the central overview of frequently asked questions for OpenProject. 

## [FAQ for work packages](../user-guide/work-packages/faq)

## [FAQ for Gantt chart](../user-guide/gantt-chart/faq)

## [FAQ for Enterprise on-premises](../enterprise-edition-guide/faq)

## [FAQ for Enterprise cloud](../cloud-edition-guide/faq)

## Learn more about OpenProject

### Is OpenProject free of charge?

We offer three different versions of OpenProject. Please get an overview of the different OpenProject Editions [here](https://www.openproject.org/pricing/). The (on-premise) OpenProject Community edition is completely free. The Enterprise cloud and Enterprise on-premises edition offer premium features and support and thus we are charging for it. Nevertheless, we offer free 14 days trials for the Enterprise versions so that you can get to know their benefits. If you prefer to use the free OpenProject Community edition, you can follow these [installation instructions](https://www.openproject.org/download-and-installation/), please note that you need a Linux server to install the Community edition. It is always possible to upgrade from the Community to the Enterprise cloud and Enterprise on-premises edition – check out the premium features [here](https://www.openproject.org/enterprise-edition/#premium-features).

### What about data privacy, data security and GDPR conformity?

Data protection and security are one of the main motivations for the development of this open source application. Thus, you have the possibility to move the OpenProject application including your data to your own infrastructure at any time. Unlike other cloud tools, you can also take a look at the software code and adapt it if necessary. 

For users who do not want to run OpenProject themselves, we offer a hosting product. Here we use subcontractors who are not based in the EU, too. We achieve compliance with the GDPR by using standard protection clauses (Art. 46 (2) (c) and (d) GDPR). 
A list of the subcontractors currently used in the Cloud Edition can be found here: https://www.openproject.org/legal/data-processing-agreement/sub-processors/
For our cloud product, we aim to completely eliminate subcontractors outside of the EU by the end of 2021. We have made a start by replacing Google Analytics with Matomo since 2020. 
You can also send us encrypted emails to privacy@openproject.com. You can find the corresponding GPG key here: https://keys.openpgp.org/vks/v1/by-fingerprint/BDCFE01EDE84EA199AE172CE7D669C6D475339588 

#### Is OpenProject Enterprise cloud GDPR compliant? 

The OpenProject cloud environment is hosted on a logically isolated virtual cloud at Amazon Web Services with all services being located in Ireland. 
AWS is a GDPR compliant cloud infrastructure provider with extensive security and compliance programs as well as unparalleled access control mechanisms to ensure data privacy. 
Employed facilities are compliant with the ISO 27001 and 27018 standards. The OpenProject cloud environment is continuously backing up user data with data at rest being fully encrypted with AES-256. 
Each individual instance is logically separated and data is persisted in a unique database schema, reducing the risk of intersection or data leaks between instances. Find out more about GDPR compliance on our [website](https://www.openproject.org/gdpr-compliance).

### How do I get access to the OpenProject premium features?
We offer the premium functions of OpenProject (incl. boards) for two different OpenProject variants:

* For the OpenProject Enterprise cloud edition (hosted by us),
* For the self-hosted (on-premises) OpenProject Enterprise on-premises edition

If you want to run OpenProject on your own server the OpenProject Enterprise on-premises edition is the right option.
Have you already installed the [OpenProject Community edition](https://www.openproject.org/download-and-installation/)? If yes, you can request a trial license for the OpenProject Enterprise on-premises edition by clicking on the button "Free trial license" [here](https://www.openproject.org/de/enterprise-edition/) and test the Enterprise on-premises edition for 14 days for free.

### What are the system requirements?

The system requirements can be found [here](../installation-and-operations/system-requirements).

Apart from using OpenProject in the cloud (OpenProject Enterprise cloud) OpenProject can be installed in two different ways: The packaged installation of OpenProject is the recommended way to install and maintain OpenProject using DEB or RPM packages. There's also a Docker based installation option. 

### How can I learn more about OpenProject and how to use it?

Here are resources to get to know OpenProject: 

- The [overview of our features](https://www.openproject.org/collaboration-software-features) 
- Our [English demo video](https://www.youtube.com/watch?v=un6zCm8_FT4) or [German demo video](https://www.youtube.com/watch?v=doVtVArSSvk) to get an overview of Openproject. There are additional videos explaining certain features to be found on our [YouTube channel](https://www.youtube.com/c/OpenProjectCommunity/videos), too.
- The [Getting started guide](../getting-started) and the [User guide](../user-guide)
- Our free trial: Click the green button [here](https://www.openproject.org/enterprise-edition) for Enterprise on-premises or go to [start.openproject.com](start.openproject.com) for the Enterprise cloud.
- Our [development roadmap](https://community.openproject.com/projects/openproject/work_packages?query_id=1993) (to get to know future features)
- Our [training and consulting offers](https://www.openproject.org/training-and-consulting) 

### Can I run OpenProject as a single user?

Our minimum plan for the Enterprise cloud edition and Enterprise on-premises edition is five users. Our pricing scheme covers three subscription options: Community Edition ($0), Enterprise cloud (€4.95/member/month or approximately $5.60/member/month), and Enterprise on-premises (€5.95/member/month or approximately $6.73/member/month). We recommend to start the [Community version](https://www.openproject.org/download-and-installation/) free of charge if the five user minimum is an issue for you.

### Openproject is Open Source. Which kind of license does it come with? What am I allowed to do? What can I change?

OpenProject comes with the GNU General Public License v3 (GPLv3). You can find out more about the copyright [here](https://github.com/opf/openproject/blob/dev/docs/COPYRIGHT.rdoc).
In accordance with the terms set by the GPLv3 license, users can make modifications, create copies and redistribute the work. 
Terms and conditions regarding GPLv3 are available at[ ](http://www.gnu.org/licenses/gpl-3.0.html.)[http://www.gnu.org/licenses/gpl-3.0.html](http://www.gnu.org/licenses/gpl-3.0.html.).

### Can I have both users with the Enterprise cloud and others with the Enterprise on-premises Edition?

This is only possible if you book two different plans for OpenProject. The users won't be able to work together directly. We strongly recommend using either Enterprise cloud *or* Enterprise on-premises, if you want to collaborate with all colleagues.

### How are users in OpenProject counted? How many licenses do I need for Enterprise on-premises or Enterprise cloud?

All users working in OpenProject Enterprise cloud/on-premises need a license in order to access OpenProject. Regarding payments, we only count the active (not blocked) users. Users who were only invited but didn't accept the invite do not count, either.

### How many projects can I manage in OpenProject at once?

The number of projects is always unlimited. 
For the paid versions Enterprise or Cloud Edition, the price differs according to the number of users. 
However, if you're still using an old OpenProject subscription there may be limits to the number of projects. In this case please contact us.

### What is the difference between Enterprise on-premises and Community Edition regarding LDAP?

In the Community Edition and in the Enterprise on-premises edition you can use the standard LDAP authentication. However, the Enterprise on-premises edition also includes LDAP group synchronization. This allows you to synchronize group members from LDAP with groups in OpenProject. The respective documentation can be found [here](../system-admin-guide/authentication/ldap-authentication/ldap-group-synchronization/#synchronize-ldap-and-openproject-groups-premium-feature).

## How to ... in OpenProject?

Most of this kind of questions will be answered in the respective sections for each topic (see links above). However, there may be some FAQ that do not really fit elsewhere:

### How can I reverse changes?

This is not possible per se, there's no Ctrl+Z option or anything similar. 

Please use these resources to find out about the latest changes and re-do them manually: The [work package activity](../getting-started/work-packages-introduction/#activity-of-work-packages), the [history of the wiki page](../user-guide/wiki/more-wiki-functions/#show-wiki-page-history) or the [Activities module](../user-guide/activity).

### How can I change the day my week starts with, etc.?

You can do this as a system administrator in the [System settings](../system-admin-guide/system-settings/display-settings/#time-and-date-formatting).

### How can I create a PDF file with an individual and consolidated projects report?

To create and print/export reports you can...

- use the [global work packages list](../user-guide/projects/#global-work-packages-list): Filter for e.g. phases and milestones (which would make sense to use in your projects in this case). Then use the [export feature](../user-guide/work-packages/exporting/#exporting-work-packages). This will give you an overview over all projects' work packages (or all projects' milestones and phases, respectively).
- use the [Wiki module](../user-guide/wiki) to document your project reports. The Wiki pages is optimized for being printed using your browser's print feature. You could even insert a work packages list there. If you want to use the Wiki we suggest setting it up in a (global) parent project.

The projects overview is not optimized for export via PDF, yet. Nevertheless, you can try to use your browser's print feature.

### How can I receive the OpenProject newsletter?

Please go to https://www.openproject.org/newsletter/ and submit your data to receive our newsletter. Another option would be to agree to receive the newsletter when creating your account.

## FAQ regarding features

### Is it possible to use multiple languages in OpenProject?

Yes, it is possible to use OpenProject in multiple languages. We support English, German, French and a number of additional languages. Each user can select their own preferred language by signing into OpenProject, clicking on the user avatar on the upper right side and selecting "My account" from the dropdown menu.
You can then select "Settings" from the side menu on the left side and [change the language](../my-account/#change-your-language).

### Is there an OpenProject app?

There is no native iOS or Android app for OpenProject, but OpenProject is responsive - so it displays well on smaller screens.

### Is it possible to connect MS Project and OpenProject or to migrate from MS Project to OpenProject?

Yes, please use the free [Excel synchronization](../user-guide/integrations/excel synchronization) for this.

### Are there plan/actual comparisons in OpenProject?

You can use the [Budgets module](../user-guide/budgets/#budgets) for a plan/actual comparison.

### Does OpenProject have guest accounts?

Currently, all users working in the OpenProject Enterprise editions need a license in order to access OpenProject. Regarding payments we only count the active (not blocked) users. If users only require temporary access, you can [block](../system-admin-guide/users-permissions/users/#lock-and-unlock-users) those users afterwards to free up additional seats.

### Can I get a notification when a deadline approaches?

Not at the moment. This is a well-known feature requirement and we are currently working on the specification for this with our dev team. It's already on our roadmap and it will be developed in one of the upcoming releases. 

### Does OpenProject offer resource management?

You can [set up budgets](../user-guide/budgets), [set an Estimated time](../user-guide/work-packages/edit-work-package/) for a work package and use the [Assignee board](../user-guide/agile-boards/#choose-between-board-types) to find out how many work packages are assigned to a person, yet. 
Additional resource management features will be added within the next years. You can find the roadmap for future releases [here](https://community.openproject.com/projects/openproject/work_packages?query_id=1993).

### Is there an organizational chart in OpenProject?

There's no such feature. However, you can use the wiki to add information regarding your departments and employees. Furthermore, you can upload existing org charts as image or e.g. PDF to the wiki or the documents module. 

In many companies it makes sense to structure your project tree according to your departments (i.e. one parent project for each department with projects for each topic or client underneath).

### Is there an architecture diagram for OpenProject?

A (very rough) diagram can be found on https://www.openproject.org/hosting/.

### Can I set up an entity-relationship diagram in OpenProject?

No, currently we do not have an entity-relationship diagram for OpenProject.

## FAQ regarding OpenProject BIM edition

### How can I find out more about OpenProject BIM edition?

Please have a look at our [demo video](https://www.youtube.com/watch?v=ThA4_17yedg) and at our [website](https://www.openproject.org/bim-project-management/). You can start a free trial there, too.

### Which IFC format are you using for conversion in the BIM module?

IFC2x3 and IFC4. We accept those formats and convert them to some other format that is optimized for web.

### Is there a way to use OpenProject BIM for free, too?

Yes, (only) as part of the Community Edition you can use OpenProject BIM for free. Please have a look [here](../installation-and-operations/changing-to-bim-edition/) to find out how to activate the BIM modules in your on-premises installation.

## Migration

### How can I migrate from Bitnami to OpenProject?

To migrate from Bitnami **to Enterprise cloud** please provide these: 
\- data as database dump (.sql file)
\- attachment folder
You can use the first two steps of [this instruction](../installation-and-operations/faq/#how-can-i-migrate-from-bitnami-to-the-official-openproject-installation-packages). Please contact us to discuss your migration.

To migrate from Bitnami **to Enterprise on premises** please use [this instruction](../installation-and-operations/faq/#how-can-i-migrate-from-bitnami-to-the-official-openproject-installation-packages). We offer (paid) installation support to help you migrate to OpenProject (for the Enterprise on-premises edition). Please contact us to request it.

### How can I migrate from Community Edition or Enterprise on-premises to Enterprise cloud?

We will need a database dump from you which we will upload to your new Enterprise cloud. Please contact us to plan the migration and get more instructions.

### How can I migrate from Enterprise cloud to Enterprise on-premises?

We will provide a database dump which you can upload into your Enterprise on-premises edition. This way you can keep all your data.

### How can I migrate from Community Edition to Enterprise on-premises?

If you [book Enterprise on-premises](../enterprise-edition-guide/activate-enterprise-edition/#order-the-enterprise-on-premises-edition) you will receive an Enterprise token. Use it to activate the Enterprise premium features. For detailed activation instructions please refer to the [Enterprise activation guide](../enterprise-edition-guide/activate-enterprise-edition/). You can keep your data that you created in the Community Edition.

### How can I migrate from Enterprise on-premises to Community Edition?

If you cancel your subscription for Enterprise on-premises you will be downgraded to Community Edition automatically as soon as the subscription period ends. You can keep all your data but won't be able to use the [premium features](https://www.openproject.org/de/enterprise-edition/#premium-features) and won't be eligible for support any more.

### Where can I find information on additional migrations (e.g. from MySQL to PostgreSQL)?

Please have a look at [this section](../installation-and-operations/misc).

## Other

### Do you support Univention users?

If you're an Enterprise on-premises user you're eligibe for Professional Support. However, we can't support you in all Univention-related topics (e.g. server not reachable, authentification setup, ...).

### Do you have a cyber insurance?

Yes, we do. 

### Is there a limitation of participants for the trainings?

No, you can join with as many people from your organization as you like. However, or most we recommend not more than 20-25 people so there's enough opportunity for everyone to ask questions.
*This answer only refers to e.g. Getting Started training and custom trainings, not to the OpenProject certification!* 

### Can trainings be conducted remotely, too (e.g. the Custom training)?

Yes, this is possible. Please get in touch.

### How long is the OpenProject certification valid?

It does not expire. However, the certification training always covers the current version of the software at the time.