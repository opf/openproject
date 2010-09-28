class CostQuery::Filter::ActivityId < CostQuery::Filter::Base
  label :field_activity

  def self.available_values(*)
    TimeEntryActivity.find(:all, :order => 'name').map { |a| [a.name, a.id] }
  end
end
