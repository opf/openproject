class CostQuery::GroupBy::ActivityId < Report::GroupBy::Base
  def self.label
    TimeEntry.human_attribute_name(:activity)
  end
end
