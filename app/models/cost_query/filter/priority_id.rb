class CostQuery::Filter::PriorityId < CostQuery::Filter::Base
  join_table Issue
  applies_for :label_issue
  label :field_priority

  def self.available_values
    IssuePriority.all.map { |i| [i.name, i.id] }
  end
end
