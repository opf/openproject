class CostQuery::GroupBy
  class PriorityId < Base
    join_table Issue
    applies_for :label_issue_attributes
    label :field_priority
  end
end
