OpenProject Backlogs Plugin
===========================

This Plugin adds features, that enable agile teams to work efficiently with
OpenProject in Scrum projects.

Find a more detailed description on [OpenProject.org](https://www.openproject.org/projects/openproject/wiki/Agile_teams).

Together with the plugin [OpenProject PDF Export](https://www.openproject.org/projects/pdf-export), story cards can be exported as printable PDF documents.

Requirements
------------

The OpenProject Backlogs plug-in requires the [OpenProject Core](https://github.com/opf/openproject/) in
version greater or equal to *3.0.0*.


Installation
------------

OpenProject Backlogs depends on OpenProject PDF export Plugin. Thus, if you haven't done
it already, add the following lines to the `Gemfile.plugins` to your OpenProject installation (if you use a different OpenProject version than OpenProject 5, adapt :branch => "stable/5" to your OpenProject version):

`gem "openproject-pdf_export", git: "https://github.com/finnlabs/openproject-pdf_export.git", :branch => "stable/5"`

For OpenProject Backlogs itself you need to add the following line to the

`Gemfile.plugins` of OpenProject (if you use a different OpenProject version than OpenProject 5, adapt :branch => "stable/5" to your OpenProject version):


`gem "openproject-backlogs", git: "https://github.com/finnlabs/openproject-backlogs.git", :branch => "stable/5"`

Afterwards, run:

`bundle install`

This plugin contains migrations. To migrate the database, run:

`rake db:migrate`


Deinstallation
--------------

Remove the line

`gem "openproject-backlogs", git: "https://github.com/finnlabs/openproject-backlogs.git", :branch => "stable/5"`

from the file `Gemfile.plugins` and run:

`bundle install`

Please not that this leaves plugin data in the database. Currently, we do not
support full uninstall of the plugin.


Bug Reporting
-------------

If you find any bugs, you can create a bug ticket at

https://community.openproject.com/projects/plugin-backlogs/work_packages/new?type=1

Development
-----------

To contribute, you can create pull request on the official repository at
`https://github.com/finnlabs/openproject-backlogs`


Credits
-------

We thank the original maintainers and developers of [Redmine
Backlogs](http://www.redminebacklogs.net/) as well as
[Chiliproject Backlogs](https://github.com/finnlabs/chiliproject_backlogs) for
their immense work on this plugin. OpenProject Backlogs would not have been
possible without their original contribution. Those contributors are:

* Marnen Laibow-Koser
* Sandro Munda
* Emiliano Heyns (friflaj)
* Maxime Guilbot
* Andrew Vit
* Joakim Kolsjö
* ibussieres
* Daniel Passos
* Jason Vasquez
* jpic
* Mark Maglana
* Joe Heck
* Nate Lowrie

Additionally, we would like to thank

* Deutsche Telekom AG (opensource@telekom.de) for project sponsorhip

Licence
-------

Copyright (C)2013-2015 the OpenProject Foundation (OPF)<br />
Copyright (C)2011 Marnen Laibow-Koser, Sandro Munda<br />
Copyright (C)2010-2011 Emiliano Heyns (friflaj)<br />
Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic<br />
Copyright (C)2009-2010 Mark Maglana<br />
Copyright (C)2009 Joe Heck, Nate Lowrie

This plugin is licensed under the GNU GPL v3. See doc/COPYRIGHT.md and doc/GPL.txt for details.
