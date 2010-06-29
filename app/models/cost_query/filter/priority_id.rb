class CostQuery::Filter::PriorityId < CostQuery::Filter::Base
  join_table Issue

  def self.available_values
    IssuePriority.all.map { |i| [i.name, i.id] }
  end
end
