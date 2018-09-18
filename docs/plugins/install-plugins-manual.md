# Install plugins - manual installation

OpenProject plugins come under the form of Ruby gems. The packaged and docker
based installation come with default plugins installed (the ones found in the
[Community Edition of OpenProject](https://github.com/opf/openproject-ce)).

For a manual installation, you can choose to install a different set of plugins
by following the instructions below.

## How to install a plugin

You can install plugins by listing them in a file called `Gemfile.plugins`. An
example `Gemfile.plugins` file looks like this:

```
# Required by backlogs
gem "openproject-pdf_export", git: "https://github.com/finnlabs/openproject-pdf_export.git", :branch => "stable/5"

gem "openproject-backlogs", git: "https://github.com/finnlabs/openproject-backlogs.git", :branch => "stable/5"
```

If you have modified the `Gemfile.plugins` file, always repeat the following
steps of the OpenProject installation:

```bash
[openproject@debian]# cd ~/openproject-ce
[openproject@debian]# bundle install
[openproject@debian]# npm install
[openproject@debian]# RAILS_ENV="production" bundle exec rake db:migrate db:seed assets:precompile
```

Restart the OpenProject server afterwards (no need to restart Apache(:

```bash
[openproject@debian]# touch ~/openproject-ce/tmp/restart.txt
```

The next request to the server will take longer (as the application is
restarted). All subsequent request should be as fast as always.

Always make sure that the plugin version is compatible with your OpenProject
version (e.g. use the ‘stable’ branch of both software -- OpenProject, and the
plugin).
