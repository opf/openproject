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
