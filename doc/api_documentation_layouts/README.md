<!---- copyright
OpenProject is a project management system.
Copyright (C) 2012-2015 the OpenProject Foundation (OPF)

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License version 3.

OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
Copyright (C) 2006-2013 Jean-Philippe Lang
Copyright (C) 2010-2013 the ChiliProject Team

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

See doc/COPYRIGHT.rdoc for more details.

++-->

API Documentation Layouts
-------------------------

## API Version 3

_Status: under development_

The documentation for APIv3 is written in the [API Blueprint Format](http://apiblueprint.org/).

You can use [aglio](https://github.com/danielgtaylor/aglio) to generate HTML documentation.
Aglio supports the use of templates to adjust the ouput to your own needs. OpenProject is
using the openproject.jade template file. To generate the documentation using the
openproject.jade layout file  the following command:

```bash
aglio -t openproject-layout.jade -i ../apiv3-documentation.api -o api.html

```

