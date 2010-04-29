class CostQuery::Filter::DueDate < CostQuery::Filter::Base
  date_operators
  join_table Issue
end
