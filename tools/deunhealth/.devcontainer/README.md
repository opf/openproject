# Development container

Development container that can be used with VSCode.

It works on Linux, Windows and OSX.

## Requirements

- [VS code](https://code.visualstudio.com/download) installed
- [VS code dev containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) installed
- [Docker](https://www.docker.com/products/docker-desktop) installed and running
- [Docker Compose](https://docs.docker.com/compose/install/) installed

## Setup

1. Create the following files and directory on your host if you don't have them:

    ```sh
    touch ~/.gitconfig ~/.zsh_history
    mkdir -p ~/.ssh
    ```

1. **For Docker on OSX**: ensure the project directory and your home directory `~` are accessible by Docker.
1. Open the command palette in Visual Studio Code (CTRL+SHIFT+P).
1. Select `Dev Containers: Open Folder in Container...` and choose the project directory.

## Customizations

For customizations to take effect, you should "rebuild and reopen":

1. Open the command palette in Visual Studio Code (CTRL+SHIFT+P)
2. Select `Dev Containers: Rebuild Container`

Customizations available are notably:

- Extend the Docker image in [Dockerfile](Dockerfile). For example add curl to it:

    ```Dockerfile
    FROM qmcgaw/godevcontainer
    RUN apk add curl
    ```

- Changes to VSCode **settings** and **extensions** in [devcontainer.json](devcontainer.json).
- Change the entrypoint script by adding a bind mount in [devcontainer.json](devcontainer.json) of a shell script to `/root/.welcome.sh` to replace the [current welcome script](https://github.com/qdm12/godevcontainer/blob/master/shell/.welcome.sh). For example:

    ```json
    // Welcome script
    {
        "source": "./.welcome.sh",
        "target": "/root/.welcome.sh",
        "type": "bind"
    },
    ```

- Change the `vscode` service container configuration either in [docker-compose.yml](docker-compose.yml) or in [devcontainer.json](devcontainer.json).
- Add other services in [docker-compose.yml](docker-compose.yml) to run together with the development VSCode service container. For example to add a test database:

    ```yml
      database:
        image: postgres
        restart: always
        environment:
          POSTGRES_PASSWORD: password
    ```

- More customizations available are documented in the [devcontainer.json reference](https://containers.dev/implementors/json_reference/).
