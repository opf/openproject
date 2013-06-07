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

class ScenarioDisabler
  def self.empty_if_disabled(scenario)
    if self.disabled?(scenario)
      step_collection = scenario.instance_variable_get(:@steps)
      step_collection.instance_variable_set(:@steps, [])

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
    @disabled_scenarios.present? && @disabled_scenarios.any? do |disabled_scenario|
      disabled_scenario[:feature] == scenario.feature.name && disabled_scenario[:scenario] == scenario.name
    end
  end

end
