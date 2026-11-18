# OpenProject Dev Container

A [Dev Container](https://containers.dev/) for developing OpenProject in VS Code or GitHub Codespaces.

## What it contains

| Service     | Source                                                                     |
|-------------|----------------------------------------------------------------------------|
| `workspace` | `docker/dev/backend/Dockerfile` (target `develop`): Ruby from `.ruby-version`, PostgreSQL 17 client, Java (LDAP specs) |
| `db`        | `pgvector/pgvector:pg17-trixie`, same image as `db` in `docker-compose.yml` |
| `cache`     | `memcached`, same image as `cache` in `docker-compose.yml`                 |

The local feature in `nodejs/` pins the NodeSource `nodejs` package that the Dockerfile installs to the exact
version 24.22.1 (bundled npm 11.19.1), matching `docker/dev/frontend/Dockerfile`. On creation,
`post-create.sh` installs the Bundler version from `Gemfile.lock`, runs `bin/setup_dev` and seeds the
development database.

## Start

- **VS Code:** install the Dev Containers extension, open the repository and run
  **Dev Containers: Reopen in Container**.
- **Codespaces:** `gh codespace create --repo <owner>/openproject --devcontainer-path .devcontainer/devcontainer.json`
- **CLI:** `npx @devcontainers/cli up --workspace-folder .`

## Run OpenProject

`bin/dev` starts the processes from `Procfile.dev` and needs `overmind` or `foreman`, which are not installed
in the container (for example `gem install foreman`). `PORT=3000` is set in the container so that foreman starts
Rails on port 3000. Alternatively, start each process in its own terminal as described in
[Install and run OpenProject from source](../docs/development/development-environment/common-setup/README.md#run-openproject-manually).

To start the frontend, run the following command from the project root:

```shell
npm run serve -- -- --host 127.0.0.1
```

Open `http://localhost:3000` and log in with `admin` / `admin`.

## Tests

`DATABASE_URL` in the workspace points at the development database. Run specs from the host in the
`backend-test` container as described in the [Docker development setup](../docs/development/development-environment/docker/README.md#running-tests):

```shell
bin/compose rspec path/to/some_spec.rb
```

Do not create `config/database.yml`: `bin/compose` refuses to run while it exists.
