class CostQuery::Filter::AssignedToId < CostQuery::Filter::Base
  null_operators
  join_table Issue
  applies_for :label_issue
  label :field_assigned_to

  def self.available_values
    CostQuery::Filter::UserId.available_values
  end
end
