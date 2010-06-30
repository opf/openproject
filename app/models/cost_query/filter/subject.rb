class CostQuery::Filter::Subject < CostQuery::Filter::Base
  join_table Issue
  applies_for :label_issue
  label :field_subject
end
