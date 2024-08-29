---
sidebar_navigation: false
---

# Manual installation guide

> **IMPORTANT: We strongly recommend to use one of the officially supported [installation methods](../../installation).**
>
> **This guide is simply provided as an OLD and OUTDATED reference, and is NOT up to date with relation to the latest OpenProject releases and will be NOT maintained NOR supported. You are on your own and maybe could ask experienced users in the forum in order to use this guide for any integrations that you would like to solve. We also removed it from the navigation sidebar on the left in order to hide it.**

Please be aware that:

* This guide **requires** that you have a clean **Ubuntu 18.04** **x64** installation
with administrative rights (i.e. you must be able to `sudo`). We have tested
the installation guide on an Ubuntu Server image, but it should work on any
derivative. You may need to alter some of the commands to match your
derivative.

* OpenProject will be installed with a **PostgreSQL** database.

* OpenProject will be served in a production environment with the **Apache** server
(this guide should work similarly with other servers, like nginx and others)

> **NOTE:** We have highlighted commands to execute like this

```shell
[user@host] command to execute
```

The `user` is the operating system user the command is executed with.
In our case it will be `root` for most of the time or `openproject`.

If you find any bugs or you have any recommendations for improving this
tutorial, please, feel free to create a pull request against this guide.

## Create a dedicated OpenProject user

```shell
sudo groupadd openproject
sudo useradd --create-home --gid openproject openproject
sudo passwd openproject #(enter desired password)
```

## Install the required system dependencies

```shell
[root@host] apt-get update -y
[root@host] apt-get install -y zlib1g-dev build-essential           \
                    libssl-dev libreadline-dev                      \
                    libyaml-dev libgdbm-dev                         \
                    libncurses5-dev automake                        \
                    libtool bison libffi-dev git curl               \
                    poppler-utils unrtf tesseract-ocr catdoc        \
                    libxml2 libxml2-dev libxslt1-dev # nokogiri     \
                    imagemagick
```

## Install the caching server (memcached)

```shell
[root@host] apt-get install -y memcached
```

## Install and setup the database server (PostgreSQL)

