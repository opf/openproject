class CostQuery::Filter::OverriddenCosts < CostQuery::Filter::Base
  label :field_overridden_costs

  def self.available_operators
    ['y', 'n'].map { |s| s.to_operator }
  end

  def self.available_values(*)
    []
  end
end
