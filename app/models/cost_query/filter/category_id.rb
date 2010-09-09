class CostQuery::Filter::CategoryId < CostQuery::Filter::Base
  use :null_operators
  join_table Issue
  applies_for :label_issue_attributes
  label :field_category

  def self.available_values(user)
    IssueCategory.find(:all, :order => 'name').map { |c| [c.name, c.id] }
  end
end
