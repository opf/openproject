---
sidebar_navigation:
  title: Install and run OpenProject from source
  short_title: Install and run from source
description: Install, configure and run OpenProject from source for development on macOS and Linux
keywords: development setup, install, run, overmind, bin/dev, setup_dev
---

# Install and run OpenProject from source

This page continues the [macOS](../macos) and [Debian / Ubuntu](../linux) development setup guides. It assumes you have installed Ruby, Node.js and PostgreSQL and created the `openproject` database user and the `openproject_dev` and `openproject_test` databases as described there.

**Please note**: This guide is NOT suitable for a production setup, but only for developing with it!

## Get the sources

In order to create a pull request to the core OpenProject repository, you will want to fork it to your own GitHub account. This allows you to create branches and push changes and finally open a pull request for us to review. To do that, go to [github.com/opf/openproject](https://github.com/opf/openproject) and press "Fork" on the upper right corner.

```shell
# Download the repository
# If you want to create a pull request, replace the URL with your own fork as described above
git clone https://github.com/opf/openproject.git
cd openproject
```

Note that we have checked out the `dev` branch of the OpenProject repository. Development in OpenProject happens in the `dev` branch (there is no `master` branch). So, if you want to develop a feature, create a feature branch from a current `dev` branch.

## Configure OpenProject

Create and configure the database configuration file in `config/database.yml` (relative to the OpenProject directory). It should look like this (just with your database name, username, and password):

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

On macOS, also apply the [macOS-specific database settings](../macos/#macos-specific-database-settings).

To configure the environment variables such as the number of web server threads `OPENPROJECT_WEB_WORKERS`, copy the `.env.example` to `.env` and add the environment variables you want to configure. The variables will be automatically loaded to the application's environment.

## Finish the installation of OpenProject

`bin/setup_dev` installs the code dependencies and prepares the application:

- gem dependencies (if you get errors here, you're likely missing a development dependency for your distribution)
- database migrations
- `node_modules` for the frontend and for the collaborative editing server (`extensions/op-blocknote-hocuspocus`)
- link plugin frontend modules
- and export frontend localization files

```shell
bin/setup_dev
```

Now, seed the development database:

```shell
RAILS_ENV=development bin/rails db:seed
```

To prepare the test setup for running tests locally, see [Running tests locally](../../testing/running-tests-locally/).

## Run OpenProject through overmind

You can run all required processes of OpenProject through `overmind`, which combines them in a single tab. Optionally, you may also run `overmind` as a daemon and connect to services individually. The `bin/dev` command will first check if `overmind` is available and run the application via `Procfile.dev`. Otherwise it will use `foreman` if it is available.

```shell
bin/dev
```

The application will be available at `http://localhost:3000`. To customize bind address and port, copy the `.env.example` provided in the root of this project as `.env` and [configure values](https://github.com/DarthSim/overmind/tree/v2.4.0#overmind-environment) as required.

By default a worker process will also be started. In development asynchronous execution of long-running background tasks (sending emails, copying projects, etc.) may be of limited use and it has known issues with regards to memory. To disable the worker process:

```shell
echo "OVERMIND_IGNORED_PROCESSES=worker" >> .overmind.env
```

For more information refer to the great Overmind documentation [usage section](https://github.com/DarthSim/overmind/tree/v2.4.0#usage).

You can access the application with the admin account having the following credentials:

```text
Username: admin
Password: admin
```

## Run OpenProject manually

To run OpenProject manually, start each process from `Procfile.dev` in its own terminal.

### Rails web server

```shell
RAILS_ENV=development bin/rails server
```

This will start the development server on port `3000` by default. The application is available at `http://localhost:3000`.

### Angular frontend

To run the frontend server, please run

```shell
npm run serve
```

This starts the Angular CLI dev server on `http://localhost:4200`. It compiles the frontend on demand, serves the frontend assets from memory and rebuilds them when you change code in `frontend/`. You will need to watch this tab for the compilation output, should you be working on the TypeScript / Angular frontend part.

Always open the application through the Rails server at `http://localhost:3000`, which loads the frontend assets from the dev server. Port `4200` only serves assets, not the application. See [Developing OpenProject Frontend](https://github.com/opf/openproject/blob/dev/frontend/doc/README.md#angular-frontend) for details.

### Background job worker

```shell
RAILS_ENV=development bundle exec good_job start
```

This will start a GoodJob worker to perform asynchronous jobs like sending emails.

### Collaborative editing server

Collaborative editing of documents uses a [Hocuspocus](https://tiptap.dev/docs/hocuspocus/introduction) server in `extensions/op-blocknote-hocuspocus`. The `SECRET` must match `OPENPROJECT_COLLABORATIVE__EDITING__HOCUSPOCUS__SECRET` (see `.env.example`).

```shell
cd extensions/op-blocknote-hocuspocus
SECRET=secret12345 npm run dev
```

The server listens on port `1234`, which `.env.example` configures as `OPENPROJECT_COLLABORATIVE__EDITING__HOCUSPOCUS__URL`.

## Access the development server from another device

Sometimes it is necessary to test with a real mobile phone or from a VM. To make this possible, the Rails server and the frontend dev server must be reachable on your machine's network address, and the frontend assets must be loaded from that address instead of `localhost`.

Find the IP address of the machine that runs the dev server on the network, then add the following to your `.env` file:

```shell
# Address the Angular CLI dev server binds to; Rails loads frontend assets from http://FE_HOST:FE_PORT
FE_HOST=<your IP address>
FE_PORT=4200
# Rails server the dev server proxies API requests to
PROXY_HOSTNAME=<your IP address>
OPENPROJECT_HOST__NAME=<your IP address>:3000
# Configure Hocuspocus if you want to use documents
OPENPROJECT_COLLABORATIVE__EDITING__HOCUSPOCUS__URL=ws://<your IP address>:1234
```

If you use a host name instead of an IP address, also allow it in Rails with `OPENPROJECT_DEV_EXTRA_HOSTS=<your host name>` (comma-separated for multiple host names).

Then start the Rails server bound to all interfaces (if you use `bin/dev`, edit the `web` line in `Procfile.dev` accordingly):

```shell
bin/rails server --binding=0.0.0.0
```

If you start the frontend dev server manually, `.env` is not loaded, so pass the variables explicitly:

```shell
FE_HOST=<your IP address> PROXY_HOSTNAME=<your IP address> npm run serve
```

Afterwards, you can open `http://<your IP address>:3000` on a device on the same network.

Alternatively, you can serve precompiled frontend assets from Rails instead of running the frontend dev server. You then need to precompile again after every frontend change.

```shell
# Precompile the application assets
bin/rails openproject:plugins:register_frontend assets:precompile

# Start the application server while disabling the CLI asset host
OPENPROJECT_CLI_PROXY='' bin/rails server --binding=0.0.0.0
```

## Known issues

### Clearing queued background jobs

If the worker has not run for a while, a lot of background jobs may have queued up (for example, emails, which you can view under `/letter_opener` in development). To get rid of the jobs before starting the worker, use the following command. **This will remove all background jobs, never use this in a production setting.**

```shell
RAILS_ENV=development bin/rails runner "GoodJob::Job.delete_all"
```
