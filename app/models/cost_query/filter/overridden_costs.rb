class CostQuery::Filter::OverriddenCosts < CostQuery::Filter::Base

  def self.label
    CostEntry.human_attribute_name(:overridden_costs)
  end

  def self.available_operators
    ['y', 'n'].map { |s| s.to_operator }
  end

  def self.available_values(*)
    []
  end
end
