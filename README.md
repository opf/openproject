OpenProject Meeting Plugin
==========================

This plugin adds functions to support project meetings to
[OpenProject](https://www.openproject.org). Meetings
can be scheduled selecting invitees from the same project to take
part in the meeting. An agenda can be created and sent to the invitees.
After the meeting, attendants can be selected and minutes can be
created based on the agenda. Finally, the minutes can be sent to
all attendants and invitees.

A more detailed feature tour can be found [here](https://www.openproject.org/projects/openproject/wiki/Meetings).

Requirements
------------

The meetings plugin currently requires the [OpenProject Core](https://github.com/opf/openproject/) in
version 3.0.0pre9 or newer.


Installation
------------

Please follow the default [plugin installation instructions for
OpenProject](https://www.openproject.org/projects/openproject/wiki/Installation#222-Add-plugins),
adding the following line to the Gemfile.plugins:

`gem "openproject-meeting"`

Afterwards, run:

`bundle install`

This plugin contains migrations. To migrate the database, run:

`rake openproject_meeting:install:migrations`

`rake db:migrate`

Deinstallation
--------------

Remove the line

`gem "openproject-meeting"`

from the file `Gemfile.plugins` and run:

`bundle install`

Please not that this leaves plugin data in the database. Currently, we do not
support full uninstall of the plugin.

Bug Reporting
-------------

If you find any bugs, you can create a bug ticket at

https://www.openproject.org/projects/plugin-meetings

Development
-----------

To contribute, you can create pull request on the official repository at

`https://github.com/finnlabs/openproject-meeting`

Credits
-------

Special thanks go to

* Deutsche Telekom AG (opensource@telekom.de) for project sponsorhip
* Le Moign Vincent and his fabulous Minicons icons on [webalys.com](http://www.webalys.com/minicons/icons-free-pack.php)

License
-------

(c) 2011 - 2013 - Finn GmbH

This plugin is licensed under the GNU GPL v3. See doc/COPYRIGHT.rdoc and
doc/GPL.txt for details.
