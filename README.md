# OpenProject XLS Export Plugin

Enables work package export as Excel spreadsheets (.xls). This plugin allows work package export as Excel document in the work package list.

To export work packages in the work package list, select the `Settings` menu button (gear icon) and select `Export ...` from the dropdown menu.
Choose either `XLS` or `XLS with descriptions` (to export the work package list with the work package descriptions) to export the work packages shown in the work package list.


Requirements
------------

The OpenProject XLS-Export plugin requires the [OpenProject Core](https://github.com/opf/openproject/) to be in the same version as the plugin.

Installation
------------

To install the OpenProject XLS-Export plugin you need to add the following line to the `Gemfile.plugins` in your OpenProject folder (if you use a different OpenProject version than OpenProject 5, adapt `:branch => "stable/5"` to your OpenProject version):

`gem "openproject-xls_export", git: "https://github.com/finnlabs/openproject-xls_export.git", :branch => "stable/5"`

Afterwards, run:

`bundle install`

Deinstallation
--------------

Remove the line

`gem "openproject-xls_export", git: "https://github.com/finnlabs/openproject-xls_export.git", :branch => "stable/5"`

from the file `Gemfile.plugins` and run:

`bundle install`

Bug Reporting
-------------

If you find any bugs, you can create a bug ticket at
https://community.openproject.org/projects/export

Development
-----------

To contribute, you can create pull request on the official repository at
`https://github.com/finnlabs/openproject-xls_export`

Copyright
-------

* Copyright (C) 2010-2015 OpenProject GmbH

Licence
-------

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
