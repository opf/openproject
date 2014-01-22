OpenProject Costs Plugin
===========================

This Plugin adds features for planning and tracking costs of projects. Budgets can be created containing the planned unit costs and labor costs. The actual costs can be assigned to the different work packages and planned and actual costs can be compared.

A more detailed description can be found on [OpenProject.org](https://www.openproject.org/projects/openproject/wiki/Time_and_Cost).


Requirements
------------

The OpenProject Backlogs plug-in requires the [OpenProject Core](https://github.com/opf/openproject/) in version greater or equal to *3.0.0pre37*.

Tests for this plugin require `pdf-inspector`, so just add the following line to OpenProject's `Gemfile.plugin`:

`gem "pdf-inspector", "~>1.0.0", :group => :test`


Installation
------------

OpenProject Backlogs depends on OpenProject Plugins. Thus, if you haven't done it already, add the following line to the `Gemfile.plugins` to your OpenProject installation:

`gem "openproject-plugins", git: "https://github.com/opf/openproject-plugins.git", :branch => "dev"`

For OpenProject Backlogs itself you need to add the following line to the `Gemfile.plugins` of OpenProject:

`gem "openproject-backlogs", git: "https://github.com/finnlabs/openproject-backlogs.git", :branch => "dev"`

Afterwards, run:

`bundle install`

This plugin contains migrations. To migrate the database, run:

`rake db:migrate`


Deinstallation
--------------

Remove the line

`gem "openproject-backlogs", git: "https://github.com/finnlabs/openproject-backlogs.git"`

from the file `Gemfile.plugins` and run:

`bundle install`

Please not that this leaves plugin data in the database. Currently, we do not support full uninstall of the plugin.


Bug Reporting
-------------

If you find any bugs, you can create a bug ticket at

https://www.openproject.org/projects/plugin-backlogs


Development
-----------

To contribute, you can create pull request on the official repository at
`https://github.com/finnlabs/openproject-backlogs`


Credits
-------

Special thanks go to

* Deutsche Telekom AG (opensource@telekom.de) for project sponsorship

Licence
-------

Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)

This plugin is licensed under the GNU GPL v3. See doc/COPYRIGHT.md and doc/GPL.txt for details.
