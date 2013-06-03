class CostQuery::GroupBy
  class AuthorId < Base
    join_table Issue
    applies_for :label_issue_attributes
    label Issue.human_attribute_name(:author)
  end
end
