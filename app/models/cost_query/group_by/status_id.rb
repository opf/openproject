class CostQuery::GroupBy
  class StatusId < Base
    join_table Issue
    applies_for :label_issue_attributes
    label Issue.human_attribute_name(:status)
  end
end
