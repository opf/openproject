class CostQuery::GroupBy::WorkPackageId < Report::GroupBy::Base

  def self.label
    WorkPackage.model_name.human
  end
end
