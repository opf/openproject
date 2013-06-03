class CostQuery::Filter::AuthorId < CostQuery::Filter::Base
  join_table Issue
  applies_for :label_issue_attributes
  label Issue.human_attribute_name(:author)

  def self.available_values(*)
    CostQuery::Filter::UserId.available_values
  end
end
