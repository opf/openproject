# OpenProject 4.1 to OpenProject 4.2 Debian/Ubuntu Upgrade Guide

Please look at the steps in the section about the upgrade to OpenProject 4.1. Just exchange `v4.1.0` to `v4.2.0` when checking out the git repository.

# OpenProject 4.0 to OpenProject 4.1 Debian/Ubuntu Upgrade Guide

This guide describes the upgrade process from OpenProject 4.0 to 4.1 on Debian 7.7 and Ubuntu 14.04 LTS step by step.

Note: We strongly recommend to update your OpenProject installation to the latest available 4.0 version (currently 4.0.9), before attempting an update to 4.1.


## Preparation

* Backup your current Openproject installation. Typically you should backup the attachment
  folder of your installation, the subversion repositories (if applicable) and your database.
  For more information please have a look at our [backup guide](backup-guide.md)

* Before Upgrading, check that all the installed OpenProject plugins support the new
  OpenProject version. Remove incompatible plugins before attempting an upgrade. Stop
  the OpenProject Server. You may even add a maintenance page, if you feel comfortable
  with that.

* If you run the worker process with a cronjob, disable the cronjob temporarily.
* Stop the (delayed\_job) worker process. In case you run the woker process through
  `RAILS_ENV=production bundle exec script/delayed_job start`, execute the following:
  `RAILS_ENV=production bundle exec script/delayed_job stop`.

## Update your system

```bash
[root@debian]# apt-get update
[root@debian]# apt-get upgrade
```

## Get the new OpenProject Source Code
Change into the directory where OpenProject is installed and switch to the operating-system-user the OpenProject operates as. We assume that OpenProject is installed in `/home/openproject/openproject` by the `openproject` user.

```bash
[root@debian]# su - openproject -c "bash -l"
[openproject@debian]# cd ~/openproject/openproject
```

Remove manual changes and modifications (If you have modified OpenProject source files and want to preserve those changes, back up your changes, and re-apply them later):

```bash
[openproject@debian]# git reset --hard
[openproject@debian]# git fetch
[openproject@debian]# git checkout v4.1.0
```

## Upgrade Ruby
OpenProject 4.1 requires Ruby to be installed in version 2.1.x. Assuming you have installed Ruby via RVM, do the following to upgrade your Ruby installation:

```bash
[openproject@debian]# rvm get stable
[openproject@debian]# export -f rvm_debug
[openproject@debian]# rvm install 2.1.5
[openproject@debian]# rvm use --default 2.1.5
[openproject@debian]# gem install bundler
[openproject@debian]# bundle install
```

### Update application server configuration
This sections only applies to you, if you serve OpenProject via Apache and Passenger. If you serve OpenProject in a different way, be sure to check that it still works.

During the upgrade of the Ruby version, we have potentially installed a new Ruby and Passenger version. The versions of Ruby and Passenger appear in the Apache configuration like this:

```apache
LoadModule passenger_module /home/openproject/.rvm/gems/ruby-2.1.4/gems/passenger-4.0.53/buildout/apache2/mod_passenger.so
<IfModule mod_passenger.c>
  PassengerRoot /home/openproject/.rvm/gems/ruby-2.1.4/gems/passenger-4.0.53
  PassengerDefaultRuby /home/openproject/.rvm/gems/ruby-2.1.4/wrappers/ruby
</IfModule>
```
Please run the following commands to upgrade passenger and re-install the Apache module:

```bash
[openproject@debian]# gem update passenger
[openproject@debian]# gem cleanup passenger
[openproject@debian]# passenger-install-apache2-module
```

The output of passenger-install-apache2-module2 tells you how to configure Apache. It is basically the same as what is already installed, except for the updated version numbers.

Don’t forget to restart apache after the configuration change:

```bash
[root@debian]# service apache2 reload
```

## Node.js installation
Node.js is necessary to precompile the assets (JavaScript and CSS). We will install the latest 0.12.x version of Node.js via nodeenv:

```bash
[openproject@debian]# exit
[root@debian]# apt-get install python python-pip
[root@debian]# pip install nodeenv
[root@debian]# su - openproject -c "bash -l"
[openproject@debian]# cd /home/openproject
[openproject@debian]# nodeenv nodeenv
[openproject@debian]# source ./nodeenv/bin/activate
[openproject@debian]# npm -g install bower
```

As a reference, the following Node.js and NPM versions have been installed on our system:

```bash
[openproject@debian]# node --version
                      v0.12.2
[openproject@debian]# npm --version
                      1.4.28
[openproject@debian]# bower --version
                      1.3.12
```

## The Upgrade

Now that the sources and dependencies are in place, you can migrate the Database and do the upgrade:

```bash
[openproject@debian]# cd /home/openproject/openproject
[openproject@debian]# npm install
[openproject@debian]# RAILS_ENV="production" bundle exec rake db:migrate
[openproject@debian]# RAILS_ENV="production" bundle exec rake db:seed
[openproject@debian]# RAILS_ENV="production" bundle exec rake assets:precompile
[openproject@debian]# touch tmp/restart.txt
```

*Side note:* If you are using `RAILS_ENV="development"` the task `bundle exec rake assets:webpack` needs to be run. This step is not necessary for `production` because it is part of the `asset:precompile` tasks.

**NOTE** `db:seed` can also be invoked with a 'LOCALE' environment variable defined, specifying the language in which to seed. Note however, that specifying different locales for calls to `db:seed` might lead to a mixture of languages in your data. It is therefore advisable to use the same language for all calls to `db:seed`.

## The Aftermath
* Re-enable the `delayed_job` cron job that was disabled in the first step.
* If you have put up a maintenance page, remove it.
* Start the OpenProject server again
* Watch for further OpenProject updates in our news, or on twitter.

## Questions, Comments, and Feedback
If you have any further questions, comments, feedback, or an idea to enhance this guide, please tell us at the appropriate forum.

Also, please take a look at the Frequently [Asked Questions](https://www.openproject.org/help/faq/).

