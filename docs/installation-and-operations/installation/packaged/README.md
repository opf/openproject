---
sidebar_navigation:
  title: Packages
  priority: 400
---

# Install OpenProject with DEB/RPM packages

The packaged installation of OpenProject is the recommended way to install and maintain OpenProject using DEB or RPM packages.

The package will:

- guide you through all the required steps

- install all the required libraries and dependencies

- install a local PostgreSQL database or allow you to connect to an existing PostgreSQL database

- allow you to install and configure an outer Apache web server (recommended)

- setup SSL/TLS encryption for the Apache server (optional)

- configure repositories (Git/SVN) (optional)

- configure email settings

The package is available for the following Linux distributions:

| Distribution (64 bits only)                 |
| ------------------------------------------- |
| [Ubuntu 20.04 Focal](#ubuntu-2004)          |
| [Ubuntu 18.04 Bionic Beaver](#ubuntu-1804)  |
| [Ubuntu 16.04 Xenial Xerus](#ubuntu-1604)   |
| [Debian 11 Bullseye](#debian-11)              |
| [Debian 10 Buster](#debian-10)              |
| [Debian 9 Stretch](#debian-9)               |
| [CentOS/RHEL 8.x](#centos-8--rhel-8)                    |
| [CentOS/RHEL 7.x](#centos-7--rhel-7)                    |
| [Suse Linux Enterprise Server 12](#sles-12) |

Please ensure that you are running on a 64bit system before proceeding with the installation. You can check by running the `uname -i` command on the target server and verifying that it outputs `x86_64`:

```bash
$ uname -i
x86_64
```

<div class="alert alert-info" role="alert">
**Important note:** Please note that the packaged installation works best when running on a dedicated server or virtual machine, as we cannot ensure that the components installed and configured by the OpenProject installer will work on systems that have been already customized. If you must install OpenProject on a server where other software is running, or with an already configured Apache or NginX server, then you should have a look at the Docker-based installation instead.

</div>

## Ubuntu Installation

### Ubuntu 20.04

Import the PGP key used to sign our packages:

```bash
wget -qO- https://dl.packager.io/srv/opf/openproject/key | sudo apt-key add -
```

Add the OpenProject package source:

```bash
sudo wget -O /etc/apt/sources.list.d/openproject.list \
  https://dl.packager.io/srv/opf/openproject/stable/12/installer/ubuntu/20.04.repo
```

Download the OpenProject package:

```bash
sudo apt-get update
sudo apt-get install openproject
```

Then finish the installation by reading the [*Initial configuration*][initial-config] section.

<video src="https://openproject-docs.s3.eu-central-1.amazonaws.com/videos/openproject-installation-ubuntu.mp4" type="video/mp4" controls="" style="width:100%"></video>

### Ubuntu 18.04

Import the PGP key used to sign our packages:

```bash
wget -qO- https://dl.packager.io/srv/opf/openproject/key | sudo apt-key add -
```

Add the OpenProject package source:

```bash
sudo wget -O /etc/apt/sources.list.d/openproject.list \
  https://dl.packager.io/srv/opf/openproject/stable/12/installer/ubuntu/18.04.repo
```

Download the OpenProject package:

```bash
sudo apt-get update
sudo apt-get install openproject
```

Then finish the installation by reading the [*Initial configuration*][initial-config] section.

### Ubuntu 16.04

Import the PGP key used to sign our packages:

```bash
wget -qO- https://dl.packager.io/srv/opf/openproject/key | sudo apt-key add -
```

Add the OpenProject package source:

```bash
sudo wget -O /etc/apt/sources.list.d/openproject.list \
  https://dl.packager.io/srv/opf/openproject/stable/12/installer/ubuntu/16.04.repo
```

Download the OpenProject package:

```bash
sudo apt-get update
sudo apt-get install openproject
```

Then finish the installation by reading the [*Initial configuration*][initial-config] section.

## Debian Installation

### Debian 11

Import the PGP key used to sign our packages:

```bash
wget -qO- https://dl.packager.io/srv/opf/openproject/key | sudo apt-key add -
```

Add the OpenProject package source:

```bash
sudo wget -O /etc/apt/sources.list.d/openproject.list \
  https://dl.packager.io/srv/opf/openproject/stable/12/installer/debian/11.repo
```

Download the OpenProject package:

```bash
sudo apt-get update
sudo apt-get install openproject
```

Then finish the installation by reading the [*Initial configuration*][initial-config] section.

### Debian 10

Import the PGP key used to sign our packages:

```bash
wget -qO- https://dl.packager.io/srv/opf/openproject/key | sudo apt-key add -
```

Add the OpenProject package source:

```bash
sudo wget -O /etc/apt/sources.list.d/openproject.list \
  https://dl.packager.io/srv/opf/openproject/stable/12/installer/debian/10.repo
```

Download the OpenProject package:

```bash
sudo apt-get update
sudo apt-get install openproject
```

Then finish the installation by reading the [*Initial configuration*][initial-config] section.

### Debian 9

Import the PGP key used to sign our packages:

```bash
wget -qO- https://dl.packager.io/srv/opf/openproject/key | sudo apt-key add -
```

Add the OpenProject package source:

```bash
sudo wget -O /etc/apt/sources.list.d/openproject.list \
  https://dl.packager.io/srv/opf/openproject/stable/12/installer/debian/9.repo
```

Download the OpenProject package:

```bash
sudo apt-get update
sudo apt-get install openproject
```

Then finish the installation by reading the [*Initial configuration*][initial-config] section.

## CentOS Installation

### CentOS 8 / RHEL 8

Add the OpenProject package source:

```bash
sudo wget -O /etc/yum.repos.d/openproject.repo \
  https://dl.packager.io/srv/opf/openproject/stable/12/installer/el/8.repo
```

If it is not already enabled, make sure to enable [Extra Packages for Enterprise Linux](https://fedoraproject.org/wiki/EPEL) (EPEL).

```bash
sudo dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm -y
```

Download the OpenProject package:

```bash
sudo yum install openproject
```

Then finish the installation by reading the [*Initial configuration*][initial-config] section.

**Note:** On this distribution full-text extraction for attachments [*is not supported*](#full-text-extraction-not-supported) by default.

### CentOS 7 / RHEL 7

Add the OpenProject package source:

```bash
sudo wget -O /etc/yum.repos.d/openproject.repo \
  https://dl.packager.io/srv/opf/openproject/stable/12/installer/el/7.repo
```

Download the OpenProject package:

```bash
sudo yum install openproject
```

Then finish the installation by reading the [*Initial configuration*][initial-config] section.

**Note:** On this distribution full-text extraction for attachments [*is not supported*](#full-text-extraction-not-supported) by default.

## SUSE Linux Enterprise Server (SLES) Installation

### SLES 12

Add the OpenProject package source:

```bash
wget -O /etc/zypp/repos.d/openproject.repo \
  https://dl.packager.io/srv/opf/openproject/stable/12/installer/sles/12.repo
```

Download the OpenProject package:

```bash
sudo zypper install openproject
```

Then finish the installation by reading the [*Initial configuration*][initial-config] section.

**Note:** On SLES12 full-text extraction for attachments [*is not supported*](#full-text-extraction-not-supported) by default.

[initial-config]: #initial-configuration

# Full-text extraction not supported

For some distributions we do not provide the required dependencies for full-text extraction of attachments. If you need this feature, please install the required dependencies (`catdoc unrtf poppler-utils tesseract-ocr`) manually. For more information, [please see the plaintext gem](https://github.com/planio-gmbh/plaintext). Once installed, check `Administration > Information` to see if OpenProject is able to pick up these dependencies.

# Initial Configuration

After you have successfully installed the OpenProject package, you can now perform the initial configuration of OpenProject, using the wizard that ships with the OpenProject package.

## Prerequisites

- If you wish to connect to an existing database server instead of setting up a local database server, please make sure to have your database hostname, port, username and password ready. The database username used to connect to the existing database must have the CREATE DATABASE privilege.

- If you want to enable HTTPS, then you will need to provide the path (on the server) to your certificate file, private key file, and CA bundle file.

## Step 0: Start the wizard

To start the configuration wizard, please run the following command  with `sudo`, or as root:

```bash
sudo openproject configure
```

**Notes:**

* In case you mistype or need to correct a configuration option, you can always safely cancel the configuration wizard by pressing `CTRL+C` and restart it by running `sudo openproject reconfigure`.

* Every time you will run the OpenProject wizard, your choices will be persisted in a configuration file at `/etc/openproject/installer.dat` and subsequent executions of `sudo openproject configure` will re-use these values, only showing you the wizard steps for options you have not yet been asked for.

* In case you want to run through all the wizard options again, you can do so by executing `sudo openproject reconfigure`. This will show all wizard steps, but again keep values you entered before showing in the input fields. You can skip dialogs you do not want to change simply by confirming them with `ENTER`.

## Step 1: Select your OpenProject Edition

OpenProject comes in two editions:

* the default edition, which is targeted at general project management.

* the BIM edition, which is specifically target at the construction industry.

![select-edition](select-edition.png)

You can find more about the BIM edition on [this page](https://www.openproject.org/bim-project-management/).

<div class="alert alert-info" role="alert">
This wizard step is only available on the following distributions:

* RHEL/CentOS 8
* Ubuntu 20.04
* Ubuntu 18.04
* Debian 10
* Debian 11

On older distributions, this wizard step won't be displayed, and the installation will default to the default edition.
</div>

## Step 2: PostgreSQL database configuration

OpenProject requires a PostgreSQL database to store your data. This wizard step allows you to choose an option for the PostgreSQL database connection: 

![01-postgres](01-postgres.png)

The dialog allows you to choose from three options:

### Install a new PostgreSQL server and database locally (default)

Choose this option if you want OpenProject to set up and configure a local database server manually. This is the best choice if you are unfamiliar with administering databases, or do not have a separate PostgreSQL database server installed that you want to connect to.

### Use an existing PostgreSQL database

Choose this option if you have a PostgreSQL database server installed either on the same host as the OpenProject package is being installed on, or on another server you can connect to from this machine.

The wizard will show you multiple additional steps in this case to enter the hostname, username & password as well as the database name for the PostgreSQL database.

### Skip (not recommended)

The wizard will not try to connect to any database. You will have to specify a database manually through the `DATABASE_URL` environment variable. If you choose skip and did not set a `DATABASE_URL`, the configuration process will fail.

You can set this `DATABASE_URL` parameter yourself to a PostgreSQL database URL.

```bash
sudo openproject config:set DATABASE_URL="postgresql://[user[:password]@][host][:port][/dbname][?param1=value1&...]
```

## Step 3: Apache2 web server

OpenProject comes with an internal ruby application server, but this server only listens on a local interface. To receive connections from the outside world, it needs a web server that will act as a proxy to forward incoming connections to the OpenProject application server.

This wizard step allows you to auto-install an Apache2 web server to function as that proxy.

![02a-apache](02a-apache.png)

The available options are:

### **Install Apache2 web server** (default)

We recommend that you let OpenProject install and configure the outer web server, in which case we will install an Apache2 web server with a VirtualHost listening to the domain name you specify, optionally providing SSL/TLS termination.

In case you select to auto-install Apache2, multiple dialogs will request the parameters for setting it up:

**Domain name**

Enter the fully qualified domain where your OpenProject installation will be reached at. This will become the `ServerName` of your apache VirtualHost and is also used to generate full links from OpenProject, such as in emails.

![02b-hostname](02b-hostname.png)

**Server path prefix**

If you wish to install OpenProject under a server path prefix, such as `yourdomain.example.com/openproject`, please specify that prefix here with a leading slash. For example: `/openproject`. If OpenProject should respond to `http(s)://yourdomain.example.com` as specified in the previous dialog, simply leave this dialog empty and confirm by pressing `ENTER`.

![02c-prefix](02c-prefix.png)

**SSL/TLS configuration**

OpenProject can configure Apache to support HTTPS (SSL/TLS). If you have SSL certificates and want to use SSL/TLS (recommended), select **Yes**.

In that case, you will be shown three additional dialogs to enter the certificate details:

1. The absolute SSL certificate path
2. The absolute SSL private key path
3. The path to the Certificate Authority bundle for the certificate (optional, leave empty unless needed)

![02d-ssl](02d-ssl.png)



**External SSL/TLS termination**

<div class="alert alert-warning" role="alert">

If you terminate SSL externally before the request hits the OpenProject server, you need to follow the following instructions to avoid errors in routing. If you want to use SSL on the server running OpenProject, skip this section.

</div>

If you have a separate server that is terminating SSL and only forwarding/proxying to the OpenProject server, you must select "No" in this dialog. However, there are some parameters you need to put into your outer configuration.

- If you're proxying to the openproject server, you need to forward the HOST header to the internal server. This ensures that the host name of the outer request gets forwarded to the internal server. Otherwise you might see redirects in your browser to the internal host that OpenProject is running on.
  - In Apache2, set the `ProxyPreserveHost On`directive 
  - In NginX, use the following value: `proxy_set_header X-Forwarded-Host $host:$server_port;`
- If you're terminating SSL on the outer server, you need to set the `X-Forwarded-Proto https`header to let OpenProject know that the request is HTTPS, even though its been terminated earlier in the request on the outer server.
  - In Apache2, use `RequestHeader set "X-Forwarded-Proto" https`
  - In Nginx, use `proxy_set_header X-Forwarded-Proto https;`

- Finally, to let OpenProject know that it should create links with 'https' when no request is available (for example, when sending emails), you need to set the following setting: `openproject config:set SERVER_PROTOCOL_FORCE_HTTPS="true"` followed by an `openproject configure`. This ensures that OpenProject responds correctly with secure cookies even though it was not configured for https in the server configuration.



### Skip (not recommended)

The installer will not set up an external web server for accessing. You will need to either install and set up a web server such as Apache2 or Nginx to function as the web server forwarding to our internal server listening at `localhost:6000` by proxying.

Only choose this option if you have a local Apache2 installed that the OpenProject package may not control, or need to use a different web server such as Nginx. Please note that not all functionality (especially regarding Repositories) are supported on Nginx. 

When installing with an existing Apache2, you can take a look at the source of our [installation  templates](https://github.com/pkgr/addon-apache2/tree/master/conf) for guidance on how to set up the integration. 

[Here's an exemplary configuration](./openproject-apache-example.conf) that might work for you.

[For a minimal nginx config, please see this gist](https://gist.github.com/seLain/375d16ccd4542e3727e97a7478187d3a) as as starting point.

**Please note:** If you reconfigure the OpenProject application and switch to `skip`, you might run into errors with the Apache configuration file, as that will not be automatically remove. Please double-check you removed references to the `openproject.conf` if you do reconfigure.

## Step 4: SVN/Git integration server

If you have selected to auto-install an Apache2 web server, you will be asked whether you want to install Git and Subversion repository support. In case you do not need it or when in doubt, choose **Skip** for both options.

For more information, [see our help on repositories](../../../user-guide/repository/)

![03-repos](03-repos.png)

## Step 5: Outgoing email configuration

OpenProject requires a setup for sending outgoing emails for notifications, such as updates on work packages, password resets, or other notifications you and your users receive.

![04-mail](04-mail.png)

The wizard supports the following options:

### **Sendmail** (default)

Uses a local sendmail installation or sets up a local-only postfix MTA in case you do not have sendmail.

Easiest setup as it does not require an SMTP configuration, but your Mails may not be delivered consistently depending on your mail accounts or firewall setup.

### **SMTP** (recommended for production systems)

Allows you to connect to a SMTP host through authentication types `NONE`,  `PLAIN,` `LOGIN`, or `CRAM-MD5`. Use this if you have a dedicated mail account to use for delivering OpenProject mail, or when sendmail does not work due to your local firewall / mail relay setup.

### **Skip** (not recommended)

Does not set up mail configuration. You can configure the mail setup in OpenProject by visiting `openproject.example.com/settings?tab=notifications` in your installation. For more information, [visit our help page on this topic](../../../system-admin-guide/system-settings/).

## Step 6: Administrator email

The wizard will ask you for an administrative email address so that it can create the administrator account with that email for the initial login. Enter your email address to have it tied to the admin account.

![05-admin](05-admin.png)

## Step 7: Memcached server

OpenProject heavily relies on caching, which is why the wizard suggests you to install a local memcached server the OpenProject instances can connect to. You should always set this to `install` unless you have a reason to configure another caching mechanism - for example when configuring multiple shared instances of OpenProject.

![06-cache](06-cache.png)

## Result

With this last step confirmed, the OpenProject wizard will complete, and apply all the configuration options that you have just selected. This might take a few minutes depending on your machine and internet connection, as OpenProject might need to install additional packages (such as the web server, database) depending on your selections.

In case this process crashes or exits with an obvious error, please keep the output and send your configuration from`/etc/openproject/installer.dat` (removing any passwords from it) to us at support@openproject.com , or [reach out to the community forums](https://community.openproject.com/projects/openproject/forums). 

When this process completes, it will have started the internal application and web servers, the background jobs to process work-intensive jobs, and set up the connection to the database.

You should be able to reach the OpenProject instance by visiting your installation at `http://<openproject.example.com>/<server prefix>`.

You can then log in using the default user/password combination:

* username = `admin`
* password = `admin`

You will be asked to change this password immediately after the first login.
