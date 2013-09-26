class CostQuery::Filter::DueDate < Report::Filter::Base
  use :time_operators
  join_table WorkPackage
  applies_for :label_work_package_attributes

  def self.label
    WorkPackage.human_attribute_name(:due_date)
  end
end
