class CostQuery::Filter::StartDate < Report::Filter::Base
  use :time_operators
  join_table WorkPackage
  applies_for :label_work_package_attributes

  def self.label
    WorkPackage.human_attribute_name(:start_date)
  end
end
