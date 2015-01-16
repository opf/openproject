OpenProject Meeting Plugin
==========================

This plugin adds functions to support project meetings to
[OpenProject](https://www.openproject.org). Meetings
can be scheduled selecting invitees from the same project to take
part in the meeting. An agenda can be created and sent to the invitees.
After the meeting, attendees can be selected and minutes can be
created based on the agenda. Finally, the minutes can be sent to
all attendees and invitees.

A more detailed feature tour can be found [here](https://www.openproject.org/projects/openproject/wiki/Meetings).

Requirements
------------

The Meeting plugin currently requires the [OpenProject Core](https://github.com/opf/openproject/) in
version greater or equal to 3.0.0.


Installation
------------

Add the following line to the `Gemfile.plugins` to your OpenProject installation:

`gem "openproject-meeting", :git => "https://github.com/finnlabs/openproject-meeting.git", :branch => "stable"`

Afterwards, run:

`bundle install`

This plugin contains migrations. To migrate the database, run:

`rake db:migrate`

Deinstallation
--------------

Remove the line

`gem "openproject-meeting", :git => "https://github.com/finnlabs/openproject-meeting.git", :branch => "stable"`

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

* Deutsche Telekom AG (opensource@telekom.de) for project sponsorship
* Vincent Le Moign and his fabulous Minicons icons on [webalys.com](http://www.webalys.com/minicons/icons-free-pack.php)

License
-------

(c) 2011 - 2014 - the OpenProject Foundation (OPF)

This plugin is licensed under the GNU GPL v3. See doc/COPYRIGHT.md and
doc/GPL.txt for details.
