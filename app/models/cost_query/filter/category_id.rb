class CostQuery::Filter::CategoryId < CostQuery::Filter::Base
  null_operators
  join_table Issue
  label :field_category

  def self.available_values
    IssueCategory.all.map { |c| [c.name, c.id] }
  end
end
