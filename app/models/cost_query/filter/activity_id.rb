class CostQuery::Filter::ActivityId < CostQuery::Filter::Base
  label :field_activity

  def self.available_values(param={})
    TimeEntryActivity.all.map { |a| [a.name, a.id] }
  end
end
