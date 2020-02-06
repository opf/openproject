---
sidebar_navigation:
  title: OpenProject Documentation
  priority: 999
description: Help and documentation for OpenProject Community, Enterprise Edition and Cloud Edition.
robots: index, follow
keywords: help, documentation
---
# OpenProject Documentation

<div class="alert alert-info" role="alert">
**Note**: To better read our OpenProject Documentation, please go to [docs.openproject.org](https://docs.openproject.org).
</div>

ToDo: check all links.

## Installation

Get started with installing and upgrading OpenProject using [our Installation Guide starting point](https://docs.openproject.org/installation-and-operations/).

The guides for [manual](./installation/manual/README.md), [packaged](./installation/packaged/) and [Docker-based](./installation/docker/README.md) installations are provided.

## Upgrading

The detailed upgrade instructions for our packaged installer are located on the [official website](https://www.openproject.org/download/upgrade-guides/).

The guides for [manual](./operations/upgrading/manual/upgrading.md), [packaged](./operations/upgrading/packaged/upgrading.md) and [Docker-based](./operations/upgrading/docker/upgrading.md) upgrading are provided.

## Operation

* Backup guides for [manual](./operations/backup/manual/backup.md), [packaged](./operations/backup/packaged/backup.md) and [Docker-based](./operations/backup/docker/backup.md) installations
* [Alter configuration of OpenProject](./configuration/configuration.md)
* [Manual repository integration for Git and Subversion](./repositories/README.md)
* [Configure incoming mails](./configuration/incoming-emails.md)
* [Install custom plugins](./plugins/plugins.md)


## User Guides

Please see our [User Guide pages](https://docs.openproject.org/user-guide/) for detailed documentation on the functionality of OpenProject.


## Development

* [Quick Start for developers](./development/quick-start.md)
* [Full development environment for developers on Ubuntu](./development/development-environment-ubuntu.md) and [Mac OS X](./development/development-environment-osx.md)
* [Developing plugins](./development/create-openproject-plugin.md)
* [Developing OmniAuth Plugins](./development/create-omniauth-plugin.md)
* [Running tests](./development/running-tests.md)
* [Code review guidelines](./development/code-review-guidelines.md)
* [API documentation](./api/README.md)


## APIv3 documentation sources

The documentation for APIv3 is written in the [API Blueprint Format](http://apiblueprint.org/) and its sources are being built from the entry point `apiv3-documentation.apib`.

You can use [aglio](https://github.com/danielgtaylor/aglio) to generate HTML documentation, e.g. using the following command:

```bash
aglio -i apiv3-documentation.apib -o api.html
```

The output of the API documentation at `dev` branch is continuously built and pushed to Github Pages at [opf.github.io/apiv3-doc/](opf.github.io/apiv3-doc/).