class CostQuery::Filter::ProjectId < CostQuery::Filter::Base
  def available_values
    Project.all.map { |p| [p.name, p.id] }
  end
end
