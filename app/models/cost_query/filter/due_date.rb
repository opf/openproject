class CostQuery::Filter::DueDate < CostQuery::Filter::Base
  date_operators
  join_table Issue
  applies_for :label_issue
  label :field_due_date
end
