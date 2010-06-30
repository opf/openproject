class CostQuery::Filter::OverriddenCosts < CostQuery::Filter::Base
  available_operators 'y', 'n'
  label :field_overridden_costs
end
