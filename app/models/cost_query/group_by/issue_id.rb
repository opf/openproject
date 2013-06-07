class CostQuery::GroupBy
  class IssueId < Base

    def self.label
      Issue.model_name.human
    end
  end
end
