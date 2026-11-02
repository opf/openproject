---
sidebar_navigation:
  title: Development FAQ
  priority: 980
description: Frequently asked questions for development
keywords: FAQ, change code, developing, plug-in
---
# Frequently asked questions (FAQ) for development

## Is there an ER diagram (entity relationship diagram) for OpenProject?

No. The database layout is subject to continuous change. Every upgrade, even from one patch level release to the next, might change the database layout. Because of that, it is also not advisable to integrate on the database level (e.g. for data warehousing/dashboards).

## Is there documentation for creating my own plugin?

The documentation for creating plugins is indeed limited at the moment. What we have is mostly [this one](../create-openproject-plugin) and the [proto plugin](https://github.com/opf/openproject-proto_plugin).

## Which gateway provider does OpenProject use for 2FA by SMS?

We use MessageBird. At the moment this can't be changed.

## Why does Docker report that database.yml exists?

The Docker development setup requires `config/database.yml` to be absent. If you also use a native development environment, rename the file to keep its configuration before starting Docker. Follow the [Docker setup guide](../development-environment/docker/) for configuration and commands.

## Why does the frontend Docker container exit with status 137?

The container may have run out of memory. Check the container logs and increase Docker's memory allocation to at least 4 GB if memory exhaustion is the cause.

## How do I repair missing frontend assets or a blank development page?

For a configured native development environment, run `bin/setup_dev` to refresh dependencies, migrate the database, and clear stale compiled assets. Restart the development servers afterwards. For a Docker environment, use the [Docker setup commands](../development-environment/docker/) inside the containers.
