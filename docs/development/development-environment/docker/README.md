---
sidebar_navigation:
  title: Development setup via docker
  short_title: Setup via Docker
description: OpenProject development setup via docker
keywords: development setup docker
---

# OpenProject development setup via docker

The quickest way to get started developing OpenProject is to use the docker setup.

## Requirements

* docker

And nothing else!

## Quick start

To get right into it and just start the application you can just do the following:

```shell
git clone https://github.com/opf/openproject.git
cd openproject
cp .env.example .env
```

Optional: In case you want to develop on the OpenProject *BIM Edition* you need to set the
environmental variable accordingly in your `.env` file.

```shell
OPENPROJECT_EDITION=bim
```

Then continue the setup:

```shell
cp docker-compose.override.example.yml docker-compose.override.yml

# Required: create the `gateway` docker network. Services like hocuspocus
# join it; the optional TLS proxy (see "TLS support" below) and other
# external services such as Nextcloud or Keycloak join the same network
# when present. Safe to run multiple times.
docker network create gateway 2>/dev/null || true

docker compose run --rm backend setup
docker compose run --rm frontend npm install
docker compose up -d backend
```

Optional: In case you want to develop on the OpenProject *BIM Edition* you need
to install all the required dependencies and command line tools to convert IFC
files into XKT files, so that the BIM models can be viewed via the *Xeokit*
BIM viewer. As the conversions are done by background jobs you need install
those tools within the `worker` service:

```shell
docker compose up -d worker
docker compose exec -u root worker setup-bim
```

Please find below instructions on how to start and stop the workers.

Once the containers are done booting you can access the application under `http://localhost:3000`.

### Tests

You can run tests inside the `backend-test` container. You can run specific tests, too.

```shell
# Run all tests (not recommended)
bin/compose rspec

# Run the specified test
bin/compose rspec spec/features/work_package_show_spec.rb
```

***

More details and options follow in the next section.

