#-- copyright
# OpenProject Reporting Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require 'rspec/example_disabler'

RSpec::ExampleDisabler.disable_example('Top menu items as a user with permissions displays all options', 'plugin openproject-reporting removes the menu item')
RSpec::ExampleDisabler.disable_example('Top menu items as an admin visits the time sheet page', 'plugin openproject-reporting removes the menu item')
RSpec::ExampleDisabler.disable_example('Top menu items as an admin displays all items', 'plugin openproject-reporting removes the menu item')
RSpec::ExampleDisabler.disable_example('Top menu items Modules as an admin visits the time sheet page', 'plugin openproject-reporting removes the menu item')
RSpec::ExampleDisabler.disable_example('Top menu items Modules as an admin displays all items', 'plugin openproject-reporting removes the menu item')
RSpec::ExampleDisabler.disable_example('Top menu items Modules as a user with permissions displays all options', 'plugin openproject-reporting removes the menu item')
