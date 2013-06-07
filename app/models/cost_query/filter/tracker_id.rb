class CostQuery::Filter::TrackerId < CostQuery::Filter::Base
  join_table Issue
  applies_for :label_issue_attributes

  def self.label
    Issue.human_attribute_name(:tracker)
  end

  def self.available_values(*)
    Tracker.find(:all, :order => 'name').map { |i| [i.name, i.id] }
  end
end
