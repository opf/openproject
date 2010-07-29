class CostQuery::Filter::CostTypeId < CostQuery::Filter::Base
  label :field_cost_type
  dont_display!

  def self.available_values
    CostType.all.map { |t| [t.name, t.id] }
  end
end
