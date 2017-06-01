### Installing plugins

Note: this guide only applies if you've installed OpenProject using our DEB/RPM packages.

[A number of plugins](https://www.openproject.org/plugins/) exist
for use with OpenProject. Most plugins that are maintained by us are shipping
with OpenProject, however there are several plugins contributed by the
community.

Previously, using them in a packaged installation was not possible without
losing your changes on every upgrade. With the following steps, you can now use
third party plugins.

**Note**: We cannot guarantee upgrade compatibility for third party plugins nor
do we provide support for them. Please carefully check whether the plugins you
use are available in newer versions before upgrading your installation.

#### 1. Add a custom Gemfile

If you have a plugin you wish to add to your packaged OpenProject installation,
create a separate Gemfile with the Gem dependencies, such as the following:

```
gem 'openproject-emoji', git: 'https://github.com/tessi/openproject-emoji.git', :branch => 'op-5-stable'
```

We suggest to store the Gemfile under `/etc/openproject/Gemfile.custom`, but
the choice is up to you, just make sure the `openproject` user is able to read
it.

#### 2. Propagate the Gemfile to the package

You have to tell your installation to use the custom gemfile via a config setting:

```
openproject config:set CUSTOM_PLUGIN_GEMFILE=/etc/openproject/Gemfile.custom
```

#### 3. Re-run the installer

To re-bundle the application including the new plugins, as well as running
migrations and precompiling their assets, simply re-run the installer while
using the same configuration as before.

```
openproject configure
```

Using `configure` will take your previous decisions in the installer and simply
re-apply them, which is an idempotent operation. It will detect the Gemfile
config option being set and re-bundle the application with the additional plugins.
