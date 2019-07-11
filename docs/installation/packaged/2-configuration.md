## Package configuration

The last step to your OpenProject installation is the configuration wizard. It will set up the connection to a database and configure the application according to your environment.

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

Depending on your free RAM on your system, we recommend you raise the default number of workers.
The default from 9.0.3 onwards is four worker processes. Each worker will take roughly 300-400MB RAM.

We recommend at least four workers. Please check your current worker count with

```bash
    sudo openproject config:get WEB_CONCURRENCY
```

If it returns nothing, the default worker count of `4` applies. To increase or decrease the worker count, call

```bash
    sudo openproject config:set WEB_CONCURRENCY=number
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

For a complete guide on upgrading your OpenProject packaged installation, please visit our documentation at <https://www.openproject.org/operations/upgrading/upgrade-guide-packaged-installation/>.

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
