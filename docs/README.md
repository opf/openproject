# OpenProject Community Guides


## Installation

Get started with installing and upgrading OpenProject using [our Installation Guide starting point](https://www.openproject.org/open-source/download/).

The guides for manual and Docker-based installations [are located here](./installing/README.md).

## Upgrading

The detailed upgrade instructions for our packaged installer are located on the [official website](https://www.openproject.org/download/upgrade-guides/).

The guides for manual and Docker-based installations [are located here](./upgrading/README.md).

## Operation

* [Backup guide](./backup/README.md)
* [Alter configuration of OpenProject](./configuration/README.md)
* [Manual repository integration for Git and Subversion](./repositories/README.md)
* [Configure incoming mails](./incoming-mails/README.md)
* [Install custom plugins](./plugins/README.md)


## User Guides

Please see our [User Guide pages](https://www.openproject.org/help/user-guides/) for detailed documentation on the functionality of OpenProject.


## Development

* [Quick Start for developers](./development/quick-start.md)
* [Full development environment for developers](./development/setting-up-development-environment.md)
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