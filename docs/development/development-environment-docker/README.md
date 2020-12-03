# OpenProject development setup via docker

The quickest way to get started developing OpenProject is to use the docker setup.

## Requirements

* docker

And nothhing else!

## Quickstart

To get right into it and just start the application you can just do the following:

```
git clone https://github.com/opf/openproject.git
cd openproject
bin/compose setup
bin/compose start
```

Once the containers are done booting you can access the application under http://localhost:3000.

If there is an `.env` file (see below) `bin/compose` will source it.
More details and options follow in the next section.

## Setup

### 1) Checkout the code

First you will need to checkout the code as usual.

```
git clone https://github.com/opf/openproject.git
```

This will checkout the dev branch in `openproject`. **Change into that directory.**

If you have OpenProject checked out already make sure that you do not have a `config/database.yml`
as that will interfere with the database connection inside of the docker containers.

### 2) Configure environment

Copy the env example to `.env`

```
cp .env.example .env
```

Afterwards, set the environment variables to your liking. `DEV_UID` and `DEV_GID` are required to be set so your project
directory will not end up with files owned by root.

### 3) Setup database and install dependencies

```
# Start the database. It needs to be running to run migrations and seeders
docker-compose up -d db

# Install frontend dependencies
docker-compose run frontend npm i

# Install backend dependencies, migrate, and seed
docker-compose run backend setup
```

### 4) Start the stack

The docker compose file also has the test containers defined. The easiest way to start only the development stack, use

```
docker-compose up frontend
```

To see the backend logs as well, use

```
docker-compose up frontend backend
```

This starts only the frontend and backend containers and their dependencies. This excludes the testing containers, which
are harmless to start as well, but take up system resources and clog your logs while running.

This process can take quite a long time on the first run where all gems are installed for the first time.
However, these are cached in a docker volume. Meaning that from the 2nd run onwards it will start a lot quicker.

Wait until you see `frontend_1  | : Compiled successfully.` and `backend_1   | => Rails 6.0.2.2 application starting in development http://0.0.0.0:3000` in the logs.
This means both frontend and backend have come up successfully.
You can now access OpenProject under http://localhost:3000, and via the live-reloaded under http://localhost:4200.

Again the first request to the server can take some time too.
But subsequent requests will be a lot faster.

Changes you make to the code will be picked up automatically.
No need to restart the containers.

## Docker

You can stop the processes via Ctrl + C. You can also run everything in the background by adding the `-d` option as in `bin/compose up -d`. In that case you'll still be able to see the logs using `docker logs` with the respective container name.
You can see the started containers using `docker ps`.

### Volumes

There are volumes for

  * the attachments (`_opdata`)
  * the database (`_pgdata`)
  * the bundle (rubygems) (`_bundle`)
  * the tmp directory (`_tmp`)
  * the test database (`_pgdata-test`)
  * the test tmp directory (`_tmp-test`)

This means these will stay between runs even if you stop and restart the containers.
If you want to reset the data you can delete the docker volumes via `docker volume rm`.

## Running tests 

Start all linked containers and migrate the test database first:

```
docker-compose up backend-test 
```

Afterwards, you can start the tests in the running `backend-test` container:

```
docker-compose run backend-test bundle exec rspec
```

Tests are ran within Selenium containers, on a small local Selenium grid. You can connect to the containers via VNC if
you want to see what the browsers are doing. `gvncviewer` on Linux is a good tool for this. Check out the docker-compose
file to see which port each browser container is exposed on. The password is `secret` for all.

## Local files

Running the docker images will change some of your local files in the mounted code directory.
The file `frontend/npm-shrinkwrap.json` may be modified.
You can just reset these changes if you want to commit something or pull the latest changes.

## Debugging

It's common to just start a debugger whithin ruby code using `binding.pry`.
This **does not work** with the application running as shown above.

If you want to be able to do that, you can, however, simply run the following:

```
bin/compose run
```

If the frontend container is not running yet, it will be started.
If the backend container is already running, it will be stopped.
Instead it will be started in the foreground.
This way you can debug using pry just as if you had started the server locally using `rails s`.
You can stop it simply with Ctrl + C too.
