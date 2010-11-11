class CostQuery::Filter::CreatedOn < CostQuery::Filter::Base
  db_field "entries.created_on"
  use :time_operators
  label :field_created_on
end