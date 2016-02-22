# OpenProject installation via package manager

The installation of the OpenProject software can be done manually or via
official software-packages built by the [Packager.io][packager-io] service.

Using these software packages is highly recommended to reduce the pain of
installation and configuration errors: the software packages ship with a
configuration wizard, which will help you get everything up and running quickly.

[packager-io]: https://packager.io/gh/opf/openproject-ce

## Stack used by the Packager.io packages

* Apache 2 (web server) – this component provides the external interface,
  handles SSL termination (if SSL is used) and distributes/forwards web
requests to the Unicorn processes.

* MySQL (database management system) – this component is used to store and
  retrieve data.

* Unicorn (application server) – this component hosts the actual application.
  By default, there is two unicorn processes running in parallel on the app
server machine.

* Ruby 2.1 (MRI) and necessary libraries to run the OpenProject source code.

# Installation

The installation procedure assumes the following prerequisites:

* A server running one of the following Linux distributions (**64bit variant only**):

  * Ubuntu 14.04 Trusty
  * Debian 8 Jessie
  * Debian 7 Wheezy
  * CentOS/RHEL 7.x
  * CentOS/RHEL 6.x
  * Fedora 20
  * Suse Linux Enterprise Server 12
  * Suse Linux Enterprise Server 11

* A mail server that is accessible via SMTP that can be used for sending
  notification emails. OpenProject supports authentication, yet does not
provide support for SMTP via SSL/TLS.

* If you intend to use SSL for OpenProject: A valid SSL certifificate along
  with the private key file. The key MUST NOT be protected by a passphrase,
otherwise the Apache server won't be able to read it when it starts.

The following steps have to be performed to initiate the actual installation of
OpenProject via the package manager that comes with your Linux distribution.
Note that all commands should either be run as root or should be prepended with
`sudo`.

## Debian 7 Wheezy

    # install https support
    sudo apt-get install apt-transport-https

    sudo wget -qO - https://deb.packager.io/key | apt-key add -
    echo "deb https://deb.packager.io/gh/opf/openproject-ce wheezy stable/5" | sudo tee /etc/apt/sources.list.d/openproject.list
    sudo apt-get update
    sudo apt-get install openproject

## Debian 8 Jessie

    # install https support
    sudo apt-get install apt-transport-https

    wget -qO - https://deb.packager.io/key | sudo apt-key add -
    echo "deb https://deb.packager.io/gh/opf/openproject-ce jessie stable/5" | sudo tee /etc/apt/sources.list.d/openproject.list
    sudo apt-get update
    sudo apt-get install openproject

## Ubuntu 14.04 Trusty

    wget -qO - https://deb.packager.io/key | sudo apt-key add -
    echo "deb https://deb.packager.io/gh/opf/openproject-ce trusty stable/5" | sudo tee /etc/apt/sources.list.d/openproject.list
    sudo apt-get update
    sudo apt-get install openproject

## Fedora 20

    sudo rpm --import https://rpm.packager.io/key
    echo "[openproject]
    name=Repository for opf/openproject-ce application.
    baseurl=https://rpm.packager.io/gh/opf/openproject-ce/fedora20/stable/5
    enabled=1" | sudo tee /etc/yum.repos.d/openproject.repo
    sudo yum install openproject

## CentOS / RHEL 6.x

    sudo rpm --import https://rpm.packager.io/key
    echo "[openproject]
    name=Repository for opf/openproject-ce application.
    baseurl=https://rpm.packager.io/gh/opf/openproject-ce/centos6/stable/5
    enabled=1" | sudo tee /etc/yum.repos.d/openproject.repo
    sudo yum install openproject

## CentOS / RHEL 7.x

    sudo rpm --import https://rpm.packager.io/key
    echo "[openproject]
    name=Repository for opf/openproject-ce application.
    baseurl=https://rpm.packager.io/gh/opf/openproject-ce/centos7/stable/5
    enabled=1" | sudo tee /etc/yum.repos.d/openproject.repo
    sudo yum install openproject

## Suse Linux Enterprise Server 12

    sudo rpm --import https://rpm.packager.io/key
    sudo zypper addrepo "https://rpm.packager.io/gh/opf/openproject-ce/sles12/stable/5" "openproject"
    sudo zypper install openproject

## Suse Linux Enterprise Server 11

    wget https://rpm.packager.io/key -O packager.key && sudo rpm --import packager.key
    sudo zypper addrepo "https://rpm.packager.io/gh/opf/openproject-ce/sles11/stable/5" "openproject"
    sudo zypper install openproject

# Configuration

After the installation of the OpenProject package the system has to be
configured to use this package and operate the OpenProject application.
Therefore the package includes a configuration wizard which can be started
using the following command:

    openproject configure

