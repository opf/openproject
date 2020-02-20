#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

class ScenarioDisabler
  def self.empty_if_disabled(scenario)
    if self.disabled?(scenario)
      scenario.skip_invoke!
      true
    else
      false
    end
  end

  def self.disable(options)
    @disabled_scenarios ||= []

    @disabled_scenarios << options
  end

  def self.disabled?(scenario)
    # we have to check whether the scenario actually has a feature because there can also be scenario outlines
    # as described in https://github.com/cucumber/cucumber/wiki/Scenario-Outlines and the variables definition is
    # also matched as a scenario
    @disabled_scenarios.present? && scenario.respond_to?(:feature) && @disabled_scenarios.any? do |disabled_scenario|
      disabled_scenario[:feature] == scenario.feature.name && disabled_scenario[:scenario] == scenario.name
    end
  end
end
