# Installation of OpenProject 4.0 with Apache on Debian 7.7 or Ubuntu 14.04 LTS

**This tutorial helps you to deploy OpenProject 4.0. Please, aware that:**

1. This guide requires that you have a clean **Debian 7.7 x64** or **Ubuntu 14.04 x64** installation with administrative rights. We have tested the installation guide on a Debian minimal netinstall image and on an Ubuntu Server image, but it should work on any derivative.
2. OpenProject will be installed with a MySQL database (the guide should work analogous with PostgreSQL).
3. OpenProject will be served in a production environment with Apache (this guide should work analogous with other servers, like nginx and others)

In this guide, we will install **OpenProject 4.0** with a **MySQL** database. Openproject will be served with the **Apache** web server. When your server needs to reboot, OpenProject should start automatically with your server.

Note: We have highlighted commands to execute like this
```bash
[user@host] command
```

Where the `user` is the operating system user the command is executed with. The `host` is either `debian` (when the command is Debian-specific), `ubuntu` (when the command is Ubuntu-specific), or `all` (when the command shall be executed on either operating system).

If you find any bugs or you have any recommendations for improving this tutorial, please, feel free to create a pull request against this guide.

## Prepare Your Environment

Install tools needed to compile Ruby and run OpenProject:

### Only on Debian

```bash
[root@debian] apt-get update
[root@debian] apt-get install git curl build-essential zlib1g-dev libyaml-dev libssl-dev libmysqlclient-dev libpq-dev libsqlite3-dev memcached libffi5
```

### Only on Ubuntu

```bash
[root@ubuntu] apt-get update
[root@ubuntu] apt-get install git curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libmysqlclient-dev libpq-dev libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties memcached libgdbm-dev libncurses5-dev automake libtool bison libffi-dev
```

### Debian and Ubuntu

Create a dedicated user for OpenProject:

```bash
[root@all] groupadd openproject
[root@all] useradd --create-home --gid openproject openproject
[root@all] passwd openproject (enter desired password)
```

## Install Database (MySQL) Packages

During installation, you have to enter a password for the mysql root-user.

```bash
[root@all] apt-get install mysql-server mysql-client
```

As a reference, we have installed the following MySQL version:

```bash
[root@all] mysql --version
              mysql  Ver 14.14 Distrib 5.5.40, for debian-linux-gnu (x86_64) using readline 6.3
```

Create the OpenProject MySQL-user and database:

```bash
[root@all] mysql -u root -p
```

You may replace the string `"openproject"` with the desired username and database-name. The password `"my_password"` should definitely be changed.

```sql
mysql> CREATE DATABASE openproject CHARACTER SET utf8;
mysql> CREATE USER 'openproject'@'localhost' IDENTIFIED BY 'my_password';
mysql> GRANT ALL PRIVILEGES ON openproject.* TO 'openproject'@'localhost';
mysql> \q
```

## Install Node.js

