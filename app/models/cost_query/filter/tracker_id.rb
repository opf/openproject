class CostQuery::Filter::TrackerId < CostQuery::Filter::Base
  join_table Issue
  applies_for :label_issue
  label :field_tracker

  def self.available_values
    Tracker.all.map { |i| [i.name, i.id] }
  end
end
