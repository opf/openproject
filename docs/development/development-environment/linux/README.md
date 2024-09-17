---
sidebar_navigation:
  title: Development setup on Debian / Ubuntu
  short_title: Setup on Debian / Ubuntu
description: OpenProject development setup on Debian / Ubuntu
keywords: development setup debian ubuntu linux
---

# OpenProject development setup on Debian / Ubuntu

To develop OpenProject a setup similar to that for using OpenProject in production is needed.

This guide assumes that you have a Ubuntu 20.04 installation with administrative rights. This guide will work
analogous with all other distributions, but may require slight changes in the required packages. _Please, help us to
extend this guide with information on other distributions should there be required changes._

OpenProject Development Environment will be installed with a PostgreSQL database, OpenProject on-premises installation
shall NOT be present before.

**Please note**: This guide is NOT suitable for a production setup, but only for developing with it!

If you find any bugs or you have any recommendations for improving this tutorial, please, feel free to send a pull
request or comment in the [OpenProject forums](https://community.openproject.org/projects/openproject/boards).

## Prepare your environment

We need an active Ruby and Node JS environment to run OpenProject. To this end, we need some packages installed on the
system.o

CPU recommendation: 4 CPUs, Memory recommendation: 8 better 16 GB (in general we need double the amount of a normal
production installation)

```shell
sudo apt-get update
sudo apt-get install git curl build-essential zlib1g-dev libyaml-dev libssl-dev libpq-dev libreadline-dev
```

### Install Ruby

Use [rbenv](https://github.com/rbenv/rbenv) and [ruby-build](https://github.com/rbenv/ruby-build#readme) to install
Ruby.
You can check available ruby versions with `rbenv install --list`.
At the time of this writing, the latest stable version is `3.3.4`, which we also require.

We suggest you install the version we require in [.ruby-version](https://github.com/opf/openproject/blob/dev/.ruby-version).
Read the first line e.g. `3.3.4` and install that version.

#### Install rbenv and ruby-build

rbenv is a ruby version manager that lets you quickly switch between ruby versions.
ruby-build is an addon to rbenv that installs ruby versions.

```shell
# Install rbenv locally for the dev user
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
# Optional: Compile bash extensions
cd ~/.rbenv && src/configure && make -C src
# Add rbenv to the shell's $PATH.
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc

# Run rbenv-init and follow the instructions to initialize rbenv on any shell
~/.rbenv/bin/rbenv init
# Issue the recommended command from the stdout of the last command
echo 'eval "$(rbenv init - bash)"' >> ~/.bashrc
# Source bashrc
source ~/.bashrc
```

#### Installing ruby-build

ruby-build is an addon to rbenv that installs ruby versions

```shell
git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
```

#### Installing ruby

With both installed, we can now install ruby. 
You can check available ruby versions with `rbenv install --list`.

We suggest you install the version we require in [.ruby-version](https://github.com/opf/openproject/blob/dev/.ruby-version).
Read the first line e.g. `3.3.4` and install that version.

```shell
# Install the required version as read from the .ruby-version file
rbenv install 3.3.4
```

This might take a while depending on whether ruby is built from source. After it is complete, you need to tell rbenv to
globally activate this version

```shell
rbenv global 3.3.4
rbenv rehash
```

You also need to install [bundler](https://github.com/bundler/bundler/), the ruby gem bundler (remark: if you run into
an error, first try with a fresh reboot).

If you get `Command 'gem' not found...` here, ensure you followed the instructions `rbenv init` command to ensure it is
loaded in your shell.

### Setup PostgreSQL database

Next, install a PostgreSQL database.

```shell
[dev@debian]# sudo apt-get install postgresql postgresql-client
```

Create the OpenProject database user and accompanied database.

```shell
sudo su - postgres
[postgres@ubuntu]# createuser -d -P openproject
```

You will be prompted for a password, for the remainder of these instructions, we assume its `openproject-dev-password`.

Now, create the database `openproject_dev` and `openproject_test` owned by the previously created user.

```shell
[postgres@ubuntu]# createdb -O openproject openproject_dev
[postgres@ubuntu]# createdb -O openproject openproject_test

# Exit the shell as postgres
[postgres@ubuntu]# exit
```

### Install Node.js

We will install the latest LTS version of Node.js via [nodenv](https://github.com/nodenv/nodenv). This is basically the
same steps as for rbenv:

#### Install nodenv

```shell
# Install nodenv
git clone https://github.com/nodenv/nodenv.git ~/.nodenv
# Optional: Install bash extensions
cd ~/.nodenv && src/configure && make -C src
# Add nodenv to the shell's $PATH.
echo 'export PATH="$HOME/.nodenv/bin:$PATH"' >> ~/.bashrc

# Run nodenv init and follow the instructions to initialize nodenv on any shell
~/.nodenv/bin/nodenv init
# Issue the recommended command from the stdout of the last command
echo 'eval "$(nodenv init -)"' >> ~/.bashrc
# Source bashrc
source ~/.bashrc
```

#### Install node-build

```shell
git clone https://github.com/nodenv/node-build.git $(nodenv root)/plugins/node-build
```

#### Install latest LTS node version

You can find the latest LTS version here: [nodejs.org/en/download/](https://nodejs.org/en/download/)

At the time of writing this is v20.9.0 Install and activate it with:

```shell
nodenv install 20.9.0
nodenv global 20.9.0
nodenv rehash
```

#### Update NPM to the latest version

```shell
npm install npm@latest -g
```

### Verify your installation

You should now have an active ruby and node installation. Verify that it works with these commands.

```shell
ruby --version
ruby 3.3.4 (2024-07-09 revision be1089c8ec) [arm64-darwin23]

bundler --version
Bundler version 2.5.13

node --version
v20.9.0

npm --version
10.5.0
```

## Install OpenProject Sources

In order to create a pull request to the core OpenProject repository, you will want to fork it to your own GitHub
account.
This allows you to create branches and push changes and finally opening a pull request for us to review.

To do that, go to [github.com/opf/openproject](https://github.com/opf/openproject) and press "Fork" on the upper right
corner.

```shell
# Download the repository
# If you want to create a pull request, replace the URL with your own fork as described above
mkdir ~/dev
cd ~/dev
git clone https://github.com/opf/openproject.git
cd openproject
```

Note that we have checked out the `dev` branch of the OpenProject repository. Development in OpenProject happens in
the `dev` branch (there is no `master` branch).
So, if you want to develop a feature, create a feature branch from a current `dev` branch.

### Configure OpenProject

Create and configure the database configuration file in `config/database.yml` (relative to the openproject-directory.

```shell
[dev@debian]# vim config/database.yml
```

Now edit the `config/database.yml` file and insert your database credentials.
It should look like this (just with your database name, username, and password):

```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  host: localhost
  username: openproject
  password: openproject-dev-password

development:
  <<: *default
  database: openproject_dev

test:
  <<: *default
  database: openproject_test
```

To configure the environment variables such as the number of web server threads `OPENPROJECT_WEB_WORKERS`, copy
the `.env.example` to `.env` and add the environment variables you want to configure. The variables will be
automatically loaded to the application's environment.

### Finish the Installation of OpenProject

Install code dependencies, link plugin modules and export translation files.

- gem dependencies (If you get errors here, you're likely missing a development dependency for your distribution)
- node_modules
- link plugin frontend modules
- and export frontend localization files

```shell
bin/setup_dev
```

Now, run the following tasks to seed the dev database, and prepare the test setup for running tests locally.

```shell
RAILS_ENV=development bin/rails db:seed
```

### Run OpenProject through overmind

You can run all required workers of OpenProject through `overmind`, which combines them in a single tab. Optionally, you
may also
run `overmind` as a daemon and connect to services individually.
The `bin/dev` command will first check if `overmind` is available and run the application via `Procfile.dev`. Otherwise
it will use `foreman` if it is available.

```shell
bin/dev
```

The application will be available at `http://127.0.0.1:3000`. To customize bind address and port copy the `.env.example`
provided in the root of this
project as `.env` and [configure values](https://github.com/DarthSim/overmind/tree/v2.4.0#overmind-environment) as
required.

By default a worker process will also be started. In development asynchronous execution of long-running background
tasks (sending emails, copying projects,
etc.) may be of limited use and it has known issues with regards to memory (see background worker section below). To
disable the worker process:

```shell
echo "OVERMIND_IGNORED_PROCESSES=worker" >> .overmind.env
```

For more information refer to the great Overmind
documentation [usage section](https://github.com/DarthSim/overmind/tree/v2.4.0#usage).

You can access the application with the admin-account having the following credentials:

```text
Username: admin
Password: admin
```

### Run OpenProject manually

To run OpenProject manually, you need to run the rails server and the webpack frontend bundler to:

#### Rails web server

```shell
RAILS_ENV=development bin/rails server
```

This will start the development server on port `3000` by default.

#### Angular frontend

To run the frontend server, please run

```shell
RAILS_ENV=development npm run serve
```

This will watch for any changes within the `frontend/` and compile the application javascript bundle on demand. You will
need to watch this tab for the compilation output,
should you be working on the TypeScript / Angular frontend part.

You can then access the application either through `localhost:3000` (Rails server) or through the frontend
proxied `http://localhost:4200`, which will provide hot reloading for changed frontend code.

#### Background job worker

```shell
RAILS_ENV=development bundle exec good_job start
```

This will start a Delayed::Job worker to perform asynchronous jobs like sending emails.

### Known issues

#### Spawning a lot of browser tabs

If you haven't run this command for a while, chances are that a lot of background jobs have queued up and might cause a
significant amount of open tabs (due to the way we deliver mails with the letter_opener gem). To get rid of the jobs
before starting the worker, use the following command. **This will remove all currently scheduled jobs, never use this
in a production setting.**

```shell
RAILS_ENV=development bin/rails runner "Delayed::Job.delete_all"
```
