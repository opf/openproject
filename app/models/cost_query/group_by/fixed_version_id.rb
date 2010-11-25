module CostQuery::GroupBy
  class FixedVersionId < Base
    join_table Issue
    applies_for :label_issue_attributes
    label :field_fixed_version
  end
end
