OpenProject My Project Page PlugIn
==================================

This plugin provides a customizable view of the Project-Overview-Page, very similar
to the "My Page" in the OpenProject Core.

Requirements
------------

The My Project Page plugin currently requires the OpenProject Core in version 3.0.0 or newer.


Installation
------------

To install the My Project Page plugin, add the following line to the `Gemfile.plugins` to your OpenProject installation:

`gem "openproject-my_project_page", :git => "https://github.com/finnlabs/openproject-my_project_page.git", :branch => "stable"`

Afterwards, run:

`bundle install`

This plugin contains migrations. To migrate the database, run:

`rake db:migrate`

Deinstallation
--------------

Remove the line

`gem "openproject-my_project_page", :git => "https://github.com/finnlabs/openproject-my_project_page.git", :branch => "stable"`

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

(c) 2011 - 2014 - the OpenProject Foundation (OPF)

This plugin is licensed under the GNU GPL v3. See doc/COPYRIGHT.rdoc and
doc/GPL.txt for details.
