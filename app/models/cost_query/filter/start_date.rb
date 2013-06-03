class CostQuery::Filter::StartDate < CostQuery::Filter::Base
  use :time_operators
  join_table Issue
  applies_for :label_issue_attributes
  label Issue.human_attribute_name(:start_date)
end