OpenProject requires PostgreSQL v9.5+. If you system package is too old, you can check [postgresql.org](https://www.postgresql.org/download/) to get a newer version installed. In our case, Ubuntu 18.04 comes with a recent-enough version so we can use the system packages:

```shell
[root@host] apt-get install postgresql postgresql-contrib libpq-dev
```

Once installed, switch to the PostgreSQL system user.

```shell
[root@host] su - postgres
```

Then, as the PostgreSQL user, create the database user for OpenProject. This will prompt you for a password. We are going to assume in the following guide that this password is 'openproject'. Of course, please choose a strong password and replace the values in the following guide with it!

```shell
[postgres@host] createuser -W openproject
```

Next, create the database owned by the new user

```shell
[postgres@host] createdb -O openproject openproject
```

Lastly, revert to the previous system user:

```shell
[postgres@host] exit
# You will be root again now.
```

## Installation of Ruby

The are several possibilities to install Ruby on your machine. 
We will use [rbenv](https://github.com/rbenv/rbenv). 
Please be aware that the actual installation of a specific Ruby version takes some time to finish.

```shell
[root@host] su openproject --login
[openproject@host] git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
[openproject@host] echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.profile
[openproject@host] echo 'eval "$(rbenv init -)"' >> ~/.profile
[openproject@host] source ~/.profile
[openproject@host] git clone https://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
```

We suggest you install the version we require in [.ruby-version](https://github.com/opf/openproject/blob/dev/.ruby-version).
Read the first line e.g. `3.3.4` and install that version.

```shell
[openproject@host] rbenv install 3.3.4
[openproject@host] rbenv rehash
[openproject@host] rbenv global 3.3.4
```

To check our Ruby installation we run `ruby --version`. It should output
something very similar to:

```text
ruby 3.3.4 (2024-07-09 revision be1089c8ec) [arm64-darwin23]
```

## Installation of Node

The are several possibilities to install Node on your machine. We will
use [nodenv](https://github.com/OiNutter/nodenv#installation). Please
run `su openproject --login` if you are the `root` user. If you are
already the `openproject` user you can skip this command. Please be
aware that the actual installation of a specific node version takes some
time to finish.

```shell
[openproject@host] git clone https://github.com/OiNutter/nodenv.git ~/.nodenv
[openproject@host] echo 'export PATH="$HOME/.nodenv/bin:$PATH"' >> ~/.profile
[openproject@host] echo 'eval "$(nodenv init -)"' >> ~/.profile
[openproject@host] source ~/.profile
[openproject@host] git clone https://github.com/OiNutter/node-build.git ~/.nodenv/plugins/node-build

[openproject@host] nodenv install 14.16.0
[openproject@host] nodenv rehash
[openproject@host] nodenv global 14.16.0
```

To check our Node installation we run `node --version`. It should output something very similar to:

```text
v20.9.0
```

## Installation of OpenProject

We will install the OpenProject Community Edition. It contains the recommended set of plugins for use
with OpenProject. For more information, see [github.com/opf/openproject](https://github.com/opf/openproject).

```shell
[openproject@host] cd ~
[openproject@host] git clone https://github.com/opf/openproject.git --branch stable/9 --depth 1
[openproject@host] cd openproject
# Ensure rubygems is up-to-date for bundler 2
[openproject@host] gem update --system
[openproject@host] gem install bundler
# Replace mysql with postgresql if you had to install MySQL
[openproject@host] bundle install --deployment --without mysql2 sqlite development test therubyracer docker
[openproject@host] npm install
```

## Configure OpenProject

Create and configure the database configuration file in config/database.yml
(relative to the openproject directory).

```shell
[openproject@host] cp config/database.yml.example config/database.yml
```

Now we edit the `config/database.yml` file and insert our database credentials for PostgreSQL.
It should look like this (please keep in mind that you have to use the values
you used above: user, database and password):

```yaml
production:
  adapter: postgresql
  encoding: unicode
  database: openproject
  pool: 5
  username: openproject
  password: openproject
```

Next we configure email notifications (this example uses a gmail account) by creating the `configuration.yml` in config directory.

```shell
[openproject@host] cp config/configuration.yml.example config/configuration.yml
```

Now we edit the `configuration.yml` file to suit our needs.

```yaml
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

Add this line into `configuration.yml` file at the end of the file for
a better performance of OpenProject:

```yaml
rails_cache_store: :memcache
```

> **NOTE:** You should validate your `yml` files, for example with [yamlchecker.com](https://yamlchecker.com/). Both, the `database.yml` and `configuration.yml` file are sensitive to whitespace. It is pretty easy to write invalid `yml` files without seeing the error. Validating those files prevents you from such errors.
>

To configure the environment variables such as the number of web server threads `OPENPROJECT_WEB_WORKERS`, copy the `.env.example` to `.env` and add the environment variables you want to configure. The variables will be automatically loaded to the application's environment.

## Finish the installation of OpenProject

```shell
[openproject@host] cd ~/openproject
[openproject@host] RAILS_ENV="production" ./bin/rake db:create
[openproject@host] RAILS_ENV="production" ./bin/rake db:migrate
[openproject@host] RAILS_ENV="production" ./bin/rake db:seed
[openproject@host] RAILS_ENV="production" ./bin/rake assets:precompile
```

> **NOTE:** When not specified differently, the default data loaded via db:seed will have an English localization. You can choose to seed in a different language by specifying the language with `OPENPROJECT_DEFAULT_LANGUAGE` or `OPENPROJECT_SEED_LOCALE` environment variable on the initial call to `db:seed`. For instance:

```shell
[openproject@all] RAILS_ENV="production" OPENPROJECT_DEFAULT_LANGUAGE=fr ./bin/rake db:seed
```

will seed the database in the French language.

### Secret token

You need to generate a secret key base for the production environment with `./bin/rails secret` and make that available through the environment variable `SECRET_KEY_BASE`.
In this installation guide, we will use the local `.profile` of the OpenProject user. You may alternatively set the environment variable in `/etc/environment` or pass it to the server upon start manually in `/etc/apache2/envvars`.

```shell
[openproject@host] echo "export SECRET_KEY_BASE=$(./bin/rails secret)" >> ~/.profile
[openproject@host] source ~/.profile
```

## Serve OpenProject with Apache and Passenger

First, we exit the current bash session with the openproject user,
so that we are again in a root shell.

```shell
[openproject@ubuntu] exit
```

Then, we prepare apache and passenger:

```shell
[root@host] apt-get install -y apache2 libcurl4-gnutls-dev      \
                               apache2-dev libapr1-dev \
                               libaprutil1-dev
[root@ubuntu] chmod o+x "/home/openproject"
```

Now, the Passenger gem is installed and integrated into apache.

```shell
[root@ubuntu] su openproject --login
[openproject@ubuntu] cd ~/openproject
[openproject@ubuntu] gem install passenger
[openproject@ubuntu] passenger-install-apache2-module
```

If you are running on a Virtual Private Server, you need to make sure you have at least 1024mb of RAM before running the `passenger-install-apache2-module`.

Follow the instructions passenger provides.
The passenger installer will ask you the question in "Which languages are you
interested in?". We are interested only in ruby.

The passenger installer tells us to edit the apache config files.
To do this, continue as the root user:

```shell
[openproject@host] exit
```

As told by the installer, create the file /etc/apache2/mods-available/passenger.load and add the following line.
But before copy&pasting the following lines, check if the content (especially the version numbers!) is the same as the passenger-install-apache2-module installer said. When you're in doubt, do what passenger tells you.

```apache
LoadModule passenger_module /home/openproject/.rbenv/versions/2.1.6/lib/ruby/gems/2.1.0/gems/passenger-5.0.14/buildout/apache2/mod_passenger.so
```

Then create the file /etc/apache2/mods-available/passenger.conf with the following contents (again, take care of the version numbers!):

```apache
 <IfModule mod_passenger.c>
   PassengerRoot /home/openproject/.rbenv/versions/2.1.6/lib/ruby/gems/2.1.0/gems/passenger-5.0.14
   PassengerDefaultRuby /home/openproject/.rbenv/versions/2.1.6/bin/ruby
 </IfModule>
```

Then run:

```shell
[root@openproject] a2enmod passenger
```

As the root user, create the file /etc/apache2/sites-available/openproject.conf with the following contents:

```apache
SetEnv EXECJS_RUNTIME Disabled

<VirtualHost *:80>
   ServerName yourdomain.com
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

   # Request browser to cache assets
   <Location /assets/>
     ExpiresActive On ExpiresDefault "access plus 1 year"
   </Location>

</VirtualHost>
```

Let's enable our new openproject site (and disable the default site, if necessary)

```shell
[root@host] a2dissite 000-default
[root@host] a2ensite openproject
```

Now, we (re-)start Apache:

```shell
[root@host] service apache2 restart
```

Your OpenProject installation should be accessible on port 80 (http). A default admin-account is created for you having the following credentials:

Username: `admin`
Password: `admin`

Please, change the password on the first login. Also, we highly recommend to configure the SSL module in Apache for https communication.

## Activate background jobs

OpenProject sends (some) mails asynchronously by using background jobs. All such jobs are collected in a queue, so that a separate process can work on them. This means that we have to start the background worker. To automate this, we put the background worker into a cronjob.

```shell
[root@all] su - openproject -c "bash -l"
[openproject@all] crontab -e
```

Now, the crontab file opens in the standard editor. Add the following entry to the file:

```cron
*/1 * * * * cd /home/openproject/openproject; /home/openproject/.rvm/gems/ruby-2.1.5/wrappers/rake jobs:workoff
```

This will start the worker job every minute.

## Follow-Ups

Your OpenProject installation is ready to run. Please refer to the [Operation guides](../../operation) or the [Advanced configuration guides](../../configuration) for more details on how to operate and configure OpenProject.

## Plug-In installation (Optional)

This step is optional.

OpenProject can be extended by various plug-ins, which extend OpenProject's capabilities.
For general information and a list of all plug-ins known to us, refer to to the [plug-in page](../../../system-admin-guide/integrations/).

OpenProject plug-ins are separated in ruby gems. You can install them by listing them in a file called `Gemfile.plugins`. An example `Gemfile.plugins` file looks like this:

```ruby
# Required by backlogs
gem "openproject-meeting", git: "https://github.com/finnlabs/openproject-meeting.git", :tag => "v4.2.2"
```

If you have modified the `Gemfile.plugin` file, always repeat the following steps of the OpenProject installation:

```shell
[openproject@all] cd ~/openproject
[openproject@all] bundle install
[openproject@all] npm install
[openproject@all] RAILS_ENV="production" ./bin/rake db:migrate
[openproject@all] RAILS_ENV="production" ./bin/rake db:seed
[openproject@all] RAILS_ENV="production" ./bin/rake assets:precompile
```

Restart the OpenProject server afterwards:

```shell
[openproject@all] touch ~/openproject/tmp/restart.txt
```

The next web-request to the server will take longer (as the application is restarted). All subsequent request should be as fast as always.

We encourage you to extend OpenProject yourself by writing a plug-in. Please, read the [plugin creation guide](../../../development/create-openproject-plugin/) for more information.

## Troubleshooting

You can find the error logs for apache here: `/var/log/apache2/error.log`

The OpenProject logfile can be found here: `/home/openproject/openproject/log/production.log`

If an error occurs, it should be logged there.

If you need to restart the server (for example after a configuration change), do

```shell
[openproject@all] touch ~/openproject/tmp/restart.txt
```

## Frequently asked questions (FAQ)

* **I followed the installation guide faithfully and OpenProject is running. Now, how do I log in?**

  The `db:seed` command listed above creates a default admin-user. The username is `admin` and the default password is `admin`. You are forced to change the admin password on the first login.
  If you cannot login as the admin user, make sure that you have executed the `db:seed` command.

  ```shell
  [openproject@all] RAILS_ENV="production" ./bin/rake db:seed
  ```

* **When accessing OpenProject, I get an error page. How do I find out what went wrong?**

  Things can go wrong on different levels. You can find the apache error logs here: `/var/log/apache2/error.log`

  The OpenProject log can be found here: `/home/openproject/openproject/log/production.log`

* **I cannot solve an error, not even with the log files. How do I get help?**

  You can find help in [the OpenProject forums](https://community.openproject.org/projects/openproject/boards). Please tell us, if possible, what you have done (e.g. which guide you have used to install OpenProject), how to reproduce the error, and provide the appropriate error logs.
  It often helps to have a look at the already answered questions, or to search the Internet for the error. Most likely someone else has already solved the same problem.

* **I get errors, since I have installed an OpenProject plug-in**

  With each new OpenProject core version, the plug-ins might need to be updated. Please make sure that the plug-in versions of all you plug-ins works with the OpenProject version you use.
  Many plug-ins follow the OpenProject version with their version number (So, if you have installed OpenProject version 4.1.0, the plug-in should also have the version 4.1.0).
