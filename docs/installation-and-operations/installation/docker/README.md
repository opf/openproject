---
sidebar_navigation:
  title: Docker
  priority: 300
---

# Install OpenProject with Docker

[Docker](https://www.docker.com/) is a way to distribute self-contained applications easily. We
provide a Docker image for the Community Edition that you can very easily
install and upgrade on your servers. However, contrary to the manual or
package-based installation, your machine needs to have the Docker Engine
installed first, which usually requires a recent operating system. Please see
the [Docker Engine installation page](https://docs.docker.com/install) if you don't have Docker
installed.

Also, please note that the Docker image is quite new and might not support all
the options that the package-based or manual installation provides.

## Quick Start

The fastest way to get an OpenProject instance up and running is to run the
following command:

```bash
docker run -it -p 8080:80 -e SECRET_KEY_BASE=secret openproject/community:10
```

This will take a bit of time the first time you launch it, but after a few
minutes you should see a success message indicating the default administration
password (login: `admin`, password: `admin`).

You can then launch a browser and access your new OpenProject installation at
<http://localhost:8080>. Easy!

To stop the container, simply hit CTRL-C.

Note that the above command will not daemonize the container and will display
the logs to your terminal, which helps with debugging if anything goes wrong.
For normal usage you probably want to start it in the background, which can be
achieved with the `-d` flag:

```bash
docker run -d -p 8080:80 -e SECRET_KEY_BASE=secret openproject/community:10
```

## Recommended usage

The one-liner above is great to get started quickly, but if you want to run
OpenProject in production you will likely want to ensure that your data is not
lost if you restart the container.

To achieve this, we recommend that you create a directory on your host system
where the Docker Engine is installed (for instance: `/var/lib/openproject`)
where all this data will be stored.

You can use the following commands to create the local directories where the
data will be stored across container restarts, and start the container with
those directories mounted:

```bash
sudo mkdir -p /var/lib/openproject/{pgdata,static}

docker run -d -p 8080:80 --name openproject -e SECRET_KEY_BASE=secret \
  -v /var/lib/openproject/pgdata:/var/openproject/pgdata \
  -v /var/lib/openproject/static:/var/openproject/assets \
  openproject/community:10
```

Since we named the container, you can now stop it by running:

```bash
docker stop openproject
```

And start it again:

```bash
docker start openproject
```

If you want to destroy the container, run the following commands

```bash
docker stop openproject
docker rm openproject
```

## Initial configuration

OpenProject is usually configured through a YAML file, but with the Docker
image you need to pass all configuration through environment variables. You can
overwrite any of the values usually found in the standard YAML file by using
[environment variables](#TODO).

Environment variables can be either passed directly on the command-line to the
Docker Engine, or via an environment file:

```bash
docker run -d -e KEY1=VALUE1 -e KEY2=VALUE2 ...
# or
docker run -d --env-file path/to/file ...
```

For more advanced configuration, please have a look at the [Advanced configuration](../../configuration) section.

## Launching a specific process instead of the all-in-one installation

OpenProject is made of multiple processes (web, worker, cron, etc.). By default the docker image will launch all those processes within a single container for ease of use. However some use cases might require that you only launch one process per container, in which case you should override the docker command to specify the process you want to launch.

By default the container will run `./docker/supervisord`, but you can override this with `./docker/web`, `./docker/worker`, `./docker/cron` to launch the individual services separately (e.g. in a docker-compose file). Please note that in this configuration you will have to setup the external services (postgres, memcached, email sending) by yourself.

Example:

```bash
docker run -d -e DATABASE_URL=xxx ... openproject/community:10 ./docker/web
docker run -d -e DATABASE_URL=xxx ... openproject/community:10 ./docker/worker
```
