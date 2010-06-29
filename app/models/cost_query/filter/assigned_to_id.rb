class CostQuery::Filter::AssignedToId < CostQuery::Filter::Base
  null_operators
  join_table Issue

  def self.available_values
    User.all.map { |u| [u.name, u.id] }
  end
end
