# OpenProject development Setup on Mac OS X

To develop OpenProject a setup similar to that for using OpenProject in production is needed.

This guide assumes that you have a Mac OS Xinstallation installation with administrative rights. 
OpenProject will be installed with a PostgreSQL database. This guide will work analagous with a MySQL installation, though. 

**Please note**: This guide is NOT suitable for a production setup, but only for developing with it!

If you find any bugs or you have any recommendations for improving this tutorial, please, feel free to send a pull request or comment in the [OpenProject forums](https://community.openproject.org/projects/openproject/boards).

# Prepare your environment

We'll use [homebrew](https://brew.sh/) to install most of our requirements. Please install that first using the guide on their homepage.

## Install Ruby 2.4.

Use [rbenv](https://github.com/rbenv/rbenv) and [ruby-build](https://github.com/rbenv/ruby-build#readme) to install Ruby 2.4.1.
**Install rbenv and ruby-build**

rbenv is a ruby version manager that lets you quickly switch between ruby versions.
ruby-build is an addon to rbenv that installs ruby versions.

```bash
# Install 
$ brew install rbenv ruby-build
# Initialize rbenv
$ rbenv init
```

**Installing ruby-2.4**

With both installed, we can now install the actual ruby version 2.4. You can check available ruby versions with `rbenv install --list`.
At the time of this writing, the latest stable version is `2.4.1`, which we also require.

We suggest you install the version we require in the [Gemfile](https://github.com/opf/openproject/blob/dev/Gemfile). Search for the `ruby '~> X.Y.Z'` line
and install that version.

```bash
# Install the required version as read from the Gemfile
[dev@ubuntu]# rbenv install 2.4.1
```

This might take a while depending on whether ruby is built from source. After it is complete, you need to tell rbenv to globally activate this version

```bash
[dev@ubuntu]# rbenv global 2.4.1
```

You also need to install [bundler](https://github.com/bundler/bundler/), the ruby gem bundler.

```bash
[dev@ubuntu]# gem install bundler
```

## Setup PostgreSQL database

Next, install a PostgreSQL database. If you wish to use a MySQL database instead and have installed one, skip these steps.

```bash
# Install postgres database
$ brew install postgres

# Create the database instance
$ postgres -D /usr/local/var/postgres
```

Then, create the OpenProject database user and accompanied database.

```bash
$ createuser -d -P openproject
```
You will be prompted for a password, for the remainder of these instructions, we assume its `openproject-dev-password`.

Now, create the database `openproject_dev` and `openproject_test` owned by the previously created user.

```bash
$ createdb -O openproject openproject_dev
$ createdb -O openproject openproject_test
```

## Install Node.js

We will install the latest LTS version of Node.js via [nodenv](https://github.com/nodenv/nodenv). This is basically the same steps as for rbenv:

**Install nodenv and node-build**

```bash
# Install
$ brew install nodenv node-build
# Initialize nodenv
$ nodenv init
```

**Install latest LTS node version**

You can find the latest LTS version here: https://nodejs.org/en/download/
Currently, this is v6.11.0. Install and activate it with:

```bash
[dev@ubuntu]# nodenv install 6.11.0
[dev@ubuntu]# nodenv global 6.11.0
```

## Verify your installation

You should now have an active ruby and node installation. Verify that it works with these commands.

```bash
$ ruby --version
ruby 2.4.1p111 (2017-03-22 revision 58053) [x86_64-linux]

$ bundler --version
Bundler version 1.15.1

$ npm --version
3.10.10
```

# Install OpenProject

```bash
# Download the repository
[dev@ubuntu]# git clone https://github.com/opf/openproject.git
[dev@ubuntu]# cd openproject

# Install gem dependencies
# If you get errors here, you're likely missing a development dependency for your distribution
[dev@ubuntu]# bundle install

# Install node_modules
[dev@ubuntu]# npm install
```

Note that we have checked out the `dev` branch of the OpenProject repository. Development in OpenProject happens in the `dev` branch (there is no `master` branch).
So, if you want to develop a feature, create a feature branch from a current `dev` branch.

## Configure OpenProject

Create and configure the database configuration file in `config/database.yml` (relative to the openproject-directory.

```bash
[dev@debian]# vim config/database.yml
```

Now edit the `config/database.yml` file and insert your database credentials.
It should look like this (just with your database name, username, and password):

```
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

**NOTE:** If you want to use MySQL instead and have a database installed, simply use the MySQL section of the exemplary `database.yml.example` configuration file.

## Finish the Installation of OpenProject

Now, run the following tasks to migrate and seed the dev database, and prepare the test setup for running tests locally.

```bash
[dev@ubuntu]# export RAILS_ENV=development
[dev@ubuntu]# ./bin/rake db:migrate db:seed db:test:prepare
```


## Run OpenProject through foreman

You can run all required workers of OpenProject through `foreman`, which combines them in a single tab. This is useful for starting out,
however most developers end up running the tasks in separate shells for better understanding of the log output, since foreman will combine all of them.

```bash
[dev@ubuntu]# gem install foreman
[dev@ubuntu]# foreman start -f Procfile.dev
```
The application will be available at `http://127.0.0.1:5000`. To customize bind address and port copy the `.env.sample` provided in the root of this
project as `.env` and [configure values][foreman-env] as required.

By default a worker process will also be started. In development asynchronous execution of long-running background tasks (sending emails, copying projects,
etc.) may be of limited use. To disable the worker process:

echo "concurrency: web=1,assets=1,worker=0" >> .foreman

For more information refer to Foreman documentation section on [default options][foreman-defaults].

You can access the application with the admin-account having the following credentials:

    Username: admin
    Password: admin

## Run OpenProject manually

To run OpenProject manually, you need to run the rails server and the webpack frontend bundler to:

**Rails web server**

```bash
[dev@ubuntu]# RAILS_ENV=development ./bin/rails server
```

This will start the development server on port `3000` by default.

**Webpack bundling**

```bash
[dev@ubuntu]# RAILS_ENV=development npm run webpack-watch
```

This will watch for any changes within the `frontend/` and compile the application javascript bundle on demand. You will need to watch this tab for the compilation output,
should you be working on the TypeScript / angular.js frontend part.


## Start Coding

Please have a look at [our development guidelines](https://www.openproject.org/open-source/code-contributions/) for tips and guides on how to start coding. We have advice on how to get your changes back into the OpenProject core as smooth as possible.
Also, take a look at the `doc` directory in our sources, especially the [how to run tests](https://github.com/opf/openproject/blob/dev/docs/development/running-tests.md) documentation (we like to have automated tests for every new developed feature).

## Troubleshooting

The OpenProject logfile can be found here:

```
/home/openproject/openproject/log/development.log
```

If an error occurs, it should be logged there (as well as in the output to STDOUT/STDERR of the rails server process).

## Questions, Comments, and Feedback

If you have any further questions, comments, feedback, or an idea to enhance this guide, please tell us at the appropriate community.openproject.org [forum](https://community.openproject.org/projects/openproject/boards/9).
[Follow OpenProject on twitter](https://twitter.com/openproject), and follow [the news](https://www.openproject.org/blog) to stay up to date.

[foreman-defaults]:http://ddollar.github.io/foreman/#DEFAULT-OPTIONS
[foreman-env]:http://ddollar.github.io/foreman/#ENVIRONMENT
