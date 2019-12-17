---
sidebar_navigation:
  title: System requirements
  priority: 1000
---

# System requirements

__Note__: The configurations described below are what we use and test against.
This means that other configurations might also work but we do not
provide any official support for them.

## Server

### Hardware

* __Memory:__ 4096 MB
* __Free disk space:__ 2 GB

### Operating system

The [package-based installation](../installation/packaged) requires one of the following Linux distributions:

| Distribution (**64 bits only**) |
| ------------------------------- |
| CentOS/RHEL 7.x                 |
| Debian 9 Stretch                |
| Debian 10 Stretch               |
| Suse Linux Enterprise Server 12 |
| Ubuntu 16.04 Xenial Xerus       |
| Ubuntu 18.04 Bionic Beaver      |

The [docker-based installation](../installation/docker) requires a system with Docker installed. Please see the [official Docker page](https://docs.docker.com/install/) for the list of supported systems.

### Overview of dependencies

Both the package and docker based installations will install and setup the following dependencies that are required by OpenProject to run:

* __Runtime:__ [Ruby](https://www.ruby-lang.org/en/) Version = 2.6.x
* __Webserver:__ [Apache](http://httpd.apache.org/)
  or [nginx](http://nginx.org/en/docs/)
* __Application server:__ [Puma](https://puma.io/)
* __Database__: [PostgreSQL](http://www.postgresql.org/) Version >= 9.5

## Client

OpenProject supports the latest versions of the major browsers. In our
strive to make OpenProject easy and fun to use we had to drop support
for some older browsers (e.g. IE 11).

* [Mozilla Firefox](https://www.mozilla.org/en-US/firefox/products/) (At least ESR version 60)
* [Microsoft Edge](https://www.microsoft.com/de-de/windows/microsoft-edge)
* [Google Chrome](https://www.google.com/chrome/browser/desktop/)
* [Apple Safari](https://www.apple.com/safari/)
