class CostQuery::Filter::TrackerId < CostQuery::Filter::Base
  join_table Issue

  def self.available_values
    Tracker.all.map { |i| [i.name, i.id] }
  end
end
