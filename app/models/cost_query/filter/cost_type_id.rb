class CostQuery::Filter::CostTypeId < CostQuery::Filter::Base
  available_operators

  def self.available_values
    CostType.all.map { |t| [t.name, t.id] }
  end
end
