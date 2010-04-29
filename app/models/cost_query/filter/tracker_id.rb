class CostQuery::Filter::TrackerId < CostQuery::Filter::Base
  join_table Issue
end
