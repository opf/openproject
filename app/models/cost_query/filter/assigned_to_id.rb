class CostQuery::Filter::AssignedToId < CostQuery::Filter::Base
  null_operators
  join_table Issue
  label :field_assigned_to

  def self.available_values
    User.all.map { |u| [u.name, u.id] }
  end
end
