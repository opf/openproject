class CostQuery::Filter::AuthorId < CostQuery::Filter::Base
  join_table Issue
  applies_for :label_issue_attributes
  label :field_author

  def self.available_values(author)
    CostQuery::Filter::UserId.available_values author
  end
end
