class CostQuery::Filter::AuthorId < CostQuery::Filter::Base
  join_table Issue
  applies_for :label_issue_attributes

  def self.label
    Issue.human_attribute_name(:author)
  end

  def self.available_values(*)
    CostQuery::Filter::UserId.available_values
  end
end
