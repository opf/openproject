module CostQuery::GroupBy
  class TrackerId < Base
    join_table Issue
    applies_for :label_issue_attributes
    label :field_tracker
  end
end
