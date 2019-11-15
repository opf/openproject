---
sidebar_navigation:
  title: (Re)configuring
  priority: 800
---

# (Re)configuring OpenProject

## Packaged installation

For packaged installations, you can restart the cofniguration process by issuing the following command on the server where OpenProject runs:

```
sudo openproject reconfigure
```

This will restart the installation wizard, and allow you to modify any of the choices that you previously selected. If a configuration options doesn't need to be modified, just hit `ENTER` to proceed to the next screen.

## Docker installation

For docker-based installations, you should update the environment file passed to the `--env-file` docker option, and issue the following command:

```
docker restart openproject
```
