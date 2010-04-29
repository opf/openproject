module CostQuery::GroupBy
  class TrackerId < Base
    join_table Issue
  end
end