> **Note**: docker compose needs access to at least 4GB of RAM. E.g. for Mac, this requires
> to [increase the default limit of the virtualized host](https://docs.docker.com/docker-for-mac/).
> Signs of lacking memory include an "Exit status 137" in the frontend container.

## Step-by-step Setup

### 1) Checkout the code

First you will need to check out the code as usual.

```shell
git clone https://github.com/opf/openproject.git
```

This will check out the dev branch in `openproject`. **Change into that directory.**

If you have OpenProject checked out already make sure that you do not have a `config/database.yml`
as that will interfere with the database connection inside the docker containers.

### 2) Configure environment

Copy the env example to `.env`

```shell
cp .env.example .env
```

Afterward, set the environment variables to your liking. `DEV_UID` and `DEV_GID` are required to be set so your project
directory will not end up with files owned by root.

`docker compose` will load the env from this file.

You also will want to create a `docker-compose.override.yml` file, which can contain the port exposure for your
containers. Those are excluded from the main compose file `docker-compose.yml` for sanity reasons. If any port is
already in use, `docker compose` won't start and will require explicit override in the `docker-compose.override.yml`
file (see instructions for [!reset](https://docs.docker.com/reference/compose-file/merge/#reset-value) and
[!override](https://docs.docker.com/reference/compose-file/merge/#replace-value)).

There is an example you can use out of the box.

```shell
cp docker-compose.override.example.yml docker-compose.override.yml
```

### 3) Create the shared `gateway` network

Services like `hocuspocus` (and, when added, external dev services such as
Nextcloud or Keycloak, plus the optional TLS proxy described under
[TLS support](#tls-support)) all join a shared docker network called
`gateway`. It's declared in `docker-compose.yml` as an externally-managed
network, so docker compose expects it to exist before any service starts.

Create it once:

```shell
docker network create gateway
```

`docker network create gateway 2>/dev/null || true` is the idempotent form if
you want to fold it into a setup script.

### 4) Setup database and install dependencies

```shell
# This will start the database as a dependency
# and then run the migrations and seeders,
# and will install all required server dependencies
docker compose run --rm backend setup

# This will install the web dependencies
docker compose run --rm frontend npm install
```

### 5) Start the stack

The docker compose file also has the test containers defined. The easiest way to start only the development stack, use

```shell
docker compose up backend
```

If you want to see the frontend logs, too.

```shell
docker compose up backend frontend
```

Alternatively, if you do want to detach from the process you can use the `-d` option.

```shell
docker compose up -d backend
```

The logs can still be accessed like this.

```shell
# Print the logs of the `frontend` service until the time you execute this command
docker compose logs frontend

# Print the logs of the `backend` service and follow the log outputs
docker compose logs -f backend
```

Those commands only start the frontend and backend containers and their dependencies. This excludes the workers, which
are needed to execute certain background actions. Nevertheless, for most interactions the worker jobs are not needed. If
needed, the workers can be started with the following command. Be aware that this process will consume a lot of the
system's resources.

```shell
# Start the worker service and let it run continuously
docker compose up -d worker
```

This process can take quite a long time on the first run where all gems are installed for the first time. However, these
are cached in a docker volume. Meaning that from the 2nd run onwards it will start a lot quicker.

Wait until you see `✔ Compiled successfully.` in the frontend logs and the success message from Puma in the backend
logs. This means both frontend and backend have come up successfully. You can now access OpenProject
under `http://localhost:3000`, and via the live-reloaded under `http://localhost:4200`.

Again the first request to the server can take some time too. But subsequent requests will be a lot faster.

Changes you make to the code will be picked up automatically. No need to restart the containers.

### Volumes

There are volumes for

* the attachments (`_opdata`)
* the database (`_pgdata`)
* the bundle (rubygems) (`_bundle`)
* the tmp directory (`_tmp`)
* the test database (`_pgdata-test`)
* the test tmp directory (`_tmp-test`)

This means these will stay between runs even if you stop (or remove) and restart the containers. If you want to reset
the data you can delete the docker volumes via `docker volume rm`.

## Running tests

Start all linked containers and migrate the test database first:

```shell
docker compose up -d backend-test
```

Afterward, you can start the tests in the running `backend-test` container:

```shell
docker compose exec backend-test bundle exec rspec
```

or for running a particular test

```shell
docker compose exec backend-test bundle exec rspec path/to/some_spec.rb
```

Tests are run within Selenium containers, on a small local Selenium grid. You can connect to the containers via VNC if
you want to see what the browsers are doing. `gvncviewer` or `vinagre` on Linux is a good tool for this. Set any port in
the `docker-compose.override.yml` to access a container of a specific browser. As a default, the `chrome` container is
exposed on port 5900. The password is `secret` for all.

Adding additional external docker networks to the test services like `backend-test` (e.g. inside the
`docker-compose.override.yml`) breaks the functionality of the Selenium service. This results in failing tests running
inside a Selenium context, like feature and UI tests.

```text
Selenium::WebDriver::Error::UnknownError:
  unknown error: net::ERR_CONNECTION_REFUSED
    (Session info: chrome=130.0.6723.91)
```

If this happens just comment out the network overrides.

## TLS support

Within `docker/dev/tls` compose files are provided, that elevate the development stack to be run under full TLS
encryption. This simulates much more accurately production environments, and it allows you to connect other services
into your development stack. This needs a couple of steps of more setup complexity, so you should only proceed, if you
really need or want it.

As an overview, you need to take the following, additional steps:

1. Set up a local certificate authority and reverse proxy
2. Extract created root certificate and install it into system and browsers
3. Amend docker containers with labels for reverse proxy

At the end you will be running two separate docker-compose stacks:

1. the normal stack in the root of the repository, and
2. the stack defined in `docker/dev/tls` that runs the CA and reverse proxy.

If the setup is successful, you will be able to access the local OpenProject application
under `https://openproject.local`. Of course, the host name is replaceable.

### Resolving host names

The current setup uses a simplified way to resolve host names. In order to do so, we redirect all host names, that
should be resolved by the proxy, to localhost. The `traefik` proxy is configured to listen to the localhost ports `80`
and `443` and redirect those requests to the specific container. To make it happen, you need to add every hostname you
define for your services to your `/etc/hosts`.

```shell
127.0.0.1   openproject.local openproject-assets.local traefik.local
::1         openproject.local openproject-assets.local traefik.local
```

### Local certificate authority

We use [traefik](https://traefik.io/) as a reverse proxy and [step-ca](https://smallstep.com/docs/step-ca/) as a local
certificate authority, so that you can enhance your development setup with TLS encryption without being forced to have
an active internet connection. A compose file exists that runs those two services.

```shell
# Create a file that serves as a certificate store
touch docker/dev/tls/acme.json
chmod 0600 docker/dev/tls/acme.json

# The `gateway` network is already created as part of the base setup
# (see "Step-by-step Setup → 3) Create the shared `gateway` network").
# If you skipped that step, create it now: `docker network create gateway`.

# Start certificate authority and reverse proxy
docker compose --project-directory docker/dev/tls up -d

# OPTIONAL: Change certificate duration to 1y - the values can be changed to any desired value
# restart stack afterwards
docker compose --project-directory docker/dev/tls exec step step ca provisioner \
  update acme --x509-min-dur=24h --x509-max-dur=8760h --x509-default-dur=8760h
docker compose --project-directory docker/dev/tls stop
docker compose --project-directory docker/dev/tls up -d
```

`step` will create the root CA, which is later stored in a persisted volume. You need to install this root CA on your
machine and your browsers, so that any issued certificate is considered trusted. This process however is very dependent
on your OS.

When requesting TLS certificates `step` will make TLS challenges. For this reason we need to amend the `traefik` service
and add aliases with the domain names of each service, that needs TLS-encrypted access. We prepared an example file
at `docker/dev/tls/docker-compose.override.example.yml`.

```shell
# Copy the override example
cp docker/dev/tls/docker-compose.override.example.yml docker/dev/tls/docker-compose.override.yml
```

### Install root CA

In this section you can find the ways, of how to make the just generated root CA available to your machine, the docker
container and your browser.

#### Browser

You need to import the created root certificate into the browser you use. Be aware, that the certificate you want to
import cannot be located in a directory only accessible by root users, as the browser won't be able to import from
there. Instead, you can copy the certificate from the docker container to any temporary location.

```shell
# Copy root certificate to any temporary location
docker compose --project-directory docker/dev/tls cp step:/home/step/certs/root_ca.crt $HOME/tmp/root_ca.crt
```

The installation of the certificate into the browser depends on the browser you are using, so you should check the docs
for that specific browser.

#### Debian/Ubuntu

On Debian, you need to add the generated root CA to system certificates bundle.

```shell
# Copy the .crt file into CA certificate location.
# You need `sudo` permission to execute this.
docker compose --project-directory docker/dev/tls cp \
 step:/home/step/certs/root_ca.crt /usr/local/share/ca-certificates/OpenProject_Development_Root_CA.crt

# Create symbolic link
ln -s /usr/local/share/ca-certificates/OpenProject_Development_Root_CA.crt /etc/ssl/certs/OpenProject_Development_Root_CA.pem

# Update certificate bundle
update-ca-certificates
```

After that the generated root CA should be inside `/etc/ssl/certs/ca-certificates.crt`.

#### Fedora

On Fedora, you need to add the root CA to the trusted system authorities.

```shell
# Copy root certificate to any temporary location
docker compose --project-directory docker/dev/tls cp step:/home/step/certs/root_ca.crt $HOME/tmp/root_ca.crt
sudo cp $HOME/tmp/root_ca.crt /etc/pki/ca-trust/source/anchors/OpenProject_Development_Root_CA.crt
sudo update-ca-trust
```

#### Arch

On ArchLinux, you need to install the root CA into the trusted system authorities.

```shell
# Copy root certificate to any temporary location
docker compose --project-directory docker/dev/tls cp step:/home/step/certs/root_ca.crt $HOME/tmp/root_ca.crt
sudo install -Dm644 $HOME/tmp/root_ca.crt /etc/ca-certificates/trust-source/anchors/OpenProject_Development_Root_CA.crt
sudo update-ca-trust
```

#### NixOS

On NixOS, you need to add the generated root CA to system certificates bundle. To do so, you need to persist the
certificate on your system.

```shell
# Copy the .crt file into a persisted location in your file system.
docker compose --project-directory docker/dev/tls cp step:/home/step/certs/root_ca.crt path_to_root_ca.crt
```

Add the following option to your NixOS configuration:

```text
security.pki.certificateFiles = [ path_to_root_ca.crt ];
```

Then rebuild your system. After that the generated root CA should be inside `/etc/ssl/certs/ca-certificates.crt`.

### Reverse proxy

After installing the root CA on your system, you need to start the reverse proxy, which now should be able to verify the
issued certificated requested from `step-ca`.

```shell
# Restart full proxy and ca stack
docker compose --project-directory docker/dev/tls down
docker compose --project-directory docker/dev/tls up -d
```

It will take a couple of seconds to start, as there is a health check in the step container.

### Amend Docker services for local TLS

When running the local setup with TLS, some services in `docker-compose.yml` require additional
configuration so that `traefik` knows which requests to route.

You need to specify, for each service, the `traefik` labels that define its HTTP router.
An example configuration is provided in `docker/dev/tls/docker-compose.core-override.example.yml`.
Copy its contents into your own `docker-compose.override.yml` in the repository root, and adjust hostnames if necessary.

Ensure that both the `backend` and `frontend` services:
- are attached to the same `networks` as `traefik`
- have the appropriate `traefik` labels

Example:

```yaml
frontend:
  networks:
    - external
  labels:
    - "traefik.enable=true"
  ...

backend:
  networks:
    - external
  labels:
    - "traefik.enable=true"
  ...
```
This ensures that traefik will route HTTPS requests for `openproject.local` and `openproject-assets.local` to the
correct containers in your local setup.

In addition, we need to alter the environmental variables used in the new overrides. So we need to amend the `.env` file
like that:

```shell
OPENPROJECT_DEV_HOST=openproject.local
OPENPROJECT_DEV_URL=https://${OPENPROJECT_DEV_HOST}
```

After amending the override file and the `.env`, ensure that you restart the stack.

```shell
docker compose up -d backend
```

### Adding a new service

Some development tasks require you to run separate services that interact with OpenProject. For example, you might want
to have Nextcloud running to test the Nextcloud-OpenProject integration. To do this, you'll need to follow some steps:

1. Add the Nextcloud service to your `docker-compose.override.yml`, with the appropriate traefik labels, network, and
   ca-bundle mounted.
2. Make sure step-ca can reach it to validate it for SSH. In `docker/dev/tls/docker-compose.override.yml`, add the host
   to the `aliases` section of the traefik networking.

### Alternative: Using Let's encrypt

An alternative approach is to issue certificates through Let's encrypt. This allows you to skip steps related to usage
and setup of a custom, non-trusted CA. However, it requires that you have access to a domain name that you control and
requires an additional step to make the reverse proxy publicly reachable, which is not in the scope of what this
documentation can cover.

If you need such a setup, you can change the `docker-compose.override.yml` for the reverse proxy, to use `letsencrypt`
(see the corresponding `docker-compose.override.example.yml`). Make sure to export an environment variable, or define
it in the `.env` files, with your alternative DNS zone before starting anything via docker compose. For example:

```bash
export OPENPROJECT_DOCKER_DEV_TLD=dev.example.com
docker compose up -d backend frontend
```

Will make your containers available under openproject.dev.example.com and openproject-assets.dev.example.com respectively.

### Troubleshooting

After this setup you should be able to access your OpenProject development instance at `https://openproject.local`. If
something went wrong, check if your problem is listed here.

#### Certificate invalid

At times, the issued certificate has a wrong start date. This is a known problem, that happens when the system clock is
synchronized after the certificate was issued from `traefik`. This usually can occur, if the docker process was
suspended and continued at a later time. To fix it, restart your proxy stack.

```shell
docker compose --project-directory docker/dev/tls down
docker compose --project-directory docker/dev/tls up -d
```

#### Blank page on `openproject.local`

A blank page on `openproject.local`  can indicate that compilation is either in progress or has failed. To investigate, check the frontend container output:
```shell
docker compose logs frontend`
```
Sometimes compilation errors can occur due to broken node_modules state(for example after switching branches or partial installations). It can be resolved by removing node_modules and installing from scratch:
```shell
rm -rf frontend/node_modules/
docker compose run --rm frontend npm install
```

Then restart both the frontend service:
```shell
docker compose restart frontend
```

If the issue persists, clear your browser cache and reload the page.
Cached assets from a previous build may prevent the updated frontend from loading correctly.

## GitLab CE Service

Within `docker/dev/gitlab` a compose file is provided for running local Gitlab instance with TLS support. This provides
a production like environment for testing the OpenProject GitLab integration against a community edition GitLab instance
accessible on `https://gitlab.local`.

> NOTE: Configure [TLS Support](#tls-support) first before starting the GitLab service

See [Install GitLab using Docker Compose](https://docs.gitlab.com/ee/install/docker.html#install-gitlab-using-docker-compose)
official GitLab documentation.

### Running the GitLab Instance

Start up the docker compose service for gitlab as follows:

```shell
docker compose --project-directory docker/dev/gitlab up -d
```

### Initial password

Once the GitLab service is started and running, you can access the initial `root` user password as follows:

```shell
docker compose --project-directory docker/dev/gitlab exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password
```

Should you need to reset your root password, execute the following command:

```shell
docker compose --project-directory docker/dev/gitlab exec -it gitlab gitlab-rake "gitlab:password:reset[root]"
```

## Keycloak Service

> NOTE: OpenID connect is an enterprise feature in OpenProject. So, to be able to use this feature for development setup, we need to have an `Enterprise Edition Token` which is restricted to the domain `openproject.local`

Within `docker/dev/keycloak` a compose file is provided for running local keycloak instance with TLS support. This provides
a production like environment for testing the OpenProject Keycloak integration against a keycloak instance accessible on `https://keycloak.local`.

> NOTE: Configure [TLS Support](#tls-support) first before starting the Keycloak service

### Running the Keycloak Instance

Start up the docker compose service for Keycloak as follows:

```shell
docker compose --project-directory docker/dev/keycloak up -d
```

Once the keycloak service is started and running, you can access the keycloak instance on `https://keycloak.local`
and login with initial username and password as `admin`.

Keycloak being an OpenID connect provider, we need to setup an OIDC integration for OpenProject.
[Setup OIDC (keycloak) integration for OpenProject](../../../system-admin-guide/authentication/openid-providers/)

Once the above setup is completed, In the root `docker-compose.override.yml` file, uncomment all the environment in `backend` service for keycloak and set the values according to configuration done in keycloak for OpenProject Integration.

```shell
# Stop all the service if already running
docker compose down

# or else simply start frontend service
docker compose up -d frontend
```

Upon setting up all the things correctly, we can see a login with `keycloak` option in login page of `OpenProject`.


## MinIO Service (local S3 storage backend)

Within `docker/dev/minio` a compose file is provided for running a local MinIO instance with TLS support which can be used as a S3 storage for uploading files.
When running with TLS support, the MinIO instance will be accessible on `https://minio.local` and a management UI (MinIO Console) will be available on `https://minioadmin.local/`.

### Running the MinIO Instance

MinIO is a S3 compatible data store which can be used for simulating uploads of files to S3.

Start up the docker compose service for MinIO:

```shell
docker compose --project-directory docker/dev/minio up -d
```
This will automatically create a bucket named `openproject-uploads` which is used to store uploaded files.

If you want to use TLS support, make sure to copy and uncomment the MinIO configuration environment variables in `docker/dev/tls/docker-compose.core.override.example.yml` to your `docker-compose.override.yml` file in the project root directory. If you want to use MinIO without TLS support, make sure to copy the environment variables from `docker/dev/minio/docker-compose.core-override.example.yml` to your `docker-compose.override.yml` file (in the project root directory).
After that, hard restart the `backend` service to apply the changes:

```
docker compose down backend
docker compose up backend
```

Another option is to use the MinIO service running in docker with OpenProject running locally. To do this, adapt the environment variables in `docker/dev/minio/docker-compose.core.override.example.yml` to your `.env` file and restart the OpenProject after that.

After uploading a file, by e.g. adding an image to a work package, you should be able to see the file in the MinIO Console (a graphical Management UI accessible in the browser). With the TLS setup you can access the MinIO Console on `https://minioadmin.local/`, without TLS it is available on `http://localhost:9001`. For login credentials see `docker/dev/minio/docker-compose.yml`.

## Local files

Running the docker images will change some of your local files in the mounted code directory. The
file `frontend/package-lock.json` may be modified. You can just reset these changes if you want to commit something or
pull the latest changes.

## Debugging

It's common to just start a debugger within ruby code using `binding.pry`. This works as expected with the application
running as shown above.

However, keep in mind that you won't see the pry console unless you attach to the container of the `backend` service.
The easiest way to do that is getting the container name from the docker compose list and attaching to it with the
standard docker command.

```shell
# Check all running services and their containers.
# As a default the `backend` container has the name `openproject-backend-1`
docker compose ps

# Attach to the container
docker attach openproject-backend-1
```

Inside the `backend` container you have a standard rails console. If you attached to the container **after** you run
into your breakpoint, you won't see the common lines pry will print before your prompt.

To detach from the `backend` container without stopping it, you can use `CTRL+P, CTRL+Q`. Using `CTRL+C` works, too, but
it will close and restart the backend container.

## Updates

When a dependency of the image or the base image itself is changed you may need rebuild the image. For instance when the
Ruby version is updated you may run into an error like the following when
running `docker compose run --rm backend setup`:

```text
Your Ruby version is 2.7.6, but your Gemfile specified ~> 3.2.3
```

This means that the current image is out-dated. You can update it like this:

```shell
docker compose build --pull
```

## Migrating Your Local Database Between Docker Versions

When upgrading your local development stack (e.g., after pulling the latest dev branch or updating Docker images),
you may want to preserve your PostgreSQL data. This guide outlines the correct steps to safely migrate your data.

### Context

The database volume may be recreated or become incompatible if you:
- rebuild Docker images,
- upgrade PostgreSQL,
- change volume mounts.

To avoid data loss, dump your database before tearing anything down.

### Step-by-step

1. Start your current environment with the existing database and backend images.
Make sure the database service is running normally.
2. Create a database dump using a PostgreSQL-compatible tool such as `pg_dump` or `pg_dumpall`.
This ensures you have a consistent export of your data before making any destructive changes.
3. Copy the resulting dump file from inside the database container to your local machine,
so it remains accessible after removing the Docker volumes.

```shell
# Copying backup to the local machine:
docker compose exec -T <db-container-name> pg_dump -U <db-user> <db-name> > openproject_backup.sql

#or

docker compose exec -T <db-container-name> pg_dumpall -U <db-user> > openproject_full_backup.sql
```
4. Shut down the Docker stack. If you want a clean reset, make sure to remove the database volume.
5. Update the codebase by pulling the latest changes from the dev branch.
You may also want to update Docker base images at this stage.
6. Rebuild the backend image to ensure it’s aligned with the current code and dependency versions.
7. Start only the database service, allowing it to initialize with a clean or migrated volume, depending on your setup.
8. Copy your previously saved database dump back into the container and restore it into the PostgreSQL instance
or load the dump from local machine. This will rehydrate the new database with your old data.
```shell
# Copying backup from the local machine:
docker compose cp openproject_backup.sql <db-container-name>:/tmp/openproject_backup.sql

# Load dump to the DB
docker compose exec -T <db-container-name> psql -U <db-user> <db-name> -f /tmp/openproject_backup.sql
```
9. Start the remaining services (backend, frontend, etc.) using the standard setup process. The stack should now function as expected, with your previous data restored and the environment updated.


