OpenProject My Project Page PlugIn
==================================

This plugin provides a customizable view of the Project-Overview-Page, very similar
to the "My Page" in Core.

Requirements
------------

The meetings plugin currently requires the OpenProject Core in
version 3.0.0pre14 or newer.


Installation
------------

Please follow the default [plugin installation instructions for
OpenProject](https://www.openproject.org/projects/openproject/wiki/Installation#222-Add-plugins),
adding the following line to the Gemfile.plugins:

`gem "openproject-my_project_page"`

Afterwards, run:

`bundle install`

This plugin contains migrations. To migrate the database, run:

`rake openproject_my_project_page:install:migrations`

`rake db:migrate`

Deinstallation
--------------

Remove the line

`gem "openproject-my_project_page"`

from the file `Gemfile.plugins` and run:

`bundle install`

Please note that this leaves plugin data in the database. Currently, we do not
support full uninstall of the plugin.

Bug Reporting
-------------

If you find any bugs, you can create a bug ticket at

https://www.openproject.org/projects/my-project-page

Development
-----------

To contribute, you can create pull request on the official repository at

`https://github.com/finnlabs/openproject-my_project_page`

Licence
-------

(c) 2013 - Finn GmbH

This plugin is licensed under the GNU GPL v3. See doc/COPYRIGHT.rdoc and
doc/GPL.txt for details.

