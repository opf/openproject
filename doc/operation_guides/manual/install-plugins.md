# Install Plugins

OpenProject plugins are separated in ruby gems.
The OpenProject Community Edition contains the recommended set of plugins for use
with OpenProject. For more information, see https://github.com/opf/openproject-ce.

You can install plugins by listing them in a file called `Gemfile.plugins`. An example `Gemfile.plugins` file looks like this:

```
# Required by backlogs
gem "openproject-pdf_export", git: "https://github.com/finnlabs/openproject-pdf_export.git", :branch => "stable/4.2"

gem "openproject-backlogs", git: "https://github.com/finnlabs/openproject-backlogs.git", :branch => "stable/4.2"
```

If you have modified the `Gemfile.plugins` file, always repeat the following steps of the OpenProject installation:

```bash
[openproject@debian]# cd ~/openproject-ce
[openproject@debian]# bundle install
[openproject@debian]# bower install
[openproject@debian]# RAILS_ENV="production" bundle exec rake db:migrate db:seed assets:precompile
```
Restart the OpenProject server afterwards (yes, you can do that without restarting Apache):

```bash
[openproject@debian]# touch ~/openproject-ce/tmp/restart.txt
```

The next web-request to the server will take longer (as the application is restarted). All subsequent request should be as fast as always.

Always make sure that the plugin version is compatible with your OpenProject version (e.g. use the ‘stable’ branch of both, OpenProject, and the plugin).
