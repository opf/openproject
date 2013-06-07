class CostQuery::GroupBy
  class CostTypeId < Base

    def self.label
      CostType.model_name.human
    end
  end
end
