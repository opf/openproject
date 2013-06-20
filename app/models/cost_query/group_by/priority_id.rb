class CostQuery::GroupBy::PriorityId < Report::GroupBy::Base
  join_table Issue
  applies_for :label_issue_attributes

  def self.label
    Issue.human_attribute_name(:priority)
  end
end
