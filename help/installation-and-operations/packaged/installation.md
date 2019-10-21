# Packaged Installation Guide

The packaged installation of OpenProject is the easiest way to install and maintain OpenProject, provided a supported distribution exists and you can allocate an isolated server for OpenProject. The package will:

- guide you  through all required steps

- install all required libraries and dependencies

- install a local PostgreSQL database or allow you to connect to an existing PostgreSQL database

- allow you to install and configure an outer Apache web server 

- setup SSL/TLS encryption for the Apache server

- configure repositories (Git/SVN)

- configure email settings

  



## Supported distributions



The packaged installation is provided for the following distributions:



| Distribution (64 bits only)     | Identifier   | init system |
| ------------------------------- | ------------ | ----------- |
| CentOS/RHEL 7.x                 | centos-7     | systemd     |
| Debian 9 Stretch                | debian-9     | systemd     |
| Debian 10 Stretch               | debian-10    | systemd     |
| Suse Linux Enterprise Server 12 | sles-12      | sysvinit    |
| Ubuntu 16.04 Xenial Xerus       | ubuntu-16.04 | upstart     |
| Ubuntu 18.04 Bionic Beaver      | ubuntu-18.04 | systemd     |



# Install the OpenProject package



As the first step, you will need to add the OpenProject package source to the package manager of your distribution. Please follow the steps with your root user (or with `sudo` if your distribution supports it) according to your distribution:


<div class="installation-distribution">

### Ubuntu 16.04.

**1. Import the packager.io repository signing key**

Import the PGP key used to sign our packages. Since we're using the *packager.io* platform to distribute our packages, both package source and signing key are tied to their service.

```bash
wget -qO- https://dl.packager.io/srv/opf/openproject/key | sudo apt-key add -
```

**2. Add the OpenProject package source**

```
sudo wget -O /etc/apt/sources.list.d/openproject.list \
  https://dl.packager.io/srv/opf/openproject/stable/10/installer/ubuntu/16.04.repo
```

**3. Install the OpenProject Community Edition package**

Using the following commands, apt will check the new package source and install the package and all required dependencies.

```bash
apt-get update
apt-get install openproject
```

</div>
<div class="installation-distribution">

### Ubuntu 18.04

**1. Import the packager.io repository signing key**

Import the PGP key used to sign our packages. Since we're using the *packager.io* platform to distribute our packages, both package source and signing key are tied to their service.

```bash
wget -qO- https://dl.packager.io/srv/opf/openproject/key | sudo apt-key add -
```

**2. Ensure that universe package source is added**

You may run into issues trying to install the `dialog` package in Ubuntu 18.04. To resolve this, please ensure you have the universe APT source

```bash
sudo add-apt-repository universe
```

**3. Add the OpenProject package source**

```
sudo wget -O /etc/apt/sources.list.d/openproject.list \
  https://dl.packager.io/srv/opf/openproject/stable/10/installer/ubuntu/18.04.repo
```

**4. Install the OpenProject Community Edition package**

Using the following commands, apt will check the new package source and install the package and all required dependencies.

```bash
apt-get update
apt-get install openproject
```

</div>
<div class="installation-distribution">

### Debian 9

**1. Import the packager.io repository signing key**

Import the PGP key used to sign our packages. Since we're using the *packager.io* platform to distribute our packages, both package source and signing key are tied to their service.

```bash
wget -qO- https://dl.packager.io/srv/opf/openproject/key | sudo apt-key add -
```

**2. Add the OpenProject package source**

```
wget -O /etc/apt/sources.list.d/openproject.list \
  https://dl.packager.io/srv/opf/openproject/stable/10/installer/debian/9.repo
```

**3. Install the OpenProject Community Edition package**

Using the following commands, apt will check the new package source and install the package and all required dependencies.

```bash
apt-get update
apt-get install openproject
```

</div>
<div class="installation-distribution">

### Debian 10

**1. Import the packager.io repository signing key**

Import the PGP key used to sign our packages. Since we're using the *packager.io* platform to distribute our packages, both package source and signing key are tied to their service.

```bash
wget -qO- https://dl.packager.io/srv/opf/openproject/key | sudo apt-key add -
```

**2. Add the OpenProject package source**

```
wget -O /etc/apt/sources.list.d/openproject.list \
  https://dl.packager.io/srv/opf/openproject/stable/10/installer/debian/10.repo
```

**3. Install the OpenProject Community Edition package**

Using the following commands, apt will check the new package source and install the package and all required dependencies.

```bash
apt-get update
apt-get install openproject
```

</div>
<div class="installation-distribution">

