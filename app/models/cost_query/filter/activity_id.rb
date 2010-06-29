class CostQuery::Filter::ActivityId < CostQuery::Filter::Base
  def self.available_values(param={})
    TimeEntryActivity.all.map { |a| [a.name, a.id] }
  end
end
