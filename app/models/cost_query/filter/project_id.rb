class CostQuery::Filter::ProjectId < CostQuery::Filter::Base
  label :field_project

  def self.available_values
    Project.all.map { |p| [p.name, p.id] }
  end
end
