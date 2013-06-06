class OpenProject::JournalFormatter::ScenarioDate < JournalFormatter::Datetime
  unloadable

  private

  def label(key)
    key_match = /^scenario_(\d+)_(start|end)_date$/.match(key)

    scenario = Timelines::Scenario.find_by_id(key_match[1])

    scenario_name = scenario ? scenario.name : l(:label_scenario_deleted)

    l(:"label_scenario_#{key_match[2]}_date", :title => scenario_name)
  end

end
