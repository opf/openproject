class CostQuery::GroupBy
  class CostObjectId < Base
    join_table Issue
    applies_for :label_issue_attributes
    label CostObject.model_name.human
  end
end
