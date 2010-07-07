class CostQuery::Filter::UpdatedOn < CostQuery::Filter::Base
  use :time_operators
  label :field_updated_on
end