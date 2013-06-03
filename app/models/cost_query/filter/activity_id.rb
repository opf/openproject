class CostQuery::Filter::ActivityId < CostQuery::Filter::Base
  label Issue.human_attribute_name(:activity)

  def self.available_values(*)
    TimeEntryActivity.find(:all, :order => 'name').map { |a| [a.name, a.id] }
  end
end
