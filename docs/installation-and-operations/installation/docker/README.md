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

OpenProject with Docker can be launched in two ways:

1. Multiple containers (recommended), each with a single process inside, using a Compose file. Allows to easily choose which services you want to run, and simplifies scaling and monitoring aspects.
2. One container with all the processes inside. Easy but not recommended for production. This is the legacy behaviour.

## One container per process (recommended)

### Quick Start

First, you must clone the OpenProject repository:

```bash
git clone --depth=1 --branch=stable/10 https://github.com/opf/openproject
```

Then, go into the OpenProject folder and you can launch all the services required by OpenProject with docker-compose:

```bash
docker-compose up -d
```

After some time, you will be able to access OpenProject on http://localhost:8080. The default username and password is login: `admin`, and password: `admin`.

Note that the official `docker-compose.yml` file present in the repository can be adjusted to your convenience. For instance you could mount specific configuration files, override environment variables, or switch off services you don't need. Please refer to the official docker-compose documentation for more details.

You can stop the Compose stack by running:

```
docker-compose down
```

## All-in-one container

### Quick Start

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

### Recommended usage

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

### Initial configuration

OpenProject is usually configured through a YAML file, but with the Docker
image you need to pass all configuration through environment variables. You can
overwrite any of the values usually found in the standard YAML file by using
[environment variables](../../configuration/environment).

Environment variables can be either passed directly on the command-line to the
Docker Engine, or via an environment file:

```bash
docker run -d -e KEY1=VALUE1 -e KEY2=VALUE2 ...
# or
docker run -d --env-file path/to/file ...
```

For more advanced configuration, please have a look at the [Advanced configuration](../../configuration) section.

### Apache Reverse Proxy Setup

Often there will be an existing web server through which you want to make OpenProject acccessible.
There are two ways to run OpenProject. We'll cover each configuration in a separate of the following sections.

For both configurations the following Apache mods are required:

* proxy
* proxy_http
* rewrite
* ssl (optional)

In each case you will create a file `/usr/local/apache2/conf/sites/openproject.conf`
with the contents as described in the respective sections.

Both configuration examples are based on the following assumptions:

* the site is accessed via https
* certificate and key are located under `/etc/ssl/crt/server.{crt, key}`
* the OpenProject docker container's port 80 is mapped to the docker host's port 8080

*Important:* Once OpenProject is running make sure to also set the host name and protocol
accordingly under Administration -> System Settings.

#### 1) Virtual host root

The default scenario is to have OpenProject serve the whole virtual host.
This requires no further configuration for the docker container beyond what is
described above.

Assuming the desired *server name* is `openproject.example.com` the configuration
will look like this:

```
<VirtualHost *:80>
    ServerName openproject.example.com

    RewriteEngine on
    RewriteCond %{HTTPS} !=on
    RewriteRule ^/?(.*)$ https://%{SERVER_NAME}/$1 [R,L]
</VirtualHost>

<VirtualHost *:443>
    ServerName openproject.example.com

    SSLEngine on
    SSLCertificateFile /etc/ssl/crt/server.crt
    SSLCertificateKeyFile /etc/ssl/crt//server.key

    RewriteEngine on
    RewriteRule "^$" "/" [R,L]

    ProxyRequests off

    <Location "/">
      RequestHeader set X-Forwarded-Proto 'https'

      ProxyPreserveHost On
      ProxyPass http://127.0.0.1:8080/
      ProxyPassReverse http://127.0.0.1:8080/
    </Location>
</VirtualHost>
```

#### 2) Location (subdirectory)

Let's assume you want OpenProject to run on your host with the *server name* `example.com`
under the *subdirectory* `/openproject`.

If you want to run OpenProject in a subdirectory on your server, first you will
need to configure OpenProject accordingly by adding the following options to the `docker run` call:

```
-e OPENPROJECT_RAILS__RELATIVE__URL__ROOT=/openproject \
-e OPENPROJECT_RAILS__FORCE__SSL=true \
```

The `force ssl` option can be left out if you are not using HTTPS.

The apache configuration for this configuration then looks like this:

```
<VirtualHost *:80>
    ServerName example.com

    RewriteEngine on
    RewriteCond %{HTTPS} !=on
    RewriteRule ^/?(openproject.*)$ https://%{SERVER_NAME}/$1 [R,L]
</VirtualHost>

<VirtualHost *:443>
    ServerName example.com

    SSLEngine on
    SSLCertificateFile /etc/ssl/crt/server.crt
    SSLCertificateKeyFile /etc/ssl/crt/server.key

    RewriteEngine on
    RewriteRule "^/openproject$" "/openproject/" [R,L]

    ProxyRequests off

    <Location "/openproject/">
      RequestHeader set X-Forwarded-Proto 'https'

      ProxyPreserveHost On
      ProxyPass http://127.0.0.1:8080/openproject/
      ProxyPassReverse http://127.0.0.1:8080/openproject/
    </Location>
</VirtualHost>
```

### OpenProject plugins

The docker image itself does not support plugins. But you can create your own docker image to include plugins.

**1. Create a new folder** with any name, for instance `custom-openproject`. Change into that folder.

**2. Create the file `Gemfile.plugins`** in that folder. In the file you declare the plugins you want to install.
For instance:

```
group :opf_plugins do
  gem "openproject-slack", git: "https://github.com/opf/openproject-slack.git", branch: "release/10.0"
end
```

**3. Create the `Dockerfile`** in the same folder. The contents have to look like this:

```
FROM openproject/community:10

COPY Gemfile.plugins /app/

RUN bundle config unset deployment && bundle install && bundle config set deployment 'true'
RUN bash docker/precompile-assets.sh
```

The file is based on the normal OpenProject docker image.
All the Dockerfile does is copy your custom plugins gemfile into the image, install the gems and precompile any new assets.

**4. Build the image**

To actually build the docker image run:

```
docker build -t openproject-with-slack .
```

The `-t` option is the tag for your image. You can choose what ever you want.

**5. Run the image**

You can run the image just like the normal OpenProject image (as shown earlier).
You just have to use your chosen tag instead of `openproject/community:10`.
To just give it a quick try you can run this:

```
docker run -p 8080:80 --rm -it openproject-with-slack
```

After which you can access OpenProject under http://localhost:8080.
