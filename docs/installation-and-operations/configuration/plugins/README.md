---
sidebar_navigation:
  title: Adding plugins
  priority: 0
---

# Adding plugins (DEB/RPM packages)

> **Note**: this guide only applies if you've installed OpenProject using our DEB/RPM packages.

A number of plugins exist for use with OpenProject. Most plugins that are maintained by us are shipping with OpenProject, however there are several plugins contributed by the community.

Previously, using them in a packaged installation was not possible without losing your changes on every upgrade. With the following steps, you can now use third party plugins.

> **Note**: We cannot guarantee upgrade compatibility for third party plugins nor do we provide support for them. Please carefully check whether the plugins you use are available in newer versions before upgrading your installation.

## Add a custom Gemfile

If you have a plugin you wish to add to your packaged OpenProject installation, create a separate Gemfile with the Gem dependencies, such as the following:

```ruby
group :opf_plugins do
  gem 'openproject-gitlab_integration', git: 'https://github.com/btey/openproject-gitlab-integration.git'
end
```

**Note:** The Gitlab plugin is usually only compatible with the latest versions. For more information, please see the respective repository: https://github.com/btey/openproject-gitlab-integration/

The group `:opf_plugins` is generally recommended, but only required for plugins with custom frontend code that is picked up by webpack and output into their respective bundles.

We suggest to store the Gemfile under `/etc/openproject/Gemfile.custom`, but the choice is up to you, just make sure the openproject user is able to read it.

## Propagate the Gemfile to the package

You have to tell your installation to use the custom gemfile via a config setting:

```shell
openproject config:set CUSTOM_PLUGIN_GEMFILE="/etc/openproject/Gemfile.custom"
```

If your plugin links into the Angular frontend, you will need to set the following environment variable to ensure it gets recompiled. Please note that NPM dependencies will be installed during the installation, and the angular CLI compilation will take place which will delay the configuration process by a few minutes.

```shell
openproject config:set RECOMPILE_ANGULAR_ASSETS="true"
```

> **Note**: Re-enabling Angular asset compilation has two implications: It will install all npm packages required for the compilation and in turn cause a higher disk and especially inode consumption. The Angular CLI production build itself then consumes a sometimes absurd amount of RAM with at least 4GB being required to compile successfully.
> If you experience any issues with OpenProject not starting after setting this flag, double check that you are not running out of inodes or RAM when calling `openproject configure`.

## Re-run the installer

To re-bundle the application including the new plugins, as well as running migrations and precompiling their assets, simply re-run the installer while using the same configuration as before.

```shell
sudo openproject configure
```

Using configure will take your previous decisions in the installer and simply re-apply them, which is an idempotent operation. It will detect the Gemfile config option being set and re-bundle the application with the additional plugins.
