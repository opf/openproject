# OpenProject Docker images

OpenProject publishes docker images in two varieties:

- `dev-slim, MAJOR-slim, MAJOR.MINOR-slim, MAJOR.MINOR.PATCH-slim` for the application container to be used with an external database, proxy. For use in [Docker compose](https://www.openproject.org/docs/installation-and-operations/installation/docker-compose/), [Kubernetes and Helm charts](https://www.openproject.org/docs/installation-and-operations/installation/helm-chart/) installations
- `dev, MAJOR, MAJOR.MINOR, MAJOR.MINOR.PATCH` for the [all-in-one container](https://www.openproject.org/docs/installation-and-operations/installation/docker/). This is meant as a quick start to get OpenProject up-and-running. We recommend to use the slim container for production systems.



## Docker Hub

All images are being published on Docker Hub. For more information on the available versions, please see https://hub.docker.com/r/openproject/openproject/tags.



## Installation guides

Please see our upstream documentation guides for installing OpenProject using Docker containers:

- [**Installation with Docker Compose (recommended)**](https://www.openproject.org/docs/installation-and-operations/installation/docker-compose/): Guide for setting up OpenProject in an isolated manner using Docker Compose
- [**Installation with single Docker container**](https://www.openproject.org/docs/installation-and-operations/installation/docker/): How to setup OpenProject as a single Docker container
- [**Installation with Helm charts (recommended for Kubernetes)**](https://www.openproject.org/docs/installation-and-operations/installation/helm-chart): Set up OpenProject using Helm charts

OpenProject also provides other means of installation. Please see https://www.openproject.org/docs/installation-and-operations/installation/ for the full reference.



## User guides

For all information related to using OpenProject, please see our user documentation at https://www.openproject.org/docs/
