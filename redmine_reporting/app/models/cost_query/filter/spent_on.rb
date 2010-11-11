class CostQuery::Filter::SpentOn < CostQuery::Filter::Base
  use :time_operators
  label :label_spent_on_reporting
end
