class CostQuery::GroupBy
  class ActivityId < Base
    label Issue.human_attribute_name(:activity)
  end
end
