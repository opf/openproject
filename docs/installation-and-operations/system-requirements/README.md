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

The server hardware requirements should be rougly the same for both the packaged installation and docker (both all-in-one container and compose).

### Minimum Hardware Requirements

* __CPU:__ Quad Core CPU (>= 2ghz)
* __Memory:__ 4096 MB
* __Free disk space:__ 20 GB

This is for a single server running OpenProject for up to 200 total users. Depending on your number of concurrent users,  these requirements might vary drastically.

### General Requirements

Generally speaking you will need more CPUs (the faster the better) and more RAM with an increasing number of users.
Technically this only really depends on the number of concurrent users. No matter if you have 1000 or only 100 total users, if there only ever 20 users working at the same time, the CPU & RAM required will be the same.
Still, the total number of users is a good general indicator of how much resources you will need.

It's not enough to simply have more resources available, however. You will have to make use of them too.
By default OpenProject has 4 so called web workers and 1 background worker. Web workers are handling the HTTP requests while backend workers are doing offloaded tasks such as sending emails or performing resource-intensive tasks of unknown duration, e.g., copying or deleting resources.
If there are more users you will need more web workers and eventually also more background workers.

The database will need resources as well, and this, too, will increase with the number of users.
There may come a point where you will have to make configuration changes to the database and/or use an external database, but for most cases the default database setup should be enough. You will ideally want to have the database on a performant storage such as SSDs. [There are also other excellent resources](https://wiki.postgresql.org/wiki/Performance_Optimization) for tuning PostgreSQL database performance.

Using a rough estimate we can give the following recommendations based on the number of users.

| Users | CPU cores | RAM in GB  | web workers | background workers | Diskspace in GB |
|-------|-----------|------------|-------------|--------------------|-----------------|
| 200   | 4         | 4          | 4           | 1                  | 20              |
| 500   | 8         | 8          | 8           | 2                  | 40              |
| 1500  | 16        | 16         | 16          | 4                  | 80              |

These numbers are a guideline only and your mileage may vary.<sup>1</sup>
It's best to monitor your server and its resource usage. You can always allocate more resources if needed.

See [here](/installation-and-operations/operation/control/#scaling-the-number-of-web-workers) how to scale those up in a packaged installation. If you are using docker-compose you can [scale](https://docs.docker.com/compose/reference/scale/) the web and worker services too.

> <sup>1</sup> When using [docker-compose](https://github.com/opf/openproject-deploy/tree/stable/11/compose) (with `USE_PUMA=true`) you can use fewer web workers which may use a bit more RAM, however. For instance for 200 users a single web worker would be enough.

**Scaling horizontally**

At some point simply increasing the resources of one single server may not be enough anymoe.

In the _packaged installation_ you can run have multiple servers running OpenProject. They will need to share an external database, memcached and file storage, however.

One way to scale the _docker_ installation is to use [docker Swarm](/installation-and-operations/installation/docker/#docker-swarm).

### Operating system

The [package-based installation](../installation/packaged) requires one of the following Linux distributions:

| Distribution (**64 bits only**) |
| ------------------------------- |
| Ubuntu 20.04 Focal              |
| Ubuntu 18.04 Bionic Beaver      |
| Ubuntu 16.04 Xenial Xerus       |
| Debian 10 Buster                |
| Debian 9 Stretch                |
| CentOS/RHEL 8.x                 |
| CentOS/RHEL 7.x                 |
| Suse Linux Enterprise Server 12 |

The [docker-based installation](../installation/docker) requires a system with Docker installed. Please see the [official Docker page](https://docs.docker.com/install/) for the list of supported systems.

### Overview of dependencies

Both the package and docker based installations will install and setup the following dependencies that are required by OpenProject to run:

* __Runtime:__ [Ruby](https://www.ruby-lang.org/en/) Version = 2.7.x
* __Webserver:__ [Apache](http://httpd.apache.org/)
  or [nginx](http://nginx.org/en/docs/)
* __Application server:__ [Puma](https://puma.io/)
* __Database__: [PostgreSQL](http://www.postgresql.org/) Version >= 9.5

## Client

OpenProject supports the latest versions of the major browsers. 

* [Mozilla Firefox](https://www.mozilla.org/en-US/firefox/products/) (at least ESR version 78.3.1)
* [Microsoft Edge](https://www.microsoft.com/de-de/windows/microsoft-edge) (only MS Edge version based on Chromium is supported)
* [Google Chrome](https://www.google.com/chrome/browser/desktop/)
* [Apple Safari](https://www.apple.com/safari/)

## Frequently asked questions (FAQ)

### Can I run OpenProject on Windows?

At the moment this is not officially supported, although the docker image might work. Check above regarding the system requirements.
