class CostQuery::Filter::Subject < CostQuery::Filter::Base
  use :string_operators
  join_table Issue
  applies_for :label_issue_attributes
  label :field_subject
end
