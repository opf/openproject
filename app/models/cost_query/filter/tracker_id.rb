class CostQuery::Filter::TrackerId < Report::Filter::Base
  join_table WorkPackage
  applies_for :label_work_package_attributes

  def self.label
    WorkPackage.human_attribute_name(:tracker)
  end

  def self.available_values(*)
    Tracker.find(:all, :order => 'name').map { |i| [i.name, i.id] }
  end
end
