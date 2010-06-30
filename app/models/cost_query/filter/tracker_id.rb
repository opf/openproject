class CostQuery::Filter::TrackerId < CostQuery::Filter::Base
  join_table Issue
  label :field_tracker

  def self.available_values
    Tracker.all.map { |i| [i.name, i.id] }
  end
end
