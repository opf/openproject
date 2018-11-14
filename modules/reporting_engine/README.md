ReportingEngine
===============

The ReportingEngine is a Rails engine containing base functionality to create customized database reports. A report consists of filters and grouping criteria, each of which selects an attribute to be used for filtering and grouping. It provides base filter and grouping classes to be used for adding new filters. It also adds some base widgets to visually represent the created reports.

This engine is mainly used in the [OpenProject Reporting plugin](https://www.openproject.org/projects/plugin-reporting), allowing to create customized cost reports when the [OpenProject Costs plugin](https://www.openproject.org/projects/costs-plugin) is used to track projects costs.

Requirements
------------

The ReportingEngine requires Rails 3.2 and is compatible with MySQL or PostgreSQL. MySQL versions 5.6.0 - 5.6.12 and 5.7.0 - 5.7.1 are not supported since they contain a bug leading to wrong report results under certain circumstances.

Installation
------------

To use the ReportingEngine, add the following line to your `Gemfile`:

`gem "reporting_engine", git: "https://github.com/finnlabs/reporting_engine.git", :branch => "dev"`

If you are running OpenProject, add the above line to the `Gemfile.plugins` in your OpenProject installation folder instead.

Afterwards, run:

`bundle install`


Deinstallation
--------------

Remove the line

`gem "reporting_engine", git: "https://github.com/finnlabs/reporting_engine.git", :branch => "dev"`

from your `Gemfile` or the `Gemfile.plugins` in your OpenProject installation and run:

`bundle install`


Bug Reporting
-------------

If you find any bugs, you can create a bug ticket at

https://www.openproject.org/projects/plugin-reportingengine


Development
-----------

To contribute, you can create pull request on the official repository at
`https://github.com/finnlabs/reporting_engine`


Credits
-------

Special thanks go to

* Deutsche Telekom AG (opensource@telekom.de) for project sponsorship

Licence
-------

Copyright (C) 2010 - 2015 OpenProject Foundation (OPF)

This plugin is licensed under the GNU GPL v3. See doc/COPYRIGHT.md and doc/GPL.txt for details.
