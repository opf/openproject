class CostQuery::GroupBy::CostTypeId < Report::GroupBy::Base

  def self.label
    CostType.model_name.human
  end
end
