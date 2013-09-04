#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

# The plugin changes the project-overview-page, which breaks this Scenario
ScenarioDisabler.disable(:feature => "Showing Projects", :scenario => "Calendar link in the 'tickets box' should work when calendar is activated")