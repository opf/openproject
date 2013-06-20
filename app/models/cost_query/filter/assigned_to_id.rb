class CostQuery::Filter::AssignedToId < Report::Filter::Base
  use :null_operators
  join_table Issue
  applies_for :label_issue_attributes

  def self.label
    Issue.human_attribute_name(:assigned_to)
  end

  def self.available_values(*)
    CostQuery::Filter::UserId.available_values
  end
end
