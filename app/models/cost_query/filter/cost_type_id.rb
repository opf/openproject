class CostQuery::Filter::CostTypeId < CostQuery::Filter::Base
  available_operators

  def available_values
    CostType.all.map { |t| [t.name, t.id] }
  end
end