### Centos 7

**1. Add the OpenProject package source**

```
sudo wget -O /etc/yum.repos.d/openproject.repo \
  https://dl.packager.io/srv/opf/openproject/stable/10/installer/el/7.repo
```

**2. Install the OpenProject Community Edition package**

Using the following command, yum will install the package and all required dependencies.

```bash
sudo yum install openproject
```

</div>
<div class="installation-distribution">

### SLES 12

**1. Add the OpenProject package source**

```
wget -O /etc/zypp/repos.d/openproject.repo \
  https://dl.packager.io/srv/opf/openproject/stable/10/installer/sles/12.repo
```

The package source is now registered as `openproject`.

**2. Install the OpenProject Community Edition package**

Using the following command, zypper will install the package and all required dependencies.

```bash
zypper install openproject
```

</div>



# Package configuration

The last but most important step to your OpenProject installation is the configuration wizard. It will set up the connection to a database and configure the application according to your environment.

The wizard can be activated through the command `sudo openproject configure` and will guide you through all necessary steps to set up your OpenProject installation. 

Once you have configured this wizard, your selection will be persisted in a configuration file in `/etc/openproject/installer.dat` and subsequent executions of `sudo openproject configure` will re-use these values, only showing you wizard steps for options you have not yet selected an option for.

In case you want to run through all wizard options again, you can do so by executing `sudo openproject reconfigure`. This will show all wizard steps, but again keep values you entered before showing in the input fields. You can skip dialogs you do not want to change simply by confirming them with `ENTER`.



## Step 0: Prepare and the configuration script

You are now ready to configure your OpenProject instance. Please prepare necessary parameters:

- If you wish to connect to an existing database, have your hostname / user:password and database name ready
- If you have SSL/TLS certificates ready, please note the paths to the certificate, key file and CA bundle



To start the configuration wizard, please run the following command  with `sudo`, or as root.

```bash
sudo openproject configure
```



**Note:** In case you mistyped or need to correct a configuratin option, you can always safely cancel the configuration wizard by pressing `CTRL+C` and restart verything by running `openproject reconfigure`. This happens often due to waiting on setups being cleared, such as DNS entries for your domain or SSL/TLS certificates that need to be set up later.

## Step 1: PostgreSQL database configuration

The first dialog in the wizard allows you to choose an option for the PostgreSQL database connection. 



