class CostQuery::GroupBy::CostObjectId < Report::GroupBy::Base
  join_table WorkPackage
  applies_for :label_work_package_attributes

  def self.label
    CostObject.model_name.human
  end
end
