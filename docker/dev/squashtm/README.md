# Setup guide

A minimal setup guide for using a local SquashTM inside a docker stack. The example compose file is connected to the standard setup of the [TLS-ready](https://www.openproject.org/docs/development/development-environment/docker/#tls-support) stack with `traefik`.

## First steps

- Up the docker stack with `docker compose up -d`
- Wait for initialization to finish (this takes some time, wait for `docker compose logs -f web` to calm down)
- Go to https://squashtm.local/squash (mind the `/squash` at the end)
- Have fun!
