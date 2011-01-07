class CostQuery::GroupBy
  class AuthorId < Base
    join_table Issue
    applies_for :label_issue_attributes
    label :field_author
  end
end
