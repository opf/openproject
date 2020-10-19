# OpenProject development setup via docker

The quickest way to get started developing OpenProject is to use the docker setup.

## Setup

### 1) Checkout the code

First you will need to checkout the code as usual.

```
git clone https://github.com/opf/openproject.git
```

This will checkout the dev branch in `openproject`. **Change into that directory.**

If you have OpenProject checked out already make sure that you do not have a `config/database.yml`
as that will interfere with the database connection inside of the docker containers.

### 3) Configure environment

Copy the env example to `.env`

```
cp .env.example .env
```

Afterwards, set the environment variables to your liking. `DEV_UID` and `DEV_GID` are required to be set so your project
directory will not end up with files owned by root.

### 2) Setup database and install dependencies

```
# Start the database. It needs to be running to run migrations and seeders
docker-compose up -d db

# Install frontend dependencies
docker-compose run frontend npm i

# Install backend dependencies, migrate, and seed
docker-compose run backend setup
```

### 3) Start the stack

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

Not all tests are functional within the docker containers yet, so it is recommended to run tests outside of Docker.
However, you can run tests by executing

```
export OPENPROJECT_HOME=`pwd`

./bin/compose up -d
./bin/compose exec backend-test bundle exec rspec
```

## Local files

Running the docker images will change some of your local files in the mounted code directory.
The file `frontend/npm-shrinkwrap.json` may be modified.
You can just reset these changes if you want to commit something or pull the latest changes.
