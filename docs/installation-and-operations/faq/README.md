---
sidebar_navigation:
  title: FAQ
  priority: 001
description: Frequently asked questions regarding installation and operation of OpenProject
robots: index, follow
keywords: installation FAQ, upgrades, updates, operation faq
---

# Frequently asked questions (FAQ) for installation and operation

## Can I use MySQL instead of PostgreSQL?

OpenProject has traditionally supported both MySQL and PostgreSQL, but in order to optimize for performance and SQL functionality, it is unfeasible to support both DBMS that are becoming more and more disjunct when trying to use more modern SQL features. This shift has started some years ago when full-text search was added for PostgreSQL, but at  the time MySQL did not yet support it - and as of yet many distributions still do not support MySQL 8 natively.

This led us to the path of removing support in the upcoming stable releases of OpenProject in order to focus on these goals. [Please see our blog post on the matter for additional notes](https://www.openproject.org/deprecating-mysql-support/).

## How can I migrate my existing MySQL database to PostgreSQL ?

Older installations of OpenProject are likely installed with a MySQL installation because the installer shipped with an option to auto-install it. With [pgloader](https://pgloader.io), it is trivially easy to convert a dump between MySQL and PostgreSQL installation. [We have prepared a guide](../misc/packaged-postgresql-migration ) on how to migrate to a PostgreSQL database if you previously used MySQL.

## My favorite Linux distribution is not listed. What can I do?

You can either try the manual installation, or ask in the forum whether this could be added to the list of supported distributions. We try to support recent major distributions, but due to maintenance and operations cost cannot freely add to that list.

## What is the better option to run OpenProject in production environments: docker or linux packages?

We recommend the Linux packages [if you have a compatible distribution](../system-requirements/) and a separate machine for OpenProject, since it will allow for the easiest and most flexible setup. Use a docker-based image either for quickly spinning up an environment or if you have knowledge in setting up and maintaining docker-based installations.

## What skills should I have for the installation?

If you use the packaged installation, you should have a basic knowledge of Linux and the command-line terminal.

If you use the docker images, you need to be familiar with Docker and Docker volumes.

## Why don't you support Windows?

Ruby support on Windows is notoriously difficult, however you might be able to run the Docker image, or use the unofficial Windows stack provided by [Bitnami](https://bitnami.com/stack/openproject/installer). We would welcome feedback and reported experiences on running OpenProject on Windows, please reach out to us if you can contribute some information.

## How can I migrate from Bitnami to the official OpenProject installation packages?

Please follow these steps:

1. Make a dump of your bitnami database to export your data. You can refer to the [Bitnami documentation][bitnami-mysql].
1. Make a dump of files your might have uploaded. You can refer to the [Bitnami documentation][bitnami-backup] to perform a full dump.
1. Copy both dumps to the server you want to install OpenProject on.
1. Install OpenProject using the packaged installation.
1. By default, this will allow you to install a PostgreSQL database, which we recommend. You can migrate your data from MySQL using https://pgloader.io
1. Import the dump into your new database. You can get your configuration by running `sudo openproject config:get DATABASE_URL`
1. Extract the bitnami backup, and copy your file assets into the relevant directory (e.g. in `/var/db/openproject/files` for uploaded files)
1. Restart OpenProject

[bitnami-mysql]: https://docs.bitnami.com/installer/components/mysql/
[bitnami-backup]: https://docs.bitnami.com/installer/apps/openproject/

## Are there extra fees to pay, in terms of installing the OpenProject software?

The Community Edition and [Enterprise on-premises edition](https://www.openproject.org/enterprise-edition/) are on-premises solutions and thus need installation from your side while the [Enterprise cloud edition](https://www.openproject.org/hosting/) is hosted by us. The Community edition is for free and we ask you to do the installation yourself. Of course we support you with a clear and easy [installation guide](https://www.openproject.org/download-and-installation/). If you would like us to install the Enterprise on-premises edition for you, we are charging a fee of €150 (excluding VAT) for this once-off service. You can add the installation support during your [Enterprise on-premises edition booking process](../../enterprise-edition-guide/activate-enterprise-edition/#order-the-enterprise-on-premises-edition).