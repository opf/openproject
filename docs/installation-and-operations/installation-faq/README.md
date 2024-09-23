---
sidebar_navigation:
  title: Installation & Ops FAQ
  priority: 001
description: Frequently asked questions regarding installation and operation of OpenProject
keywords: installation FAQ, upgrades, updates, operation faq
---

# Frequently asked questions (FAQ) for installation and operation

## Installation and configuration

### Which options are there to install OpenProject?

There's the package based installation (recommended), installation via Docker, using a provider (like Bitnami, IONOS) and the manual installation.

### What skills should I have for the installation of Community edition or Enterprise on-premises?

If you use the packaged installation, you should have basic knowledge of Linux and the command-line terminal.

If you use the docker images, you need to be familiar with Docker and Docker volumes.

### My favorite Linux distribution is not listed. What can I do?

You can either try the OUTDATED and OLD manual installation guide, or add a Feature request whether your operating system could be added to the list of supported distributions. We try to support recent major distributions, but due to maintenance and operations cost cannot freely add to that list.

### What is the better option to run OpenProject in production environments: Docker or Linux packages?

We recommend the Linux packages [if you have a compatible distribution](../system-requirements/) and a separate machine for OpenProject, since it will allow for the easiest and most flexible setup. Use a Docker-based image either for quickly spinning up an environment or if you have knowledge in setting up and maintaining Docker-based installations.

### Are there any default ports that should be closed for security reasons?

Anything besides 443 and 80 should be closed on a  system hosting OpenProject by default. You may need SSH (port 22), but that should only be open to whitelisted IPs.

### Can I use a virtual machine (VM) to install OpenProject?

You can use a virtual machine as long as the hardware and the operating system match the system requirements. However, the virtual machine may be less powerful. Installing on a virtual machine could be an alternative to Docker if you would like to install OpenProject in a Windows environment. However, we can't officially support this.

### Why is there no installation wizard for desktop as there is for other software?

The Community edition and Enterprise edition of OpenProject are not a desktop application but a server application, typically for Linux servers. Therefore there's no typical user interface to install it.
If you want to install it on Windows or Mac you can use the Docker based installation. Please note that installing on Windows Desktop usually works but is not officially supported.
The package based installation (for Linux) offers an installation wizard.

