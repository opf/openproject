# DeUnhealth

Restart your unhealthy containers safely

[![Build status](https://github.com/qdm12/deunhealth/actions/workflows/ci.yml/badge.svg)](https://github.com/qdm12/deunhealth/actions/workflows/ci.yml)

[![dockeri.co](https://dockeri.co/image/qmcgaw/deunhealth)](https://hub.docker.com/r/qmcgaw/deunhealth)

![Last release](https://img.shields.io/github/release/qdm12/deunhealth?label=Last%20release)
![Last Docker tag](https://img.shields.io/docker/v/qmcgaw/deunhealth?sort=semver&label=Last%20Docker%20tag)
[![Last release size](https://img.shields.io/docker/image-size/qmcgaw/deunhealth?sort=semver&label=Last%20released%20image)](https://hub.docker.com/r/qmcgaw/deunhealth/tags?page=1&ordering=last_updated)
![GitHub last release date](https://img.shields.io/github/release-date/qdm12/deunhealth?label=Last%20release%20date)
![Commits since release](https://img.shields.io/github/commits-since/qdm12/deunhealth/latest?sort=semver)

[![Latest size](https://img.shields.io/docker/image-size/qmcgaw/deunhealth/latest?label=Latest%20image)](https://hub.docker.com/r/qmcgaw/deunhealth/tags)

[![GitHub last commit](https://img.shields.io/github/last-commit/qdm12/deunhealth.svg)](https://github.com/qdm12/deunhealth/commits/main)
[![GitHub commit activity](https://img.shields.io/github/commit-activity/y/qdm12/deunhealth.svg)](https://github.com/qdm12/deunhealth/graphs/contributors)
[![GitHub closed PRs](https://img.shields.io/github/issues-pr-closed/qdm12/deunhealth.svg)](https://github.com/qdm12/deunhealth/pulls?q=is%3Apr+is%3Aclosed)
[![GitHub issues](https://img.shields.io/github/issues/qdm12/deunhealth.svg)](https://github.com/qdm12/deunhealth/issues)
[![GitHub closed issues](https://img.shields.io/github/issues-closed/qdm12/deunhealth.svg)](https://github.com/qdm12/deunhealth/issues?q=is%3Aissue+is%3Aclosed)

[![Lines of code](https://img.shields.io/tokei/lines/github/qdm12/deunhealth)](https://github.com/qdm12/deunhealth)
![Code size](https://img.shields.io/github/languages/code-size/qdm12/deunhealth)
![GitHub repo size](https://img.shields.io/github/repo-size/qdm12/deunhealth)
![Go version](https://img.shields.io/github/go-mod/go-version/qdm12/deunhealth)

[![MIT](https://img.shields.io/github/license/qdm12/deunhealth)](https://github.com/qdm12/deunhealth/master/LICENSE)
![Visitors count](https://visitor-badge.laobi.icu/badge?page_id=deunhealth.readme)

## Features

- Restart unhealthy containers marked with `deunhealth.restart.on.unhealthy=true` label
- Receive Docker events as stream instead of polling periodically
- Doesn't need network for security purposes
- Compatible with `amd64`, `386`, `arm64`, `arm32v7`, `arm32v6`, `ppc64le`, `s390x` and `riscv64` CPU architectures
- [Docker image tags and sizes](https://hub.docker.com/r/qmcgaw/deunhealth/tags)

## Setup

1. Use the following command:

    ```sh
    docker run -d --network none -v /var/run/docker.sock:/var/run/docker.sock qmcgaw/deunhealth
    ```

    You can also use [docker-compose.yml](https://github.com/qdm12/deunhealth/blob/main/docker-compose.yml) with:

    ```sh
    docker-compose up -d
    ```

1. Set labels on containers:
    - To restart containers if they go unhealthy, use the label `deunhealth.restart.on.unhealthy=true`

1. You can update the image with `docker pull qmcgaw/deunhealth:latest` or use one of the [tags available](https://hub.docker.com/r/qmcgaw/deunhealth/tags). ⚠️ You might want to use tagged images since `latest` will likely break compatibility until we reach a `v1.0.0` release.

### Options

| Environment variable | Flag | Default | Possible values | Description |
| --- | --- | --- | --- | --- |
| `DOCKER_HOST` | `--docker-host` | Default Docker socket location | Docker host value | Docker host value such as `unix:///var/run/docker.sock` or `tcp://socket-proxy:2375` |
| `LOG_LEVEL` | `--log-level` | `info` | `debug`, `info`, `warning`, `error` | Logging level |
| `HEALTH_SERVER_ADDRESS` | `--health-server-address` | `127.0.0.1:9999` | Valid address | Internal health http server listening address. Nothing to do with restarting unhealthy containers. |
| `TZ` | N/A | `America/Montreal` | *string* | Timezone |

## Safety

- The application doesn't need network to reduce the attack surface
- Since Docker is written in Go, the program is also written in Go and uses the [official Docker Go API](https://github.com/moby/moby)
- The Docker container is based on [scratch](https://hub.docker.com/_/scratch) to reduce the attack surface and only contains the static binary
- The container has to run as root unfortunately 😢

## Development

### VSCode and Docker

Please refer to the corresponding [readme](.devcontainer).

### Locally

1. Install [Go](https://golang.org/dl/), [Docker](https://www.docker.com/products/docker-desktop) and [Git](https://git-scm.com/downloads)
1. Install Go dependencies with

    ```sh
    go mod download
    ```

1. Install [golangci-lint](https://github.com/golangci/golangci-lint#install)
1. You might want to use an editor such as [Visual Studio Code](https://code.visualstudio.com/download) with the [Go extension](https://code.visualstudio.com/docs/languages/go).

### Commands available

```sh
# Build the binary
go build cmd/app/main.go
# Test the code
go test ./...
# Lint the code
golangci-lint run
# Build the Docker image
docker build -t qmcgaw/deunhealth .
```

See [Contributing](https://github.com/qdm12/deunhealth/main/.github/CONTRIBUTING.md) for more information on how to contribute to this repository.

## TODOs

1. Trigger mechanism such that a container restart triggers other restarts
2. Inject pre-build binary doing a DNS lookup to containers labeled for it and that do not have a healthcheck built in (useful for scratch based images without healthcheck especially)
3. Integration tests in Go instead of shell script
