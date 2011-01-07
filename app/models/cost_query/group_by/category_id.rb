class CostQuery::GroupBy
  class CategoryId < Base
    join_table Issue
    applies_for :label_issue_attributes
    label :field_category
  end
end
