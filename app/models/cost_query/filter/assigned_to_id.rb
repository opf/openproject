class CostQuery::Filter::AssignedToId < CostQuery::Filter::Base
  use :null_operators
  join_table Issue
  applies_for :label_issue_attributes
  label :field_assigned_to

  def self.available_values(user)
    CostQuery::Filter::UserId.available_values user
  end
end
