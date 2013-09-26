class CostQuery::GroupBy::TypeId < Report::GroupBy::Base
  join_table WorkPackage
  applies_for :label_work_package_attributes

  def self.label
    WorkPackage.human_attribute_name(:type)
  end
end
