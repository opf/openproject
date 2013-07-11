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

class OpenProject::JournalFormatter::ScenarioDate < JournalFormatter::Datetime
  unloadable

  private

  def label(key)
    key_match = /^scenario_(\d+)_(start|due)_date$/.match(key)

    scenario = Scenario.find_by_id(key_match[1])

    scenario_name = scenario ? scenario.name : l(:label_scenario_deleted)

    l(:"label_scenario_#{key_match[2]}_date", :title => scenario_name)
  end

end
