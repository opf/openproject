class CostQuery::GroupBy
  class AssignedToId < Base
    join_table Issue
    applies_for :label_issue_attributes
    label Issue.human_attribute_name(:assigned_to)
  end
end
