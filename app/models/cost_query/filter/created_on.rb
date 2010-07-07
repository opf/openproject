class CostQuery::Filter::CreatedOn < CostQuery::Filter::Base
  use_time_operators
  use_date_operators
  label :field_created_on
end