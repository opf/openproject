
### Package configuration

The last step to your OpenProject installation is the configuration wizard. It will set up the connection to a database and configure the application according to your environment.

The OpenProject installation wizard currently supports the automatic setup for  MySQL databases only. However, OpenProject itself supports both MySQL and PostgreSQL. To configure the package to use an existing database, see the section below. To install or configure a MySQL database, skip to _Configuration_.

The OpenProject package is configured through ENV parameters that are passed to the `openproject` user. You can read the current ENV parameters with `openproject run env`. To write/read individual parameters, use `openproject config:set PARAMETER=VALUE` and `openproject config:get PARAMETER`.

For instance if you wanted to change the session store you would do:

    sudo openproject config:set SESSION_STORE=active_record_store

This is handy to configure options that are not available in the installer (yet). In most cases though, you should always try to `configure` the application first.

#### Configuring for an existing a PostgreSQL database

The MySQL wizard of the OpenProject installer internally sets the `DATABASE_URL`  (See [DATABASE_URL](http://edgeguides.rubyonrails.org/configuring.html) in the Rails Guides for more information).

You can set this `DATABASE_URL` parameter yourself to either a MySQL or PostgreSQL database URL.

    openproject config:set DATABASE_URL="postgresql://[user[:password]@][host][:port][/dbname][?param1=value1&...]

**Then, when configuring the addon, select skip in the MySQL installation wizard.** The database specified using the URL will be used by Rails automatically for preparing the database.

You can use these ENV parameters to customize OpenProject. See [OpenProject Configuration](https://github.com/opf/openproject/blob/dev/doc/CONFIGURATION.md).

### Package configuration

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

### Managing your OpenProject installation

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

#### Run commands like rake tasks or rails console

The openproject command line tool supports running rake tasks and known scripts
like the rails console:

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

You can also find all the logs in `/var/log/openproject/`.

#### Reconfigure the application

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
    WEB_CONCURRENCY=2
    WEB_TIMEOUT=15
    RAILS_CACHE_STORE=memcache
    SESSION_STORE=cache_store
