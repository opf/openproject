# OpenProject devcontainers

Hi there! These are the development containers for OpenProject. You can use them from your IDE (RubyMine, VSCode) or
if you don't have one, check out [DevPod](https://devpod.sh).

We have the following environments for your convenience:

## Minimal (`/.devcontainer/devcontainer.json`)

This setup pulls up an OpenProject with a PostgreSQL backend. The setup starts the backend and the frontend as separate
processes in a `screen` each, which you can reconnect using `screen -x frontend|backend`.
