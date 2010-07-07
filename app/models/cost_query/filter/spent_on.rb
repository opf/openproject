class CostQuery::Filter::SpentOn < CostQuery::Filter::Base
  use_time_operators
  use_date_operators
  label :field_spent_on
end
