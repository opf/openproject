---
sidebar_navigation:
  title: Configuring SSL
  priority: 9
---

# Configuring SSL

## Package-based installation (DEB/RPM)

SSL configuration can be applied on the first installation, or at any time by reconfiguring the application with:

```bash
sudo openproject reconfigure
```

You will be prompted with the same dialogs than on the [initial configuration](#TODO) guide. This assumes that you select the **install** option when the **server/autoinstall** dialog appears, and that you have certificate and key files available on your server at a path you know.

[initial_configuration]: ../installation/packaged/#install-apache2-web-server-default

## Docker-based installation

The current Docker image does not support SSL by default. Usually you would
already have an existing Apache or NginX server on your host, with SSL
configured, which you could use to set up a simple ProxyPass rule to direct
traffic to the container.

If you really want to enable SSL from within the container, you could try
mounting a custom apache2 directory when you launch the container with `-v
my/apache2/conf:/etc/apache2`. This would entirely replace the configuration
we're using.
