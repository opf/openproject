class CostQuery::Filter::ActivityId < CostQuery::Filter::Base
  def available_values
    Activity.all.map { |a| [a.name, a.id] }
  end
end
