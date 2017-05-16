# OpenProject 5.x Development Setup on Debian 7.7

To develop OpenProject a setup similar to that for using OpenProject in production is needed. However, we can skip some parts of the installation guide, so that we can get up a development environment a little easier.

1. This guide requires that you have a clean Debian 7.7 x64 installation with administrative rights.
2. OpenProject will be installed with a MySQL database (the guide should work analogous with PostgreSQL).
3. OpenProject will be served in a development environment

If you find any bugs or you have any recommendations for improving this tutorial, please, feel free to comment in the [OpenProject forums](https://community.openproject.org/projects/openproject/boards).

## Prepare your environment

Install tools needed to compile Ruby and run OpenProject:

```bash
[dev@debian]# sudo apt-get update
[dev@debian]# sudo apt-get install git curl build-essential zlib1g-dev libyaml-dev libssl-dev libmysqlclient-dev libpq-dev libsqlite3-dev memcached libffi5
```

## Install Database (MySQL) packages

During installation, you have to enter a password for the mysql root-user.

```bash
[dev@debian]# sudo apt-get install mysql-server mysql-client
```

As a reference, we have installed the following MySQL version:

```bash
[dev@debian]# mysql --version
  mysql  Ver 14.14 Distrib 5.5.40, for debian-linux-gnu (x86_64) using readline 6.2
```

Create the OpenProject MySQL-user and database:

```bash
[dev@debian]# mysql -u root -p
```

You may replace the string “openproject” with the desired username and database-name. The password “my_password” should definitely be changed.

```sql
mysql> CREATE DATABASE openproject CHARACTER SET utf8;
mysql> CREATE USER 'openproject'@'localhost' IDENTIFIED BY 'my_password';
mysql> GRANT ALL PRIVILEGES ON openproject.* TO 'openproject'@'localhost';
mysql> \q
```

## Install Node.js

We will install the latest 0.10.x version of Node.js via [nodeenv](https://pypi.python.org/pypi/nodeenv):

```bash
[dev@debian]# sudo apt-get install python python-pip
[dev@debian]# sudo pip install nodeenv
```

## Install Ruby

Switch to your development directory. In this guide we develop straight in the `$HOME` directory.

```bash
[user@debian]# cd ~
```

… and install RVM (Ruby Version Manager)

```bash
[dev@debian]# \curl -sSL https://get.rvm.io | bash -s stable
[dev@centos]# source $HOME/.rvm/scripts/rvm
[dev@debian]# export -f rvm_debug
[dev@debian]# rvm autolibs disable
[dev@debian]# rvm install 2.1.4
[dev@debian]# rvm use --default 2.1.4
[dev@debian]# gem install bundler
```

## Activate Node.js

```bash
[dev@debian]# nodeenv nodeenv
[dev@debian]# source ./nodeenv/bin/activate
[dev@debian]# npm -g install bower
```

If the first step fails with `OSError: Command make --jobs=2 failed with error code 2` try:

```bash
[dev@debian]# rm -r nodeenv
[dev@debian]# # for Ubuntu 12.04 virtualenv needed to be installed
[dev@debian]# sudo pip install virtualenv
[dev@debian]# virtualenv nodeenv
[dev@debian]# source ./nodeenv/bin/activate
[dev@debian]# pip install nodeenv
[dev@debian]# nodeenv -p --prebuilt
[dev@debian]# npm -g install bower
```

As a reference, the following Node.js and NPM versions have been installed on our system:

```bash
[dev@debian]# node --version
                      v6.2.2
[dev@debian]# npm --version
                      3.9.5
[dev@debian]# bower --version
                      1.7.9
```

## Install OpenProject

```bash
[dev@debian]# git clone https://github.com/opf/openproject.git
[dev@debian]# cd openproject
[dev@debian]# bundle install
[dev@debian]# npm install
[dev@debian]# npm run webpack
[dev@debian]# cd frontend
[dev@debian]# bower install
[dev@debian]# cd ..
```

Note that we have checked out the `dev` branch of the OpenProject repository. Development in OpenProject happens in the `dev` branch (there is no `master` branch).
So, if you want to develop a feature, create a feature branch from a current `dev` branch.

## Configure OpenProject

Create and configure the database configuration file in `config/database.yml` (relative to the openproject-directory.

```bash
[dev@debian]# cp config/database.yml.example config/database.yml
```

Now edit the `config/database.yml` file and insert your database credentials.
It should look like this (just with your database name, username, and password):

```bash
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

**NOTE:** You should validate the `database.yml` file, for example with http://www.yamllint.com/. YML-files are sensitive to whitespace — It is pretty easy to write invalid .yml files without seeing the error. Validating those files prevents you from such errors.

## Finish the Installation of OpenProject

```bash
[dev@debian]# bundle exec rake db:create:all
[dev@debian]# bundle exec rake generate_secret_token
[dev@debian]# bundle exec rake db:migrate
[dev@debian]# bundle exec rake db:seed
```

The `db:seed` step is optional, but recommended. It creates many users, work packages, news etc. This takes some time, but gives you useful test data.

## Run OpenProject as a Developer

You can start OpenProject with:

```bash
bundle exec rails server
```

Your OpenProject installation should be accessible on port 3000 (http). A default admin-account is created for you having the following credentials:

```
Username: admin
Password: admin
```

## Start Coding

Please have a look at [our development guidelines](https://www.openproject.org/open-source/code-contributions/) for tips and guides on how to start coding. We have advice on how to get your changes back into the OpenProject core as smooth as possible.
Also, take a look at the `doc` directory in our sources, especially the [how to run tests](https://github.com/opf/openproject/blob/dev/docs/development/running_tests.md) documentation (we like to have automated tests for every new developed feature).

## Troubleshooting

The OpenProject logfile can be found here:

```
/home/openproject/openproject/log/development.log
```

If an error occurs, it should be logged there (as well as in the output to STDOUT/STDERR of the rails server process).

## Questions, Comments, and Feedback

If you have any further questions, comments, feedback, or an idea to enhance this guide, please tell us at the appropriate community.openproject.org [forum](https://community.openproject.org/projects/openproject/boards/9).
[Follow OpenProject on twitter](https://twitter.com/openproject), and follow [the news](https://www.openproject.org/blog) to stay up to date.

