---
sidebar_navigation:
  title: FAQ
  priority: 950
description: Frequently asked questions for OpenProject (FAQ)
keywords: FAQ, introduction, tutorial, project management software, frequently asked questions, help
---
# Frequently asked questions (FAQ) for OpenProject

Welcome to the central overview of frequently asked questions for OpenProject.

| Topic                                                                           | Content                                                                                           |
|---------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------|
| [Learn more about OpenProject](#learn-more-about-openproject)                   | General questions about OpenProject, security, setup and much more                                |
| [How to ... in OpenProject](#how-to--in-openproject)                            | Questions about how to achieve certain outcomes in OpenProject that do not fit elsewhere          |
| [FAQ regarding features](#faq-regarding-features)                               | Information about frequent feature requests                                                       |
| [FAQ regarding OpenProject BIM edition](#faq-regarding-openproject-bim-edition) | Questions concerning the additional BCF module for OpenProject and the BIM edition                |
| [Migration](#migration)                                                         | Questions regarding migrating to OpenProject from e.g. Bitnami or from other OpenProject versions |
| [Other](#other)                                                                 | Additional questions, e.g. about contribution, training, support                                  |
| [Topic-specific FAQ](#topic-specific-faq)                                       | Links to other FAQ sections                                                                       |

## Learn more about OpenProject

### How do I get access to the OpenProject Enterprise add-ons?

We offer the Enterprise add-ons of OpenProject (incl. boards) for two different OpenProject variants:

* For the OpenProject Enterprise cloud edition (hosted by us),
* For the self-hosted (on-premises) OpenProject Enterprise on-premises edition

If you want to run OpenProject on your own server, the OpenProject Enterprise on-premises edition is the right option.
Have you already installed the [OpenProject Community edition](https://www.openproject.org/download-and-installation/)? If yes, you can request a trial license for the OpenProject Enterprise on-premises edition by clicking on the button "Free trial license" [here](https://www.openproject.org/de/enterprise-edition/) and test the Enterprise on-premises edition for 14 days for free.

### Can I have some users with Enterprise add-ons and some without?

As the Enterprise Enterprise add-ons affect the whole instance (e.g. with Agile Boards and project custom fields) it's not possible to upgrade only some users.

### What are the system requirements?

The system requirements can be found [here](../installation-and-operations/system-requirements).

Apart from using OpenProject in the cloud (OpenProject Enterprise cloud) OpenProject can be installed in two different ways: The packaged installation of OpenProject is the recommended way to install and maintain OpenProject using DEB or RPM packages. There's also a Docker based installation option.

### How can I learn more about OpenProject?

Here are resources to get to know OpenProject:

- The [overview of our features](https://www.openproject.org/collaboration-software-features)
- Our [English demo video](https://www.youtube.com/watch?v=un6zCm8_FT4) or [German demo video](https://www.youtube.com/watch?v=doVtVArSSvk) to get an overview of OpenProject. There are additional videos explaining certain features to be found on our [YouTube channel](https://www.youtube.com/c/OpenProjectCommunity/videos), too.
- The [Getting started guide](../getting-started) and the [User guide](../user-guide)
- Our free trial: Click the green button [here](https://www.openproject.org/enterprise-edition) for Enterprise on-premises or go to [start.openproject.com](https://start.openproject.com) for the Enterprise cloud.
- Our [development roadmap](https://community.openproject.org/projects/openproject/roadmap) (to get to know future features)
- Our [training and consulting offers](https://www.openproject.org/training-and-consulting)

### Can I run OpenProject as a single user?

Our minimum plan for the Enterprise cloud edition and Enterprise on-premises edition is five users. Our pricing scheme covers three subscription options: Community edition ($0), Enterprise cloud (€5.95/member/month or $7.25/member/month), and Enterprise on-premises (€5.95/member/month or $7.25/member/month). We recommend to start the [Community version](https://www.openproject.org/download-and-installation/) free of charge if the five user minimum is an issue for you.

### OpenProject is Open Source. Which kind of license does it come with? What am I allowed to do? What can I change?

OpenProject comes with the GNU General Public License v3 (GPLv3). You can find out more about the copyright [here](https://github.com/opf/openproject/blob/dev/COPYRIGHT).
In accordance with the terms set by the GPLv3 license, users can make modifications, create copies and redistribute the work.
Terms and conditions regarding GPLv3 are available at [https://www.gnu.org/licenses/gpl-3.0.en.html](https://www.gnu.org/licenses/gpl-3.0.en.html) or in [our repository](https://github.com/opf/openproject/blob/dev/LICENSE).

### Is OpenProject free of charge?

We offer three different versions of OpenProject. Please get an overview of the different OpenProject Editions [here](https://www.openproject.org/pricing/#features).

The (on-premise) OpenProject Community edition is completely free. The Enterprise cloud and Enterprise on-premises edition offer Enterprise add-ons, hosting and support and thus we are charging for it. Nevertheless, we offer free 14 days trials for the Enterprise versions so that you can get to know their benefits. If you prefer to use the free OpenProject Community edition, you can follow these [installation instructions](https://www.openproject.org/download-and-installation/), please note that you need a Linux server to install the Community edition. It is always possible to upgrade from the Community to the Enterprise cloud and Enterprise on-premises edition – check out the Enterprise add-ons [here](https://www.openproject.org/enterprise-edition/#enterprise-add-ons).

### Can I have both users with the Enterprise cloud and others with the Enterprise on-premises edition?

This is only possible if you book two different plans for OpenProject. The users won't be able to work together directly. We strongly recommend using either Enterprise cloud *or* Enterprise on-premises, if you want to collaborate with all colleagues.

### How are users in OpenProject counted? How many licenses do I need for Enterprise on-premises or Enterprise cloud?

All users working in OpenProject Enterprise cloud/on-premises need a license in order to access OpenProject. Regarding payments, we only count the active (not blocked) users. Users who were only invited but didn't accept the invite do not count, either.

### How many projects can I manage in OpenProject at once?

The number of projects is always unlimited.
For the paid versions Enterprise on-premises or Enterprise cloud edition, the price differs according to the number of users.
However, if you're still using an old OpenProject subscription there may be limits to the number of projects. In this case please contact us.

### What is the difference between Enterprise on-premises and Community edition regarding LDAP?

In the Community edition and in the Enterprise on-premises edition you can use the standard LDAP authentication. However, the Enterprise on-premises edition also includes LDAP group synchronization. This allows you to synchronize group members from LDAP with groups in OpenProject. The respective documentation can be found [here](../system-admin-guide/authentication/ldap-connections/ldap-group-synchronization/#synchronize-ldap-and-openproject-groups-enterprise-add-on).

## How to ... in OpenProject

Most of this kind of questions will be answered in the respective sections for each topic (see links below). However, there may be some FAQ that do not really fit elsewhere:

### I cannot log in, I do not know my password. What can I do?

As a first step please try to [reset your password](../getting-started/sign-in-registration/#reset-your-password). Please look in your spam folder, too, if you didn't receive an email.

If that doesn't help please contact your admin for login related topics. He/she can [set a new password for you](../system-admin-guide/users-permissions/users/#manage-user-settings).

If you don't know the URL of your OpenProject Enterprise cloud, you can find it on [this website](https://www.openproject.org/request-organization) on the basis of your email address.

### I cannot log in. Resetting my password seems to have no effect. What do I do?

Look in your spam folder for the email.

Ask your system admin to [set a new password for you](../system-admin-guide/users-permissions/users/#manage-user-settings).

If you are the system administrator of an on-premises installation (Enterprise on-premises or Community edition) please have a look at [this FAQ](../installation-and-operations/operation/faq/#i-lost-access-to-my-admin-account-how-do-i-reset-my-password).

### How can I reverse changes?

This is not possible per se, there's no Ctrl+Z option or anything similar.

Please use these resources to find out about the latest changes and re-do them manually: The [work package activity](../getting-started/work-packages-introduction/#activity-of-work-packages), the [history of the wiki page](../user-guide/wiki/more-wiki-functions/#show-wiki-page-history) or the [Activities module](../user-guide/activity).

### How can I increase or decrease the number of users in OpenProject?

You can invite new users in the system administration as long as you have enough licenses.

For the Community edition you can have as many users as you need for free.
If you are using Enterprise on-premises, please write an email to sales @ openproject.com.

If you are using the Enterprise cloud, you can easily upgrade or downgrade the number of users by navigating to *Administration -> Billing -> Manage subscription* and choosing the new amount of users which you need in your system. Find out more [here](../enterprise-guide/enterprise-cloud-guide/manage-cloud-subscription).

### How can I change the day my week starts with, etc.?

You can do this as a system administrator in the [System settings](../system-admin-guide/calendars-and-dates).

### How can I add a RACI matrix in OpenProject?

You can add [project custom fields](../system-admin-guide/custom-fields/custom-fields-projects/) of the type "user" to your projects and track the respective persons there.

On a work package level you could use "Assignee" for "Responsible", "Accountable" for "Accountable" and [add custom fields](../system-admin-guide/custom-fields/) for "Consulted" and "Informed". For the latter one you could also just set the person as watcher instead.

### How can I create a PDF file with an individual and consolidated projects report?

To create and print/export reports you can...

- use the [global work packages list](../user-guide/projects/project-lists/#global-work-package-tables): Filter for e.g. phases and milestones (which would make sense to use in your projects in this case). Then use the [export feature](../user-guide/work-packages/exporting/). This will give you an overview over all projects' work packages (or all projects' milestones and phases, respectively).
- use the [Wiki module](../user-guide/wiki) to document your project reports. The Wiki pages is optimized for being printed using your browser's print feature. You could even insert a work packages list there. If you want to use the Wiki we suggest setting it up in a (global) parent project.

The projects overview is not optimized for export via PDF, yet. Nevertheless, you can try to use your browser's print feature.

### How can I receive the OpenProject newsletter?

Please go to [openproject.org/newsletter/](https://www.openproject.org/newsletter/) and submit your data to receive our newsletter. Another option would be to agree to receive the newsletter when creating your account.

## FAQ regarding features

Please find information on the features of OpenProject [here](https://www.openproject.org/collaboration-software-features/) and a comparison between Enterprise on-premises, Enterprise cloud and Community edition [here](https://www.openproject.org/pricing/#features). The community platform to see and [issue](../development/submit-feature-idea/) feature ideas can be found [here](https://community.openproject.org).

### Is it possible to use multiple languages in OpenProject?

Yes, it is possible to use OpenProject in multiple languages. We support English, German, French and a number of additional languages. Each user can select their own preferred language by signing into OpenProject, clicking on the user avatar on the upper right side and selecting "My account" from the dropdown menu.
You can then select "Settings" from the side menu on the left side and [change the language](../user-guide/my-account/#change-your-language).

### Is there an OpenProject app?

There is no native iOS or Android app for OpenProject, but OpenProject is responsive - so it displays well on smaller screens.

### Is it possible to connect MS Project and OpenProject or to migrate from MS Project to OpenProject?

Yes, please use the free [Excel synchronization](../system-admin-guide/integrations/excel-synchronization/) for this.

### Are there plan/actual comparisons in OpenProject?

You can use the [Budgets module](../user-guide/budgets/#budgets) for a plan/actual comparison.

### Can I use OpenProject offline?

No, it's not possible to use OpenProject without Internet access (Enterprise cloud) or access to the server it is installed on (on-premises installations).

### Can I import tasks from spreadsheets like Excel or LibreOffice?

Yes, that’s possible. Please have a look at our [Excel sync](../system-admin-guide/integrations/excel-synchronization/).

### Does OpenProject have guest accounts?

Currently, all users working in the OpenProject Enterprise editions need a license in order to access OpenProject. Regarding payments we only count the active (not blocked) users. If users only require temporary access, you can [block](../system-admin-guide/users-permissions/users/#lock-and-unlock-users) those users afterwards to free up additional seats.

Apart from that, you can use [placeholder users](../system-admin-guide/users-permissions/placeholder-users/) to set up your project without using license seats.

### Can I get a notification when a deadline approaches?

Yes, you can. Starting with OpenProject 12.4 we implemented date alerts and email reminders about upcoming deadlines and overdue tasks. Please refer to [this guide](../user-guide/notifications/) for more details.

### Does OpenProject offer resource management?

You can [set up budgets](../user-guide/budgets), [set the estimated time in  the **Work** field](../user-guide/work-packages/edit-work-package/) of a work package and use the [Assignee board](../user-guide/agile-boards/#choose-between-board-types) to find out how many work packages are assigned to a person at the moment.
Additional resource management features will be added within the next years. You can find the roadmap for future releases [here](https://community.openproject.org/projects/openproject/work_packages?query_id=1993).
More information regarding resource management in OpenProject can be found in the [Use Cases](../use-cases/resource-management) section.

### Does OpenProject offer portfolio management?

For portfolio management or custom reporting, you can use either the project list, or the global work package table. Both views can be used to create optimal reports via filtering, sorting and other configuration options.

For more information on portfolio management options in OpenProject please refer to this [Use Case](../use-cases/portfolio-management).

### Is there an organizational chart in OpenProject?

There's no such feature. However, you can use the wiki to add information regarding your departments and employees. Furthermore, you can upload existing org charts as image or e.g. PDF to the wiki or the documents module.

In many companies it makes sense to structure your project tree according to your departments (i.e. one parent project for each department with projects for each topic or client underneath).

### Is there an architecture diagram for OpenProject?

A (very rough) diagram can be found on [https://www.openproject.org/enterprise-edition/#hosting-options](https://www.openproject.org/enterprise-edition/#hosting-options).

### Can I set up an entity-relationship diagram in OpenProject?

No, currently we do not have an entity-relationship diagram for OpenProject.

### Can I edit the Home page?

Only the welcome block/text can be edited, the rest cannot. However, you can [change the theme and logo](../system-admin-guide/design) of your OpenProject instance if you use Enterprise on-premises or Enterprise cloud.

## FAQ regarding OpenProject BIM edition

### How can I find out more about OpenProject BIM edition?

Please have a look at our [demo video](https://www.youtube.com/watch?v=ThA4_17yedg) and at our [website](https://www.openproject.org/bim-project-management/). You can start a free trial there, too.

### Which IFC format are you using for conversion in the BIM module?

IFC2x3 and IFC4. We accept those formats and convert them to a smaller format (XKT) that is optimized for browsing the models on the web.

### Is there a way to use OpenProject BIM for free, too?

Yes, (only) as part of the Community edition you can use OpenProject BIM for free. Please have a look [here](../installation-and-operations/bim-edition/) to find out how to activate the BIM modules in your on-premises installation.

### Can a BCF file created from other software e.g. BIMcollab, Solibri, etc. be opened in OpenProject?

Yes, of course. That's why the module for this in OpenProject is called "BCF". You can import and export BCF XML files. Our goal is to have specialized tools like Solibri do model checks, but the coordination of the results, the issues, is done in OpenProject, because more people can get access to the BCF issues through OpenProject because our licenses are much cheaper. In addition, BCF issues imported into OpenProject behave just like other non-BCF work packages. For example, you can plan them in a Gantt chart on the timeline, or manage them agilely in boards. We support the current BCF XML format 2.1.
Furthermore, we are planning a direct integration into Solibri. Then you don't need to export and import XML files anymore, but Solibri will read and write directly into OpenProject via an interface, the BCF-API. Before that, however, we will complete the integration in Autodesk Revit.
(Status: February 2021)

### Does clicking on a BCF-issue zoom you to the appropriate location in the model?

Yes, the so-called camera position is stored in the BCF-issues, so that exactly the same camera position is assumed when you click on the BCF-issue. These are called viewpoints. If you have several models, e.g. architecture and technical building equipment, these must be activated (made visible) before you click on the BCF-issue. In the same way, BCF-elements of the model can be hidden or selected via the viewpoint.

In our [introductory video](https://www.youtube.com/watch?v=ThA4_17yedg) to the OpenProject BIM edition the basics are shown very well. In particular, the integration of BCF management into the rest of the project management of a construction project is the strength of OpenProject.

### Can I add photos from my mobile/phone to BIM issues?

Yes. Take a photo with your camera and save it on your phone. Then open the correct work package in your browser or create a new one. Append the photo as an attachment to the work package.

### Can I use IFC while a Revit connection is not available?

Yes, of course. Within the BCF module you can upload multiple IFC models and create and manage BCF issues.

## Migration

### How can I migrate from Bitnami to OpenProject?

To migrate from Bitnami **to Enterprise cloud** please provide these:

- data as database dump (.sql file)
- attachment folder

You can use the first two steps of [this instruction](../installation-and-operations/installation-faq/#how-can-i-migrate-from-bitnami-to-the-official-openproject-installation-packages). Please contact us to discuss your migration.

To migrate from Bitnami **to Enterprise on premises** please use [this instruction](../installation-and-operations/installation-faq/#how-can-i-migrate-from-bitnami-to-the-official-openproject-installation-packages). We offer (paid) installation support to help you migrate to OpenProject (for the Enterprise on-premises edition). Please contact us to request it.

### How can I migrate from Jira/Confluence to OpenProject?

At the moment there are these ways to migrate:

- our [API](../api/)
- our [Excel sync](../system-admin-guide/integrations/excel-synchronization)
- Using a [Markdown export app](https://marketplace.atlassian.com/apps/1221351/markdown-exporter-for-confluence) you can export pages from Confluence and paste them (via copy & paste) into OpenProject in e.g. the wiki. This should preserve at least most of the layout. Attachments would then have to be added manually.

Our partners at [ALMToolbox](https://www.almtoolbox.com/)  are happy to support you with Jira or Confluence migration. 

For more information please contact us.

### How can I migrate from Community edition or Enterprise on-premises to Enterprise cloud?

We will need a [backup](../system-admin-guide/backup) of your OpenProject Installation which we will restore to your new Enterprise cloud. Please calculate with a downtime of approximately 60 minutes in regular cases. Please contact us to plan the migration and get more instructions.

### How can I migrate from Enterprise cloud to Enterprise on-premises?

We will need a [backup](../system-admin-guide/backup) which we will restore into your Enterprise on-premises edition. Please calculate with a downtime of approximately 60 minutes in regular cases. This way you can keep all your data.

### How can I migrate from Community edition to Enterprise on-premises?

If you [book Enterprise on-premises](../enterprise-guide/enterprise-on-premises-guide/activate-enterprise-on-premises/#order-the-enterprise-on-premises-edition) you will receive an Enterprise token. Use it to activate the Enterprise Enterprise add-ons. For detailed activation instructions please refer to the [Enterprise activation guide](../enterprise-guide/enterprise-on-premises-guide/activate-enterprise-on-premises/). You can keep your data that you created in the Community edition.

### How can I migrate from Enterprise on-premises to Community edition?

If you cancel your subscription for Enterprise on-premises you will be downgraded to Community edition automatically as soon as the subscription period ends. You can keep all your data but won't be able to use the [Enterprise add-ons](https://www.openproject.org/de/enterprise-edition/#enterprise-add-ons) and won't be eligible for support any more.

### How can I migrate from an old version of OpenProject to the latest version?

OpenProject changed the database from MySQL (rarely also MariaDB) in older Versions and used PostgreSQL 10 afterwards. With the release of version 12 OpenProject introduced the PostgreSQL 13 database. For further information on several database migrations, please have a look at [this section](../installation-and-operations/misc).

## Other

### How can I contribute to OpenProject?

We welcome everybody willing to help make OpenProject better. There are a lot of possibilities for helping, be it [improving the translations](../development/translate-openproject) via crowdin, answering questions in the [forums](https://community.openproject.org/projects/openproject/forums) or by fixing bugs and implementing features.

If you want to code, a good starting point would be to make yourself familiar with the [basic approaches for developing](../development/) in OpenProject and opening a pull request on GitHub referencing an existing bug report or feature request. Find our GitHub page [here](https://github.com/opf/openproject).

If in doubt on how you should start, you can also just [contact us](https://www.openproject.org/contact/).

### How can I receive support?

We offer our Professional Support for Enterprise on-premises users and Enterprise cloud users. Please write an email to support@openproject.com.

If you use the Community edition please feel free to use our [forums](https://community.openproject.org/projects/openproject/forums) for exchange with other users.

To learn more about OpenProject and how its features work please have a look at [this FAQ](#how-can-i-learn-more-about-openproject).

### Do you have a cyber insurance?

Yes, we do.

### Is there a limitation of participants for the trainings?

No, you can join with as many people from your organization as you like. However, we recommend not more than 20-25 people so there's enough opportunity for everyone to ask questions.
*This answer only refers to e.g. Getting Started training and custom trainings, not to the OpenProject certification!*

### Can trainings be conducted remotely, too (e.g. the Custom training)?

Yes, this is possible. Please get in touch.

### How long is the OpenProject certification valid?

It does not expire. However, the certification training always covers the current version of the software at the time.

### Where can I find out more about pricing?

You can find the price calculator [here](https://www.openproject.org/pricing) and FAQ regarding pricing [here](https://www.openproject.org/pricing/#faq).

## Topic-specific FAQ

Here are some selected links to other FAQ pages. Please use the menu to navigate to a topic's section to find more FAQs or use the search bar in the header.

- [FAQ for work packages](../user-guide/work-packages/work-packages-faq)
- [FAQ for Gantt chart](../user-guide/gantt-chart/gantt-chart-faq)
- [FAQ for Enterprise on-premises](../enterprise-guide/enterprise-on-premises-guide/enterprise-on-premises-faq)
- [FAQ for Enterprise cloud](../enterprise-guide/enterprise-cloud-guide/enterprise-cloud-faq)
- [FAQ for system administration](../system-admin-guide/system-admin-guide-faq)
- [FAQ for installation, operation and upgrades](../installation-and-operations/installation-faq)
