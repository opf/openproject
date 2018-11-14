#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
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

RSpec::ExampleDisabler.disable_example('WorkPackagesController index with valid query settings passed to front-end client visible attributes all attributes visible', 'plugin openproject-costs changes behavior')
RSpec::ExampleDisabler.disable_example('API::V3::WorkPackages::WorkPackageRepresenter generation spentTime content time entry with multiple hours', 'plugin openproject-costs changes behavior')
RSpec::ExampleDisabler.disable_example('API::V3::WorkPackages::WorkPackageRepresenter generation spentTime content no time entry', 'plugin openproject-costs changes behavior')
RSpec::ExampleDisabler.disable_example('API::V3::WorkPackages::WorkPackageRepresenter generation spentTime content time entry with single hour', 'plugin openproject-costs changes behavior')

RSpec::ExampleDisabler.disable_example('API::V3::WorkPackages::Schema::WorkPackageSchemaRepresenter generation spentTime not allowed to view time entries does not show spentTime', 'plugin openproject-costs causes unexpected message')
