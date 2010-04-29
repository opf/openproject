module CostQuery::GroupBy
  class CostObjectId < Base
    join_table Issue
  end
end
