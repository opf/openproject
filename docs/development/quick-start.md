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

## Manual development environment

Please see the following guides for detailed instructions on how to get started developing for OpenProject.

- [Development environment for Ubuntu 16.04.](./development-environment-ubuntu.md)
- [Development environment for Mac OS X](./development-environment-osx.md)
