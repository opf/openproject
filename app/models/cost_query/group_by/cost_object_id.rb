class CostQuery::GroupBy
  class CostObjectId < Base
    join_table Issue
    applies_for :label_issue_attributes
    label :field_cost_object
  end
end
