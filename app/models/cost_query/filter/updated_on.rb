class CostQuery::Filter::UpdatedOn < CostQuery::Filter::Base
  db_field "entries.updated_on"
  use :time_operators
  label :field_updated_on
end