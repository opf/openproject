class CostQuery::Filter::CategoryId < CostQuery::Filter::Base
  null_operators
  join_table Issue

  def available_values
    IssueCategory.all.map { |c| [c.name, c.id] }
  end
end
