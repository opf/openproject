# Install OpenProject (Docker)

[Docker][docker] is a way to distribute self-contained applications easily. We
provide a Docker image for the Community Edition that you can very easily
install and upgrade on your servers. However, contrary to the manual or
package-based installation, your machine needs to have the Docker Engine
installed first, which usually requires a recent operating system. Please see
the [Docker Engine installation page][docker-install] if you don't have Docker
installed.

Also, please note that the Docker image is quite new and might not support all
the options that the package-based or manual installation provides.

[docker]: https://www.docker.com/
[docker-install]: https://docs.docker.com/engine/installation/

## Quick Start

The fastest way to get an OpenProject instance up and running is to run the
following command:

    docker run -it -p 8080:80 -e SECRET_KEY_BASE=secret openproject/community:5.0

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

    docker run -d -p 8080:80 -e SECRET_KEY_BASE=secret openproject/community:5.0

## Recommended usage

The one-liner above is great to get started quickly, but if you want to run
OpenProject in production you will likely want to ensure that your data is not
lost if you restart the container, as well as ensuring that the logs persist on
your host machine in case something goes wrong.

To achieve this, we recommend that you create a directory on your host system
where the Docker Engine is installed (for instance: `/var/lib/openproject`)
where all those data will be stored.

You can use the following commands to create the local directories where the
data will be stored across container restarts, and start the container with
those directories mounted:

    sudo mkdir -p /var/lib/openproject/{pgdata,logs,static}

    docker run -d -p 8080:80 --name openproject -e SECRET_KEY_BASE=secret \
      -v /var/lib/openproject/pgdata:/var/lib/postgresql/9.4/main \
      -v /var/lib/openproject/logs:/var/log/supervisor \
      -v /var/lib/openproject/static:/var/db/openproject \
      openproject/community:5.0

Since we named the container, you can now stop it by running:

    docker stop openproject

And start it again:

    docker start openproject

If you want to destroy the container, run the following commands

    docker stop openproject && docker rm openproject

## Configuration

OpenProject is usually configured through a YAML file, but with the Docker
image you need to pass all configuration through environment variables. You can
overwrite any of the values usually found in the standard YAML file by using
environment variables as explained in the [CONFIGURATION][configuration-doc]
documentation.

Environment variables can be either passed directly on the command-line to the
Docker Engine, or via an environment file:

    docker run -d -e KEY1=VALUE1 -e KEY2=VALUE2 ...
    docker run -d --env-file path/to/file ...

[configuration-doc]: https://github.com/opf/openproject/blob/dev/doc/CONFIGURATION.md

## FAQ

* Can I use SSL?

The current Docker image does not support SSL by default. Usually you would
already have an existing Apache or NginX server on your host, with SSL
configured, which you could use to set up a simple ProxyPass rule to direct
traffic to the container.

If you really want to enable SSL from within the container, you could try
mounting a custom apache2 directory when you launch the container with `-v
my/apache2/conf:/etc/apache2`. This would entirely replace the configuration
we're using.


* Can I use an external (MySQL or PostgreSQL) database?

Yes. You can simply pass a custom `DATABASE_URL` environment variable on the
command-line, which could point to an external database. You can even choose to
use MySQL instead of PostgreSQL if you wish. Here is how you would do it:

    docker run -d ... -e DATABASE_URL=mysql2://user:pass@host:port/dbname openproject/community:5.0

The container will make sure that the database gets the migrations and demo
data as well.

