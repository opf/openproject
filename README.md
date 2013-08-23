OpenProject Global Roles Plugin
==========================


This plugin adds global roles to [OpenProject](https://www.openproject.org).
A user can have a global role allowing to perform actions outside of the scope
of a specific project normally only allowed for administrators.
By assigning the permission to create projects to a global role,
non-administrators can create top-level projects.


Requirements
------------

The Global Roles plugin currently requires the [OpenProject Core](https://github.com/opf/openproject/) in
version 3.0.0pre13 or newer.


Installation
------------

Please follow the default [plugin installation instructions for
OpenProject](https://www.openproject.org/projects/openproject/wiki/Installation#222-Add-plugins),
adding the following line to the Gemfile.plugins:

`gem "openproject-global_roles"`

Afterwards, run:

`bundle install`

This plugin contains migrations. To migrate the database, run:

`rake openproject_global_roles:install:migrations`

`rake db:migrate`

Deinstallation
--------------

Currently, there complete automatic uninstall is not supported.
Before the plugin can be removed, all global roles have to be deleted.
Afterwards, remove the line

`gem "openproject-global_roles"`

from the file `Gemfile.plugins` and run:

`bundle install`

Please not that this changes by the plugin in the database. Currently, we do not
support full uninstall of the plugin.

Bug Reporting
-------------

If you find any bugs, you can create a bug ticket at

https://www.openproject.org/projects/plugin-global-roles

Development
-----------

To contribute, you can create pull request on the official repository at

`https://github.com/finnlabs/openproject-global_roles`

Credits
-------

Special thanks go to

* Deutsche Telekom AG (opensource@telekom.de) for project sponsorship

License
-------

(c) 2010 - 2013 - Finn GmbH

This plugin is licensed under the GNU GPL v3. See doc/COPYRIGHT.rdoc and
doc/GPL.txt for details.
