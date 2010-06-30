class CostQuery::Filter::DueDate < CostQuery::Filter::Base
  date_operators
  join_table Issue
  label :field_due_date
end
