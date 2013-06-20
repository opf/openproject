class CostQuery::Filter::ActivityId < Report::Filter::Base

  def self.label
    TimeEntry.human_attribute_name(:activity)
  end

  def self.available_values(*)
    TimeEntryActivity.find(:all, :order => 'name').map { |a| [a.name, a.id] }
  end
end
