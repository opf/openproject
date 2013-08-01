OpenProject Meeting Plugin
==========================

This plugin adds functions to support project meetings. Meetings
can be scheduled selecting invitees from the same project to take
part in the meeting. An agenda can be created and sent to the invitees.
After the meeting, attendants can be selected and minutes can be
created based on the agenda. Finally, the minutes can be sent to
all attendants and invitees.

Requirements
------------

The meetings plugin currently requires the OpenProject Core in
version 3.0.0pre9 or newer.


Installation
------------

Please follow the default [plugin installation instructions for
OpenProject](https://www.openproject.org/projects/openproject/wiki/Installation#222-Add-plugins),
adding the following line to the Gemfile.plugins:

`gem "openproject-meeting", :git => "https://github.com/finnlabs/openproject-meeting"`

Afterwards, run:

`bundle install`

This plugin contains migrations. To migrate the database, run:

`rake openproject_meeting:install:migrations`

`rake db:migrate`

Deinstallation
--------------

Remove the line

`gem "openproject-meeting", :git => "https://github.com/finnlabs/openproject-meeting"`

from the file `Gemfile.plugins` and run:

`bundle install`

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

We would like to thank

* Deutsche Telekom AG (opensource@telekom.de) for project sponsorhip
* Birthe Russmeyer and Niels Lindenthal of finnlabs for their consulting and
  project management

Licence
-------

(c) 2013 - Finn GmbH

This plugin is licensed under the GNU GPL v3. See doc/COPYRIGHT.rdoc and
doc/GPL.txt for details.
