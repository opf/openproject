---
sidebar_navigation:
  title: (Re)configuring
  priority: 10
---

# (Re)configuring OpenProject

## Packaged installation

For packaged installations, you can restart the configuration process by issuing the following command on the server where OpenProject runs:

```bash
sudo openproject reconfigure
```

This will restart the installation wizard, and allow you to modify any of the choices that you previously selected. If a configuration option doesn't need to be modified, just hit `ENTER` to proceed to the next screen.

The wizard configuration is stored in `/etc/openproject/installer.dat`.

The wizard will automatically set environment variables to be used by OpenProject. Those variables can be manipulated with the CLI tool that ships with OpenProject:

* `sudo openproject config` will display the list of environment variables set.
* `sudo openproject config:get KEY` allows you to get the value of single environment variable.
* `sudo openproject config:set KEY VALUE` allows you to set a new value for a single environment variable.

## Docker installation

For the Compose-based docker installation, you should update the `docker-compose.yml` file and add any [environment variable](../../configuration/environment) that you may require. Docker Compose supports [file overrides](https://docs.docker.com/compose/extends/) so you may also want to use that. Then simply issue the following command:

```
docker-compose up -d
```

For all-in-one docker installations, you should update the environment file given to the `--env-file` docker option, and issue the following command:

```bash
docker restart openproject
```
