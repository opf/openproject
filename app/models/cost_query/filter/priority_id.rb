class CostQuery::Filter::PriorityId < CostQuery::Filter::Base
  join_table Issue
  applies_for :label_issue_attributes
  label Issue.human_attribute_name(:priority)

  def self.available_values(*)
    IssuePriority.find(:all, :order => 'position DESC').map { |i| [i.name, i.id] }
  end
end
