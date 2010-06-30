class CostQuery::Filter::CategoryId < CostQuery::Filter::Base
  null_operators
  join_table Issue
  applies_for :label_issue
  label :field_category

  def self.available_values
    IssueCategory.all.map { |c| [c.name, c.id] }
  end
end
