---
sidebar_navigation:
  title: FAQ
  priority: 4
---


# Frequently asked questions - FAQ

TODO: review

## How can I install an OpenProject plugin?

Our [official installation page][install-page] has instructions on how to customize your OpenProject installation.
Please note that customization is not yet supported for Docker-based installations.

[install-page]: https://www.openproject.org/download-and-installation/

## How to migrate from Bitnami to the official OpenProject installation packages?

Please follow the following steps:

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



## Can I use NginX instead of Apache webserver?

Yes, but you will lose the ability to enable Git/SVN repository integration. Note that the OpenProject installer does not support NginX, so you will have to ask to disable the Apache2 integration when running the installer, and then configure NginX yourself so that it forwards traffic to the OpenProject web process (listening by default on 127.0.0.1:6000). If using SSL/TLS, please ensure you set the header value `X-Forwarded-Proto https` so OpenProject can correctly produce responses. [For more information, please visit our forums](https://community.openproject.com/projects/openproject/boards).



## Can I use MySQL instead of PostgreSQL?

OpenProject has traditionally supported both MySQL and PostgreSQL, but in order to optimize for performance and SQL functionality, it is unfeasible to support both DBMS that are becoming more and more disjunct when trying to use more modern SQL features. This shift has started some years ago when full-text search was added for PostgreSQL, but at  the time MySQL did not yet support it - and as of yet many distributions still do not support MySQL 8 natively.

This led us to the path of removing support in the upcoming stable releases of OpenProject in order to focus on these goals. [Please see our blog post on the matter for additional notes](https://www.openproject.org/deprecating-mysql-support/).



## How can I migrate my existing MySQL database to PostgreSQL ?

Older installations of OpenProject are likely installed with a MySQL installation because the installer shipped with an option to auto-install it. With [pgloader](https://pgloader.io), it is trivially easy to convert a dump between MySQL and PostgreSQL installation. [We have prepared a guide](https://www.openproject.org/operations/upgrading/migrating-packaged-openproject-database-postgresql/) on how to migrate to a PostgreSQL database if you previously used MySQL. 



## My favorite linux distribution is not listed. What can I do?

You can either try the manual installation, or ask in the forum whether this could be added to the list of supported distributions. We try to support recent major distributions, but due to maintenance and operations cost cannot freely add to that list.



## What is the better option to run OpenProject in production environments: docker or linux packages?

We recommend the Linux packages [if you have a compatible distribution](https://www.openproject.org/system-requirements/) and a separate machine for OpenProject, since it will allow for the easiest and most flexible setup. Use a docker-based image either for quickly spinning up an environment or if you have knowledge in setting up and maintaing docker-based installations.

Please note we currently  do not yet provide a docker-compose based image, [please see this ticket for a timeline](https://community.openproject.com/wp/30551) and help us contribute one!



## Do you provide different release channels?

Yes! We release OpenProject in separate release channels that you can try out. For production environments, **always** use the `stable/MAJOR`  (e.g., stable/9) package source that will receive stable and release updates. Every major upgrade will result in a source switch (from `stable/7` to `stable/8` for example).

A closer look at the available branches:

* [stable/9](https://packager.io/gh/opf/openproject/refs/stable/9): Latest stable releases, starting with 9.0.0 until the last minor and patch releases of 9.X.Y are released, this will receive updates.
* [release/9.0](https://packager.io/gh/opf/openproject/refs/release/9.0): Regular (usually daily) release builds for the current next patch release (or for the first release in this version, such as 9.0.0). This will contain early bugfixes before they are being release into stable. **Do not use in production**. But, for upgrading to the next major version, this can be regarded as a _release candidate channel_ that you can use to test your upgrade on a copy of your production environment.
* [dev](https://packager.io/gh/opf/openproject/refs/dev): Daily builds of the current development build of OpenProject. While we try to keep this operable, this may result in broken code and/or migrations from time to time. Use when you're interested what the next release of OpenProject will look like. **Do not use in production!**

For more information, please visit our dedicated [page regarding release candidates and channels](https://www.openproject.org/download-and-installation/release-candidate/).



## How to upgrade my OpenProject installation?

Please refer to the documentation at https://www.openproject.org/operations/upgrading/



## What skills should I have for the installation?

If you use the packaged installation, you should have a basic knowledge of Linux and the command-line terminal.

If you use the docker images, you need to be familiar with Docker and Docker volumes.



## Why don't you support Windows?

Ruby support on Windows is notoriously difficult, however you might be able to run the Docker image, or use the unofficial Windows stack provided by [Bitnami](https://bitnami.com/stack/openproject/installer). We would welcome feedback and reported experiences on running OpenProject on Windows, please reach out to us if you can contribute some information.



## How to backup and restore my OpenProject installation?

Please refer to the [backup documentation](../backing-up) for the packaged installation.



## How can I install a free SSL certificate using let's encrypt?

You can get an SSL certificate for free via Let's Encrypt.
Here is how you do it using [certbot](https://github.com/certbot/certbot):

    curl https://dl.eff.org/certbot-auto > /usr/local/bin/certbot-auto
    chmod a+x /usr/local/bin/certbot-auto
    
    certbot-auto certonly --webroot --webroot-path /opt/openproject/public -d openprojecct.mydomain.com

This requires your OpenProject server to be available from the Internet on port 443 or 80.
If this works the certificate (`cert.pem`) and private key (`privkey.pem`) will be created under `/etc/letsencrypt/live/openproject.mydomain.com/`. Configure these for OpenProject to use by running `openproject reconfigure` and choosing yes when the wizard asks for SSL.

Now this Let's Encryt certificate is only valid for 90 days. To renew it automatically all you have to do is to add the following entry to your crontab (run `crontab -e`):

    0 1 * * * certbot-auto renew --quiet --post-hook "service apache2 restart"

This will execute `certbot renew` every day at 1am. The command checks if the certificate is expired and renews it if that is the case. The web server is restarted in a post hook in order for it to pick up the new certificate.
