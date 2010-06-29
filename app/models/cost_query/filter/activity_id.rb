class CostQuery::Filter::ActivityId < CostQuery::Filter::Base
  def available_values(query=nil)
    TimeEntryActivity.all.map { |a| [a.name, a.id] }
  end
end