Side note: The installer supports the configuration of necessary SSL
connections too. If required the corresponding SSL certificates (incl. keys)
have to be placed somewhere on the machine **before** running the installer (or
`reconfigure` the application later to enable the SSL support).

After you have completed the configuration wizard, the OpenProject instance
will be started automatically. You can log into the instance initially with the
user/password combination _admin/admin_. You will be asked to change this
password immediately after the first login.

# Managing your OpenProject installation

The openproject package comes with a command line tool to help manage the
application. To see all possible command options of this tool you can run:

    admin@openproject-demo:~# sudo openproject
    Usage:
      openproject run COMMAND [options]
      openproject scale TYPE=NUM
      openproject logs [--tail|-n NUMBER]
      openproject config:get VAR
      openproject config:set VAR=VALUE
      openproject reconfigure

In the rest of this section we'll go over some of the most important commands.

## Run commands like rake tasks or rails console

The openproject command line tool supports running rake tasks and known scripts
like the rails console:

    sudo openproject run console
    # or a rake task
    sudo openproject run rake db:migrate
    # or check the version of ruby used by openproject
    sudo openproject run ruby -v

## Show logs

The command line tool can also be used to see the log information. The most
typically use case is to show/follow all current log entries. This can be
accomplished using the the `–tail` flag. See example below:

    sudo openproject logs --tail

You can also find all the logs in `/var/log/openproject/`.

## Reconfigure the application

At any point in time, you can reconfigure the whole application by re-running
the installer with the following command:

    sudo openproject reconfigure

The command above will bring up the installation wizard again. Please be aware
that it will start the configuration/installation process from scratch. You can
choose to modify existing entries, or just leave them as they are if you want
to reuse them (note that passwords will appear as "blank" entries in their
respective input fields, but you don't need to enter them again if don't want
to modify them).

Note that if you've just updated your OpenProject version, you should run
`openproject configure` (see section below), which would automatically reuse
your previous configuration, and only asks for your input if new configuration
options are available.

## Inspect the existing configuration

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
    WEB_CONCURRENCY=2
    WEB_TIMEOUT=15
    RAILS_CACHE_STORE=memcache
    SESSION_STORE=cache_store

# Upgrade to a newer version

Upgrading the OpenProject is as easy as installing a newer OpenProject package
and running the `openproject configure` command.

## Debian / Ubuntu

    sudo apt-get update
    sudo apt-get install --only-upgrade openproject
    sudo openproject configure

## Fedora / CentOS / RHEL

    sudo yum update
    sudo yum install openproject
    sudo openproject configure

## SuSE

    sudo zypper update openproject
    sudo openproject configure


# Advanced

## Adding custom plugins to the installation

[A number of plugins](https://www.openproject.org/open-source/openproject-plugins/) exist for use with OpenProject. Most plugins that are maintained by us are shipping with OpenProject, however there are several plugins contributed by the community.

Previously, using them in a packaged installation was not possible without losing your changes on every upgrade. With the following steps, you can now use third party plugins.

**Note**: We cannot guarantee upgrade compatibility for third party plugins nor do we provide support for them. Please carefully check whether the plugins you use are available in newer versions before upgrading your installation.

#### 1. Add a custom Gemfile

If you have a plugin you wish to add to your packaged OpenProject installation, create a separate Gemfile with the Gem dependencies, such as the following:

```
gem 'openproject-emoji', git: 'https://github.com/tessi/openproject-emoji.git', :branch => 'op-5-stable'
```

We suggest to store the Gemfile under `/etc/openproject/Gemfile.custom`, but the choice is up to you, just make sure the `openproject` user is able to read it.

#### 2. Propagate the Gemfile to the package

You have to tell your installation to use the custom gemfile via a config setting:

```
openproject config:set CUSTOM_PLUGIN_GEMFILE=/etc/openproject/Gemfile.custom
```

#### 3. Re-run the installer

To re-bundle the application including the new plugins, as well as running migrations and precompiling their assets, simply re-run the installer while using the same configuration as before.

```
openproject configure
```

Using `configure` will take your previous decisions in the installer and simply re-apply them, which is an idempotent operation. It will detect the Gemfile config option being set and re-bundle the application.

## Manually set configuration options

The installation wizard should take care of setting the most important
configuration options automatically based on your choices. However you might
want to tweak an option not supported by the wizard, in which case you can
directly set it using the `config:set` command of the `openproject` CLI.

For instance if you wanted to change the session store you would do:

    sudo openproject config:set SESSION_STORE=active_record_store
    sudo service openproject restart

In most cases though, you should always try to `reconfigure` the application first.