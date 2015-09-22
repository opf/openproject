# Install Plugins

OpenProject plug-ins are separated in ruby gems. You can install them by listing them in a file called `Gemfile.plugins`. An example `Gemfile.plugins` file looks like this:

```
# Required by backlogs
gem "openproject-pdf_export", git: "https://github.com/finnlabs/openproject-pdf_export.git", :branch => "stable/4.2"

gem "openproject-backlogs", git: "https://github.com/finnlabs/openproject-backlogs.git", :branch => "stable/4.2"
```

If you have modified the `Gemfile.plugins` file, always repeat the following steps of the OpenProject installation:

```bash
[openproject@debian]# cd ~/openproject
[openproject@debian]# bundle install
[openproject@debian]# bower install
[openproject@debian]# RAILS_ENV="production" bundle exec rake db:migrate
[openproject@debian]# RAILS_ENV="production" bundle exec rake db:seed
[openproject@debian]# RAILS_ENV="production" bundle exec rake assets:precompile
```
Restart the OpenProject server afterwards (yes, you can do that without restarting Apache):

```bash
[openproject@debian]# touch ~/openproject/tmp/restart.txt
```

The next web-request to the server will take longer (as the application is restarted). All subsequent request should be as fast as always.

Note: plugins are only supported for the manual installation. The `Gemfile.plugins` file needs to be created first in the OpenProject root folder.

Always make sure that the plugin version is compatible with your OpenProject version (e.g. use the ‘stable’ branch of both, OpenProject, and the plugin).
