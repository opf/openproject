class CostQuery::Filter::StartDate < CostQuery::Filter::Base
  date_operators
  join_table Issue
  applies_for :label_issue
  label :field_start_date
end