![01-postgres](https://github.com/opf/openproject/blob/dev/docs/installation/packaged/screenshots/01-postgres.png?raw=true)



The dialog allows you to choose from three options:



### Install a new PostgreSQL server and database locally (default)

Choose this option if you want OpenProject to set up and configure a local database server manually. This is the best choice if you are unfamiliar with adminstering databases, or do not have a separate PostgreSQL database server installed that you want to connect to.



### Use an existing PostgreSQL database

Choose this option if you have a PostgreSQL database server installed either on the same host as the OpenProject package is being installed on, or on another server you can connect to from this machine.

The wizard will show you multiple additional steps in this case to enter the hostname, username & password as well as the database name for the PostgreSQL database.



### Skip (not recommended)

The wizard will not try to connect to any database. You will have to specify a database manually thorugh the `DATABASE_URL` environment variable. If you choose skip and did not set a `DATABASE_URL`, the configuration process will fail.

You can set this `DATABASE_URL` parameter yourself to a PostgreSQL database URL.

```
openproject config:set DATABASE_URL="postgresql://[user[:password]@][host][:port][/dbname][?param1=value1&...]
```



## Step 2: Apache2 web server

OpenProject comes with an internal ruby application server, but that will run only on a local interface. It needs an external web server handling connections from the outside world and pass those to the application server with a proxy / reverse-proxy configuration.

This wizard step allows you to auto-install an Apache2 web server to function as that external web server.

![02a-apache](https://github.com/opf/openproject/blob/dev/docs/installation/packaged/screenshots/02a-apache.png?raw=true)



**Install Apache2 web server** (default)

We recommend that you let OpenProject install and configure the outer web server, in which case we will install an Apache2 web server with a VirtualHost listening to the domain name you specify, optionally providing SSL/TLS termination.



**Skip** (not recommended)

The installer will not set up an external web server for accessing. You will need to either install and set up a web server such as Apache2 or Nginx to function as the web server forwarding to our internal server listeing at `localhost:6000` by proxying.

Only choose this option if you have a local Apache2 installed that the OpenProject package may not control,

or need to use a different web server such as Nginx. Please note that not all functionality (especially regarding Repositories) are supported on Nginx. 

When installing with an existing Apache2, you can use our [installation wizard templates](https://github.com/pkgr/addon-apache2/tree/master/conf) for guidance on how to set up the integration. [For a minimal nginx config, please see this gist](https://gist.github.com/seLain/375d16ccd4542e3727e97a7478187d3a) as as starting point.

(Please help us improve this section with your feeback and experiences of integrating OpenProject in other servers. [You can find this documentation on GitHub](https://github.com/opf/openproject/blob/dev/docs/installation/packaged/2-configuration.md)).



In case you select to auto-install Apache2, multiple dialogs will request the parameters for setting it up.



**Domain name**

Enter the fully qualified domain where your OpenProject installation will be reached at. This will become the `ServerName` of your apache VirtualHost and is also used to generate full links from OpenProject, such as in emails.

![02b-hostname](https://github.com/opf/openproject/blob/dev/docs/installation/packaged/screenshots/02b-hostname.png?raw=true)



**Server path prefix**

If you wish to install OpenProject under a server path prefix, such as `yourdomain.example.com/openproject`, please specify that prefix here with a leading slash. For example: `/openproject`. If OpenProject should respond to `http(s)://yourdomain.example.com` as specified in the previous dialog, simply leave this dialog empty and confirm by pressing `ENTER`.

![02c-prefix](https://github.com/opf/openproject/blob/dev/docs/installation/packaged/screenshots/02c-prefix.png?raw=true)





**SSL/TLS configuration**

OpenProject can configure the necessary steps in your VirtualHost to terminate SSL/TLS connections at the web server. If you have SSL certificates and want to use SSL/TLS (recommended), select **Yes**.

In that case, you will be shown three additional dialogs to enter the certificate details:

1. The absolute SSL certificate path
2. The absolute SSL private key path
3. (optional, leave empty unless needed) The path to the Certificate Authority bundle for the certificate

![02d-ssl](https://github.com/opf/openproject/blob/dev/docs/installation/packaged/screenshots/02d-ssl.png?raw=true)



## Step 3: SVN/Git integration server

If you have selected to auto-install an Apache2 web server, you will be asked whether you want to install Git and Subversion repository support. In case you do not need it or when in doubt, choose **Skip** for both options.

For more information, [see our help on repositories](https://www.openproject.org/help/repository/)

![03-repos](https://github.com/opf/openproject/blob/dev/docs/installation/packaged/screenshots/03-repos.png?raw=true)



## Step 4: Outgoing email configuration

OpenProject requires a setup for sending outgoing emails for notifications, such as updates to created tickets or other notifications you and your users receive.

![04-mail](https://github.com/opf/openproject/blob/dev/docs/installation/packaged/screenshots/04-mail.png?raw=true)



**Sendmail** (default)

Uses a local sendmail installation or sets up a local-only postfix MTA in case you do not have sendmail.

Easiest setup as it does not require an SMTP configuration, but your Mails may not be delivered consistently depending on your mail accounts or firewall setup.

**SMTP** (recommend for production systems)

Allows you to connect to a SMTP host through authentication types `NONE`,  `PLAIN,` `LOGIN`, or `CRAM-MD5`. Use this if you have a dedicated mail account to use for delivering OpenProject mail, or when sendmail does not work due to your local firewall / mail relay setup.

**Skip** (not recommended)

Does not set up mail configuration. You can configure the mail setup in OpenProject by visiting `openproject.example.com/settings?tab=notifications` in your installation. For more information, [visit our help page on this topic](https://www.openproject.org/help/system-settings/email-notification-settings/).



## Step 5: Administrator email

The wizard will ask you for an administrative email address to create the administrator account with for initial login. Enter your email address to have it tied to the admin account.

![05-admin](https://github.com/opf/openproject/blob/dev/docs/installation/packaged/screenshots/05-admin.png?raw=true)



### Last step: Memcached server

OpenProject heavily relies on caching, which is why the wizard suggests you to install a local memcached server the OpenProject instances can connect to. You should always set this to `install` unless you have a reason to configure another caching mechanism - for example when configuring multiple shared instances of OpenProject.

![06-cache](https://github.com/opf/openproject/blob/dev/docs/installation/packaged/screenshots/06-cache.png?raw=true)



With this last step confirmed, the OpenProject wizard will complete, and apply all the configuration options that you have just chosen. This might take a few minutes depending on your machine and internet connection, as OpenProject might need to install additional packages (such as the web server, database) depending on your selections.

In case this process crashes or exits with an obvious error, please keep the output and send your configuration from`/etc/openproject/installer.dat` (removing any passwords from it) to us at support@openproject.com , or [reach out to the community forums](https://community.openproject.com/projects/openproject/forums). 

When this process completes, it will have started the internal application and web servers, the background jobs to process work-intensive jobs, and set up the connection to the database.

You can log into the instance initially by visiting your installation at `http://<openproject.example.com>/<server prefix>` and log in initially using the user/password combination **admin/admin.** You will be asked to change this password immediately after the first login.

This concludes the initial configuration, the following sections will detail the commands you can use to additionall configure and/or maintain your installation.



## Managing your OpenProject installation

The openproject package comes with a command line tool to help manage the
application. To see all possible command options of this tool you can run:

    admin@openproject-demo:~# sudo openproject
    Usage:
      openproject run COMMAND [options]
      openproject scale PROCESS=NUM
      openproject logs [--tail|-n NUMBER]
      openproject config:get VAR
      openproject config:set VAR=VALUE
      openproject config:unset VAR
      openproject reconfigure
      openproject restart [PROCESS]

In the rest of this section we'll go over some of the most important commands.

#### Run commands like rake tasks or rails console

The openproject command line tool supports running rake tasks and known scripts
like the rails console:

    # Get the current version of OpenProject
    sudo openproject run bundle exec rake version
    # Or spawn an interactive console
    sudo openproject run console
    # or a rake task
    sudo openproject run rake db:migrate
    # or check the version of ruby used by openproject
    sudo openproject run ruby -v

#### Show logs

The command line tool can also be used to see the log information. The most
typically use case is to show/follow all current log entries. This can be
accomplished using the the `–tail` flag. See example below:

    sudo openproject logs --tail

Note:

* On distributions that are based on systemd, all the logs are sent to journald, so you can also display them via `journalctl`.
* On older distributions that use either sysvinit or upstart, all the logs are stored in `/var/log/openproject/`.

#### Scaling the number of web workers

Depending on your free RAM on your system, we recommend you raise the default number of workers. The default from 9.0.3 onwards is four worker processes. Each worker will take roughly 300-400MB RAM.

We recommend at least four workers. Please check your current worker count with

```bash
    sudo openproject config:get OPENPROJECT_WEB_WORKERS
```

If it returns nothing, the default worker count of `4` applies. To increase or decrease the worker count, call

```bash
    sudo openproject config:set OPENPROJECT_WEB_WORKERS=number
```

Where `number` is a positive number between 1 and `round(AVAILABLE_RAM * 1.5)`.

After changing these values, call `sudo openproject configure` to apply it to the web server.

#### Reconfigure the application

At any point in time, you can reconfigure the whole application by re-running the installer with the following command:

    sudo openproject reconfigure

The command above will bring up the installation wizard again. Please be aware that it will start the configuration/installation process from scratch. You can choose to modify existing entries, or just leave them as they are if you want to reuse them (note that passwords will appear as "blank" entries in their
respective input fields, but you don't need to enter them again if don't want to modify them).

#### Upgrading the application

As openproject is a system package, it will be automatically updated when you install your package updates.

After you have just updated your OpenProject version, you should run `openproject configure` (see section below), which would automatically reuse your previous configuration, and only asks for your input if new configuration options are available.

For a complete guide on upgrading your OpenProject packaged installation, [please see this guide](upgrading).

#### Inspect the existing configuration

You can list all of the environment variables accessible to the application by running:

    sudo openproject config
    # this will return something like:
    DATABASE_URL=mysql2://openproject:9ScapYA1MN7JQrPR7Wkmp7y99K6mRHGU@127.0.0.1:3306/openproject
    SECRET_TOKEN=c5aa99a90f9650404a885cf5ec7c28f7fe1379550bb811cb0b39058f9407eaa216b9b2b22d27f58fb15ac21adb3bd16494ebe89e39ec225ef4627db048a12530
    ADMIN_EMAIL=mail@example.com
    EMAIL_DELIVERY_METHOD=smtp
    SMTP_DOMAIN=example.com
    SMTP_HOST=smtp.example.com
    SMTP_PASSWORD=mail
    SMTP_PORT=25
    SMTP_URL=smtp://mail:mail@smtp.example.com:25/example.com
    SMTP_USERNAME=mail
    SMTP_ENABLE_STARTTLS_AUTO=true
    SMTP_AUTHENTICATION=plain
    WEB_CONCURRENCY=4
    WEB_TIMEOUT=15
    RAILS_CACHE_STORE=memcache
    SESSION_STORE=cache_store



# Frequently asked questions - FAQ

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

Please refer to the [backup documentation](backup) for the packaged installation.



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
