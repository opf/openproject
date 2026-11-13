---
sidebar_navigation:
  title: Development setup on MacOS
  short_title: Setup on MacOS
description: OpenProject development setup on Mac OS
keywords: development setup macos
---

# OpenProject development setup on macOS

To develop OpenProject a setup similar to that for using OpenProject in production is needed.

This guide assumes that you have a macOS installation with administrative rights.
OpenProject will be installed with a PostgreSQL database.

**Please note**: This guide is NOT suitable for a production setup, but only for developing with it!

If you find any bugs or you have any recommendations for improving this tutorial, please, feel free to send a pull
request or comment in the [OpenProject forums](https://community.openproject.org/projects/openproject/boards).

## Prepare your environment

We'll use [homebrew](https://brew.sh/) to install most of our requirements. Please install that first using the guide on
their homepage.

### Install Ruby

Use [rbenv](https://github.com/rbenv/rbenv) and [ruby-build](https://github.com/rbenv/ruby-build#readme) to install
Ruby. We always require the latest ruby versions, and you can check which version is required
in [.ruby-version](https://github.com/opf/openproject/blob/dev/.ruby-version). At the time of writing, this version
is "4.0.9"

#### Install rbenv and ruby-build

rbenv is a ruby version manager that lets you quickly switch between ruby versions.
ruby-build is an addon to rbenv that installs ruby versions.

```shell
# Install
$ brew install rbenv ruby-build
# Initialize rbenv
$ rbenv init
```

#### Installing ruby

With both installed, we can now install the actual ruby version.
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
```

You also need to install [bundler](https://github.com/bundler/bundler/), the ruby gem bundler.

```shell
gem install bundler
```

### Setup PostgreSQL database

Next, install a PostgreSQL database. OpenProject requires
[PostgreSQL 16 or above](../../../installation-and-operations/system-requirements/#database).

```shell
# Install and start the postgres database
brew install postgresql@17
brew services start postgresql@17
```

`postgresql@17` is keg-only, so its commands such as `createuser` are not on your `PATH` by default. Follow the
instructions Homebrew prints after the installation to add them.

Then, create the OpenProject database user and accompanied database.

```shell
createuser -d -P openproject
```

You will be prompted for a password, for the remainder of these instructions, we assume its `openproject-dev-password`.

Now, create the database `openproject_dev` and `openproject_test` owned by the previously created user.

```shell
createdb -O openproject openproject_dev
createdb -O openproject openproject_test
```

### Install Node.js

We will install the latest LTS version of Node.js via [nodenv](https://github.com/nodenv/nodenv). This is basically the
same steps as for rbenv:

#### Install nodenv and node-build

```shell
# Install
brew install nodenv node-build
# Initialize nodenv
nodenv init
```

#### Install latest LTS node version

You can find the latest LTS version here: [nodejs.org/en/download](https://nodejs.org/en/download/)

At the time of writing this is v24.22.1. Install and activate it with:

```shell
nodenv install 24.22.1
nodenv global 24.22.1
```

#### Update NPM to the latest version

```shell
npm install npm@latest -g
```

### Verify your installation

You should now have an active ruby and node installation. Verify that it works with these commands.

```shell
$ ruby --version
ruby 4.0.9 (2026-10-23 revision 3e93b23afc) +PRISM [arm64-darwin25]

$ bundler --version
# The version listed under BUNDLED WITH at the end of Gemfile.lock

node --version
v24.22.1

npm --version
11.16.0
```

## Install and run OpenProject

Continue with [Install and run OpenProject from source](../common-setup/), which covers getting the sources, configuring
OpenProject, and running it. On macOS, apply the database settings below when you create `config/database.yml`.

## macOS-specific database settings

Socket encryption must be disabled on macOS. Add `gssencmode: disable` to the `default` section of
`config/database.yml`, otherwise Ruby will crash whenever a route is accessed (see
[ruby-pg#311](https://github.com/ged/ruby-pg/issues/311)):

```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  gssencmode: disable
  host: localhost
  username: openproject
  password: openproject-dev-password
```

> [!TIP]
> Instead of using the `gssencmode` flag in `config/database.yml`, you can add `export PGGSSENCMODE="disable"` to your
> Shell profile (`~/.zprofile` by default). This will prevent Ruby crashes for _all_ of your projects.

Some users report Ruby crashes despite having set this flag to disable. If this is the case for you as well,
try adding `export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=yes` to your Shell profile.

## Install other requirements

Some operations in OpenProject require additional software. These include PDF exports and interaction with an
LDAP server.

In order to develop OpenProject in these areas, you need to install `imagemagick` and `java`.

```shell
brew install imagemagick java
```

As of writing, you need to manually create a symlink to OpenJDK for the Java installation to take effect. Homebrew will
tell you how.

## Additional test dependencies

The test suite requires a few additional dependencies to be installed. These are not required for running OpenProject in
development mode, but only for running the entire test suite.

### Java 7 or later

To test the integration with LDAP servers, we rely on [ladle](https://github.com/NUBIC/ladle) to spin up an LDAP server
when running tests. As this runs [ApacheDS](https://directory.apache.org/apacheds/) internally, it requires Java 7 or
later to be installed.

If java is not installed, some tests will stall for 60 seconds before timing out. To run the tests, install java with

```shell
brew install openjdk

# The installation instructions will tell you to add a symlink to the JDK for the `java` command to pick it up
sudo ln -sfn $(brew --prefix)/opt/openjdk/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk
```

### Subversion

To test the integration with Subversion repositories, we rely on the `svnadmin` command to be available. If subversion
is not installed, the tests _will be skipped_. To run the tests, install subversion with

```shell
brew install subversion
```

### Git

To test the integration with Git repositories, we rely on the `git` command to be available. Git is either installed via
the Xcode Command Line Tools, with [Xcode](https://apps.apple.com/us/app/xcode/id497799835?mt=12) or via homebrew.

```shell
xcode-select --install

# or

brew install git
```