Alternatively, you could use OpenProject [as cloud version](https://www.openproject.org/enterprise-edition/#hosting-options) to avoid installation.

### Why don't you support Windows?

Ruby support on Windows is notoriously difficult, however you might be able to run the Docker image, or use the unofficial Windows stack provided by [Bitnami](https://bitnami.com/stack/openproject/installer). We would welcome feedback and reported experiences on running OpenProject on Windows, please reach out to us if you can contribute some information.

### Can I install OpenProject on my Mac?

There's no installation packages for Mac. However, you can use Docker (easier way) or install it manually.
Your Mac will have to be reachable from the Internet if you want to collaborate with others.

### Does the OpenProject docker container run on ARM technology like Apple M1 or Raspberry PI?

Starting with OpenProject 12.5.6 we publish our containers for three architectures.

1. AMD64 (x86)
2. ARM64
3. PPC64

However, the OpenProject **BIM Edition** is only supported on AMD64.

### Can I install OpenProject offline?

For the packaged installation there are quite a few dependencies which would have to be loaded during installation (like SQLite3, unzip, poppler-utils, unrtf, ...). Therefore, we recommend  to use a Docker setup for offline installation. A Docker image contains all dependencies and can really be transferred as single files (via docker save ) without further dependencies. Please find out more about air-gapped installation [here](../installation/docker#offlineair-gapped-installation).
Alternatively, you could install OpenProject on a virtual machine with Internet access and then re-use the VM image on the offline hosts.

### Can I use MySQL instead of PostgreSQL?

OpenProject has traditionally supported both MySQL and PostgreSQL, but in order to optimize for performance and SQL functionality, it is unfeasible to support both DBMS that are becoming more and more disjunct when trying to use more modern SQL features. This shift has started some years ago when full-text search was added for PostgreSQL, but at the time MySQL did not yet support it - and as of yet many distributions still do not support MySQL 8 natively.

This led us to the path of removing support in the upcoming stable releases of OpenProject in order to focus on these goals. [Please see our blog post on the matter for additional notes](https://www.openproject.org/blog/deprecating-mysql-support/).

### How can I migrate my existing MySQL database to PostgreSQL ?

Older installations of OpenProject are likely installed with a MySQL installation because the installer shipped with an option to auto-install it. With [pgloader](https://pgloader.io), it is trivially easy to convert a dump between MySQL and PostgreSQL installation. [We have prepared a guide](../misc/packaged-postgresql-migration ) on how to migrate to a PostgreSQL database if you previously used MySQL.

### How can I migrate from Bitnami to the official OpenProject installation packages?

Please follow these steps:

1. Make a dump of your Bitnami database to export your data. You can refer to the [Bitnami documentation](https://docs.bitnami.com/general/infrastructure/mysql/administration/backup-restore-mysql-mariadb/).
1. Make a dump of files you might have uploaded. You can refer to the [Bitnami documentation](https://docs.bitnami.com/general/apps/openproject/) to perform a full dump.
1. Copy both dumps to the server you want to install OpenProject on.
1. Install OpenProject using the packaged installation.
1. By default, this will allow you to install a PostgreSQL database, which we recommend. You can migrate your data from MySQL using [pgloader](https://pgloader.io)
1. Import the dump into your new database. You can get your configuration by running `sudo openproject config:get DATABASE_URL`
1. Extract the Bitnami backup, and copy your file assets into the relevant directory (e.g. in `/var/db/openproject/files` for uploaded files)
1. Restart OpenProject

### Are there extra fees to pay, in terms of installing the OpenProject software?

The Community edition and [Enterprise on-premises edition](https://www.openproject.org/enterprise-edition/) are on-premises solutions and thus need installation from your side while the [Enterprise cloud edition](https://www.openproject.org/enterprise-edition/#hosting-options) is hosted by us.
The Community edition is for free and we ask you to do the installation yourself. Of course we support you with a clear and easy [installation guide](https://www.openproject.org/download-and-installation/).
If you would like us to install the **Enterprise on-premises edition** for you, we are charging a fee of €300 (excluding VAT) for this once-off service. You can add the installation support during your [Enterprise on-premises edition booking process](../../enterprise-guide/enterprise-on-premises-guide/activate-enterprise-on-premises/#order-the-enterprise-on-premises-edition).

### How do I get SSL certificates (in case of installation support by OpenProject employee)? Do we have to purchase them?

You can either order the SSL certificates from your ISP or we can create them during installation using Let's Encrypt. If you want the former, you must store the certificates, keys and potentially the passphrase on the server so that they can be entered during the installation. If you want to use Let's Encrypt for encryption, please check whether your operating system supports the [certbot software](https://certbot.eff.org/instructions).

### How do you implement the routing so that the page requests intended for this project domain of ours land on the Apache server that is part of the OpenProject installation? What agreements or requirements do we have to discuss with our domain/webspace provider?

A DNS record needs to be placed at the ISP that connects the domain name you would like your OpenProject installation to be reachable at (e.g. [community.openproject.org](https://community.openproject.org/)) to the IP Address of your designated server (e.g. 13.226.159.10). The ports do not matter here as they can simply all be routed to the server. The server will then only listen on 80 and 443 and redirect 80 to 443. Depending on your network configuration, additional configurations need to be carried out e.g. on intermediary load balancers or switches.

### Does the email address used by OpenProject have to be within the our domain for OpenProject or can this also be another address?

The email address does not have to match the domain. For users, however, an email address that matches the domain could be easier to understand.

### How can I select the BIM edition during installation?

Please have a look at the [initial configuration instruction](../installation/packaged/#step-1-select-your-openproject-edition).

## Operation and upgrading

### How do I access my self hosted OpenProject version?

You can access it using a browser. Please see our [Installation & Upgrades Guide](../) for more information.

### My OpenProject instance is slow but my RAM isn't fully used. What can I do?

Set a higher number of web workers to allow more processes to be handled at the same time. Find out more [here](../operation/control) and about system requirements [here](../system-requirements/).

### I don't receive emails. Test email works fine but not the one for work package updates. What can I do?

There are two different types of emails in OpenProject: One sent directly within the request to the server (this includes the test mail) and one sent asynchronously, via a background job from the backend. The majority of mail sending jobs is run asynchronously to facilitate a faster response time for server request.

Use a browser to call your domain name followed by "health_checks/all" (e.g. `https://myopenproject.com/health_checks/all`). There should be entries about "worker" and "worker_backed_up". If PASSED is written behind it, everything is good.

If the health check does not return satisfying results, have a look if the background worker is running by entering `ps aux | grep jobs` on the server. If it is not running, no entry is returned. If it is running an entry with "jobs:work" at the end is displayed.

If the worker is not running please try a restart with `sudo openproject restart worker`.
If that doesn't help it could be that the worker is scaled to 0 for some reason, so please try `sudo openproject scale worker=1`.
If that doesn't help either, please have a look at your [logs](../operation/monitoring), which are accessible with `sudo openproject logs`.

Another approach would be to restart OpenProject completely, especially after changing the configuration of your SMTP server: `sudo openproject restart`.

### How can I enable OpenProject on boot?

This will be done automatically in case the package based installation is used.

### The packaged installation cannot be installed or upgraded due to errors. What could cause them?

For packaged installations, the openproject package behaves just like every other system package (dpkg or rpm packages, depending on your distribution). If you encounter errors while trying to install or upgrade, please check the following pieces of information first.

1. You have enough free space available on `/opt` or your root `/` partition. Verify that `df -h` has at least a few GB of free space.
2. You have enough inodes on your partitions left. Verify with `df -i` . As OpenProject packages contains a high number of files, these might cause problems with low free inode counts.
3. Make sure you do not have a virus scanner such as Sophos or other pieces of software blocking the installation of packages.

### After upgrading I receive the error message "Your OpenProject installation has pending database migrations. You have likely missed running the migrations on your last upgrade. Please check the upgrade guide to properly upgrade your installation." What does that mean?

For some updates of OpenProject, the database layout needs to be adapted to support new features and fix bugs. These changes need to be carried out as part of the update process. This is why it is important to always run `sudo openproject configure` as part of the update process.

Please also have a look at [our upgrade guide](../operation/upgrading).

### How can I set up a Remotely Managed Repository option for the integration between OpenProject and our Git server?

Are you using the packaged installation or are you running OpenProject using docker?
If the former you may have to run `sudo openproject reconfigure`. Leave everything the same but select git integration.

Once that's done all you have to do is enable automatic creation under /settings/repositories (*Administration -> System Settings -> Repositories*) and enable repositories by default under *Administration -> System Settings -> Projects* in the project modules if you want new projects to automatically get a git repository.

For existing projects you can enable the module in the project settings (*Project Settings -> Modules*) and then configure the repository under *Project Settings -> Repository* where you choose git and then "Git repository integrated into OpenProject".

Mind, that repository integration in the sense that you will be able to checkout the repository through OpenProject **does only work in the packaged installation, not docker**.

### How can I uninstall OpenProject (Community edition or Enterprise on-premises)?

The package based installation is intended to be run on a dedicated system. Dedicated in this case means that no other application software should be served by the server. The system can be either physical or virtual. Removing OpenProject is then equivalent with removing that system or docker instances.

In case the database is stored on a different system, e.g. within a database cluster, it needs to be removed separately. The database URL can be found within the OpenProject installation, via `openproject config:get DATABASE_URL`.

In case the attachments are stored on a different system, e.g. on an NFS or on S3, they also need to be removed separately.

### Does OpenProject prohibit users from logging into the application on more than one workstation at the same time with the same user ID?

It doesn't by default. There is a setting which enables this option: drop_old_sessions_on_login.

### Can the OpenProject force password expiration and prevent users from reusing a password?

There is no password expiration in OpenProject, but OpenProject can prevent the re-use of previous passwords via the password_count_former_banned setting. If you use an LDAP-Server for login that has this feature, you can archive this via your LDAP-Server. Other identity providers (e.g. KeyCloak) used via OpenID Connect or SAML can also do this. You can set up these rules in these identity providers directly and use them for authentication.
