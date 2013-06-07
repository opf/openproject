class CostQuery::GroupBy
  class ProjectId < Base

    def self.label
      Project.model_name.human
    end
  end
end
