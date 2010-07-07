class CostQuery::Filter::SpentOn < CostQuery::Filter::Base
  use :time_operators
  label :field_spent_on
end
