class CostQuery::Filter::Subject < CostQuery::Filter::Base
  use_string_operators
  join_table Issue
  applies_for :label_issue
  label :field_subject
end
