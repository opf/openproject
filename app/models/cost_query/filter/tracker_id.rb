class CostQuery::Filter::TrackerId < CostQuery::Filter::Base
  join_table Issue
  applies_for :label_issue_attributes
  label :field_tracker

  def self.available_values(*)
    Tracker.find(:all, :order => 'name').map { |i| [i.name, i.id] }
  end
end
