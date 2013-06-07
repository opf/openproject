class CostQuery::GroupBy
  class ActivityId < Base

    def self.label
      TimeEntry.human_attribute_name(:activity)
    end
  end
end