We will install the latest 0.10.x version of Node.js via [nodeenv](https://pypi.pythn.org/pypi/nodeenv):

```bash
[root@all] apt-get install python python-pip
[root@all] pip install nodeenv
```


## Install Ruby

Switch to the dedicated OpenProject-user (user `openproject` in our case):

```bash
[root@all] su openproject -c "bash -l"
```

Switch to the user's home directory ...

```bash
[openproject@all] cd ~
```

... and install RVM (Ruby Version Manager)

```bash
[openproject@all] \curl -sSL https://get.rvm.io | bash -s stable
```

It can be that curl fails to download the RVM source, because of the missing GPG key. If that is the case, download the key (as suggested in the error message):

```bash
[openproject@all] gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3
```

Then try to download RVM again and continue the installation with:

```bash
[openproject@all] source $HOME/.rvm/scripts/rvm
[openproject@all] rvm autolibs disable
[openproject@all] rvm install 2.1.4
[openproject@all] rvm use --default 2.1.4
[openproject@all] gem install bundler
```

As a reference, we have installed the following version of bundler:

```bash
[openproject@all] bundle --version
                  Bundler version 1.7.4
```

## Activate Node.js

```bash
[openproject@all] cd ~
[openproject@all] nodeenv nodeenv
[openproject@all] source ./nodeenv/bin/activate
[openproject@all] npm -g install bower
```

As a reference, the following Node.js and NPM versions have been installed on our system:

```bash
[openproject@all] node --version
                  v0.10.33
[openproject@all] npm --version
                  1.4.28
[openproject@all] bower --version
                  1.3.12
```

## Install OpenProject

```bash
[openproject@all] cd ~
[openproject@all] git clone https://github.com/opf/openproject.git
[openproject@all] cd openproject
[openproject@all] git checkout stable
[openproject@all] bundle install
[openproject@all] npm install
[openproject@all] bower install
```

## Configure OpenProject

Create and configure the database configuration file in `config/database.yml` (relative to the openproject-directory).

```bash
[openproject@all] cp config/database.yml.example config/database.yml
```

Now edit the `config/database.yml` file and insert your database credentials.
It should look like this (just with your database name, username, and password):

```ruby
production:
  adapter: mysql2
  database: openproject
  host: localhost
  username: openproject
  password: openproject
  encoding: utf8

development:
  adapter: mysql2
  database: openproject
  host: localhost
  username: openproject
  password: openproject
  encoding: utf8
```

Configure email notifications (using a gmail account as an example) by creating configuration.yml in `config` directory.

```bash
[openproject@all] cp config/configuration.yml.example config/configuration.yml
```

Now, edit the `configuration.yml` file as you like.

```ruby
production:                          #main level
  email_delivery_method: :smtp       #settings for the production environment
  smtp_address: smtp.gmail.com
  smtp_port: 587
  smtp_domain: smtp.gmail.com
  smtp_user_name: ***@gmail.com
  smtp_password: ****
  smtp_enable_starttls_auto: true
  smtp_authentication: plain
```

Add this line into `configuration.yml` file at the of of file for better performance of OpenProject:

```ruby
rails_cache_store: :memcache
```

**NOTE:** You should validate your .yml-files, for example with http://www.yamllint.com/. Both, the `database.yml` and `configuration.yml` file are sensitive to whitespace. It is pretty easy to write invalid .yml files without seeing the error. Validating those files prevents you from such errors.

## Finish the Installation of OpenProject

```bash
[openproject@all] cd ~/openproject
[openproject@all] bundle exec rake db:create:all
[openproject@all] bundle exec rake generate_secret_token
[openproject@all] RAILS_ENV="production" bundle exec rake db:migrate
[openproject@all] RAILS_ENV="production" bundle exec rake db:seed
[openproject@all] RAILS_ENV="production" bundle exec rake assets:precompile
```


## Serve OpenProject with Apache and Passenger

OpenProject will be served by the Rails application server "Passenger", and the apache webserver.
We set up the system in a way, that automatically starts OpenProject with the operating system.

### Only on Debian

First, exit the current bash session with the `openproject` user, so that we are again in a root shell.
Then, we prepare apache and passenger:

```bash
[openproject@debian] exit
[root@debian] apt-get install apache2 libcurl4-gnutls-dev apache2-threaded-dev libapr1-dev libaprutil1-dev
[root@debian] chmod o+x "/home/openproject"
```

Now, the Passenger gem is installed and integrated into apache.

```bash
[root@debian] su - openproject -c "bash -l"
[openproject@debian] cd ~/openproject
[openproject@debian] gem install passenger
[openproject@debian] passenger-install-apache2-module
```

Follow the instructions passenger provides.
The passenger installer will ask you the question in "Which languages are you interested in?". We are interested only in ruby.

As told by the installer, add this lines to `/etc/apache2/apache2.conf`.
But before copy&pasting the following lines, check if the content (especially the version numbers!) is the same as the `passenger-install-apache2-module` installer said. When you're in doubt, do what passenger tells you.

```apache
LoadModule passenger_module /home/openproject/.rvm/gems/ruby-2.1.4/gems/passenger-4.0.53/buildout/apache2/mod_passenger.so
<IfModule mod_passenger.c>
  PassengerRoot /home/openproject/.rvm/gems/ruby-2.1.4/gems/passenger-4.0.53
  PassengerDefaultRuby /home/openproject/.rvm/gems/ruby-2.1.4/wrappers/ruby
</IfModule>
```

As the root user, create the file `/etc/apache2/conf.d/openproject.conf` with the following contents:

```apache
<VirtualHost *:80>
   ServerName www.myopenprojectsite.com
   # !!! Be sure to point DocumentRoot to 'public'!
   DocumentRoot /home/openproject/openproject/public
   <Directory /home/openproject/openproject/public>
      # This relaxes Apache security settings.
      AllowOverride all
      # MultiViews must be turned off.
      Options -MultiViews
      # Uncomment this if you're on Apache >= 2.4:
      #Require all granted
   </Directory>
</VirtualHost>
```

### Only on Ubuntu

First, exit the current bash session with the `openproject` user, so that we are again in a root shell.
Then, we prepare apache and passenger:

```bash
[openproject@ubuntu] exit
[root@ubuntu] apt-get install apache2 libcurl4-gnutls-dev apache2-threaded-dev libapr1-dev libaprutil1-dev
[root@ubuntu] chmod o+x "/home/openproject"
```

As a reference, the following version of apache was installed:

```bash
[root@ubuntu] apache --version
```

Now, the Passenger gem is installed and integrated into apache.

```bash
[root@ubuntu] su - openproject -c "bash -l"
[openproject@ubuntu] cd ~/openproject
[openproject@ubuntu] gem install passenger
[openproject@ubuntu] passenger-install-apache2-module
```

Follow the instructions passenger provides.
The passenger installer will ask you the question in "Which languages are you interested in?". We are interested only in ruby.

The passenger installer tells us to edit the apache config files. To do this, continue as the root user:

```bash
[openproject@ubuntu] exit
```

As told by the installer, create the file `/etc/apache2/mods-available/passenger.load` and add the following line.
But before copy&pasting the following lines, check if the content (especially the version numbers!) is the same as the `passenger-install-apache2-module` installer said. When you're in doubt, do what passenger tells you.

```apache
LoadModule passenger_module /home/openproject/.rvm/gems/ruby-2.1.4/gems/passenger-4.0.53/buildout/apache2/mod_passenger.so
```

Then create the file `/etc/apache2/mods-available/passenger.conf` with the following contents (again, take care of the version numbers!):

```apache
<IfModule mod_passenger.c>
  PassengerRoot /home/openproject/.rvm/gems/ruby-2.1.4/gems/passenger-4.0.53
  PassengerDefaultRuby /home/openproject/.rvm/gems/ruby-2.1.4/wrappers/ruby
</IfModule>
```

Then run:

```bash
[root@openproject] a2enmod passenger
```

As the root user, create the file `/etc/apache2/sites-available/openproject.conf` with the following contents:

```apache
<VirtualHost *:80>
   ServerName www.myopenprojectsite.com
   # !!! Be sure to point DocumentRoot to 'public'!
   DocumentRoot /home/openproject/openproject/public
   <Directory /home/openproject/openproject/public>
      # This relaxes Apache security settings.
      AllowOverride all
      # MultiViews must be turned off.
      Options -MultiViews
      # Uncomment this if you're on Apache >= 2.4:
      Require all granted
   </Directory>
</VirtualHost>
```

Let's enable our new `openproject` site (and disable the default site, if necessary)

```bash
[root@ubuntu] a2dissite 000-default
[root@ubuntu] a2ensite openproject
```

### Debian and Ubuntu

Now, we (re-)start Apache:

```bash
[root@all] service apache2 reload
```

Your OpenProject installation should be accessible on port 80 (http). A default admin-account is created for you having the following credentials:

```bash
Username: admin
Password: admin
```

Please, change the password on the first login. Also, we highly recommend to configure the SSL module in Apache for https communication.

## Activate Background Jobs

OpenProject sends (some) mails asynchronously by using background jobs. All such jobs are collected in a queue, so that a separate process can work on them. This means that we have to start the background worker. To automate this, we put the background worker into a cronjob.

```bash
[root@all] su - openproject -c "bash -l"
[openproject@all] crontab -e
```

Now, the crontab file opens in the standard editor. Add the following entry to the file:

```cron
*/1 * * * * cd /home/openproject/openproject; /home/openproject/.rvm/gems/ruby-2.1.4/wrappers/rake jobs:workoff
```

This will start the worker job every minute.

## Follow-Ups

Your OpenProject installation is ready to run. However, there are some things to consider:

* Regularly backup your OpenProject installation. See the [backup guide](https://community.openproject.org/projects/openproject/wiki/Create_Backups) for details.
* Serve OpenProject via https
* Enable Repositories for your OpenProject projects
* Watch for OpenProject updates. We advise to always run the latest stable version of OpenProject (especially for security updates). You can find out about new OpenProject releases in our [news](https://community.openproject.org/projects/openproject/news), or on [twitter](https://twitter.com/openproject).

## Plug-In Installation (Optional)

This step is optional.

OpenProject can be extended by various plug-ins, which extend OpenProject's capabilities.
For general information and a list of all plug-ins known to us, refer to to the [plug-in page](https://www.openproject.org/projects/openproject/wiki/OpenProject_Plug-Ins).

OpenProject plug-ins are separated in ruby gems. You can install them by listing them in a file called `Gemfile.plugin`. An example `Gemfile.plugin` file looks like this:

```ruby
# Required by backlogs
gem "openproject-pdf_export", git: "https://github.com/finnlabs/openproject-pdf_export.git", :branch => "stable"
gem "openproject-backlogs", git: "https://github.com/finnlabs/openproject-backlogs.git", :branch => "stable"
```

If you have modified the @Gemfile.plugin@ file, always repeat the following steps of the OpenProject installation:

```bash
[openproject@all] cd ~/openproject
[openproject@all] bundle install
[openproject@all] bower install
[openproject@all] RAILS_ENV="production" bundle exec rake db:migrate
[openproject@all] RAILS_ENV="production" bundle exec rake db:seed
[openproject@all] RAILS_ENV="production" bundle exec rake assets:precompile
```

Restart the OpenProject server afterwards:

```bash
[openproject@all] touch ~/openproject/tmp/restart.txt
```

The next web-request to the server will take longer (as the application is restarted). All subsequent request should be as fast as always.

We encourage you to extend OpenProject yourself by writing a plug-in. Please, read the [plugin-contributions](https://community.openproject.org/projects/openproject/wiki/Developing_Plugins) guide for more information.

## Troubleshooting

You can find the error logs for apache here:
<pre>/var/log/apache2/error.log</pre>

The OpenProject logfile can be found here:
<pre>/home/openproject/openproject/log/production.log</pre>

If an error occurs, it should be logged there.

If you need to restart the server (for example after a configuration change), do

```bash
[openproject@all] touch ~/openproject/tmp/restart.txt
```

## Frequently Asked Questions (FAQ)

* **I followed the installation guide faithfully and OpenProject is running. Now, how do I log in?**

  The `db:seed` command listed above creates a default admin-user. The username is `admin` and the default password is `admin`. You are forced to change the admin password on the first login.
  If you cannot login as the admin user, make sure that you have executed the `db:seed` command.
  ```bash
  [openproject@all] RAILS_ENV="production" bundle exec rake db:seed
  ```

* **When accessing OpenProject, I get an error page. How do I find out what went wrong?**

  Things can go wrong on different levels. You can find the apache error logs here:
  <pre>/var/log/apache2/error.log</pre>
  The OpenProject log can be found here:
  <pre>/home/openproject/openproject/log/production.log</pre>

* **I cannot solve an error, not even with the log files. How do I get help?**

  You can find help in [the OpenProject forums](https://community.openproject.org/projects/openproject/boards). Please tell us, if possible, what you have done (e.g. which guide you have used to install OpenProject), how to reproduce the error, and provide the appropriate error logs.
  It often helps to have a look at the already answered questions, or to search the Internet for the error. Most likely someone else has already solved the same problem.

* **I get errors, since I have installed an OpenProject plug-in**

  With each new OpenProject core version, the plug-ins might need to be updated. Please make sure that the plug-in versions of all you plug-ins works with the OpenProject version you use.
  Many plug-ins follow the OpenProject version with their version number (So, if you have installed OpenProject version 4.0.0, the plug-in should also have the version 4.0.0).
  Also, most plug-ins provide a `stable` branch containing the last stable version (just like we do for the OpenProject core).
  When you're in doubt, please contact the plug-in maintainer.

* **I get an error during @bower install@. What can I do?**

  We heard that `bower install` can fail, if your server is behind a firewall which does not allow `git://` URLs. The error looks like this:

  ```
  bower openproject-ui_components#with-bower ECMDERR Failed to execute "git ls-remote --tags --heads git://github.com/opf/openproject-ui_components.git", exit code of #128

  Additional error details:
  fatal: unable to connect to github.com:
  github.com[0: 192.30.252.131]: errno=Connection refused

  npm ERR! OpenProject@0.1.0 postinstall: `./node_modules/bower/bin/bower install`
  ```

  The solution is to configure git to use `https://` URLs instead of `git://` URLs lke this:
  ```bash
  git config --global url."https://".insteadOf git://
  ```


## Questions, Comments, and Feedback

If you have any further questions, comments, feedback, or an idea to enhance this guide, please tell us at the appropriate community [forum](https://community.openproject.org/projects/openproject/boards/9).
[Follow OpenProject on twitter](https://twitter.com/openproject), and follow the news on [openproject.org](http://openproject.org) to stay up to date.
