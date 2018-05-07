# OpenProject Avatars Plugin

This plugin allows users to add an avatar picture to their user profile. They can either

* Use a Gravatar image assigned to their registered mail address
* Upload a local avatar

As an admin, you can enable or disable each of these features.


Requirements
------------

The OpenProject Avatars plugin requires the [OpenProject Core](https://github.com/opf/openproject/) to be in the same version as the plugin.

Installation
------------

To install the OpenProject Avatars plugin you need to add the following line to the `Gemfile.plugins` in your OpenProject folder (if you use a different OpenProject version than OpenProject 7, adapt `:branch => "stable/7"` to your OpenProject version):

`gem "openproject-avatars", git: "https://github.com/opf/openproject-avatars", :branch => "stable/7"`

Afterwards, run:

`bundle install`

Deinstallation
--------------

Remove the line

`gem "openproject-avatars", git: "https://github.com/opf/openproject-avatars", :branch => "stable/7"`

from the file `Gemfile.plugins` and run:

`bundle install`

Bug Reporting
-------------

If you find any bugs, you can create a bug ticket at
https://community.openproject.org/projects/avatars

Development
-----------

To contribute, you can create pull request on the official repository at
`https://github.com/opf/openproject-avatars`

Acknowledgment
--------------

A. Chaika wrote the original version of the local-avatars plugin
* http://www.redmine.org/boards/3/topics/5365
* https://github.com/Ubik/redmine_avatars

Luca Pireddu <pireddu@gmail.com> at CRS4 (http://www.crs4.it), contributed updates and improvements.

Copyright
-------

* Copyright (C) 2011-2017 OpenProject GmbH

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
