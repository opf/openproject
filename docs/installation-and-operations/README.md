---
sidebar_navigation:
  title: Installation & operations guide
  priority: 940
---

# Installation & operations guide

This page summarizes the options for getting OpenProject, some hosted and some on-premise. With this information you should be able to decide what option is best for you. Find a full feature comparison [here](https://www.openproject.org/pricing/#features).

## On-premises

* **Community edition** - The free, no license, edition of OpenProject that you install on-premise. The additional add-ons of the Enterprise edition are not included. See the "Installation" row of the table below.
* **Enterprise on-premise edition** - Builds on top of the Community edition: Enterprise add-ons, professional support, hosted on-premises with optional installation support. See more [on the website](https://www.openproject.org/enterprise-edition/), where you can apply for a free trial, or in the [documentation](../enterprise-guide/enterprise-on-premises-guide/). The Community edition can easily be upgraded to the Enterprise on-premises edition.

## Hosted

* **Enterprise Enterprise cloud edition** - Hosted by OpenProject in an EU Data Center, with Enterprise add-ons and professional support . See more on the [website](https://www.openproject.org/enterprise-edition/#hosting-options), where you can apply for a free trial, or in the [documentation](../enterprise-guide/enterprise-cloud-guide/).

All editions can be enhanced by adding [the BIM module](../bim-guide/), including features for construction project management, i.e. 3D model viewer, BCF management. See how to [switch to that edition](bim-edition/) in the documentation or how to start a [BIM Enterprise cloud edition](https://start.openproject.com/trial/bim).

Compare the features of these versions [on the website](https://www.openproject.org/pricing/#features).

> **Note**: there are some minor options given in the "Other" row of the table below. These are not recommended but you may wish to try them.

## On-premises installation overview

| Main Topics                                 | Content                                                                                    |
|---------------------------------------------|:-------------------------------------------------------------------------------------------|
| [System requirements](system-requirements/) | Learn the minimum configuration required to run OpenProject                                |
| [Installation](installation/)               | How to install OpenProject and the methods available                                       |
| [Operations & Maintenance](operation/)      | Guides on how to configure, backup, **upgrade**, and monitor your OpenProject installation |
| [Advanced configuration](configuration/)    | Guides on how to perform advanced configuration of your OpenProject installation           |
| [Other](misc/)                              | Guides on infrequent operations such as MySQL to PostgreSQL migration                      |
| [BIM](../bim-guide/)                        | How to install OpenProject BIM edition                                                     |

For production environments and when using a [supported distribution](system-requirements), we recommend using the [packaged installation](installation/packaged/). This will install OpenProject as a system dependency using your distribution's package manager, and provide updates in the same fashion that all other system packages do.

An OUTDATED and OLD [manual installation](installation/manual) option exists, but due to the large number of components involved and the rapid evolution of OpenProject, we cannot ensure that the procedure is either up-to-date or that it will correctly work on your machine. This means that manual installation is NOT recommended NOR supported.
