class CostQuery::Filter::TrackerId < CostQuery::Filter::Base
  join_table Issue
  applies_for :label_issue_attributes
  label Issue.human_attribute_name(:tracker)

  def self.available_values(*)
    Tracker.find(:all, :order => 'name').map { |i| [i.name, i.id] }
  end
end
