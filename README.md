OpenProject Reporting Plugin
=============================

The OpenProject Reporting plugin allows to create custom reports for costs associated to projects using the [OpenProject Costs plugin](https://www.openproject.org/projects/costs-plugin). Various attributes including custom fields can be used to filter the data and the results can be grouped by these attributes.

The OpenProject Reporting plugin is built on top of the [ReportingEngine Rails engine](https://www.openproject.org/projects/plugin-reportingengine), providing the base functionality for customized database reports.

Requirements
------------

The OpenProject Reporting plugin requires the [OpenProject Core](https://github.com/opf/openproject/) in
version greater or equal to *3.0.0*. It also requires the [ReportingEngine Rails engine](https://github.com/finnlabs/reporting_engine.git) in version greater or equal to *1.0.0*. Finally, it also requires the [OpenProject Costs plugin](https://github.com/finnlabs/openproject-costs.git).

Installation
------------

Reporting depends on the OpenProject Costs plugin. If you have not installed it yet, you can do so by adding the following line to the `Gemfile.plugins` in your OpenProject installation:

`gem "openproject-costs", git: "https://github.com/finnlabs/openproject-costs.git", :branch => "stable"`

Furthermore, OpenProject reporting depends on the ReportingEngine which should be installed by adding the following line to your `Gemfile.plugins` in your OpenProject installation folder:

`gem "reporting_engine", git: "https://github.com/finnlabs/reporting_engine.git", :branch => "stable"`

Finally, add the following line to your `Gemfile.plugins` in your OpenProject installation folder to use the Reporting plugin:

`gem "openproject-reporting", git: "https://github.com/finnlabs/openproject-reporting.git", :branch => "stable"`

Afterwards, run:

`bundle install`


Deinstallation
--------------

Remove the lines

`gem "reporting_engine", git: "https://github.com/finnlabs/reporting_engine.git", :branch => "stable"`
`gem "openproject-reporting", git: "https://github.com/finnlabs/openproject-reporting.git", :branch => "stable"`

from your `Gemfile.plugins` in your OpenProject installation folder and run:

`bundle install`

to uninstall the ReportingEngine and the OpenProject Reporting plugin.


Bug Reporting
-------------

If you find any bugs, you can create a bug ticket at

https://www.openproject.org/projects/plugin-reporting


Development
-----------

To contribute, you can create pull request on the official repository at
`https://github.com/finnlabs/openproject-reporting`


Credits
-------

Special thanks go to

* Deutsche Telekom AG (opensource@telekom.de) for project sponsorship

Licence
-------

Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)

This plugin is licensed under the GNU GPL v3. See doc/COPYRIGHT.md and doc/GPL.txt for details.
