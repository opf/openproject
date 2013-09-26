class CostQuery::GroupBy::FixedVersionId < Report::GroupBy::Base
  join_table WorkPackage
  applies_for :label_work_package_attributes

  def self.label
    WorkPackage.human_attribute_name(:fixed_version)
  end
end
