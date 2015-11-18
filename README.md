OpenProject Costs Plugin
===========================

This Plugin adds features for planning and tracking costs of projects. Budgets can be created containing the planned unit costs and labor costs. The actual costs can be assigned to the different work packages and planned and actual costs can be compared.

A more detailed description can be found on [OpenProject.org](https://community.openproject.org/projects/openproject/wiki/Time_and_Cost).


Requirements
------------

The OpenProject Costs plug-in requires the [OpenProject Core](https://github.com/opf/openproject/) in the same version.


Installation
------------

For OpenProject Costs itself you need to add the following line to the `Gemfile.plugins` of OpenProject (if you use a different OpenProject version than OpenProject 4.1, adapt `:branch => "stable/4.1"` to your OpenProject version):

`gem "openproject-costs", git: "https://github.com/finnlabs/openproject-costs.git", :branch => "stable/4.1"`

Afterwards, run:

`bundle install`

This plugin contains migrations. To migrate the database, run:

`rake db:migrate`


Deinstallation
--------------

Remove the line

`gem "openproject-costs", git: "https://github.com/finnlabs/openproject-costs.git", :branch => "stable/4.1"`

from the file `Gemfile.plugins` and run:

`bundle install`

Please not that this leaves plugin data in the database. Currently, we do not support full uninstall of the plugin.


Bug Reporting
-------------

If you find any bugs, you can create a bug ticket at

https://www.openproject.org/projects/costs-plugin


Development
-----------

To contribute, you can create pull request on the official repository at
`https://github.com/finnlabs/openproject-costs`


Credits
-------

Special thanks go to

* Deutsche Telekom AG (opensource@telekom.de) for project sponsorship

Licence
-------

Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)

This plugin is licensed under the GNU GPL v3. See doc/COPYRIGHT.md and doc/GPL.txt for details.
