class CostQuery::Filter::PriorityId < Report::Filter::Base
  join_table Issue
  applies_for :label_issue_attributes

  def self.label
    Issue.human_attribute_name(:priority)
  end

  def self.available_values(*)
    IssuePriority.find(:all, :order => 'position DESC').map { |i| [i.name, i.id] }
  end
end
