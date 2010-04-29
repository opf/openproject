class CostQuery::Filter::FixedVersionId < CostQuery::Filter::Base
  null_operators
  join_table Issue
end
