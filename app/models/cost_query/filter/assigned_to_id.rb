class CostQuery::Filter::AssignedToId < CostQuery::Filter::Base
  null_operators
  join_table Issue
  label :field_assigned_to

  def self.available_values
    CostQuery::Filter::UserId.available_values
  end
end
