class CostQuery::Filter::UpdatedOn < CostQuery::Filter::Base
  use_time_operators
  label :field_updated_on
end