# Quick start for developers


Detailed installation instructions for different platforms are located on the [OpenProject website](https://www.openproject.org/download/).

You can find information on configuring OpenProject in [`config/CONFIGURATION.md`](CONFIGURATION.md).

## Fast install (Docker version)

### Prerequisites

* Git
* [Docker Engine](https://docs.docker.com/engine/installation/)
* [Docker Compose](https://docs.docker.com/compose/)

### Building and running

1. Build the image (this will take some time)

        docker-compose build

2. Start and setup the database

        docker-compose up -d db
        cp config/database.docker.yml config/database.yml
        docker-compose run web rake db:create db:migrate db:seed

3. Start the other processes

        docker-compose up

Assets should be automatically recompiled anytime you make a change, and your
ruby code should also be reloaded when you change a file locally.

You can run arbitrary commands in the context of the application by using
`docker-compose run`. For instance:

    docker-compose run web rake db:migrate
    docker-compose run web rails c
    ...

## Fast install (manual)

These are generic (and condensed) installation instructions for the **current dev** branch *without plugins*, and optimised for a development environment. Refer to the OpenProject website for instructions for the **stable** branch, OpenProject configurations with plugins, as well as platform-specific guides.

### Prerequisites

* Git
* Database (MySQL 5.x/PostgreSQL 8.x)
* Ruby 2.1.x
* Node.js (tested on LTS v6.9.1, lower versions may work)
* Bundler (version 1.5.1 or higher required)

### Install dependencies

1. Install Ruby dependencies with Bundler:

        bundle install

2. Install JavaScript dependencies with [npm]:

        npm install

3. Install `foreman` gem:

        [sudo] gem install foreman

### Configure Rails

1. Copy `config/database.yml.example` to `config/database.yml`:

        cd config
        cp database.yml.example database.yml

   Edit `database.yml` according to your preferred database's settings.

2. Copy `config/configuration.yml.example` to `config/configuration.yml`:

        cp configuration.yml.example configuration.yml
        cd ..

   Edit `configuration.yml` according to your preferred settings for email, etc. (see [`config/CONFIGURATION.md`](CONFIGURATION.md) for a full list of configuration options).

3. Create databases, schemas and populate with seed data:

        # bundle exec rake db:create:all
        # bundle exec rake db:migrate
        # bundle exec rake db:seed

4. Generate a secret token for the session store:

        bundle exec rake generate_secret_token

### Run!

1. Start OpenProject in development mode:

        foreman start -f Procfile.dev

   The application will be available at `http://127.0.0.1:5000`. To customize
   bind address and port copy the `.env.sample` provided in the root of this
   project as `.env` and [configure values][foreman-env] as required.

   By default a worker process will also be started. In development asynchronous
   execution of long-running background tasks (sending emails, copying projects,
   etc.) may be of limited use. To disable the worker process:

        echo "concurrency: web=1,assets=1,worker=0" >> .foreman

   For more information refer to Foreman documentation section on [default options][foreman-defaults].
   
  You can access the application with the admin-account having the following credentials:

        Username: admin
        Password: admin

## Full guide

Please see [here](./development/setting-up-development-environment.md)

[Node.js]:http://nodejs.org/
[Bundler]:http://bundler.io/
[npm]:https://www.npmjs.org/
[foreman-defaults]:http://ddollar.github.io/foreman/#DEFAULT-OPTIONS
[foreman-env]:http://ddollar.github.io/foreman/#ENVIRONMENT
