module CostQuery::GroupBy
  class StatusId < Base
    join_table Issue
    applies_for :label_issue_attributes
    label :field_status
  end
end
