class CostQuery::Filter::StartDate < CostQuery::Filter::Base
  date_operators
  join_table Issue
end
