---
sidebar_navigation:
  title: Development setup on Debian / Ubuntu
  short_title: Setup on Debian / Ubuntu
description: OpenProject development setup on Debian / Ubuntu
keywords: development setup debian ubuntu linux
---

# OpenProject development setup on Debian / Ubuntu

To develop OpenProject a setup similar to that for using OpenProject in production is needed.

This guide assumes that you have an Ubuntu 24.04 installation with administrative rights. This guide will work
analogous with all other distributions, but may require slight changes in the required packages. _Please, help us to
extend this guide with information on other distributions should there be required changes._

OpenProject Development Environment will be installed with a PostgreSQL database, OpenProject on-premises installation
shall NOT be present before.

**Please note**: This guide is NOT suitable for a production setup, but only for developing with it!

If you find any bugs or you have any recommendations for improving this tutorial, please, feel free to send a pull
request or comment in the [OpenProject forums](https://community.openproject.org/projects/openproject/boards).

## Prepare your environment

We need an active Ruby and Node JS environment to run OpenProject. To this end, we need some packages installed on the
system.

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
At the time of this writing, the latest stable version is `4.0.9`, which we also require.

We suggest you install the version we require in [.ruby-version](https://github.com/opf/openproject/blob/dev/.ruby-version).
Read the first line e.g. `4.0.9` and install that version.

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
Read the first line e.g. `4.0.9` and install that version.

```shell
# Install the required version as read from the .ruby-version file
rbenv install 4.0.9
```

This might take a while depending on whether ruby is built from source. After it is complete, you need to tell rbenv to
globally activate this version

```shell
rbenv global 4.0.9
rbenv rehash
```

You also need to install [bundler](https://github.com/bundler/bundler/), the ruby gem bundler (remark: if you run into
an error, first try with a fresh reboot).

```shell
gem install bundler
```

If you get `Command 'gem' not found...` here, ensure you followed the instructions `rbenv init` command to ensure it is
loaded in your shell.

### Setup PostgreSQL database

Next, install a PostgreSQL database. OpenProject requires
[PostgreSQL 16 or above](../../../installation-and-operations/system-requirements/#database). Ubuntu 24.04 ships
PostgreSQL 16. On older releases, install a supported version from the
[PostgreSQL apt repository](https://www.postgresql.org/download/linux/ubuntu/).

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

At the time of writing this is v24.22.1 Install and activate it with:

```shell
nodenv install 24.22.1
nodenv global 24.22.1
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
ruby 4.0.9 (2026-10-23 revision 3e93b23afc) +PRISM [arm64-darwin25]

bundler --version
# The version listed under BUNDLED WITH at the end of Gemfile.lock

node --version
v24.22.1

npm --version
11.16.0
```

## Install and run OpenProject

Continue with [Install and run OpenProject from source](../common-setup/), which covers getting the sources, configuring
OpenProject, and running it.
