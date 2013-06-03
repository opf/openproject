class CostQuery::GroupBy
  class ActivityId < Base
    label TimeEntry.human_attribute_name(:activity)
  end
end
