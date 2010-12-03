class CostQuery::GroupBy
  class AssignedToId < Base
    join_table Issue
    applies_for :label_issue_attributes
    label :field_assigned_to
  end
end
