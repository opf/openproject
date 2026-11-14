# OpenProject devcontainers

Hi there! These are the development containers for OpenProject. You can use them from your IDE (RubyMine, VSCode) or
if you don't have one, check out [DevPod](https://devpod.sh).

For VS Code on macOS, you'll need the [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) extension. If starting the dev container fails right away, you may have run into a known permission clash between `docker buildx` and the current Dev Containers extension: it generates files in system temp, which the Docker tooling then promptly fails to process because they are outside the build context. Until that's fixed upstream, temporarily disable file systems entitlements by starting VS Code like so: `BUILDX_BAKE_ENTITLEMENTS_FS=0 code .`

We have the following environments for your convenience:

## Minimal (`/.devcontainer/devcontainer.json`)

This setup pulls up an OpenProject with a PostgreSQL backend. The setup starts the backend and the frontend as separate
processes in a `screen` each, which you can reconnect using `screen -x frontend|backend`.
