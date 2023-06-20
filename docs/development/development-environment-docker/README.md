# OpenProject development setup via docker

The quickest way to get started developing OpenProject is to use the docker setup.

## Requirements

* docker

And nothing else!

## Quickstart

To get right into it and just start the application you can just do the following:

```bash
git clone https://github.com/opf/openproject.git
cd openproject
cp .env.example .env
cp docker-compose.override.example.yml docker-compose.override.yml
docker compose run --rm backend setup
docker compose run --rm frontend npm install
docker compose up -d frontend
```

Once the containers are done booting you can access the application under `http://localhost:3000`.

### Tests

You can run tests inside the `backend-test` container. You can run specific tests, too.

```bash
# Run all tests (not recommended)
docker compose run --rm backend-test bundle exec rspec

# Run the specified test
docker compose run --rm backend-test bundle exec rspec spec/features/work_package_show_spec.rb
```

***

More details and options follow in the next section.


> **Note**: docker compose needs access to at least 4GB of RAM. E.g. for Mac, this requires
> to [increase the default limit of the virtualized host](https://docs.docker.com/docker-for-mac/).
> Signs of lacking memory include an "Exit status 137" in the frontend container.

## Step-by-step Setup

### 1) Checkout the code

First you will need to check out the code as usual.

```bash
git clone https://github.com/opf/openproject.git
```

This will check out the dev branch in `openproject`. **Change into that directory.**

If you have OpenProject checked out already make sure that you do not have a `config/database.yml`
as that will interfere with the database connection inside the docker containers.

### 2) Configure environment

Copy the env example to `.env`

```bash
cp .env.example .env
```

Afterward, set the environment variables to your liking. `DEV_UID` and `DEV_GID` are required to be set so your project
directory will not end up with files owned by root.

`docker compose` will load the env from this file.

You also will want to create a `docker-compose.override.yml` file, which can contain the port exposure for your
containers. Those are excluded from the main compose file `docker-compose.yml` for sanity reasons. If any port is
already in use, `docker compose` won't start and as you cannot disable the exposed port in
the `docker-compose.override.yml` file, you would have to alter the original `docker-compose.yml`.

There is an example you can use out of the box.

```bash
cp docker-compose.override.example.yml docker-compose.override.yml
```

### 3) Setup database and install dependencies

```bash
# This will start the database as a dependency
# and then run the migrations and seeders,
# and will install all required server dependencies
docker compose run --rm backend setup

# This will install the web dependencies 
docker compose run --rm frontend npm install
```

### 4) Start the stack

The docker compose file also has the test containers defined. The easiest way to start only the development stack, use

```bash
docker compose up frontend
```

If you want to see the backend logs, too.

```bash
docker compose up frontend backend
```

Alternatively, if you do want to detach from the process you can use the `-d` option.

```bash
docker compose up -d frontend
```

The logs can still be accessed like this.

```bash
# Print the logs of the `frontend` service until the time you execute this command
docker compose logs frontend

# Print the logs of the `backend` service and follow the log outputs
docker compose logs -f backend
```

Those commands only start the frontend and backend containers and their dependencies. This excludes the workers, which
are needed to execute certain background actions. Nevertheless, for most interactions the worker jobs are not needed. If
needed, the workers can be started with the following command. Be aware that this process will consume a lot of the
system's resources.

```bash
# Start the worker service and let it run continuously
docker compose up -d worker

# Start the worker service to work off all delayed jobs and shut it down afterwards
docker compose run --rm worker rake jobs:workoff
```

The testing containers are excluded as well, while they are harmless to start, but take up system resources again and
clog your logs while running. The delayed_job background worker reloads the application for every job in development
mode. This is a know issue and documented here: https://github.com/collectiveidea/delayed_job/issues/823

This process can take quite a long time on the first run where all gems are installed for the first time. However, these
are cached in a docker volume. Meaning that from the 2nd run onwards it will start a lot quicker.

Wait until you see `✔ Compiled successfully.` in the frontend logs and the success message from Puma in the backend
logs. This means both frontend and backend have come up successfully. You can now access OpenProject
under http://localhost:3000, and via the live-reloaded under http://localhost:4200.

Again the first request to the server can take some time too. But subsequent requests will be a lot faster.

Changes you make to the code will be picked up automatically. No need to restart the containers.

### Storybook

There is a service to launch the storybook of the SPOT design system in the local development environment. To run it,
simply use:

```bash
# Start the worker and let them run continuously
docker compose up -d storybook
```

If you used the default overrides you will access the storybook now under `http://localhost:6006`.

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

```bash
docker compose up -d backend-test
```

Afterward, you can start the tests in the running `backend-test` container:

```bash
docker compose exec backend-test bundle exec rspec
```

or for running a particular test

```bash
docker compose exec backend-test bundle exec rspec path/to/some_spec.rb
```

Tests are ran within Selenium containers, on a small local Selenium grid. You can connect to the containers via VNC if
you want to see what the browsers are doing. `gvncviewer` or `vinagre` on Linux is a good tool for this. Set any port in
the `docker-compose.override.yml` to access a container of a specific browser. As a default, the `chrome` container is
exposed on port 5900. The password is `secret` for all.

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

```bash
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

```
Your Ruby version is 2.7.6, but your Gemfile specified ~> 3.2.1
```

This means that the current image is out-dated. You can update it like this:

```bash
docker compose build --pull
```
