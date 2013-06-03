class CostQuery::GroupBy
  class CategoryId < Base
    join_table Issue
    applies_for :label_issue_attributes
    label Issue.human_attribute_name(:category)
  end
end
