class CostQuery::Filter::Subject < Report::Filter::Base
  use :string_operators
  join_table WorkPackage
  applies_for :label_work_package_attributes

  def self.label
    WorkPackage.human_attribute_name(:subject)
  end
end
